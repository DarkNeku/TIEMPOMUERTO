extends Node

const RUTA_PARTIDA = "user://datos_partida.json"
var datos_actuales: Dictionary = {}

func _ready():
	cargar_datos()

func cargar_datos():
	if FileAccess.file_exists(RUTA_PARTIDA):
		var archivo = FileAccess.open(RUTA_PARTIDA, FileAccess.READ)
		var datos = JSON.parse_string(archivo.get_as_text())
		archivo.close()
		if datos:
			datos_actuales = datos
			return
	crear_datos_por_defecto()

func guardar_datos():
	var archivo = FileAccess.open(RUTA_PARTIDA, FileAccess.WRITE)
	archivo.store_string(JSON.stringify(datos_actuales, "\t"))
	archivo.close()

func nueva_partida(cant_jugadores: int, tiempo_juego: int):
	datos_actuales = {
		"cant_jugadores": cant_jugadores,
		"tiempo_juego": tiempo_juego,
		"jugadores": []
	}
	guardar_datos()

func crear_datos_por_defecto():
	datos_actuales = {"cant_jugadores": 2, "tiempo_juego": 60, "jugadores": []}

func get_cant_jugadores() -> int:
	return datos_actuales.get("cant_jugadores", 2)

func get_tiempo_juego() -> int:
	return datos_actuales.get("tiempo_juego", 60)

func get_jugadores() -> Array:
	return datos_actuales.get("jugadores", [])
