extends Node2D

func _ready():
	$Panel/BTN_VOLVER.connect("pressed", Callable(self, "on_btn_volver_pressed"))
	$Panel/BTN_CREAR_SALA.connect("pressed", Callable(self, "on_btn_crear_sala_pressed"))

func on_btn_volver_pressed():
	get_tree().change_scene_to_file("res://SCENE/MAIN_MENU.tscn")

func on_btn_crear_sala_pressed():
	var nombre_sala = $Panel/TXT_SALA.text
	var nombre_usuario = $Panel/TXT_NOMBRE.text
	if Network.start_host():
		# Llama directamente a la función en lugar de usar RPC (eres el host)
		Network.salas[nombre_sala] = []
		Network.jugadores[nombre_sala] = [nombre_usuario]
		Network.sala_actual = nombre_sala
		print("Sala creada: " + nombre_sala)
		print("Usuario creado: " + nombre_usuario)
		if Network.peer:
			print("Peer ID host: " + str(Network.peer.get_unique_id()))
		var jugadores = Network.get_jugadores(nombre_sala)
		print("Jugadores en la sala: " + str(jugadores))
		if jugadores.size() > 0:
			for jugador in jugadores:
				print("Usuario en sala: " + jugador)
		else:
			print("ERROR: No se agregó el usuario correctamente!")
		get_tree().change_scene_to_file("res://SCENE/LOBBY.tscn")
	else:
		print("No se pudo iniciar el servidor")
