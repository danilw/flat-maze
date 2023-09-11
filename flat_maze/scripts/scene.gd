extends Node2D

var iTime=0.0
var iFrame=0
var iMouse=Vector3() 
var iResolution=Vector2(1280,720)

func _ready():
	pass

func upd_imouse():
	var tres=get_viewport().size
	tres.x=max(tres.x,1)
	tres.y=max(tres.y,1)
	var m_pos=get_viewport().get_mouse_position()/tres
	m_pos.x=clamp(m_pos.x,0,1)
	m_pos.y=clamp(m_pos.y,0,1)
	iMouse=Vector3(m_pos.x*iResolution.x,iResolution.y*m_pos.y,0)
	if(Input.is_mouse_button_pressed(BUTTON_LEFT)):
		iMouse.z=1

func _process(delta):
	iTime+=delta
	iFrame+=1
	upd_imouse()
