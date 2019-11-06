shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform float scale_v;
uniform int iFrame;
uniform float b2d;
uniform float b1d;
uniform float play_timer;

uniform sampler2D iChannel0;
uniform sampler2D iChannel1;
uniform sampler2D iChannel2;
uniform sampler2D iChannel3;
uniform vec3 iMouse;

    vec4 hash42(vec2 p){

        vec4 p4 = fract(vec4(p.xy,p.xy) * vec4(443.8975,397.2973, 491.1871, 470.7827));
        p4 += dot(p4.wzxy, p4+19.19);
        return fract(vec4(p4.x * p4.y, p4.x*p4.z, p4.y*p4.w, p4.x*p4.w));
    }


    float hash( float n ){
        return fract(sin(n)*43758.5453123);
    }

    // 3d noise function (iq's)
    float n( in vec3 x ){
        vec3 p = floor(x);
        vec3 f = fract(x);
        f = f*f*(3.0-2.0*f);
        float n = p.x + p.y*57.0 + 113.0*p.z;
        float res = mix(mix(mix( hash(n+  0.0), hash(n+  1.0),f.x),
                            mix( hash(n+ 57.0), hash(n+ 58.0),f.x),f.y),
                        mix(mix( hash(n+113.0), hash(n+114.0),f.x),
                            mix( hash(n+170.0), hash(n+171.0),f.x),f.y),f.z);
        return res;
    }

    //tape noise
    float nn(vec2 p,float t){


        float y = p.y;
        float s = t*2.;

        float v = (n( vec3(y*.01 +s, 			1., 1.0) ) + .0)
                 *(n( vec3(y*.011+1000.0+s, 	1., 1.0) ) + .0) 
                 *(n( vec3(y*.51+421.0+s, 	1., 1.0) ) + .0)   
            ;
        //v*= n( vec3( (fragCoord.xy + vec2(s,0.))*100.,1.0) );
        v*= hash42(   vec2(p.x +t*0.01, p.y) ).x +.3 ;


        v = pow(v+.3, 1.);
        if(v<.7) v = 0.;  //threshold
        return v;
    }


//https://www.shadertoy.com/view/4dXBW2
float sat1( float t ) {
	return clamp( t, 0.0, 1.0 );
}

vec2 sat2( vec2 t ) {
	return clamp( t, 0.0, 1.0 );
}

//remaps inteval [a;b] to [0;1]
float remap  ( float t, float a, float b ) {
	return sat1( (t - a) / (b - a) );
}

//note: /\ t=[0;0.5;1], y=[0;1;0]
float linterp( float t ) {
	return sat1( 1.0 - abs( 2.0*t - 1.0 ) );
}

vec3 spectrum_offset( float t ) {
	vec3 ret;
	float lo = step(t,0.5);
	float hi = 1.0-lo;
	float w = linterp( remap( t, 1.0/6.0, 5.0/6.0 ) );
	float neg_w = 1.0-w;
	ret = vec3(lo,1.0,hi) * vec3(neg_w, w, neg_w);
	return pow( ret, vec3(1.0/2.2) );
}

//note: [0;1]
float rand( vec2 n ) {
  return fract(sin(dot(n.xy, vec2(12.9898, 78.233)))* 43758.5453);
}

//note: [-1;1]
float srand( vec2 n ) {
	return rand(n) * 2.0 - 1.0;
}

float mytrunc1( float x, float num_levels )
{
	return floor(x*num_levels) / num_levels;
}
vec2 mytrunc2( vec2 x, float num_levels )
{
	return floor(x*num_levels) / num_levels;
}

vec4 glitch_c( vec2 uv)
{	
	float time = mod(iTime*100.0, 32.0)/110.0; // + modelmat[0].x + modelmat[0].z;
    float GLITCH =0.2*b1d;
	
	float gnm = sat1( GLITCH );
	float rnd0 = rand( mytrunc2( vec2(time, time), 6.0 ) );
	float r0 = sat1((1.0-gnm)*0.7 + rnd0);
	float rnd1 = rand( vec2(mytrunc1( uv.x, 10.0*r0 ), time) ); //horz
	//float r1 = 1.0f - sat( (1.0f-gnm)*0.5f + rnd1 );
	float r1 = 0.5 - 0.5 * gnm + rnd1;
	r1 = 1.0 - max( 0.0, ((r1<1.0) ? r1 : 0.9999999) ); //note: weird ass bug on old drivers
	float rnd2 = rand( vec2(mytrunc1( uv.y, 40.0*r1 ), time) ); //vert
	float r2 = sat1( rnd2 );

	float rnd3 = rand( vec2(mytrunc1( uv.y, 10.0*r0 ), time) );
	float r3 = (1.0-sat1(rnd3+0.8)) - 0.1;

	float pxrnd = rand( uv + time );

	float ofs = 0.05 * r2 * GLITCH;
	if(( rnd0 > 0.5 ))ofs*=1.;
	else ofs*=-1.;
	ofs += 0.5 * pxrnd * ofs;

	uv.y += 0.1 * r3 * GLITCH;

    int NUM_SAMPLES = 20;
    float RCP_NUM_SAMPLES_F = 1.0 / float(NUM_SAMPLES);
    
	vec4 sum = vec4(0.0);
	vec3 wsum = vec3(0.0);
	for( int i=0; i<NUM_SAMPLES; ++i )
	{
		float t = float(i) * RCP_NUM_SAMPLES_F;
		uv.x = sat1( uv.x + ofs * t );
		vec4 samplecol = texture( iChannel0, uv);
		vec3 s = spectrum_offset( t );
		samplecol.rgb = samplecol.rgb * s;
		sum += samplecol;
		wsum += s;
	}
	sum.rgb /= wsum;
	sum.a *= RCP_NUM_SAMPLES_F;

	return vec4(sum.rgb,sum.a);
}


void mainImage( out vec4 fragColor, in vec2 fragCoord ,in vec2 iResolution)
{
	vec2 uv=fragCoord/iResolution;
	float vignetteAmt = 1. - dot((uv-0.5) * 0.65, (uv-0.5) * 0.65);
	fragColor=texture(iChannel0,uv);
	if(b1d>0.){
		fragColor.rgb=glitch_c(uv).rgb;
	}
	
	if(b2d>0.){
	float linesN = 440.;
	float one_y = iResolution.y / linesN; //field line
	vec2 tuv=floor(vec2(uv.x,1.-uv.y)*iResolution.xy/one_y)*one_y;
	float dtx=nn(tuv,iTime)*b2d;
	fragColor.rgb=fragColor.rgb*(1.-dtx*0.25)+dtx*0.25*vignetteAmt;
	}
	
	fragColor.rgb*=vignetteAmt;
	fragColor.rgb += (rand(uv) - .5)*.07;
	fragColor.rgb*=smoothstep(0.5,0.,play_timer);
	fragColor.a=1.;

}
void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution);
}