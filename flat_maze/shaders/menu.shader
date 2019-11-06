shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform float scale_v;
uniform int iFrame;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform vec3 iMouse;

void mainImage( out vec4 fragColor, in vec2 fragCoord ,in vec2 iResolution)
{
	vec2 uv=fragCoord/iResolution;
	fragColor=texture(iChannel1,uv);
	if(all(greaterThan(uv-0.5,vec2(0.)))){
		float a=smoothstep(0.6,0.5,(uv.x+uv.y)-1.);
		fragColor.rgb=fragColor.rgb*a+texture(iChannel2,uv).rgb*(1.-a);
	}
	float TIMESPAN=20.0;
	float st = 1.0/TIMESPAN;
	vec3 prevCol = texture(iChannel0,uv).rgb;
    fragColor.rgb = prevCol*(1.0-st)+fragColor.rgb*st;
	fragColor.a=1.;

}
void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution);
}