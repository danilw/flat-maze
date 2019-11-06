extends Sprite

onready var global_v=get_node("../")

func _ready():
	pass

var local_atimer=3.0/9 # start 3 frame from sprites
var last_atime=-10.0
func _process(delta):
	self.material.set("shader_param/iTime",local_atimer)
	self.material.set("shader_param/rTime",global_v.iTime)
	self.material.set("shader_param/iFrame",global_v.iFrame)
	self.material.set("shader_param/iMouse",global_v.iMouse)
	self.material.set("shader_param/zoom",global_v.zoom*1.5)
	self.material.set("shader_param/anim_state",global_v.last_anim_state)
	if(global_v.anim_state>=0):
		local_atimer+=delta
		global_v.last_anim_state=global_v.anim_state
		last_atime=global_v.iTime
	else:
		local_atimer+=delta*smoothstep(0.5,0.0,global_v.iTime-last_atime)
	
	
	













