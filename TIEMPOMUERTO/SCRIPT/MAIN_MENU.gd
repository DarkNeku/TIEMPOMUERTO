extends Control

func _ready():
	if has_node("Panel/BTN_CREAR"):
		$Panel/BTN_CREAR.connect("pressed", Callable(self, "on_btn_crear_pressed"))
	if has_node("Panel/BTN_PRUEBA"):
		$Panel/BTN_PRUEBA.visible = false # Ocultamos el botón viejo de prueba

func on_btn_crear_pressed():
	get_tree().change_scene_to_file("res://SCENE/CREAR_SALA.tscn")
