extends Sprite

onready var global_v=get_node("../")

#same in logic shader
const mov_speed=0.008 # start mov speed
const max_mov_speed=0.015

#same in screen_parts
const min_zoom=0.015
const zoom_step=0.005
const play_zoom=0.115 #max zoom

const startup_zoom_timer=10.0 # not sec, look play_start_zoom
const startup_zoom_timer_sec=6.0 # sec

const map_res=Vector2(320,180)
onready var spawn_pos=(Vector2(2+0.5,179+0.5)/map_res)*global_v.iResolution #in pixels that map ID

var zoom=1.0
onready var res=0.5*(global_v.iResolution/global_v.iResolution.y)
onready var self_pos=Vector2(0,0) # in % of screen res

func _ready():
	pass

var wheel_a=0.0
var smooth_wheel_a=0.0
func _input(event):
	if event is InputEventMouseButton:
		if event.is_pressed():
			if event.button_index == BUTTON_WHEEL_UP:
				wheel_a+=1
			if event.button_index == BUTTON_WHEEL_DOWN:
				wheel_a+=-1
	wheel_a=clamp(wheel_a,-2,2)

# only startup zoom+move stay here
var pa_once=false
var pa_timer=0.0
func play_start_zoom(delta):
	if(pa_once):
		return
	if(global_v.iTime>01.6):
		zoom=min_zoom+(1-min_zoom)*smoothstep(startup_zoom_timer,0.0,pa_timer)
		self_pos=(spawn_pos/global_v.iResolution.y-res)*smoothstep(0.0,startup_zoom_timer,pa_timer)
		pa_timer+=delta+max((startup_zoom_timer-pa_timer*1.25),0)*delta
	if(pa_timer>startup_zoom_timer)&&(startup_zoom_timer_sec<global_v.iTime):
		pa_once=true
		zoom=min_zoom
		self_pos=spawn_pos/global_v.iResolution.y-res

func _process(delta):
	self.material.set("shader_param/iTime",global_v.iTime)
	self.material.set("shader_param/iFrame",global_v.iFrame)
	self.material.set("shader_param/iMouse",global_v.iMouse)
	self.material.set("shader_param/pa_once",pa_once)
	self.material.set("shader_param/screen_pos",self_pos/(res*2.0))
	self.material.set("shader_param/zoom",global_v.zoom*min_zoom)
	self.material.set("shader_param/mousedr",global_v.iMoused.y*min(global_v.impower,1))
	#self.material.set("shader_param/txgrad",(zoom/1.250)/min_zoom) #for textureLod
	self.material.set("shader_param/txgrad",max(1,10*(zoom/min_zoom))) #textureGrad
	
	global_v.zoom=(zoom/min_zoom)
	global_v.anim_state=-1
	global_v.anim_state1=-1
	global_v.anim_state2=-1
	
	play_start_zoom(delta)
	if(!pa_once):
		return
	process_input(delta)

# posiiton control moved to shader
var dir=Vector2()
var is_shoot=false
var smooth_zoom=0.0
func process_input(delta):
	
	if Input.is_action_pressed("esc")&&(!global_v.restart):
		global_v.restart=!global_v.restart
		get_node("../endgame").visible=!get_node("../endgame").visible
	
	if Input.is_action_pressed("zoom_in"):
		smooth_zoom+=-zoom_step*delta
	else:
		if Input.is_action_pressed("zoom_out"):
			smooth_zoom+=zoom_step*delta
		else:
			smooth_zoom=smooth_zoom-smooth_zoom*delta*2.5
	
	
	smooth_wheel_a+=delta*wheel_a*zoom_step
	smooth_wheel_a=smooth_wheel_a-smooth_wheel_a*delta*3.5
	wheel_a=wheel_a-wheel_a*delta*20
	smooth_wheel_a=clamp(smooth_wheel_a,-zoom_step,zoom_step)
	smooth_zoom=clamp(smooth_zoom,-zoom_step,zoom_step)
	zoom+=smooth_zoom+smooth_wheel_a
	if(zoom<min_zoom):
		smooth_zoom=0
		smooth_wheel_a=0
	if(zoom>play_zoom):
		smooth_zoom=0
		smooth_wheel_a=0
	zoom=clamp(zoom,min_zoom,play_zoom)
	
	var any_key=false
#	var tmspd=mov_speed+(max_mov_speed-mov_speed)*smoothstep(0.5,1.5,temp_mov_timer)
	
	if Input.is_action_pressed("ui_down"):
		if(global_v.temp_mov_timer>1):
			global_v.anim_state=6
			global_v.anim_state1=6
		else:
			global_v.anim_state=2
			global_v.anim_state1=2
#		dir.y+=tmspd*delta*8.5
		any_key=true
	else:
		if Input.is_action_pressed("ui_up"):
			if(global_v.temp_mov_timer>1):
				global_v.anim_state=7
				global_v.anim_state1=7
			else:
				global_v.anim_state=3
				global_v.anim_state1=3
#			dir.y+=-tmspd*delta*8.5
			any_key=true
#		else:
#			dir.y=dir.y-dir.y*delta*8.5
	
	
	if Input.is_action_pressed("ui_left"):
		if(global_v.temp_mov_timer>1):
			global_v.anim_state=4
			global_v.anim_state2=4
		else:
			global_v.anim_state=0
			global_v.anim_state2=0
#		dir.x+=-tmspd*delta*8.5
		any_key=true
	else:
		if Input.is_action_pressed("ui_right"):
			if(global_v.temp_mov_timer>1):
				global_v.anim_state=5
				global_v.anim_state2=5
			else:
				global_v.anim_state=1
				global_v.anim_state2=1
#			dir.x+=tmspd*delta*8.5
			any_key=true
#		else:
#			dir.x=dir.x-dir.x*delta*8.5
	
	if(any_key):
		global_v.temp_mov_timer+=delta*0.3
	else:
		global_v.temp_mov_timer=0.0
	
	
	if Input.is_action_pressed("shoot"):
		is_shoot=true
	else:
		is_shoot=false
	
#	dir=(dir/tmspd).normalized()*min(dir.length(),tmspd)
#
#	self_pos+=dir*delta
#	self_pos.x=clamp(self_pos.x,-res.x,res.x)
#	self_pos.y=clamp(self_pos.y,-res.y,res.y)
	
	



















