extends Control

var timer: Timer
var es_android: bool = false

func _ready():
	es_android = OS.get_name() == "Android"
	
	$Panel/NOMBRE_SALA.text = "Sala: " + Network.sala_actual
	
	print("")
	print("=== LOBBY (CELULAR): Iniciando ===")
	print("Sala: " + Network.sala_actual)
	print("Soy host? " + str(Network.soy_host()))
	
	if Network.peer:
		print("Peer ID: " + str(Network.peer.get_unique_id()))
	
	Network.connect("jugadores_actualizados", Callable(self, "_on_jugadores_actualizados"))
	
	if has_node("Panel/BTN_VOLVER"):
		$Panel/BTN_VOLVER.connect("pressed", Callable(self, "on_btn_volver_pressed"))
	
	if Network.soy_host():
		mostrar_jugadores(Network.sala_actual)
	else:
		var wait_time = 1.0 if es_android else 0.5
		await get_tree().create_timer(wait_time).timeout
		Network.pedir_jugadores.rpc_id(1, Network.sala_actual)
		await get_tree().create_timer(wait_time).timeout
		mostrar_jugadores(Network.sala_actual)
	
	if not has_node("Timer"):
		timer = Timer.new()
		timer.wait_time = 2.0
		timer.autostart = true
		timer.one_shot = false
		timer.timeout.connect(Callable(self, "_on_timer_timeout"))
		add_child(timer)

func _on_jugadores_actualizados():
	mostrar_jugadores(Network.sala_actual)

func _on_timer_timeout():
	mostrar_jugadores(Network.sala_actual)

func mostrar_jugadores(nombre_sala):
	$Panel/LISTA_JUGADORES.clear()
	
	var jugadores = Network.get_jugadores(nombre_sala)
	print("Jugadores: " + str(jugadores))
	
	if jugadores.size() > 0:
		for jugador in jugadores:
			$Panel/LISTA_JUGADORES.add_item(jugador)
	else:
		$Panel/LISTA_JUGADORES.add_item("Esperando jugadores...")

func on_btn_volver_pressed():
	if timer:
		timer.stop()
	get_tree().change_scene_to_file("res://SCENE/UNIRSE_SALA.tscn")
