extends Node2D

onready var logic=get_node("../logic")
onready var logic_buf=get_node("../logic_buf")

onready var particles=get_node("../particles")
onready var particles_buf=get_node("../particles_buf")

func _ready():
	var tc=logic_buf.get_viewport().get_texture()
	tc.flags=0
	logic.get_child(0).material.set("shader_param/iChannel0",tc)
	
	var ptc=particles_buf.get_viewport().get_texture()
	ptc.flags=0
	particles.get_child(0).material.set("shader_param/iChannel0",ptc)
	
	logic.get_child(0).material.set("shader_param/iChannel1",ptc)
	
