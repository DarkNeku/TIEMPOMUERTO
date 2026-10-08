extends Node

const RUTA_PLANTILLA = "res://DATA/datos_prueba.json"
const RUTA_PARTIDA = "user://datos_partida.json"

var datos_actuales: Dictionary = {}

func _ready():
	# ✅ En el CLIENTE: limpiar jugadores viejos al arrancar (evita fantasmas)
	# El HOST NO debe borrar nada.
	if Network and Network.has_method("soy_host") and not Network.soy_host():
		if FileAccess.file_exists(RUTA_PARTIDA):
			print("🧹 Cliente: limpiando jugadores viejos de user://")
			var archivo = FileAccess.open(RUTA_PARTIDA, FileAccess.READ)
			if archivo:
				var contenido = archivo.get_as_text()
				archivo.close()
				var datos = JSON.parse_string(contenido)
				if datos:
					datos["jugadores"] = []
					var w = FileAccess.open(RUTA_PARTIDA, FileAccess.WRITE)
					if w:
						w.store_string(JSON.stringify(datos, "\t"))
						w.close()
	
	cargar_datos()

# ============================================
# CARGAR DATOS
# ============================================
func cargar_datos() -> bool:
	print("")
	print("=== DataManager: Cargando datos ===")
	
	# PRIORIDAD 1: Si existe una PARTIDA guardada, cargarla
	if FileAccess.file_exists(RUTA_PARTIDA):
		var archivo = FileAccess.open(RUTA_PARTIDA, FileAccess.READ)
		if archivo:
			var contenido = archivo.get_as_text()
			archivo.close()
			var datos = JSON.parse_string(contenido)
			if datos:
				datos_actuales = datos
				print("✅ Partida cargada desde user://")
				mostrar_info_jugadores()
				return true
	
	# ✅ DETECTAR SI SOMOS HOST O CLIENTE
	var es_host: bool = false
	if Network and Network.has_method("soy_host"):
		es_host = Network.soy_host()
	
	if es_host:
		print("⚠️ Host sin partida guardada. Cargando plantilla...")
		if cargar_plantilla():
			return true
		print("❌ No hay plantilla. Creando datos por defecto...")
		crear_datos_por_defecto()
		return false
	else:
		print("⚠️ Cliente sin partida guardada. Iniciando vacío (esperando RPC del host)...")
		crear_datos_por_defecto()
		return false

func cargar_plantilla() -> bool:
	if not FileAccess.file_exists(RUTA_PLANTILLA):
		print("❌ No existe la plantilla: " + RUTA_PLANTILLA)
		return false
	
	var archivo = FileAccess.open(RUTA_PLANTILLA, FileAccess.READ)
	if not archivo:
		return false
	
	var contenido = archivo.get_as_text()
	archivo.close()
	var datos = JSON.parse_string(contenido)
	
	if not datos:
		print("❌ Error al parsear la plantilla")
		return false
	
	datos_actuales = datos
	print("✅ Plantilla cargada desde res://")
	return true

# ============================================
# GUARDAR DATOS
# ============================================
func guardar_datos() -> bool:
	var archivo = FileAccess.open(RUTA_PARTIDA, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos_actuales, "\t"))
		archivo.close()
		print("💾 Partida guardada")
		return true
	return false

# ============================================
# NUEVA PARTIDA
# ============================================
func nueva_partida(nombre_sala: String, cant_jugadores: int, tiempo_juego: int) -> bool:
	print("")
	print("╔═══════════════════════════════════════╗")
	print("║     CREANDO NUEVA PARTIDA             ║")
	print("╚═══════════════════════════════════════╝")
	
	datos_actuales = {
		"sala": nombre_sala,
		"ip_host": "",
		"puerto": 12345,
		"cant_jugadores": cant_jugadores,
		"tiempo_juego": tiempo_juego,
		"jugadores": []
	}
	
	guardar_datos()
	
	print("✅ Nueva partida creada:")
	print("   Sala: " + nombre_sala)
	print("   Jugadores máx: " + str(cant_jugadores))
	print("   Tiempo: " + str(tiempo_juego) + " min")
	
	return true

# ============================================
# AGREGAR JUGADOR (NORMALIZADO)
# ============================================
func agregar_jugador_partida(nombre: String) -> bool:
	var nombre_normalizado = nombre.strip_edges().to_upper()
	
	var jugadores = datos_actuales.get("jugadores", [])
	
	for j in jugadores:
		if j.get("nombre", "").to_upper() == nombre_normalizado:
			print("⚠️ El jugador " + nombre_normalizado + " ya está en la partida")
			return false
	
	jugadores.append({
		"nombre": nombre_normalizado,
		"color": "",
		"avatar": "",
		"conectado": true
	})
	
	datos_actuales["jugadores"] = jugadores
	guardar_datos()
	
	print("✅ Jugador agregado a la partida: " + nombre_normalizado)
	return true

# ============================================
# DATOS POR DEFECTO
# ============================================
func crear_datos_por_defecto():
	datos_actuales = {
		"sala": "",
		"ip_host": "",
		"puerto": 12345,
		"cant_jugadores": 2,
		"tiempo_juego": 60,
		"jugadores": []
	}

func mostrar_info_jugadores():
	var jugadores = datos_actuales.get("jugadores", [])
	print("   Jugadores: " + str(jugadores.size()))
	for j in jugadores:
		print("   • " + j.get("nombre", "?") + " → color: '" + str(j.get("color", "")) + "'")

# ============================================
# GETTERS
# ============================================
func get_sala() -> String:
	return datos_actuales.get("sala", "")

func get_ip() -> String:
	return datos_actuales.get("ip_host", "")

func get_puerto() -> int:
	return datos_actuales.get("puerto", 12345)

func get_cant_jugadores() -> int:
	return datos_actuales.get("cant_jugadores", 2)

func get_tiempo_juego() -> int:
	return datos_actuales.get("tiempo_juego", 60)

func get_jugadores() -> Array:
	return datos_actuales.get("jugadores", [])

func get_jugador_por_nombre(nombre: String) -> Dictionary:
	var nombre_normalizado = nombre.strip_edges().to_upper()
	
	for jugador in get_jugadores():
		if jugador.get("nombre", "").to_upper() == nombre_normalizado:
			return jugador
	return {}

# ============================================
# ACTUALIZAR COLOR (NORMALIZADO)
# ============================================
func actualizar_color_jugador(nombre: String, nuevo_color: String) -> bool:
	var nombre_normalizado = nombre.strip_edges().to_upper()
	
	var jugadores = datos_actuales.get("jugadores", [])
	for i in range(jugadores.size()):
		if jugadores[i].get("nombre", "").to_upper() == nombre_normalizado:
			jugadores[i]["color"] = nuevo_color
			guardar_datos()
			print("✅ Color actualizado: " + nombre_normalizado + " → " + nuevo_color)
			return true
	
	print("❌ No se encontró al jugador: " + nombre_normalizado)
	print("   Jugadores existentes:")
	for j in jugadores:
		print("   • '" + j.get("nombre", "?") + "'")
	
	return false

func actualizar_avatar_jugador(nombre: String, nuevo_avatar: String) -> bool:
	var nombre_normalizado = nombre.strip_edges().to_upper()
	
	var jugadores = datos_actuales.get("jugadores", [])
	for i in range(jugadores.size()):
		if jugadores[i].get("nombre", "").to_upper() == nombre_normalizado:
			jugadores[i]["avatar"] = nuevo_avatar
			guardar_datos()
			return true
	return false

func actualizar_conexion_jugador(nombre: String, estado: bool) -> bool:
	var nombre_normalizado = nombre.strip_edges().to_upper()
	
	var jugadores = datos_actuales.get("jugadores", [])
	for i in range(jugadores.size()):
		if jugadores[i].get("nombre", "").to_upper() == nombre_normalizado:
			jugadores[i]["conectado"] = estado
			guardar_datos()
			return true
	return false

func actualizar_ip_host(nueva_ip: String) -> void:
	datos_actuales["ip_host"] = nueva_ip
	guardar_datos()
