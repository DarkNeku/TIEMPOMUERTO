extends Node2D

func _ready():
    $Panel/BTN_VOLVER.connect("pressed", Callable(self, "on_btn_volver_pressed"))

func on_btn_volver_pressed():
    get_tree().change_scene_to_file("res://SCENE/MAIN_MENU.tscn")
