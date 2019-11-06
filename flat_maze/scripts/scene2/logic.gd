extends Sprite

onready var global_v=get_node("../../")

func _ready():
	pass

func _process(delta):
	self.material.set("shader_param/iTime",global_v.iTime)
	self.material.set("shader_param/iFrame",global_v.iFrame)
	self.material.set("shader_param/iMouse",global_v.iMouse)
	self.material.set("shader_param/delta",delta)
	self.material.set("shader_param/temp_mov_timer",global_v.temp_mov_timer)
	self.material.set("shader_param/anim_state1",global_v.anim_state1)
	self.material.set("shader_param/anim_state2",global_v.anim_state2)
	self.material.set("shader_param/add_speed",global_v.add_speed)
	
	var res=0.5*(global_v.iResolution/global_v.iResolution.y)
	var self_pos=Vector2(0,0)
	var map_res=Vector2(320,180)
	var spawn_pos=(Vector2(2+0.5,179+0.5)/map_res)*global_v.iResolution #in pixels that map ID
	self_pos=spawn_pos/global_v.iResolution.y-res