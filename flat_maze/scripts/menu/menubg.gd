extends Sprite

onready var global_v=get_node("../../")

func _ready():
	pass

func _process(delta):
	self.material.set("shader_param/iTime",global_v.iTime)
	self.material.set("shader_param/iFrame",global_v.iFrame)
	self.material.set("shader_param/iMouse",global_v.iMouse)

