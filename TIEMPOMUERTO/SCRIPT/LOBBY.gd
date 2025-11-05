extends Node2D

var timer: Timer

func _ready():
	$Panel/NOMBRE_SALA.text = Network.sala_actual

	# Si no soy el host, solicitar la lista actualizada de jugadores
	if !Network.soy_host():
		print("=== CLIENTE: Solicitando lista de jugadores al host...")
		await get_tree().create_timer(0.5).timeout
		Network.pedir_jugadores.rpc_id(1, Network.sala_actual)
		await get_tree().create_timer(0.5).timeout

	mostrar_jugadores(Network.sala_actual)
	var jugadores = Network.get_jugadores(Network.sala_actual)
	print("Jugadores en lobby: ", jugadores)
	if jugadores.size() > 0:
		for jugador in jugadores:
			print("Usuario en lobby: " + jugador)
	else:
		print("No hay usuarios en la sala todavía.")
	print("Sala actual: " + Network.sala_actual)
	if Network.peer:
		print("Peer ID: " + str(Network.peer.get_unique_id()))
	# Timer para refrescar la lista
	if !has_node("Timer"):
		timer = Timer.new()
		timer.wait_time = 1.0
		timer.autostart = true
		timer.one_shot = false
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))
		add_child(timer)

func _on_timer_timeout():
	mostrar_jugadores(Network.sala_actual)

func mostrar_jugadores(nombre_sala):
	$Panel/LISTA_JUGADORES.clear()
	var jugadores = Network.get_jugadores(nombre_sala)
	for jugador in jugadores:
		$Panel/LISTA_JUGADORES.add_item(jugador)
