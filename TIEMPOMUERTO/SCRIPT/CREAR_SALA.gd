extends Node2D

func _ready():
	$Panel/BTN_VOLVER.connect("pressed", Callable(self, "on_btn_volver_pressed"))
	$Panel/BTN_CREAR_SALA.connect("pressed", Callable(self, "on_btn_crear_sala_pressed"))

func on_btn_volver_pressed():
	get_tree().change_scene_to_file("res://SCENE/MAIN_MENU.tscn")

func on_btn_crear_sala_pressed():
	var nombre_sala = $Panel/TXT_SALA.text
	var nombre_usuario = $Panel/TXT_NOMBRE.text
	
	if nombre_sala.strip_edges() == "" or nombre_usuario.strip_edges() == "":
		print("ERROR: Completa todos los campos")
		return
	
	print("=== CREANDO SALA: " + nombre_sala)
	
	if Network.start_host():
		Network.salas[nombre_sala] = []
		Network.jugadores[nombre_sala] = [nombre_usuario]
		Network.sala_actual = nombre_sala
		
		print("=== SALA CREADA EXITOSAMENTE")
		print("=== Salas disponibles: " + str(Network.salas.keys()))
		
		Network.sync_salas.rpc(Network.salas)
		print("=== Sincronización enviada a todos los peers")
		
		get_tree().change_scene_to_file("res://SCENE/LOBBY.tscn")
	else:
		print("=== ERROR: No se pudo iniciar el servidor")
