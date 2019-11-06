shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform int iFrame;
uniform int index;
uniform float scale;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform vec3 iMouse;

void mainImage( out vec4 fragColor, in vec2 fragCoord ,in vec2 iResolution)
{
	vec2 uv=fragCoord/iResolution;
	uv*=1./8.;
	uv+=1./scale*(1./8.*(vec2(float(index%8),float(index/8))));
	uv+=-(1./8.)/2.;
	uv*=scale;
	uv=clamp(uv,(-1./8.)/2.+1./8.*(vec2(float(index%8),float(index/8))),(1./8.)/2.+1./8.*(vec2(float(index%8),float(index/8))));
	uv+=(1./8.)/2.;
	fragColor.rgb=textureLod(iChannel0,uv,0).rgb;
	fragColor.a=min(textureLod(iChannel0,uv,0).a,1./scale)*smoothstep(2.,1.5,iTime);

}
void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution);
}