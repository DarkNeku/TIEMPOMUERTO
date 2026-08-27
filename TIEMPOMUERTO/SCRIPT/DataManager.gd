extends Node

const RUTA_DATOS = "user://datos_prueba.json"
var datos_actuales: Dictionary = {}

func _ready():
	cargar_datos()

func cargar_datos() -> bool:
	if FileAccess.file_exists(RUTA_DATOS):
		var archivo = FileAccess.open(RUTA_DATOS, FileAccess.READ)
		if archivo:
			var contenido = archivo.get_as_text()
			archivo.close()
			var datos = JSON.parse_string(contenido)
			if datos:
				datos_actuales = datos
				print("✅ Datos cargados desde user://")
				return true
	
	print("⚠️ No hay datos en user://, creando por defecto")
	crear_datos_por_defecto()
	guardar_datos()
	return true

func guardar_datos() -> bool:
	var archivo = FileAccess.open(RUTA_DATOS, FileAccess.WRITE)
	if archivo:
		archivo.store_string(JSON.stringify(datos_actuales, "\t"))
		archivo.close()
		print("✅ Datos guardados en user://")
		return true
	return false

func crear_datos_por_defecto():
	datos_actuales = {
		"sala": "SALA 1",
		"ip_host": "192.168.1.102",
		"puerto": 12345,
		"jugadores": [
			{"nombre": "JOSE", "color": "", "avatar": "", "conectado": false},
			{"nombre": "JENNY", "color": "", "avatar": "", "conectado": false},
			{"nombre": "ALE", "color": "", "avatar": "", "conectado": false},
			{"nombre": "FRAN", "color": "", "avatar": "", "conectado": false},
			{"nombre": "CRIS", "color": "", "avatar": "", "conectado": false}
		]
	}

func get_sala() -> String:
	return datos_actuales.get("sala", "SALA 1")

func get_ip() -> String:
	return datos_actuales.get("ip_host", "192.168.1.102")

func get_puerto() -> int:
	return datos_actuales.get("puerto", 12345)

func get_jugadores() -> Array:
	return datos_actuales.get("jugadores", [])

# ============================================
# FUNCIONES PARA ACTUALIZAR DATOS
# ============================================

func actualizar_color_jugador(nombre: String, nuevo_color: String) -> bool:
	for i in range(datos_actuales.jugadores.size()):
		if datos_actuales.jugadores[i].nombre == nombre:
			datos_actuales.jugadores[i].color = nuevo_color
			guardar_datos()
			print("✅ Color actualizado para " + nombre + ": " + nuevo_color)
			return true
	print("❌ No se encontró al jugador: " + nombre)
	return false

func actualizar_avatar_jugador(nombre: String, nuevo_avatar: String) -> bool:
	for i in range(datos_actuales.jugadores.size()):
		if datos_actuales.jugadores[i].nombre == nombre:
			datos_actuales.jugadores[i].avatar = nuevo_avatar
			guardar_datos()
			print("✅ Avatar actualizado para " + nombre + ": " + nuevo_avatar)
			return true
	return false

func actualizar_conexion_jugador(nombre: String, estado: bool) -> bool:
	for i in range(datos_actuales.jugadores.size()):
		if datos_actuales.jugadores[i].nombre == nombre:
			datos_actuales.jugadores[i].conectado = estado
			guardar_datos()
			print("✅ Conexión actualizada para " + nombre + ": " + str(estado))
			return true
	return false
