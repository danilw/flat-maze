extends Sprite

onready var global_v=get_node("../")

var a11_g1=load("res://menubg/a11_g1.png") as Texture
var a11_g2=load("res://menubg/a11_g2.png") as Texture
var a11_g3=load("res://menubg/a11_g3.png") as Texture
var a12_g1=load("res://menubg/a12_g1.png") as Texture
var a21_g1=load("res://menubg/a21_g1.png") as Texture
var a21_g2=load("res://menubg/a21_g2.png") as Texture
var a21_g3=load("res://menubg/a21_g3.png") as Texture
var a22_g1=load("res://menubg/a22_g1.png") as Texture
var a31_g1=load("res://menubg/a31_g1.png") as Texture
var a31_g2=load("res://menubg/a31_g2.png") as Texture
var a31_g3=load("res://menubg/a31_g3.png") as Texture
var a32_g1=load("res://menubg/a32_g1.png") as Texture
var a41_g1=load("res://menubg/a41_g1.png") as Texture
var a41_g2=load("res://menubg/a41_g2.png") as Texture
var a41_g3=load("res://menubg/a41_g3.png") as Texture
var a42_g1=load("res://menubg/a42_g1.png") as Texture
var b1=load("res://menubg/b1.png") as Texture
var b2=load("res://menubg/b2.png") as Texture

var texarr=[[a11_g1,a11_g2,a11_g3,a12_g1],
[a21_g1,a21_g2,a21_g3,a22_g1],
[a31_g1,a31_g2,a31_g3,a32_g1],
[a41_g1,a41_g2,a41_g3,a42_g1]]

var indexa=0
var b2e=false
var b2d=0.0
var b1e=false
var b1d=0.0

onready var menu_bg=get_node("../menu_bg").get_child(0)

func _ready():
	pass

func _process(delta):
	if(b2e):
		b2d+=delta
	else:
		b2d+=-delta
	b2d=clamp(b2d,0,1)
	
	if(b1e):
		b1d=1
		b1e=false
	else:
		b1d+=-delta
	b1d=clamp(b1d,0,1)
	
	self.material.set("shader_param/iTime",global_v.iTime)
	self.material.set("shader_param/iFrame",global_v.iFrame)
	self.material.set("shader_param/iMouse",global_v.iMouse)
	self.material.set("shader_param/b2d",b2d)
	self.material.set("shader_param/b1d",b1d)
	self.material.set("shader_param/play_timer",play_timer)
	
	if(play_click):
		if(play_timer>=0.5):
			get_node("../../").goto_scene("res://scene2.tscn")
		play_timer+=delta

func set_pressed_a():
	menu_bg.material.set("shader_param/iChannel1",texarr[indexa][3])

func set_unpressed_a():
	menu_bg.material.set("shader_param/iChannel1",texarr[indexa][0])

func set_pressed_b():
	menu_bg.material.set("shader_param/iChannel1",texarr[indexa][1])

func set_unpressed_b():
	menu_bg.material.set("shader_param/iChannel1",texarr[indexa][0])

func set_pressed2_b():
	menu_bg.material.set("shader_param/iChannel1",texarr[indexa][2])

func set_unpressed2_b():
	menu_bg.material.set("shader_param/iChannel1",texarr[indexa][1])

func _on_b1_pressed():
	indexa+=1
	indexa=indexa%4
	b1e=true
	set_pressed_a()

func _on_b2_button_down():
	set_pressed2_b()

func _on_b2_button_up():
	set_unpressed2_b()

func _on_b2_mouse_entered():
	b2e=true
	set_pressed_b()

func _on_b2_mouse_exited():
	b2e=false
	set_unpressed_b()

func _on_b1_mouse_entered():
	set_pressed_a()

func _on_b1_mouse_exited():
	set_unpressed_a()


func _on_b3_mouse_entered():
	menu_bg.material.set("shader_param/iChannel2",b2)


func _on_b3_mouse_exited():
	menu_bg.material.set("shader_param/iChannel2",b1)

var play_click=false
var play_timer=0.0
func _on_b3_pressed():
	get_node("Control").visible=false
	play_click=true
