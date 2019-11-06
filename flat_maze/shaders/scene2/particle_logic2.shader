shader_type canvas_item;
render_mode blend_mix;

uniform float iTime;
uniform int iFrame;
uniform float zoom;

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform sampler2D particles;
uniform sampler2D logic;
uniform sampler2DArray blocks;
uniform sampler2DArray zombi;
uniform sampler2DArray eye;
uniform sampler2DArray fball;
uniform sampler2DArray ghost;
uniform sampler2DArray ghost2;
uniform float real_resolution;
uniform vec3 iMouse;


//because of bug https://github.com/godotengine/godot/issues/33134 logic here

//---------------------------------------

float decodeval_vel(int varz) {
    int iret=0;
    iret=varz>>8;
    int gxffff=65535;
    return float(iret)/float(gxffff);
}

vec4 getV(in ivec2 p){
	if((p.x<0)||(p.x>=1280)||(p.y>=720)||(p.y<0)) return vec4(-1.,0.,0.,0.);
    vec4 tval=texelFetch( particles, ivec2(p), 0 );
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

ivec2 extra_dat_vel(ivec2 p){
	vec4 tval=texelFetch( particles, ivec2(p), 0 );
	int gxff=255;
	return ivec2(abs(int(tval.z))&gxff,abs(int(tval.w))&gxff);
}

int get_id(ivec2 p){
    ivec2 v2=extra_dat_vel(p);
    int iret=(v2[0]<<8)|(v2[1]<<0);
    return iret;
}

vec2 get_self_prticle(ivec2 p){
	vec4 ball = getV(p);
	return ball.xy;
}

//-----------------------------

vec2 get_screen_pos(){
	return texelFetch(logic,ivec2(0,0),0).xy;
}

int pack_type_hp(int type, int hp){
	int gxff=255;
	return (((type&gxff)<<8)|((hp&gxff)<<0));
}

void vertex() {
	vec2 self_res=vec2(1280.,720);
	vec2 res=vec2(self_res)/vec2(self_res).y;
	float ridx=max(0.01,real_resolution);
	
	//texture(particle) size 256*256, screen size 1280*720, particles (77,45)-4 per screen
	//calculating particle base scale
	
	
	vec2 custom_size=vec2(77.75,45.5)-4.;
	float base_size=(self_res.y/custom_size.y);
	float base_scale=base_size/256.;
	
	VERTEX*=ridx;
	VERTEX*=base_scale+base_scale*zoom;
	ivec2 index2d=ivec2(INSTANCE_CUSTOM.xy);
	vec2 index2df=(get_screen_pos()/(res))*vec2(self_res);
	vec2 index2dfo=((get_screen_pos()/(res))+0.5)*vec2(self_res);
	
	ivec2 sidx=(index2d*1+((ivec2(index2dfo+0.0001))%2))+ivec2(index2dfo)-ivec2(custom_size/2.+2.)*2;
	vec2 self_ppos=get_self_prticle(sidx);
	float left_right=10.;
	if(self_ppos.x>index2dfo.x)left_right=-10.;
	left_right+=sign(left_right)*distance(self_ppos,index2dfo)/(25.);
	int real_index=-1;//10<<8|0;
	
	
	if((false&&(ivec2(self_ppos)!=sidx)||self_ppos.x<0.)){
		VERTEX+=vec2(100000.)+vec2(100.)*vec2(index2d);
	}
	else{
	vec2 addx=vec2(0.);
	
	if((ivec2(self_ppos)!=sidx)){
		addx=-sign(vec2(sidx)-floor(self_ppos)); //fix for blicks on switch
	}
	
	real_index=get_id(sidx);
	
	//shift from particle map
	VERTEX+=(fract(self_ppos)*(128.*(base_scale+base_scale*zoom))+ //128
	(vec2(0.4,0.25)+0.25)*(256.*(base_scale+base_scale*zoom)))*ridx; //this is because custom part of pixel from custom size
	
	VERTEX+=(addx*(128.*(base_scale+base_scale*zoom)))*ridx;
	
	VERTEX+=(base_size*(vec2(index2d)/2.-1.5)*(1.+zoom)-(base_size*custom_size/2.)*zoom)*ridx;
	VERTEX+=(0.5*(-fract(index2dfo))*(256.*(base_scale+base_scale*zoom)))*ridx;
	VERTEX+=(256.*(base_scale+base_scale*zoom)*0.5*vec2(ivec2(index2dfo+0.0001)%2))*ridx;
	//screen float(smooth) shift posiiton without map
	//VERTEX+=0.5*(-fract(index2df))*(256.*(base_scale+base_scale*zoom));
	//VERTEX+=256.*(base_scale+base_scale*zoom)*0.5*vec2(ivec2(index2df+0.0001)%2);
	}
	
	COLOR=vec4(vec2(index2d),float(real_index),left_right);
}

//-----------------------------

ivec2 unpack_type_hp(int id){
	int gxff=255;
	return ivec2(((id>>8)&gxff),((id>>0)&gxff));
}

//fire from https://www.shadertoy.com/view/WtjGR3
float GetNoise(vec2 uv) // -> (0.25, 0.75)
{
    float n = (texture(iChannel3, uv*.25).r - 0.5) * 0.5;
    n += (texture(iChannel3, uv * 2.0*0.25).r - 0.5) * 0.5 * 0.5;
    return n + 0.5;
}

mat2 GetRotationMatrix(float angle)
{
    mat2 m;
    m[0][0] = cos(angle); m[0][1] = -sin(angle);
    m[1][0] = sin(angle); m[1][1] = cos(angle);
    return m;
}

vec4 get_fire(in vec2 fragCoord, vec2 iResolution, int index)
{
	float paramWindSpeedMagnitude=-80.0;
	float flamePersonalitySeed=1000.0;
    vec2 uv = fragCoord.xy / iResolution.xy;
	uv.y=1.-uv.y;
    uv -= vec2(0.5,0.5-0.1);
	uv*=vec2(0.75,1.25);
    vec2 flameSpacePosition = uv + vec2(0.0, 0.5); 
    uv.y /= (iResolution.x / iResolution.y); 
    float paramTime = iTime+float(index);
    
    float FlameSpeed= 0.23;
    float flameTime = paramTime * FlameSpeed;

    float windAngle = -sign(paramWindSpeedMagnitude) * 0.4 * smoothstep(0.0, 100.0, abs(paramWindSpeedMagnitude));
    windAngle *= flameSpacePosition.y;
    windAngle *=0.25;
    uv = GetRotationMatrix(windAngle) * (uv + vec2(0.0, 0.5)) - vec2(0.0, 0.5);
    float NoiseResolution=0.37;
    float fragmentNoise = GetNoise(uv * NoiseResolution + vec2(flamePersonalitySeed)/777.0 + vec2(0.0, -flameTime/0.8));
    float angle = (fragmentNoise - 0.5);
    angle /= max(0.1, length(uv));
    angle *= smoothstep(-0.1, 0.5, flameSpacePosition.y);
    angle *= 0.45;
    uv += GetRotationMatrix(angle) * uv;    
    float FlameWidth=0.5;
    float thickness = 1.0 - smoothstep(0.1, FlameWidth, abs(uv.x));
    float variationH = fragmentNoise * 1.4;
    thickness *= smoothstep(1.3, variationH * 0.5, flameSpacePosition.y); // Taper up
    thickness *= smoothstep(-0.15, 0.15, flameSpacePosition.y); // Taper down
    float FlameFocus=2.0;
    thickness = pow(clamp(thickness, 0.0, 3.0), FlameFocus);
    vec3 col1 = mix(vec3(1.0, 1.0, 0.6), vec3(1.0, 1.0, 1.0), thickness);
    col1 = mix(vec3(1.0, 0.4, 0.1), col1, smoothstep(0.3, 0.8, thickness));
    float alpha = smoothstep(0.0, 0.5, thickness);
    return vec4(pow(col1,vec3(2.)), alpha);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ,in vec2 iResolution, in vec4 coldat)
{
	fragColor=vec4(0.);
	vec2 uv=fragCoord/iResolution;
	ivec2 index2d=ivec2(coldat.xy);
	int type_id=int(coldat.z);
	bool left_right=false;
	float lrdist=abs(coldat.w)-10.;
	if(coldat.w<0.)left_right=true;
	if(type_id>0){
		ivec2 type_hp=unpack_type_hp(type_id);
		int real_hp=type_hp.y;
		int real_index=type_hp.x;
		if((real_index>=4)&&(real_index!=40)&&(real_index!=41)&&(real_index!=42)&&(real_index!=43)){
			int tid=real_index-4;
			bool isf=false;
			if(tid>=20){
				tid+=-20;
				isf=true;
			}
			if(tid==0)
			fragColor=texture(blocks,vec3(uv,0));
			else
			if(tid==1)
			fragColor=texture(blocks,vec3(uv,1));
			else
			if(tid==2)
			fragColor=texture(blocks,vec3(uv,2));
			else
			if(tid==3)
			fragColor=texture(blocks,vec3(uv,3));
			else
			if(tid==4)
			fragColor=texture(blocks,vec3(uv,4));
			else
			if(tid==5)
			fragColor=texture(blocks,vec3(uv,5));
			else
			if(tid==6)
			fragColor=texture(blocks,vec3(uv,6));
			else
			if(tid==7)
			fragColor=texture(blocks,vec3(uv,7));
			else
			if(tid==8)
			fragColor=texture(blocks,vec3(uv,8));
			else
			if(tid==9)
			fragColor=texture(blocks,vec3(uv,9));
			else
			if(tid==10)
			fragColor=texture(blocks,vec3(uv,10));
			else
			if(tid==11)
			fragColor=texture(blocks,vec3(uv,11));
			else
			if(tid==12)
			fragColor=texture(blocks,vec3(uv,12));
			else
			if(tid==13)
			fragColor=texture(blocks,vec3(uv,13));
			if(isf){
				vec4 firex=get_fire(fragCoord,iResolution,real_index);
				fragColor=mix(fragColor,pow(firex,vec4(2.))*1.75,firex.a);
			}
		}
		else 
		if(real_index==3){
			if(left_right)uv.x=1.-uv.x;
			if(real_hp==0){
				fragColor=texture(zombi,vec3(uv,0));
			}
			else
			if(real_hp==1){
				fragColor=texture(zombi,vec3(uv,1));
			}
			else
			if(real_hp==2){
				fragColor=texture(zombi,vec3(uv,2));
			}
			else
			if(real_hp==3){
				fragColor=texture(zombi,vec3(uv,3));
			}
			else
			if(real_hp==4){
				fragColor=texture(zombi,vec3(uv,4));
			}
			else
			if(real_hp==5){
				fragColor=texture(zombi,vec3(uv,5));
			}
			else
			if(real_hp==6){
				fragColor=texture(zombi,vec3(uv,6));
			}
			else
			if(real_hp==7){
				fragColor=texture(zombi,vec3(uv,7));
			}
			else
			if(real_hp==8){
				fragColor=texture(zombi,vec3(uv,8));
			}
			else
			if(real_hp==9){
				fragColor=texture(zombi,vec3(uv,9));
			}
			if((fragColor.r>0.7)&&(fragColor.g>0.7)){
				fragColor.rgb=fragColor.rgb*(.75+5.*lrdist);
			}
			
		}
		else
		if(real_index==2){
			if(left_right)uv.x=1.-uv.x;
			if(real_hp==0){
				fragColor=texture(ghost,vec3(uv,0));
			}
			else
			if(real_hp==1){
				fragColor=texture(ghost,vec3(uv,1));
			}
			else
			if(real_hp==2){
				fragColor=texture(ghost,vec3(uv,2));
			}
			else
			if(real_hp==3){
				fragColor=texture(ghost,vec3(uv,3));
			}
			else
			if(real_hp==4){
				fragColor=texture(ghost,vec3(uv,4));
			}
			else
			if(real_hp==5){
				fragColor=texture(ghost,vec3(uv,5));
			}
			else
			if(real_hp==6){
				fragColor=texture(ghost,vec3(uv,6));
			}
			else
			if(real_hp==7){
				fragColor=texture(ghost,vec3(uv,7));
			}
			else
			if(real_hp==8){
				fragColor=texture(ghost,vec3(uv,8));
			}
			else
			if(real_hp==9){
				fragColor=texture(ghost,vec3(uv,9));
			}
			fragColor.rgb=fragColor.rgb*(.75+2.*lrdist);
		}
		else
		if(real_index==1){
			if(!left_right)uv.x=1.-uv.x;
			if(real_hp==0){
				fragColor=texture(ghost2,vec3(uv,0));
			}
			else
			if(real_hp==1){
				fragColor=texture(ghost2,vec3(uv,1));
			}
			else
			if(real_hp==2){
				fragColor=texture(ghost2,vec3(uv,2));
			}
			else
			if(real_hp==3){
				fragColor=texture(ghost2,vec3(uv,3));
			}
			else
			if(real_hp==4){
				fragColor=texture(ghost2,vec3(uv,4));
			}
			else
			if(real_hp==5){
				fragColor=texture(ghost2,vec3(uv,5));
			}
			else
			if(real_hp==6){
				fragColor=texture(ghost2,vec3(uv,6));
			}
			else
			if(real_hp==7){
				fragColor=texture(ghost2,vec3(uv,7));
			}
			else
			if(real_hp==8){
				fragColor=texture(ghost2,vec3(uv,8));
			}
			else
			if(real_hp==9){
				fragColor=texture(ghost2,vec3(uv,9));
			}
			else
			if(real_hp==10){
				fragColor=texture(ghost2,vec3(uv,10));
			}
			else
			if(real_hp==11){
				fragColor=texture(ghost2,vec3(uv,11));
			}
			else
			if(real_hp==12){
				fragColor=texture(ghost2,vec3(uv,12));
			}
			else
			if(real_hp==13){
				fragColor=texture(ghost2,vec3(uv,13));
			}
			else
			if(real_hp==14){
				fragColor=texture(ghost2,vec3(uv,14));
			}
			fragColor.rgb=fragColor.rgb*(.75+4.*lrdist);
		}else
		if((real_index==40)||(real_index==41)||(real_index==42)||(real_index==43)){
			if((real_index==40))uv.x=1.-uv.x;
			if((real_index==42)||(real_index==43)){
				uv.xy=uv.yx;
				if(real_index==42)uv.x=1.-uv.x;
			}
			uv.y*=2.;
			int cid=real_hp/3;
			if((cid)%5==0){
				fragColor=texture(fball,vec3(uv,0));
			}
			else
			if((cid)%5==1){
				fragColor=texture(fball,vec3(uv,1));
			}
			else
			if((cid)%5==2){
				fragColor=texture(fball,vec3(uv,2));
			}
			else
			if((cid)%5==3){
				fragColor=texture(fball,vec3(uv,3));
			}
			else
			if((cid)%5==4){
				fragColor=texture(fball,vec3(uv,4));
			}
			fragColor.rgb=fragColor.rgb*(.75+4.*lrdist);
			fragColor.r+=-10.;
			fragColor.a*=min(1.,float(real_hp)/float(22));
		}
	}
}

void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution,COLOR);
}