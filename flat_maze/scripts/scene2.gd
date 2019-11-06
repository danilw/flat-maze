extends Node2D

var iTime=0.0
var iFrame=0
var iMouse=Vector3(0,0,0) 
var iResolution=Vector2(1280,720)
var iResolution_real=Vector2(1280,720)
var restart=false
var zoom=1.0 #number of steeps min_zoom (mainImage)
var anim_state=-1
var anim_state1=-1
var anim_state2=-1
var last_anim_state=0
var temp_mov_timer=0.0
var spwan_b_once=false
var add_speed=0
var rclicks=0
var mouse_down=false
var iMoused=Vector2(0,0)
var impower=0.0

func _ready():
	randomize()

const startup_zoom_timer_sec=6.0

func upd_imouse(delta):
	var tres=get_viewport().size
	tres.x=max(tres.x,1)
	tres.y=max(tres.y,1)
	var m_pos=get_viewport().get_mouse_position()/tres
	iResolution_real=tres
	m_pos.x=clamp(m_pos.x,0,1)
	m_pos.y=clamp(m_pos.y,0,1)
	iMouse=Vector3(m_pos.x*iResolution.x,iResolution.y*m_pos.y,0)
	if(Input.is_mouse_button_pressed(BUTTON_LEFT)):
		iMouse.z=1
		iMoused.x+=delta*0.15
	else:
		#iMoused.x+=-delta
		iMoused.x=0
	
	if(Input.is_mouse_button_pressed(BUTTON_RIGHT)):
		iMoused.y+=delta*3
		impower+=-delta
		mouse_down=true
	else:
		if(mouse_down):
			rclicks+=1
			add_speed=rclicks/5.0
		mouse_down=false
		iMoused.y+=-delta*3
		impower+=delta/2
	
	impower=clamp(impower,0,2)
	iMoused=Vector2(clamp(iMoused.x,0,1),clamp(iMoused.y,0,1))

func _process(delta):
	iTime+=delta
	iFrame+=1
	if(iTime>startup_zoom_timer_sec):
		upd_imouse(delta)
	
