extends Sprite

onready var global_v=get_node("../../")

func _ready():
	pass

var local_iTime=0.0

func _process(delta):
	if(!global_v.restart):
		local_iTime=0.0
		return
	local_iTime+=delta
	self.material.set("shader_param/iTime",local_iTime)
	self.material.set("shader_param/iFrame",global_v.iFrame)
	self.material.set("shader_param/iMouse",global_v.iMouse)