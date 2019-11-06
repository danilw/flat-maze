extends Node2D

onready var menubg=get_node("../menu_bg")
onready var menubg_buf=get_node("../menu_bg_buf")

func _ready():
	var tc=menubg_buf.get_viewport().get_texture()
	tc.flags=Texture.FLAG_FILTER
	tc.flags=0
	menubg.get_child(0).material.set("shader_param/iChannel0",tc)
