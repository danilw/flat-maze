shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform int iFrame;
uniform float zoom;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform sampler2D logic;
uniform float mousedr;
uniform vec3 iMouse;

vec2 get_screen_pos(){
	return texelFetch(logic,ivec2(0,0),0).xy;
}

vec2 my_normalize(vec2 v){
	float len = length(v);
	if(len==0.0)return vec2(0.,0.);
	return v/len;
}

//save force normal map, two layers
//pixel [x,y]-small normal map for collision
//pixel [z,w]-big normal for force to player
//explossion force added to both layers

void mainImage( out vec4 fragColor, in vec2 fragCoord ,in vec2 iResolution)
{
	vec2 res=iResolution/iResolution.y;
	vec2 uv = fragCoord.xy / iResolution.y - res/2.0;
	vec2 index2df=(get_screen_pos()/(res))*vec2(iResolution);
	//index2df=vec2(0.,0.);
	float static_zoom=38.;
	vec2 f_pos=vec2(0.5);
	vec2 tuv=(fragCoord.xy-index2df+f_pos) / iResolution.y - res/2.0;
	tuv+=vec2(0.,-.025)/max(0.01,static_zoom);
	vec2 nor=my_normalize(tuv)*smoothstep(0.5,0.45,length(tuv*static_zoom)*5.);
	
	vec2 nor3=3.*my_normalize(tuv)*smoothstep(0.5,0.45,length(tuv*static_zoom)*(5.-4.5*mousedr))*mousedr;
	
	static_zoom=1.;
	tuv=(fragCoord.xy-index2df+f_pos) / iResolution.y - res/2.0;
	//tuv+=vec2(0.,-.025)/max(0.01,static_zoom);
	vec2 nor2=my_normalize(tuv)*(0.015+smoothstep(0.,0.15,length(tuv*static_zoom)*1.));
	
	nor+=nor3;
	nor2+=-nor3;
	
	fragColor=vec4(nor,-nor2);

}
void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution);
}