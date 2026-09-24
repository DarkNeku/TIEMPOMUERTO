extends Node2D

func _ready():
	$Panel/BTN_UNIRSE.connect("pressed", Callable(self, "on_btn_unirse_pressed"))


func on_btn_unirse_pressed():
	get_tree().change_scene_to_file("res://SCENE/UNIRSE_SALA.tscn")
