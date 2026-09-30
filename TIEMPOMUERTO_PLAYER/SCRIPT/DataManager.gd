extends Node

const RUTA_LECTURA = "res://DATA/datos_prueba.json"
const RUTA_ESCRITURA = "user://datos_prueba.json"

var datos_actuales: Dictionary = {}

func _ready():
	cargar_datos()

func cargar_datos() -> bool:
	print("=== DataManager: Cargando datos ===")
	
	# PRIORIDAD 1: Leer desde res://
	if FileAccess.file_exists(RUTA_LECTURA):
		var archivo = FileAccess.open(RUTA_LECTURA, FileAccess.READ)
		if archivo:
			var contenido = archivo.get_as_text()
			archivo.close()
			var datos = JSON.parse_string(contenido)
			if datos:
				datos_actuales = datos
				print("✅ Datos cargados desde res://")
				
				var jugadores = datos_actuales.get("jugadores", [])
				print("   Jugadores: " + str(jugadores.size()))
				for j in jugadores:
					print("   • " + j.get("nombre", "?") + " → color: '" + str(j.get("color", "")) + "'")
				
				guardar_datos()
				return true
	
	# PRIORIDAD 2: Leer desde user://
	if FileAccess.file_exists(RUTA_ESCRITURA):
		var archivo = FileAccess.open(RUTA_ESCRITURA, FileAccess.READ)
		if archivo:
			var contenido = archivo.get_as_text()
			archivo.close()
			var datos = JSON.parse_string(contenido)
			if datos:
				datos_actuales = datos
				print("⚠️ Datos cargados desde user://")
				return true
	
	print("❌ No se encontraron datos. Creando por defecto...")
	crear_datos_por_defecto()
	return false

func guardar_datos() -> bool:
	var archivo = FileAccess.open(RUTA_ESCRITURA, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos_actuales, "\t"))
		archivo.close()
		print("✅ Datos guardados en user://")
		return true
	return false

func crear_datos_por_defecto():
	datos_actuales = {
		"sala": "SALA 1",
		"ip_host": "",
		"puerto": 12345,
		"jugadores": [
			{"nombre": "JOSE", "color": "VERDE", "avatar": "", "conectado": false},
			{"nombre": "JENNY", "color": "AZUL", "avatar": "", "conectado": false},
			{"nombre": "ALE", "color": "AMARILLO", "avatar": "", "conectado": false},
			{"nombre": "FRAN", "color": "ROJO", "avatar": "", "conectado": false},
			{"nombre": "CRIS", "color": "GRIS", "avatar": "", "conectado": false}
		]
	}
	guardar_datos()

func get_sala() -> String:
	return datos_actuales.get("sala", "SALA 1")

func get_ip() -> String:
	return datos_actuales.get("ip_host", "")

func get_puerto() -> int:
	return datos_actuales.get("puerto", 12345)

func get_jugadores() -> Array:
	return datos_actuales.get("jugadores", [])

func get_jugador_por_nombre(nombre: String) -> Dictionary:
	for jugador in get_jugadores():
		if jugador.get("nombre", "") == nombre:
			return jugador
	return {}

func actualizar_color_jugador(nombre: String, nuevo_color: String) -> bool:
	var jugadores = datos_actuales.get("jugadores", [])
	for i in range(jugadores.size()):
		if jugadores[i].get("nombre", "") == nombre:
			jugadores[i]["color"] = nuevo_color
			guardar_datos()
			return true
	return false

func actualizar_avatar_jugador(nombre: String, nuevo_avatar: String) -> bool:
	var jugadores = datos_actuales.get("jugadores", [])
	for i in range(jugadores.size()):
		if jugadores[i].get("nombre", "") == nombre:
			jugadores[i]["avatar"] = nuevo_avatar
			guardar_datos()
			return true
	return false

func actualizar_conexion_jugador(nombre: String, estado: bool) -> bool:
	var jugadores = datos_actuales.get("jugadores", [])
	for i in range(jugadores.size()):
		if jugadores[i].get("nombre", "") == nombre:
			jugadores[i]["conectado"] = estado
			guardar_datos()
			return true
	return false

func actualizar_ip_host(nueva_ip: String) -> void:
	datos_actuales["ip_host"] = nueva_ip
	guardar_datos()
