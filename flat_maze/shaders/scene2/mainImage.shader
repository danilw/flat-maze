shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform float txgrad;
uniform int iFrame;

uniform bool pa_once;

uniform vec2 screen_pos;
uniform float zoom;
uniform float mousedr;

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform sampler2D maze_map;
uniform sampler2D ground1;
uniform sampler2D ground2;
uniform sampler2D ground2a;
uniform sampler2D ground2b;
uniform sampler2D ground2c;
uniform sampler2D ground2d;
uniform sampler2D ground3;
uniform sampler2D wla;
uniform sampler2D wlb;
uniform vec3 iMouse;

float circle( in vec2 uv, float r1, float r2,vec2 ab)
{
    float t = r1-r2;
    float r = r1;    
    //return smoothstep(ab.x,ab.y, abs((uv.y) - r) - t/10.0);      // line
    return smoothstep(ab.x,ab.y, abs(length(uv) - r) - t/10.0);        
}

float circle2( in vec2 uv, float r1, float r2,vec2 ab)
{
    float t = r1-r2;
    float r = r1;    
    //return smoothstep(ab.x,ab.y, abs((uv.y) - r) - t/10.0);      // line
    return smoothstep(ab.x,ab.y, (length(uv) - r) - t/10.0);        
}

vec3 color(vec2 p) {
    vec3 colx=vec3(0.720, 0.25, 0.08);

    float vx=min(smoothstep(0.1,0.2,1.2*circle(p*3.,1.,0.19,vec2(-0.25,0.8))),5.*max(0.1,circle2(p*3.,.3,0.19,vec2(-0.24645,01.28))));
	vx=max(vx,0.015);
	colx*=0.02/(vx);
	return clamp(pow(colx, vec3(2.0))*(.5-.52*vx),vec3(0.),vec3(5.));
}

vec3 glow_c(vec2 uv) {
	vec3 col=vec3(0.);
	uv.y+=-0.05;
	float mdrx=max(0.001,mousedr*5.);
	uv*=1./mdrx;
	float a=smoothstep(0.45,0.4,length(uv));
	if(a>0.){
	col = color(uv);
	col=clamp(abs(col),vec3(0.),vec3(1.));
	col*=smoothstep(0.45,0.4,length(uv));
	col = 2.*pow(col, vec3(0.24545));
	col=col+col*col;
    }
	return col;
}



vec4 get_collision_hp(){
	return texelFetch(iChannel0,ivec2(1,0),0).xyzw;
}

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

vec2 get_screen_pos(){
	return texelFetch(iChannel0,ivec2(0,0),0).xy;
}

float SampleShadow(int id, vec2 uv, vec2 iResolution)
{
	float tau = atan(1.0)*8.0;
	vec2 hpo = 0.5 / iResolution.xy;
    float a = atan(uv.y, uv.x)/tau + 0.5;
    float r = length(uv);
    
    float idn = float(id)/iResolution.y;
   
    float s = texture(iChannel1, vec2(a, idn) + hpo).x;
    
    return 1.0-smoothstep(s, s+0.02, length(uv));    
}

vec2 LightOrigin(int id)
{
	return texelFetch(iChannel1,ivec2(0, id),0).yz;   
}

vec3 LightColor(int id)
{
	return texelFetch(iChannel1,ivec2(1, id),0).yzw;   
}

vec3 MixLights(vec2 uv, vec2 iResolution)
{
	vec3 AMBIENT_LIGHT=vec3(0.1, 0.01, 0.01);
	int NUM_LIGHTS=1;
    vec3 b = AMBIENT_LIGHT;
	float min_zoom=0.015;
	for(int i = 0;i < NUM_LIGHTS;i++)
    {
	    vec2 o = LightOrigin(i);
	    vec3 c = LightColor(i);
	    
	    //float l = 0.01 / (pow(0.5*length(vec3((uv*((zoom)/min_zoom) - o), 0.1)), 2.));
		float l = (2.25-min((01.*length(vec3((uv*((zoom)/min_zoom) - o), 0.1))),2.25))/2.;
	    l *= SampleShadow(i, uv-o/max(0.01,zoom/min_zoom),iResolution);
		l=max(l,smoothstep(0.+mousedr*2.,-0.2+mousedr*2.,length((uv*((zoom)/min_zoom)- vec2(0.,-0.05)))));
	    b += c * l;
    }
    return b;
}

float rand(vec2 co){
    return fract(sin(dot(co.xy ,vec2(12.9898,78.233))) * 43758.5453);
}

void mainImage( out vec4 fragColor, in vec2 fragCoord ,in vec2 iResolution)
{
	fragColor=vec4(0.);
	
	vec2 uv=fragCoord/iResolution;
	vec2 res=iResolution/iResolution.y;
	vec2 zuv=uv;
	zuv+=-0.5;
	zuv*=max(0.01,zoom);
	if(!pa_once){
		zuv+=screen_pos;
	}else{
		zuv+=get_screen_pos()/(res); // res/2*2
	}
	zuv+=0.5;
	vec2 tuvv=tile_uv_f(zuv,iResolution);
	// the real dFdx(tuvv),dFdy(tuvv) are bugged for this low zoom
	// this why dFdx(zuv*(txgrad)),dFdy(zuv*(txgrad)) used
	if(get_map(zuv,iResolution)){
		vec4 tc=textureGrad(ground1,tuvv,dFdx(zuv*(txgrad)),dFdy(zuv*(txgrad))); //textureLod(...,txgrad-1.)
		bool atp=false;
		vec4 pc=vec4(0.);
		vec2 res_step=1./vec2(320.,180.);
		if(zuv.x-0.5-res_step.x>-0.5){
			atp=!get_map(zuv+res_step*vec2(-1.,0.),iResolution);
		}
		if(atp){
			pc=textureGrad(ground2a,tuvv,dFdx(zuv*(txgrad)),dFdy(zuv*(txgrad)));
		}
		atp=false;
		if(zuv.x-0.5+res_step.x<0.5){
			atp=!get_map(zuv+res_step*vec2(1.,0.),iResolution);
		}
		if(atp){
			pc=max(pc,textureGrad(ground2c,tuvv,dFdx(zuv*(txgrad)),dFdy(zuv*(txgrad))));
		}
		atp=false;
		if(zuv.y-0.5+res_step.y<0.5){
			atp=!get_map(zuv+res_step*vec2(0.,1.),iResolution);
		}
		if(atp){
			pc=max(pc,textureGrad(ground2b,tuvv,dFdx(zuv*(txgrad)),dFdy(zuv*(txgrad))));
		}
		atp=false;
		if(zuv.y-0.5-res_step.y>-0.5){
			atp=!get_map(zuv+res_step*vec2(0.,-1.),iResolution);
		}
		if(atp){
			pc=max(pc,textureGrad(ground2d,tuvv,dFdx(zuv*(txgrad)),dFdy(zuv*(txgrad))));
		}
		atp=false;
		float a=tc.a;
		fragColor.rgb = mix(tc.rgb,pc.rgb,pc.a);
	}
	else {
		vec4 tc=textureGrad(ground2,tuvv,dFdx(zuv*(txgrad)),dFdy(zuv*(txgrad)));
		float a=tc.a;
		fragColor.rgb = tc.rgb;
		
	}
	if((zuv.x>1260./iResolution.x)&&(zuv.y<16./iResolution.y)&&(zuv.x<1280./iResolution.x)&&(zuv.y>0./iResolution.y)){
		fragColor.rgb=fragColor.rgb*0.2+1.5*fragColor.brg;
	}
	float min_zoom=0.015;
	float startup_zoom_timer_sec=6.0;
	
	vec4 adglowc=vec4(0.);
	if(mousedr>0.){
		vec3 ccx=glow_c(res*((uv-0.5)*(max(0.01,zoom/min_zoom))));//*smoothstep(5.5,startup_zoom_timer_sec,iTime);
		float a=dot(clamp(ccx,0,1.),vec3(1.))/3.;
		adglowc=vec4(ccx,min(a*2.,1.));
	}
	vec3 oc=fragColor.rgb;
	
	vec4 parts=texture(iChannel2,uv);
	if(parts.r<0.)parts.r=parts.r+10.*parts.a;
	
	float vignetteAmt = 1. - dot((uv-0.5) * 0.85, (uv-0.5) * 0.85);
	vec2 uvo = fragCoord.xy / iResolution.y - res/2.0;
	uvo=-uvo; //?
	fragColor.rgb =pow(fragColor.rgb,vec3(2.))*0.35+fragColor.rgb*0.95*MixLights(uvo,iResolution);
	fragColor.rgb=mix(fragColor.rgb,adglowc.rgb,adglowc.a*smoothstep(0.,0.5,mousedr));
	fragColor.rgb=clamp(fragColor.rgb,0.,1.);
	float shl= (1.5-min((01.*length(vec3((uvo*((zoom)/min_zoom) - LightOrigin(0)), 0.1))),1.5))*0.35;
	shl = shl+0.01 / (pow(0.25*length(vec3((uvo*((zoom)/min_zoom) - LightOrigin(0)), 0.1)), 2.));
	shl=0.25+0.75*shl;
	shl=max(shl,smoothstep(0.+mousedr*2.,-0.2+mousedr*2.,length((uvo*((zoom)/min_zoom)- vec2(0.,-0.05)))));
	fragColor.rgb=mix(fragColor.rgb,parts.rgb*clamp(shl,0.25,1.),parts.a);
	
	fragColor.rgb*=smoothstep(0.,0.5,iTime)*vignetteAmt;
	fragColor.rgb = fragColor.rgb *0.5 + 0.5*fragColor.rgb*fragColor.rgb;
	fragColor.rgb = clamp(fragColor.rgb,0.,1.);
	
	fragColor.rgb = mix(oc,fragColor.rgb,smoothstep(5.5,startup_zoom_timer_sec,iTime));
	
	fragColor.rgb += (rand(uv) - .5)*.07*smoothstep(4.,1.,(zoom)/min_zoom);
	
	//if((zuv.x<0.)||(zuv.x>1.)||(zuv.y>1.)||(zuv.y<0.))
	//fragColor.rgb*=vec3(.65);
	
	vec2 state=get_collision_hp().yw;
	float lost_hp_timer=state.y;
	float player_hp=state.x;
	bool is_player_alive=player_hp>=1.;
	
	if(player_hp<1000.){
		float mpl=1.;
		if(!is_player_alive)mpl=smoothstep(0.0,0.5,lost_hp_timer);
		fragColor.rgb=mix(fragColor.rgb,texture(wla,uv).rgb,1.-mpl);
	}else{
		float mpl=smoothstep(0.0,0.5,lost_hp_timer);
		fragColor.rgb=mix(fragColor.rgb,texture(wlb,uv).rgb,1.-mpl);
	}
	
	fragColor.rgb*=smoothstep(0.0,0.5,iTime);
	
	fragColor.a=1.;

}
void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution);
}