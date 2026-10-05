extends Control

func _ready():
	# Conectar botones
	$Panel/BTN_VOLVER.connect("pressed", Callable(self, "on_btn_volver_pressed"))
	$Panel/BTN_CREAR_SALA.connect("pressed", Callable(self, "on_btn_crear_sala_pressed"))
	
	# ✅ Configurar SpinBox de CANT_JUGADORES
	var spin_jugadores = $Panel/CANT_JUGADORES
	if spin_jugadores:
		spin_jugadores.min_value = 2
		spin_jugadores.max_value = 6
		spin_jugadores.value = 2
		spin_jugadores.step = 1
		# Conectar señal de cambio de valor
		if not spin_jugadores.value_changed.is_connected(_on_cant_jugadores_changed):
			spin_jugadores.value_changed.connect(_on_cant_jugadores_changed)
	
	# ✅ Configurar SpinBox de CANT_TIEMPO
	var spin_tiempo = $Panel/CANT_TIEMPO
	if spin_tiempo:
		spin_tiempo.min_value = 60
		spin_tiempo.max_value = 120
		spin_tiempo.value = 60
		spin_tiempo.step = 30  # 60, 90, 120
		# Conectar señal
		if not spin_tiempo.value_changed.is_connected(_on_tiempo_changed):
			spin_tiempo.value_changed.connect(_on_tiempo_changed)
	
	# Actualizar labels iniciales
	actualizar_labels()

func _on_cant_jugadores_changed(valor: float):
	actualizar_labels()

func _on_tiempo_changed(valor: float):
	actualizar_labels()

func actualizar_labels():
	var cant = int($Panel/CANT_JUGADORES.value)
	var tiempo = int($Panel/CANT_TIEMPO.value)
	
	$Panel/LBL_CANT_JUGADORES.text = "Jugadores: " + str(cant)
	$Panel/LBL_TIEMPO_DE_JUEGO.text = "Tiempo: " + str(tiempo) + " min"

func on_btn_volver_pressed():
	get_tree().change_scene_to_file("res://SCENE/MAIN_MENU.tscn")

func on_btn_crear_sala_pressed():
	var nombre_sala = $Panel/TXT_SALA.text.strip_edges()
	var cant_jugadores = int($Panel/CANT_JUGADORES.value)
	var tiempo_juego = int($Panel/CANT_TIEMPO.value)
	
	# Validar
	if nombre_sala == "":
		print("❌ ERROR: Debes ingresar un nombre de sala")
		return
	
	print("")
	print("╔═══════════════════════════════════════╗")
	print("║     CREANDO SALA (PC-HOST)            ║")
	print("╚═══════════════════════════════════════╝")
	print("   Nombre: " + nombre_sala)
	print("   Cant. jugadores: " + str(cant_jugadores))
	print("   Tiempo: " + str(tiempo_juego) + " min")
	
	# ✅ GUARDAR DATOS EN EL JSON
	Global.guardar_datos_sala(nombre_sala, cant_jugadores, tiempo_juego)
	
	if Network.start_host():
		Network.salas[nombre_sala] = []
		Network.sala_actual = nombre_sala
		
		# ✅ Guardar datos adicionales de la sala en memoria
		Network.datos_salas[nombre_sala] = {
			"cant_jugadores": cant_jugadores,
			"tiempo_juego": tiempo_juego,
			"jugadores_listos": []
		}
		
		print("✅ SALA CREADA EXITOSAMENTE")
		print("   Salas disponibles: " + str(Network.salas.keys()))
		print("   Datos de sala: " + str(Network.datos_salas[nombre_sala]))
		
		# Sincronizar con todos los peers
		Network.sync_salas.rpc(Network.salas)
		Network.sync_datos_salas.rpc(Network.datos_salas)
		print("✅ Sincronización enviada a todos los peers")
		
		get_tree().change_scene_to_file("res://SCENE/LOBBY.tscn")
	else:
		print("❌ ERROR: No se pudo iniciar el servidor")
