shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform int iFrame;
uniform float scale_v;
uniform bool clean_scr;
uniform bool clean_scr5;
uniform bool clean_scr10;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform sampler2D maze_map;
uniform sampler2D color_map;
uniform sampler2D force_collision;
uniform float mousedl;
uniform float scr_posx;
uniform float scr_posy;
uniform float speed_x;
uniform int last_index;
uniform bool spawn1;
uniform bool spawn2;
uniform vec2 gravity;
uniform bool spwan_b_once;
uniform int anim_state;
uniform sampler2D logic;
uniform vec3 iMouse;

// base on https://www.shadertoy.com/view/wdG3Wd

// data
// in [x,y,z,w]
// x-posx
// y-posy
// z-0xffff-velx, 0xff-data
// w-0xffff-vely, 0xff-data

//in data(0x[ffff]) stored:
//[its type][its HP]
// HP-values 0-0xff when HP==0 types go down
// type:
// 1-2 ghost
// 3-zombi
// 4-18 blocks 
// +20 is on fire
// 40 is bullet(right) 41 left 42 top 43 down


//HP used also as timer(frames) for burn/explode animation

// ids from color_id_map:
// idx for color block, same for lolly but wth 0.5 value
// (1,0,0) red
// (0,1,0) green
// (0,0,1) blue
// (1,1,0) yellow
// (0,1,1) purle
// (1,0,1) light red
// (1,1,1) orange

// particle shader here https://www.shadertoy.com/view/tstSz7

vec2 tile_uv(vec2 uv, vec2 iResolution){
	ivec2 tuv=ivec2(uv*vec2(320.,180.));
	return vec2(tuv)/vec2(320.,180.);
}

vec2 tile_uv_f(vec2 uv, vec2 iResolution){
	vec2 tuv=vec2(uv*vec2(320.,180.));
	return fract(tuv);
}

bool get_map(vec2 uv, vec2 iResolution){
	return (texture(maze_map,tile_uv(uv,iResolution)).r>0.5);
}

vec3 get_col_map(vec2 uv, vec2 iResolution){
	return (texture(color_map,tile_uv(uv,iResolution)).rgb);
}

ivec2 index_x(int id){
	ivec2 p_res=ivec2(1280,720);
	int x=id%p_res.x;
	int y=id/p_res.x;
	return ivec2(x,y);
}

bool is_alive(int id){
	return true;
	if(texelFetch(iChannel1,index_x(id),0).y>0.)return true;
	return false;
}

float decodeval_vel(int varz) {
    int iret=0;
    iret=varz>>8;
    int gxffff=65535;
    return float(iret)/float(gxffff);
}

int encodeval_vel(ivec2 colz) {
    int gxffff=65535;
    int gxff=255;
    return int(((colz[0]&gxffff)<< 8)|((colz[1]&gxff)<< 0));
}


// get [pos,vel]
vec4 getV(in vec2 p){
    if (p.x < 0.001 || p.y < 0.001) return vec4(0);
    vec4 tval=texelFetch( iChannel0, ivec2(p), 0 );
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
    vec4 tval=texelFetch( iChannel0, ivec2(p), 0 );
    int gxff=255;
    return ivec2(abs(int(tval.z))&gxff,abs(int(tval.w))&gxff);
}

// get saved unique ID
int get_id(vec2 p){
    ivec2 v2=extra_dat_vel(p);
    int iret=(v2[0]<<8)|(v2[1]<<0);
    return iret;
}

ivec4 save_id(int id){
    int gxff=255;
    int gxf=15;
    int a=(id>>20)&gxf;
    int b=(id>>16)&gxf;
    int c=(id>>8)&gxff;
    int d=(id>>0)&gxff;
    return ivec4(a,b,c,d);
}

vec2 pack_vel(vec2 vel,ivec2 extra_val){
    int gxffff=65535;
    int v1=abs(int(vel.x*float(gxffff)));
    int v2=abs(int(vel.y*float(gxffff)));
    float vx=float(encodeval_vel(ivec2(v1,extra_val.x)));
    float vy=float(encodeval_vel(ivec2(v2,extra_val.y)));
    float si=1.;
    if(vel.x<0.)si=-1.;
    float si2=1.;
    if(vel.y<0.)si2=-1.;
    return vec2(vx*si,vy*si2);
}

// save everything to pixel color
vec4 save_all(vec2 pos, vec2 vel, int id){
    ivec4 tid=save_id(id);
    ivec2 extra_data_pos=tid.xy;
    ivec2 extra_data_vel=tid.zw;
    vec2 pos_ret=pos;
    vec2 vel_ret=pack_vel(vel,extra_data_vel);
    return vec4(pos_ret,vel_ret);
}

float rand(vec2 co){
  return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

int pack_type_hp(int type, int hp){
	int gxff=255;
	return (((type&gxff)<<8)|((hp&gxff)<<0));
}

ivec2 unpack_type_hp(int id){
	int gxff=255;
	return ivec2(((id>>8)&gxff),((id>>0)&gxff));
}

// (1,0,0) red
// (0,1,0) green
// (0,0,1) blue
// (1,1,0) yellow
// (0,1,1) purle
// (1,0,1) light red
// (1,1,1) orange

int get_id_by_color(vec3 col){
	int ret=0;
	if(all(greaterThan(col,vec3(0.75))))
	ret=3+7;
	else
	if(all(greaterThan(col,vec3(0.45))))
	ret=3;
	else
	if((col.r>0.75)&&all(lessThan(col.gb,vec2(0.25))))
	ret=1+7;
	else
	if((col.r>0.45)&&all(lessThan(col.gb,vec2(0.25))))
	ret=1;
	else
	if((col.g>0.75)&&all(lessThan(col.rb,vec2(0.25))))
	ret=4+7;
	else
	if((col.g>0.45)&&all(lessThan(col.rb,vec2(0.25))))
	ret=4;
	else
	if((col.b>0.75)&&all(lessThan(col.gr,vec2(0.25))))
	ret=5+7;
	else
	if((col.b>0.45)&&all(lessThan(col.gr,vec2(0.25))))
	ret=5;
	else
	if((col.b<0.25)&&all(greaterThan(col.rg,vec2(0.75))))
	ret=3+7;
	else
	if((col.b<0.25)&&all(greaterThan(col.rg,vec2(0.45))))
	ret=3;
	else
	if((col.r<0.25)&&all(greaterThan(col.gb,vec2(0.75))))
	ret=6+7;
	else
	if((col.r<0.25)&&all(greaterThan(col.gb,vec2(0.45))))
	ret=6;
	else
	if((col.g<0.25)&&all(greaterThan(col.rb,vec2(0.75))))
	ret=0+7;
	else
	if((col.g<0.25)&&all(greaterThan(col.rb,vec2(0.45))))
	ret=0;
	return ret;
}

vec2 get_force(vec2 p){
    vec4 tval=texelFetch(force_collision, ivec2(int(p.x),int(0.+p.y)), 0 );
	return tval.xy;
}

vec2 get_force2(vec2 p){
    vec4 tval=texelFetch(force_collision, ivec2(int(p.x),int(0.+p.y)), 0 );
	return tval.zw;
}

vec4 spawner(vec2 uv,vec2 middle, vec2 iResolution){
	ivec2 iv = ivec2(middle);
	//int spawner_cd=60*10;
	//spawner_cd=6;
	vec4 retc=vec4(-1.,0.,0.,0.);
	//if(iFrame%spawner_cd!=0)return retc;
	if ((iv.x %2 == 0)&&(iv.y %2 == 0)&&(!get_map(uv,iResolution))&&(iv.x>0&&iv.y>0&&iv.x<1280-1&&iv.y<720-1))
	{
			int id=pack_type_hp(4+get_id_by_color(get_col_map(uv,iResolution)),1);
			vec2 pos=(middle+(rand(vec2(iv))-0.5)*0.25);
			vec2 vel=vec2(0.);
			retc = save_all(pos,vel,id);
		}
	return retc;
}

vec2 my_normalize(vec2 v){
	float len = length(v);
	if(len==0.0)return vec2(0.,0.);
	return v/len;
}

vec2 get_screen_dir(){
	return (texelFetch(logic,ivec2(0,0),0).zw);
}

vec4 get_dir_by_anim(){
	vec2 dir=vec2(0.,1.);
	vec2 rdir=(get_screen_dir());
	vec2 tdir=my_normalize(rdir);
	if(length(tdir)<=0.01){
	if((anim_state==0)||(anim_state==4)){
		dir=vec2(-1.,0.);
	}else
	if((anim_state==1)||(anim_state==5)){
		dir=vec2(1.,0.);
	}else
	if((anim_state==2)||(anim_state==6)){
		dir=vec2(0.,1.);
	}else
	if((anim_state==3)||(anim_state==7)){
		dir=vec2(0.,-1.);
	}
	}
	else dir=tdir;
	return vec4(dir,rdir);
}

vec4 spawner_bullets(vec2 uv,vec2 middle, vec2 iResolution){
	ivec2 iv = ivec2(middle);
	int spawner_cd=35;//+int(45.*(1.-mousedl));
	//spawner_cd=6;
	vec4 retc=vec4(-1.,0.,0.,0.);
	if(iFrame%spawner_cd!=0)return retc;
	
	vec2 nval=get_force(vec2(iv.xy));
	if ((iv.x %2 == 0)&&(iv.y %2 == 0)&&(iv.x>0&&iv.y>0&&iv.x<1280-1&&iv.y<720-1)&&(abs(nval.x)+abs(nval.y))>0.)
	{
		vec4 dirl=get_dir_by_anim();
		vec2 dir=dirl.xy;
		vec2 rdir=dirl.zw;
		
		int ttype=40;
		if((dir.y>0.5)&&(dirl.y>abs(dirl.x)))ttype=42;
		else if((dir.y<0.)&&(abs(dirl.y)>abs(dirl.x)))ttype=43;
		else if((dir.x>0.5)&&(dirl.x>abs(dirl.y)))ttype=40;
		else if((dir.x<0.)&&(abs(dirl.x)>abs(dirl.y)))ttype=41;
		int id=pack_type_hp(ttype,150);
		vec2 pos=(middle+(rand(vec2(iv))-0.5)*0.25);
		vec2 vel=vec2(0.)+dir;
		retc = save_all(pos,vel,id);
	}
	return retc;
}

ivec2 type_hp_logic(ivec2 type_hp, vec2 vel){
	int real_index=type_hp.x;
	if((real_index>=4)&&(real_index!=40)&&(real_index!=41)&&(real_index!=42)&&(real_index!=43)){
		int tid=real_index-4;
		if(tid>=20){
			type_hp.y+=-1;
			if(type_hp.y<=0){
				//type_hp.x+=-20;
				type_hp.x=3;
				type_hp.y=0;
			}
		}
	}else 
	if(real_index==3){
		if(iFrame%(13-int(6.*min(length(vel)*20.,1.)))==0){
		type_hp.y+=1;
		type_hp.y=type_hp.y%10;
		}
	}else
	if(real_index==2){
		if(iFrame%(13-int(6.*min(length(vel)*20.,1.)))==0){
		type_hp.y+=1;
		type_hp.y=type_hp.y%10;
		}
	}else
	if(real_index==1){
		if(iFrame%(13-int(6.*min(length(vel)*20.,1.)))==0){
		type_hp.y+=1;
		type_hp.y=type_hp.y%15;
		}
	}else
	if((real_index==40)||(real_index==41)||(real_index==42)||(real_index==43)){
		if((iFrame%(2))==0){
		type_hp.y+=-1;
		type_hp.y=max(type_hp.y,0);
		}
	}
	return type_hp;
}

void sim_step( out vec4 fragColor, in vec2 fragCoord, in vec2 iResolution )
{
	vec2 uv=fragCoord/iResolution;
	
    float BALL_SIZE = 0.90 ; // should be between sqrt(2)/2 and 1
    float BALL_D = 2.0 * BALL_SIZE; 
    float VEL_LIMIT = 0.2 * BALL_SIZE;
    vec2 G = gravity;//vec2(0.0, -0.006); // 0.006
    float E_FORCE = 1.9;
    float M = 0.6 * BALL_SIZE;
    float DAMP_K = 0.98;
    float SQ_K = 0.0;
    float player_F = 0.025;
	float monster_F = 0.15;
	float slow_down=0.925;
    vec2 middle = (fragCoord);
    int self_id=0;
    if ((false)||(iFrame <= 10)) {
        ivec2 iv = ivec2(fragCoord);
            //init
			if ((iv.x %2 == 0)&&(iv.y %2 == 0)&&(!get_map(uv,iResolution))&&(iv.x>0&&iv.y>0&&iv.x<1280-1&&iv.y<720-1)){
					int id=pack_type_hp(4+get_id_by_color(get_col_map(uv,iResolution)),1);
					vec2 pos=(middle+ (rand(fragCoord)-0.5)*0.25);
					vec2 vel=vec2(0.);
					fragColor = save_all(pos,vel,id);
				}
			else {
            fragColor = vec4(-1.,0.,0.,0.);
        }
    } else {
        // check if ball needs to transition between cells
        vec4 v = vec4(0.); 
        vec2 lp=vec2(-10.);
        bool br=false;
        for (int x=-1; x<=1; x++) {
            if(br)break;
            for (int y=-1; y<=1; y++) {
                vec2 np = fragCoord + vec2(float(x),float(y));
                vec4 p = getV(np);
                //found ball for transition
                if(trunc(middle) == trunc(p.xy)){
                    v = p;
                    lp=np;
                    br=true;
                    break;
                }
            }
        }

        // movement calculations
        if (br){
            self_id=get_id(trunc(lp.xy));
			ivec2 type_hp=unpack_type_hp(self_id);
			int real_index=type_hp.x;
			if(!is_alive(self_id)){
					fragColor = vec4(-1.,0.,0.,0.);
				return;
			}
            vec2 dr = vec2(0);//vec2(0.0, -0.01);

            // collision checks
            float stress = 0.0;
			bool need_upd=false;
            for (int x=-2; x<=2; x++) {
                for (int y=-2; y<=2; y++) {
                    if (x !=0 || y != 0) 
                    {
                        vec4 p = getV(fragCoord + vec2(float(x),float(y)));
                        if (p.x > 0.0) {
                            vec2 d2 = v.xy - p.xy;
                            float l = length(d2);
                            float f = BALL_D - l;
                            if (l >= 0.001* BALL_SIZE &&  f > 0.0) {
								if(((real_index==40)||(real_index==41)||(real_index==42)||(real_index==43))&&(type_hp.y>22)){
									int h_id=get_id(fragCoord + vec2(float(x),float(y)));
									ivec2 htype_hp=unpack_type_hp(h_id);
									int hreal_index=htype_hp.x;
									if((hreal_index!=40)&&(hreal_index!=41)&&(hreal_index!=42)&&(hreal_index!=43))type_hp.y=22;
								}else{if(!need_upd){
									int h_id=get_id(fragCoord + vec2(float(x),float(y)));
									ivec2 htype_hp=unpack_type_hp(h_id);
									int hreal_index=htype_hp.x;
									if(((hreal_index==40)||(hreal_index==41)||(hreal_index==42)||(hreal_index==43))&&(htype_hp.y>22)){
									need_upd=true;}
									}
								}
                                float f2 = f / (BALL_D);
                                f2 +=  SQ_K*f2*f2;
                                f2 *= BALL_D;
                                vec2 force_part = E_FORCE * normalize(d2)*f2;
                                stress += abs(force_part.x)+abs(force_part.y);
                                dr += force_part;
                            }
                        }
                    }
                }
            }

			
			vec2 nval=player_F *max(stress, 1.0)*get_force(trunc(lp.xy));
			
			//collision with player
			if(((abs(nval.x)+abs(nval.y))>0.)){
				if((real_index>=4)&&(real_index!=40)&&(real_index!=41)&&(real_index!=42)&&(real_index!=43)){
				int tid=real_index-4;
				if(tid<20){
					type_hp.x+=20;
					type_hp.y=255;
				}
				dr+=nval;
				}
				//fragColor = vec4(-1.,0.,0.,0.);
				//return;
				
				}
			
			if((need_upd)&&(real_index<24)){
				if((real_index>=4)){
					type_hp.x+=20;
					type_hp.y=255;
				}else
				if(real_index==3){
					type_hp.x=min(int(1.+3.*rand(vec2(uv+iTime))),2);
					type_hp.y=1;
				}else
				if(real_index==2){
					type_hp.x=0;
					type_hp.y=1;
				}else
				if(real_index==1){
					//type_hp.x==0; one ghost immortal
					//type_hp.y=1;
				}
				
				
			}
			
			if(real_index<=3){
				vec2 nval2=monster_F *max(stress, 1.0)*get_force2(trunc(lp.xy));
				if(real_index==3)nval2*=0.46;
				else
				if(real_index==2)nval2*=0.65;
				else
				if(real_index==1)nval2*=1.25;
				dr+=nval2;
			}
			if((((real_index==40)||(real_index==41)||(real_index==42)||(real_index==43))&&(type_hp.y==0))||(type_hp.x<=0)){
				fragColor = vec4(-1.,0.,0.,0.);
				return;
			}
			
			
            // movement calculation
            vec2 pos = v.xy;
            float damp_k = length(dr)>0.001? DAMP_K : 1.0; // don't apply damping to freely flying balls
			if((real_index==40)||(real_index==41)||(real_index==42)||(real_index==43))M=100.;
            dr += G * M; // gravity
            vec2 vel = damp_k * v.zw + dr / M;
            vel = clamp(vel, vec2(-1.0), vec2(1.0));

            vec2 dpos = vel * VEL_LIMIT;
            pos += dpos*speed_x;
            v.xy = pos;
            v.xy = clamp(v.xy,vec2(BALL_SIZE *(1.0 + sin(pos.y)*0.1),BALL_SIZE),iResolution.xy-vec2(BALL_SIZE));
            //pack everything
			type_hp=type_hp_logic(type_hp,vel);
			self_id=pack_type_hp(type_hp.x,type_hp.y);
			if((real_index!=40)&&(real_index!=41)&&(real_index!=42)&&(real_index!=43))vel*=slow_down;
            v=save_all(v.xy,vel,self_id);
            fragColor = v; 
        } else {
			if(mousedl>0.){
				fragColor = spawner_bullets(uv,middle,iResolution);
			}else
			if(spwan_b_once){
				fragColor = spawner(uv,middle,iResolution);
			}
			else{
				fragColor = vec4(-1.,0.,0.,0.);
			}
        }
    }
}

void mainImage( out vec4 fragColor, in vec2 fragCoord, in vec2 iResolution )
{
    sim_step(fragColor, fragCoord, iResolution);
}

void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	
	mainImage(COLOR,UV*iResolution,iResolution);
}
