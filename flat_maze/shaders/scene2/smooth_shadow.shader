shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform int iFrame;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform vec3 iMouse;
uniform float zoom;

float SampleShadow(int id, vec2 uv, vec2 iResolution)
{
	float tau = atan(1.0)*8.0;
	vec2 hpo = 0.5 / iResolution.xy;
    float a = atan(uv.y, uv.x)/tau + 0.5;
    float r = length(uv);
    
    float idn = float(id)/iResolution.y;
   
    float s = texture(iChannel0, vec2(a, idn) + hpo).x;
    
    return 1.0-smoothstep(s, s+0.02, length(uv));    
}

vec2 LightOrigin(int id)
{
	return texelFetch(iChannel0,ivec2(0, id),0).yz;   
}

vec3 LightColor(int id)
{
	return texelFetch(iChannel0,ivec2(1, id),0).yzw;   
}

vec3 MixLights(vec2 uv, vec2 iResolution)
{
	vec3 AMBIENT_LIGHT=vec3(0.1, 0.01, 0.01);
	int NUM_LIGHTS=1;
    vec3 b = AMBIENT_LIGHT;
	//float mz=zoom/0.015;
	float mz=zoom;
	for(int i = 0;i < NUM_LIGHTS;i++)
    {
	    vec2 o = LightOrigin(i);
	    vec3 c = LightColor(i);
	    
		float l = (2.25-min((01.*length(vec3((uv*((mz)) - o), 0.1))),2.25))/2.;
	    l *= SampleShadow(i, uv-o/max(0.01,mz),iResolution);
	    b += c * l;
    }
    return b;
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ,in vec2 iResolution)
{
	vec2 uv=fragCoord/iResolution;
	vec2 res=iResolution/iResolution.y;
	
	vec2 uvo = fragCoord.xy / iResolution.y - res/2.0;
	uvo=-uvo;
	fragColor.rgb =MixLights(uvo,iResolution);
	float TIMESPAN=4.0;
	float st = 1.0/TIMESPAN;
	vec3 prevCol = texture(iChannel1,uv).rgb;
    fragColor.rgb = prevCol*(1.0-st)+fragColor.rgb*st;
	fragColor.a=1.;

}
void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution);
}