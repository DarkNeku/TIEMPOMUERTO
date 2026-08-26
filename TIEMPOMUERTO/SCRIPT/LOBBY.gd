extends Node2D

var timer: Timer
var es_android: bool = false

func _ready():
	es_android = OS.get_name() == "Android"
	
	$Panel/NOMBRE_SALA.text = "Sala: " + Network.sala_actual
	
	print("=== LOBBY: Iniciando lobby para sala: " + Network.sala_actual)
	print("=== LOBBY: Soy host? " + str(Network.soy_host()))
	print("=== LOBBY: Es Android? " + str(es_android))
	
	if Network.peer:
		print("=== LOBBY: Peer ID: " + str(Network.peer.get_unique_id()))
	
	Network.connect("jugadores_actualizados", Callable(self, "_on_jugadores_actualizados"))
	
	if Network.soy_host():
		print("=== LOBBY: Soy el host, mostrando jugadores...")
		mostrar_jugadores(Network.sala_actual)
	else:
		print("=== LOBBY: Soy cliente, solicitando lista de jugadores...")
		var wait_time = 1.0 if es_android else 0.5
		await get_tree().create_timer(wait_time).timeout
		Network.pedir_jugadores.rpc_id(1, Network.sala_actual)
		await get_tree().create_timer(wait_time).timeout
		mostrar_jugadores(Network.sala_actual)
	
	var jugadores = Network.get_jugadores(Network.sala_actual)
	print("=== LOBBY: Jugadores en la sala: " + str(jugadores))
	
	if jugadores.size() > 0:
		for jugador in jugadores:
			print("=== LOBBY: Usuario en sala: " + jugador)
	else:
		print("=== LOBBY: No hay usuarios en la sala todavía.")
	
	if not has_node("Timer"):
		timer = Timer.new()
		timer.wait_time = 2.0
		timer.autostart = true
		timer.one_shot = false
		timer.connect("timeout", Callable(self, "_on_timer_timeout"))
		add_child(timer)

func _on_jugadores_actualizados():
	print("=== LOBBY: Señal de jugadores actualizados recibida")
	mostrar_jugadores(Network.sala_actual)

func _on_timer_timeout():
	mostrar_jugadores(Network.sala_actual)

func mostrar_jugadores(nombre_sala):
	$Panel/LISTA_JUGADORES.clear()
	
	if not Network.has_method("get_jugadores"):
		print("=== ERROR: Network.get_jugadores no existe!")
		$Panel/LISTA_JUGADORES.add_item("Error: Función no encontrada")
		return
	
	var jugadores = Network.get_jugadores(nombre_sala)
	
	print("=== LOBBY: Actualizando lista de jugadores: " + str(jugadores))
	
	if jugadores.size() > 0:
		for jugador in jugadores:
			$Panel/LISTA_JUGADORES.add_item(jugador)
	else:
		$Panel/LISTA_JUGADORES.add_item("No hay jugadores")
