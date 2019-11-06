extends Control

onready var global_v=get_node("../../")

func _ready():
	pass

func _process(delta):
	get_node("gbb").material.set("shader_param/scale",3-2*smoothstep(0,1.5,atimer))
	get_node("gbb").material.set("shader_param/iTime",atimer)
	get_node("gbb").material.set("shader_param/index",index)
	if(click):
		atimer+=delta
		if(atimer>2):
			atimer=0.0
			click=false
			index=int(randf()*48)
			index=index%48

var index=0
var atimer=0.0
var click=false
func _on_gbb_pressed():
	global_v.spwan_b_once=true
	if(click):
		return
	click=true
	atimer=0.0


func _on_restart_pressed():
	get_tree().reload_current_scene()


func _on_back_pressed():
	get_node("../").visible=false
	global_v.restart=false
