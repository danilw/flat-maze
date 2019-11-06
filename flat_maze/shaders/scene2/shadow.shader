shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform int iFrame;
uniform float zoom;
uniform vec4 col_o1:hint_color;

uniform sampler2D iChannel0;
uniform vec3 iMouse;

float bw_tex( vec2 uv)
{
	vec4 col=texture(iChannel0,uv);
	if(col.r<0.)col=vec4(0.);
	//float res=((1.25+0.5*max(0.01,zoom-1.))*max(max(col.r,col.g),col.b))*col.a;
	float res=(20.*dot(col.rgb,vec3(1.)))*col.a;
	res=clamp(res,0.,1.);
	return 1.-res;

}


//https://www.shadertoy.com/view/XsK3RR
//1D Distance field shadow map.
//Each row is a radial shadow map for a light.
//r = distance
//gba = light info (position / color)



float Scene(vec2 uv, vec2 iResolution)
{
    uv.x *=  1./(iResolution.x / iResolution.y);
    uv+=.5;
    return bw_tex(uv);
}

float MarchShadow(vec2 orig, vec2 dir, vec2 iResolution)
{
    float d = 0.0;
    
	int MAX_STEPS=256;
	float EPS=1e-4;
	
    for(int i = 0;i < MAX_STEPS;i++)
    {
        float ds = Scene(dir * d - orig, iResolution);
        ds*=(1./float(MAX_STEPS))/max(0.01,zoom)*2.25;
        d += ds;
        
        if(ds < EPS)
        {
        	break;   
        }
    }
    
    return d;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord)
{
	fragColor=vec4(0.);
	vec2 iResolution=vec2(1280.,720.);
    vec2 res = iResolution.xy / iResolution.y;  
    
	float tau = atan(1.0)*8.0;
    float a = (fragCoord.x / iResolution.x) * tau;
    vec2 dir = vec2(cos(a), sin(a));
    
    int id = int(fragCoord.y);
    if(id>1)return;
	
	vec2 origin1=vec2(0.,-0.1);
	vec3 light_color1=col_o1.rgb;
	int slot = int(fragCoord.x);
	
    float dist = MarchShadow(origin1/max(0.01,zoom), dir, iResolution);
    
	vec3 data = vec3(0);
	
    if(slot == 0)
    {
        data = vec3(origin1,0);
    }
    
    if(slot == 1)
    {
    	data = light_color1;   
    }
	
	fragColor = vec4(dist, data);
} 







void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution);
}