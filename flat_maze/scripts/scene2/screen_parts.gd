extends Particles2D

onready var global_v=get_node("../../")

# particles displayed only on zoom < max zoom
# max zoom is play_zoom=0.115
# max particles = ((map_res*play_zoom))*2+4=(151.199997, 86.800003) 
# (2x2(*2) particles per pixel of map)
# +4 is additional particles outside of screen(2 is enought)

const map_res=Vector2(320,180)*2
const play_zoom=0.115
const min_zoom=0.015
var max_particles2d=((map_res*play_zoom))*2+Vector2(4,4)
var max_particles=int(max_particles2d.x)*int(max_particles2d.y)+1280 #12986+1280 14266

func _ready():
	self.amount=max_particles
	self.emitting=false

var once_e=false
func start_emit():
	if(once_e):
		return
	once_e=true
	self.emitting=true
	self.amount=max_particles

func _process(delta):
	self.material.set("shader_param/iTime",global_v.iTime)
	self.material.set("shader_param/iFrame",global_v.iFrame)
	self.material.set("shader_param/iMouse",global_v.iMouse)
	self.material.set("shader_param/real_resolution",global_v.iResolution_real.x/global_v.iResolution.x)
	
	var tzoom=(global_v.zoom*min_zoom)/play_zoom
	if(tzoom>0)&&(tzoom<=1):
		self.material.set("shader_param/zoom",1/tzoom-1)
		start_emit()
















