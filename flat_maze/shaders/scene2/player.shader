shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform float rTime;
uniform int iFrame;
uniform int anim_state;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform sampler2D iChannel4;
uniform sampler2D iChannel5;
uniform sampler2D iChannel6;
uniform sampler2D logic;
uniform float zoom;
uniform vec3 iMouse;

vec4 get_collision_hp(){
	return texelFetch(logic,ivec2(1,0),0).xyzw;
}

vec4 tilesx2(vec2 uv,float it, sampler2D ismlp){
	float fms=2.;
	int max_frames=3;
	if(anim_state==0){
		uv.x=1.-uv.x;
	}
	uv*=1./fms;
	int index=int(iTime*float(max_frames))%int(max_frames);
	float idx=float(index);
	uv+=1./zoom*(1./fms*(vec2(float(int(idx)%int(fms)),float(int(idx)/int(fms)))));
	uv+=-0.5*1./fms;
	uv*=zoom;
	uv=clamp(uv,(-1./fms)*0.5+(1./fms*(vec2(float(int(idx)%int(fms)),float(int(idx)/int(fms))))),
	(1./fms)*0.5+(1./fms*(vec2(float(int(idx)%int(fms)),float(int(idx)/int(fms))))));
	uv+=0.5*1./fms;
	vec4 col=texture(ismlp,uv);
	return col;
}

vec4 tilesx3inx4(vec2 uv, sampler2D ismlp){
	float fms=4.;
	int max_frames=8;
	if((anim_state==0)||(anim_state==4)){
		uv.x=1.-uv.x;
	}
	uv*=1./fms;
	int index=int(iTime*float(max_frames))%int(max_frames);
	if(index>=3)index+=1;
	if(index>6)index+=1;
	float idx=float(index);
	uv+=1./zoom*(1./fms*(vec2(float(int(idx)%int(fms)),float(int(idx)/int(fms)))));
	uv+=-0.5*1./fms;
	uv*=zoom;
	uv=clamp(uv,(-1./fms)*0.5+(1./fms*(vec2(float(int(idx)%int(fms)),float(int(idx)/int(fms))))),
	(1./fms)*0.5+(1./fms*(vec2(float(int(idx)%int(fms)),float(int(idx)/int(fms))))));
	uv+=0.5*1./fms;
	vec4 col=texture(ismlp,uv);
	return col;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ,in vec2 iResolution)
{
	vec2 uv=fragCoord/iResolution;
	vec4 col=vec4(0.);
	if((anim_state==0)||(anim_state==1)){
		col=tilesx3inx4(uv,iChannel0);
	}
	else
	if(anim_state==2){
		col=tilesx3inx4(uv,iChannel2);
	}
	else
	if(anim_state==3){
		col=tilesx3inx4(uv,iChannel1);
	}
	else
	
	if((anim_state==4)||(anim_state==5)){
		col=tilesx3inx4(uv,iChannel3);
	}
	else
	if(anim_state==6){
		col=tilesx3inx4(uv,iChannel5);
	}
	else
	if(anim_state==7){
		col=tilesx3inx4(uv,iChannel4);
	}
	
	vec2 state=get_collision_hp().yw;
	float lost_hp_timer=state.y;
	float player_hp=state.x;
	bool is_player_alive=player_hp>=1.;
	bool is_player_win=player_hp>=1000.;
	
	fragColor=col;
	fragColor.rgb = fragColor.rgb *0.25 + fragColor.rgb*fragColor.rgb;
	fragColor.rgb += vec3(01.8,0.2,0.1)*smoothstep(0.25,0.5,lost_hp_timer);
	if(!is_player_alive)fragColor.rgb=vec3(dot(fragColor.rgb,vec3(1.))/3.);
	float startup_zoom_timer_sec=6.0;
	fragColor.a*=smoothstep(5.5,startup_zoom_timer_sec,rTime);
	if((!is_player_alive)||(is_player_win))fragColor.a*=smoothstep(0.0,0.5,lost_hp_timer);

}
void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution);
}