extends Node2D

func _ready():
	$Panel/BTN_CREAR.connect("pressed", Callable(self, "on_btn_crear_pressed"))


func on_btn_crear_pressed():
	get_tree().change_scene_to_file("res://SCENE/CREAR_SALA.tscn")
