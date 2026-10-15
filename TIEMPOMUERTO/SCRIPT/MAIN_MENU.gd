extends Control

func _ready():
	$Panel/BTN_CREAR.connect("pressed", Callable(self, "on_btn_crear_pressed"))
	
	# ✅ Conectar BTN_PRUEBA si existe
	if has_node("Panel/BTN_PRUEBA"):
		$Panel/BTN_PRUEBA.connect("pressed", Callable(self, "on_btn_prueba_pressed"))
		print("✅ BTN_PRUEBA conectado")

func on_btn_crear_pressed():
	get_tree().change_scene_to_file("res://SCENE/CREAR_SALA.tscn")

# ============================================
# ✅ MODO PRUEBA: carga datos_prueba.json y arranca host directo
# ============================================
func on_btn_prueba_pressed():
	print("")
	print("╔═══════════════════════════════════════╗")
	print("║     🧪 MODO PRUEBA (PC-HOST)          ║")
	print("╚═══════════════════════════════════════╝")
	
	# 1) Cargar el JSON de prueba
	var ruta = "res://DATA/datos_prueba.json"
	if not FileAccess.file_exists(ruta):
		print("❌ No existe: " + ruta)
		return
	
	var archivo = FileAccess.open(ruta, FileAccess.READ)
	var contenido = archivo.get_as_text()
	archivo.close()
	var datos = JSON.parse_string(contenido)
	
	if not datos:
		print("❌ Error al parsear: " + ruta)
		return
	
	var nombre_sala = datos.get("sala", "SALA 1")
	var jugadores_prueba = datos.get("jugadores", [])
	
	print("📋 Datos cargados del JSON:")
	print("   Sala: " + nombre_sala)
	print("   Jugadores: " + str(jugadores_prueba.size()))
	
	# 2) Forzar configuración de prueba: 2 jugadores, 60 min
	var cant_jugadores = 2
	var tiempo_juego = 60
	
	# 3) Inicializar Global con nueva partida
	Global.nueva_partida(nombre_sala, cant_jugadores, tiempo_juego)
	
	# 4) Copiar los jugadores del JSON al DataManager y a Global
	if Global.data_manager:
		Global.data_manager.datos_actuales["jugadores"] = jugadores_prueba
		Global.data_manager.guardar_datos()
		Global.jugadores = jugadores_prueba
	
	print("✅ Global actualizado con " + str(jugadores_prueba.size()) + " jugadores de prueba")
	
	# 5) Arrancar el host
	if not Network.start_host():
		print("❌ No se pudo iniciar el host")
		return
	
	# 6) Inicializar sala en Network
	Network.salas[nombre_sala] = []
	Network.jugadores[nombre_sala] = []  # vacío: los jugadores se reservan al conectarse
	Network.sala_actual = nombre_sala
	Network.datos_salas[nombre_sala] = {
		"cant_jugadores": cant_jugadores,
		"tiempo_juego": tiempo_juego,
		"jugadores_listos": []
	}
	
	# 7) Sincronizar salas al inicio (por si algún cliente se conecta)
	Network.sync_salas.rpc(Network.salas)
	Network.sync_datos_salas.rpc(Network.datos_salas)
	
	print("✅ SALA DE PRUEBA CREADA: " + nombre_sala)
	print("🔄 Cambiando a PC.tscn (Room00)...")
	
	# 8) Ir directo a PC.tscn
	get_tree().change_scene_to_file("res://SCENE/PC.tscn")
