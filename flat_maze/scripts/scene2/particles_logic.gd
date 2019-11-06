extends Sprite

onready var global_v=get_node("../../")

func _ready():
	pass

var lframe=1

func _process(delta):
	self.material.set("shader_param/iTime",global_v.iTime)
	self.material.set("shader_param/iFrame",global_v.iFrame)
	self.material.set("shader_param/iMouse",global_v.iMouse)
	self.material.set("shader_param/zoom",global_v.zoom)
	self.material.set("shader_param/spwan_b_once",global_v.spwan_b_once)
	self.material.set("shader_param/mousedl",global_v.iMoused.x)
	self.material.set("shader_param/anim_state",global_v.last_anim_state)
	if(lframe==0):
		lframe=1
		global_v.spwan_b_once=false
	if(global_v.spwan_b_once):
		lframe=(lframe+1)%2