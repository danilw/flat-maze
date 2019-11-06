shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform int iFrame;
uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform sampler2D logic;
uniform vec3 iMouse;


//https://www.shadertoy.com/view/tsdGzN

void C(inout vec2 U, inout vec4 T, in int c){
    U.x+=.5;
    if(U.x<.0||U.x>1.||U.y<0.||U.y>1. ){
        T+= vec4(0);
    }
    else{
		vec2 tu=U/16. + fract( vec2(float(c), float(15-c/16)) / 16.);
		tu.y=1.-tu.y;
        T+= textureGrad( iChannel3,tu, dFdx(tu/16.),dFdy(tu/16.));
    }
}

// X dig max
float print_int(vec2 U, int val) {
    vec4 T = vec4(0);
    int cval=val;
    int X=3;
    for(int i=0;i<X;i++){
    if(cval>0){
        int tv=cval%10;
        C(U,T,48+tv);
        cval=cval/10;
    }
    else{
        if(length(T.yz)==0.)
            return -1.;
        else return T.x;
    }
    }
    if(length(T.yz)==0.)
        return -1.;
    else return T.x;
}

//https://www.shadertoy.com/view/llscz4
float trianglefunction(float t, float period) {
    float ps = mod(t, period) / period; // 0 to 1 in period
    if (ps > 0.5)
        ps = 1.0 - ps;    
    return ps * 2.0;
}

// Returns 1 where the crest is strongest, can go <0 too though
float waterwave(vec2 uv,
                float t,
    			float period, 
                float horzSpeed, 
                float vertSpeed,
                float amplitude, 
                float crestWidth
               ) {
	// canvas moves
    float cx = uv.x;
    float cy = uv.y + vertSpeed * sin(t);
    
    // map area to [0..TWOPI, -1..1]
	float sx = cx * 6.28318;
    float sy = cy * 2.0 - 1.0;

    float ss = trianglefunction(t, period);
    ss = ss * 2.0 - 1.0;

    float f = sin(t * horzSpeed + sx) * ss * amplitude;

    float d = abs(sy - f) / crestWidth;
    return 1.0 - d;
}

vec4 get_collision_hp(){
	return texelFetch(logic,ivec2(1,0),0).xyzw;
}

void mainImage( out vec4 fragColor, in vec2 fragCoord,in vec2 iResolution)
{
	vec4 WATER_COLOR = vec4(0.0, 0.412, 0.58, 1.0); // sea blue
	vec4 CREST_COLOR = vec4(1.0, 1.0, 1.0, 1.0);
	
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    float w1 = waterwave(vec2(uv.x, uv.y - 0.2),
                        iTime*0.2,
        			    8.0, // period
                        1.0, // horzSpeed
                        0.2, // vertSpeed
                        0.5, // amplitude
                        1.5 // crestWidth
                        );
    
    float w2 = waterwave(vec2(uv.x, uv.y + 0.3),
                        iTime*0.2,
        			    5.0, // period
                        2.5, // horzSpeed
                        0.1, // vertSpeed
                        0.15, // amplitude
                        0.5 // crestWidth
                        );
    
    float waves = w1 + w2 * 0.25;

    vec4 tc=texture(iChannel0,uv);
	//if((abs(uv.x-0.5)<0.1)&&(abs(uv.y-0.5)<0.1))
	{
		int imint=int(get_collision_hp().y);
		if(imint<1000){
		float c=print_int(((vec2(uv.x,1.-uv.y)-vec2(0.515,0.425))*vec2(16.,9.)*0.5)*2.,int(get_collision_hp().y));
		c=clamp(c,0.,1.);
		tc+=c;}
	}
    fragColor = mix(WATER_COLOR, CREST_COLOR, waves);
    fragColor = mix(tc, fragColor, waves*0.55);
	fragColor.rgb=clamp(fragColor.rgb,0.,1.);
	fragColor.a=smoothstep(0.,0.5,iTime);
}

void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution);
}