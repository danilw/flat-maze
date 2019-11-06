shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform float delta;
uniform float temp_mov_timer;
uniform int iFrame;
uniform int anim_state1;
uniform int anim_state2;
uniform float add_speed;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform vec3 iMouse;

//return vec2(0) on normalize length==0
vec2 my_normalize(vec2 v){
	float len = length(v);
	if(len==0.0)return vec2(0.,0.);
	return v/len;
}

vec4 get_collision_hp(){
	return texelFetch(iChannel0,ivec2(1,0),0).xyzw;
}

vec4 screen_pos(){
	vec4 old_state=texelFetch(iChannel0,ivec2(0,0),0);
	vec2 map_res=vec2(320.,180.);
	vec2 iResolution=vec2(1280.,720.);
	vec2 res=0.5*(iResolution/iResolution.y);
	vec2 self_pos=old_state.xy;
	vec2 dir=old_state.zw;
	float mov_speed=0.005+add_speed*0.001/6.; // start mov speed
	float max_mov_speed=0.0125+add_speed*0.001;
	
	vec4 retc=vec4(0.);
	
	vec4 chp=get_collision_hp();
	bool is_collide=chp.x>0.;
	float player_hp=chp.y;
	float slowdown_timer=chp.z;
	float mn=1.;
	if(is_collide){
		mn=0.25;
	}
	
	if(iFrame<10)
	{
		vec2 spawn_pos=(vec2(2.+0.5,179.+0.5)/map_res)*iResolution; //in pixels that map ID
		self_pos=spawn_pos/iResolution.y-res;
		retc.xy=self_pos;
		return retc;
	}
	
	float tmspd=mov_speed+(max_mov_speed-mov_speed)*smoothstep(0.5,1.5,temp_mov_timer)*smoothstep(3.,0.,slowdown_timer);
	
	if((anim_state1==2)||(anim_state1==6)){
		dir.y+=tmspd*delta*8.5;
	}
	else
	if((anim_state1==3)||(anim_state1==7)){
		dir.y+=-tmspd*delta*8.5;
	}else dir.y=dir.y-dir.y*delta*8.5;
	
	if((anim_state2==4)||(anim_state2==0)){
		dir.x+=-tmspd*delta*8.5;
	}
	else
	if((anim_state2==1)||(anim_state2==5)){
		dir.x+=tmspd*delta*8.5;
	}
	else dir.x=dir.x-dir.x*delta*8.5;
	
	dir=my_normalize(dir/tmspd)*min(length(dir),tmspd); // OpenGL normalize(vec2(0))=inf

	//dir.x=clamp(dir.x,-tmspd,tmspd);
	//dir.y=clamp(dir.y,-tmspd,tmspd);
	
	if(player_hp>0.)
	self_pos+=dir*delta*mn;
	float px=1.5/iResolution.y;
	self_pos.x=clamp(self_pos.x,-res.x+px*2.,res.x-px);
	self_pos.y=clamp(self_pos.y,-res.y+px,res.y-px);
	
	retc.xy=self_pos;
	retc.zw=dir;
	
	return retc;
}

vec2 get_screen_pos(){
	return texelFetch(iChannel0,ivec2(0,0),0).xy;
}

vec2 get_screen_dir(){
	return texelFetch(iChannel0,ivec2(0,0),0).zw;
}

float decodeval_vel(int varz) {
    int iret=0;
    iret=varz>>8;
    int gxffff=65535;
    return float(iret)/float(gxffff);
}

// get [pos,vel]
vec4 getV(in vec2 p){
    if (p.x < 0.001 || p.y < 0.001) return vec4(0);
    vec4 tval=texelFetch( iChannel1, ivec2(p), 0 );
	if(tval.x<0.)return vec4(-1.,0.,0.,0.);
    float p1=tval.x;
    float p2=tval.y;
    float v1=decodeval_vel(abs(int(tval.z)));
    float v2=decodeval_vel(abs(int(tval.w)));
    float si=1.;
    if(tval.z<0.)si=-1.;
    float si2=1.;
    if(tval.w<0.)si2=-1.;
    vec2 unp=vec2(si*v1,si2*v2);
    return vec4(vec2(p1,p2),unp.xy);
}

ivec2 extra_dat_vel(vec2 p){
    vec4 tval=texelFetch( iChannel1, ivec2(p), 0 );
    int gxff=255;
    return ivec2(abs(int(tval.z))&gxff,abs(int(tval.w))&gxff);
}

// get saved unique ID
int get_id(vec2 p){
    ivec2 v2=extra_dat_vel(p);
    int iret=(v2[0]<<8)|(v2[1]<<0);
    return iret;
}

ivec2 unpack_type_hp(int id){
	int gxff=255;
	return ivec2(((id>>8)&gxff),((id>>0)&gxff));
}

vec4 player_collision(){
	
	vec4 retc=vec4(0.);
	
	if(iFrame<10)
	{
		retc=vec4(-1.,10.,0.,0.);
		return retc;
	}
	
	vec4 old_state=texelFetch(iChannel0,ivec2(1,0),0);
	vec2 screen_res=vec2(1280.,720.);
	vec2 res=screen_res/screen_res.y;
	vec2 index2dfo=(((get_screen_pos())/(res))+0.5)*vec2(screen_res)-0.25;
	vec2 index2ddir=(get_screen_dir()/(res))*vec2(screen_res);
	vec2 next_fc=index2dfo+index2ddir*delta;
	
	float is_collide=old_state.x;
	float player_hp=old_state.y;
	float slowdown_timer=old_state.z;
	float lost_hp_timer=old_state.w;
	lost_hp_timer+=-delta;
	lost_hp_timer=max(lost_hp_timer,0.);
	slowdown_timer+=-delta;
	slowdown_timer=max(slowdown_timer,0.);
	
	vec4 v = vec4(0.); 
    vec2 lp=vec2(-10.);
    bool br=false;
    for (int x=-4; x<=4; x++) {
        if(br)break;
        for (int y=-4; y<=4; y++) {
            vec2 np = next_fc + vec2(float(x),float(y));
            vec4 p = getV(np);
            if(trunc(next_fc) == trunc(p.xy)){
                v = p;
                lp=np;
                br=true;
                break;
            }
        }
    }
	if(br){
		int self_id=get_id(trunc(lp.xy));
		ivec2 type_hp=unpack_type_hp(self_id);
		if((int(type_hp.x)!=40)&&(int(type_hp.x)!=41)&&(int(type_hp.x)!=42)&&(int(type_hp.x)!=43)){
		is_collide=1.;
		slowdown_timer=3.;
		if((lost_hp_timer<=0.01)&&(player_hp>0.)&&(player_hp<1000.)&&(type_hp.x<4)){
			player_hp+=-1.;
			lost_hp_timer=0.5;
		}
		}else{
			is_collide=-1.;
		}
	}else{
		is_collide=-1.;
	}
	if((index2dfo.x>1260.)&&(index2dfo.y<16.)&&(player_hp<1000.)){
		lost_hp_timer=0.5;
		player_hp=2000.;
	}
	retc=vec4(is_collide,player_hp,slowdown_timer,lost_hp_timer);
	return retc;
}

// [0,0] screen_pos logic [pos,dir]
// [1,0] player collision check [is_collide,player_HP,slowdown_timer,lost_hp_timer] player_HP>1000=win

void mainImage( out vec4 fragColor, in vec2 fragCoord ,in vec2 iResolution)
{
	fragColor=vec4(0.);
	ivec2 ipx=ivec2(fragCoord);
	if(ipx==ivec2(0,0)){
		fragColor=screen_pos();
	}
	if(ipx==ivec2(1,0)){
		fragColor=player_collision();
	}
	
}
void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution);
}