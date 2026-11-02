extends Node2D

func _ready():
	$Panel/BTN_VOLVER.connect("pressed", Callable(self, "on_btn_volver_pressed"))
	$Panel/BTN_CREAR_SALA.connect("pressed", Callable(self, "on_btn_continuar_pressed"))
	
	var spin_jugadores = $Panel/CANT_JUGADORES
	if spin_jugadores:
		spin_jugadores.min_value = 2
		spin_jugadores.max_value = 4
		spin_jugadores.value = 2
		spin_jugadores.step = 1
		spin_jugadores.value_changed.connect(_on_valor_changed)
	
	var spin_tiempo = $Panel/CANT_TIEMPO
	if spin_tiempo:
		spin_tiempo.min_value = 30
		spin_tiempo.max_value = 120
		spin_tiempo.value = 60
		spin_tiempo.step = 10
		spin_tiempo.value_changed.connect(_on_valor_changed)
	
	actualizar_labels()

func _on_valor_changed(_valor):
	actualizar_labels()

func actualizar_labels():
	var cant = int($Panel/CANT_JUGADORES.value)
	var tiempo = int($Panel/CANT_TIEMPO.value)
	
	$Panel/LBL_CANT_JUGADORES.text = "Jugadores: " + str(cant)
	$Panel/LBL_TIEMPO_DE_JUEGO.text = "Tiempo: " + str(tiempo) + " min"

func on_btn_volver_pressed():
	get_tree().change_scene_to_file("res://SCENE/MAIN_MENU.tscn")

func on_btn_continuar_pressed():
	var cant_jugadores = int($Panel/CANT_JUGADORES.value)
	var tiempo_juego = int($Panel/CANT_TIEMPO.value)
	
	Global.nueva_partida(cant_jugadores, tiempo_juego)
	
	print("✅ Configuración guardada. Pasando a Colores...")
	get_tree().change_scene_to_file("res://SCENE/COLORES.tscn")
