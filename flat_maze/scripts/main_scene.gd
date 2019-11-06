extends Node2D

var current_scene = null
onready var root = get_tree().get_root()

func _ready():
	current_scene = root.get_child(root.get_child_count() - 1)

func goto_scene(path):
	call_deferred("_deferred_goto_scene", path)

func _deferred_goto_scene(path):
	current_scene.call_deferred("free")
	var s = ResourceLoader.load(path)
	
	current_scene = s.instance()
	
	root.add_child(current_scene)
	
	get_tree().set_current_scene(current_scene)

