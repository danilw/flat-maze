shader_type particles;
render_mode disable_velocity,disable_force;

uniform sampler2D logic;
uniform float zoom;

//because bug https://github.com/godotengine/godot/issues/33134
//used only single sampler2D
//because of it posiiton logic moved to vertex shader of particle

vec2 get_screen_pos(){
	return texelFetch(logic,ivec2(0,0),0).xy;
}

//custom index for max scale
ivec2 index_x_maxzoom(int id){
	//ivec2 p_res=ivec2(77,45);
	ivec2 p_res=ivec2(151,86);
	int x=id%p_res.x;
	int y=id/p_res.x;
	return ivec2(x,y);
}

void vertex() {
	
	ivec2 index2d=index_x_maxzoom(INDEX);
	
	TRANSFORM=EMISSION_TRANSFORM;
	TRANSFORM[3].z = 0.0;
	
	CUSTOM=vec4(vec2(index2d),0.,0.);
	
	COLOR=vec4(0.);
}