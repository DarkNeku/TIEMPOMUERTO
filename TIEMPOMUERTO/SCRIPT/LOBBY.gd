extends Control

var timer: Timer
var es_android: bool = false

func _ready():
	es_android = OS.get_name() == "Android"
	
	$Panel/NOMBRE_SALA.text = "Sala: " + Network.sala_actual
	
	# ✅ Ocultar botón LISTO al inicio
	if has_node("Panel/BTN_LISTO"):
		$Panel/BTN_LISTO.visible = false
		$Panel/BTN_LISTO.connect("pressed", Callable(self, "on_btn_listo_pressed"))
		print("✅ BTN_LISTO oculto al inicio")
	
	# ✅ Conectar botón VOLVER
	if has_node("Panel/BTN_VOLVER"):
		$Panel/BTN_VOLVER.connect("pressed", Callable(self, "on_btn_volver_pressed"))
	
	# ✅ Mostrar info de la sala
	var cant_max = Global.get_cant_jugadores()
	var tiempo = Global.get_tiempo_juego()
	
	print("")
	print("=== LOBBY: Iniciando lobby ===")
	print("=== LOBBY: Sala: " + Network.sala_actual)
	print("=== LOBBY: Soy host? " + str(Network.soy_host()))
	print("=== LOBBY: Capacidad máxima: " + str(cant_max))
	print("=== LOBBY: Tiempo de juego: " + str(tiempo) + " min")
	
	# Mostrar info en un label si existe
	if has_node("Panel/LBL_INFO_SALA"):
		$Panel/LBL_INFO_SALA.text = "Máx: " + str(cant_max) + " jugadores  |  Tiempo: " + str(tiempo) + " min"
	
	if Network.peer:
		print("=== LOBBY: Peer ID: " + str(Network.peer.get_unique_id()))
	
	# Conectar señal de actualización
	Network.connect("jugadores_actualizados", Callable(self, "_on_jugadores_actualizados"))
	
	# Mostrar jugadores
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
	
	# Timer para actualizar cada 2 segundos
	if not has_node("Timer"):
		timer = Timer.new()
		timer.wait_time = 2.0
		timer.autostart = true
		timer.one_shot = false
		timer.timeout.connect(Callable(self, "_on_timer_timeout"))
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
	var cant_max = Global.get_cant_jugadores()
	
	print("=== LOBBY: Jugadores: " + str(jugadores) + " (" + str(jugadores.size()) + "/" + str(cant_max) + ")")
	
	if jugadores.size() > 0:
		for jugador in jugadores:
			$Panel/LISTA_JUGADORES.add_item(jugador)
	else:
		$Panel/LISTA_JUGADORES.add_item("Esperando jugadores...")
	
	# ✅ Verificar si todos están y mostrar/ocultar BTN_LISTO
	verificar_boton_listo(jugadores.size(), cant_max)

func verificar_boton_listo(cant_actual: int, cant_max: int):
	if not has_node("Panel/BTN_LISTO"):
		return
	
	if cant_actual >= cant_max and cant_max > 0:
		# ✅ Todos están presentes
		if not $Panel/BTN_LISTO.visible:
			$Panel/BTN_LISTO.visible = true
			print("")
			print("✅ ¡TODOS LOS JUGADORES ESTÁN LISTOS! (" + str(cant_actual) + "/" + str(cant_max) + ")")
			print("✅ Botón LISTO visible")
	else:
		# ❌ Faltan jugadores
		if $Panel/BTN_LISTO.visible:
			$Panel/BTN_LISTO.visible = false
			print("⏳ Faltan jugadores: " + str(cant_actual) + "/" + str(cant_max))

# ============================================
# BOTÓN LISTO
# ============================================
func on_btn_listo_pressed():
	print("")
	print("╔═══════════════════════════════════════╗")
	print("║     ¡INICIANDO JUEGO!                 ║")
	print("╚═══════════════════════════════════════╝")
	
	# ✅ Notificar a TODOS los clientes que el juego empieza
	Network.iniciar_juego.rpc()
	print("✅ Notificación enviada a todos los clientes")
	
	# El host también pasa a COLORES
	print("🔄 Host cambiando a COLORES...")
	get_tree().change_scene_to_file("res://SCENE/COLORES.tscn")

# ============================================
# BOTÓN VOLVER
# ============================================
func on_btn_volver_pressed():
	print("=== LOBBY: Volviendo al menú principal ===")
	
	if timer:
		timer.stop()
	
	Network.desconectar()
	get_tree().change_scene_to_file("res://SCENE/CREAR_SALA.tscn")
