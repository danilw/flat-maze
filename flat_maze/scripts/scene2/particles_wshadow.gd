extends Viewport

var last_iResolution_real=Vector2(1280,720)
onready var global_v=get_node("../")

func _ready():
	pass

func _process(delta):
	if(int(global_v.iResolution_real.x)!=int(last_iResolution_real.x)):
		self.size=global_v.iResolution_real
		last_iResolution_real=global_v.iResolution_real