shader_type canvas_item;
render_mode blend_disabled;

uniform float iTime;
uniform int iFrame;

uniform sampler2D iChannel0;
uniform vec3 iMouse;

// Horizontal bloom blur

// Dedicated to the public domain under CC0 1.0 Universal
//  https://creativecommons.org/publicdomain/zero/1.0/legalcode

void mainImage( out vec4 fragColor, in vec2 fragCoord, vec2 iResolution)
{
    vec3 acc = vec3(0.0);
    
    vec2 uv = fragCoord.xy / iResolution.xy;
    
    // Manually expanded weights/iteration to please inferior shader compilers
    int steps = 7;
    float weights0 = 0.00598;
    float weights1 = 0.060626;
    float weights2 = 0.241843;
    float weights3 = 0.383103;
    float weights4 = 0.241843;
    float weights5 = 0.060626;
    float weights6 = 0.00598;
    
    vec2 direction = vec2(1.0, 0.0);	
    
    vec2 offset0 = direction * float(0 - steps / 2) / iResolution.xy;
    acc += texture(iChannel0, uv + offset0).xyz * weights0;
    vec2 offset1 = direction * float(1 - steps / 2) / iResolution.xy;
    acc += texture(iChannel0, uv + offset1).xyz * weights1;
    vec2 offset2 = direction * float(2 - steps / 2) / iResolution.xy;
    acc += texture(iChannel0, uv + offset2).xyz * weights2;
    vec2 offset3 = direction * float(3 - steps / 2) / iResolution.xy;
    acc += texture(iChannel0, uv + offset3).xyz * weights3;
    vec2 offset4 = direction * float(4 - steps / 2) / iResolution.xy;
    acc += texture(iChannel0, uv + offset4).xyz * weights4;
    vec2 offset5 = direction * float(5 - steps / 2) / iResolution.xy;
    acc += texture(iChannel0, uv + offset5).xyz * weights5;
    vec2 offset6 = direction * float(6 - steps / 2) / iResolution.xy;
    acc += texture(iChannel0, uv + offset6).xyz * weights6;
    
    fragColor = vec4(acc, 1.0);
}




void fragment(){
	vec2 iResolution=floor(1./TEXTURE_PIXEL_SIZE);
	mainImage(COLOR,UV*iResolution,iResolution);
}