extends Node

var jugadores: Array = [] # Guarda los colores: [{"color": "VERDE", "avatar": "verde"}, ...]
var tiempo_juego: int = 60
var tiempo_restante: int = 60
var cant_jugadores: int = 2

func _ready():
	print("=== GLOBAL: Iniciando ===")
	# Ya no instanciamos DataManager acá, porque es un Autoload global.
	cargar_desde_data_manager()

func cargar_desde_data_manager():
	if DataManager:
		jugadores = DataManager.get_jugadores()
		tiempo_juego = DataManager.get_tiempo_juego()
		tiempo_restante = tiempo_juego
		cant_jugadores = DataManager.get_cant_jugadores()

func nueva_partida(cant: int, tiempo: int):
	cant_jugadores = cant
	tiempo_juego = tiempo
	tiempo_restante = tiempo
	jugadores = []
	if DataManager:
		DataManager.nueva_partida(cant, tiempo)

func agregar_jugador_color(color: String):
	var nuevo_jugador = {
		"color": color.to_upper(),
		"avatar": color.to_lower()
	}
	jugadores.append(nuevo_jugador)
	if DataManager:
		DataManager.datos_actuales["jugadores"] = jugadores
		DataManager.guardar_datos()

func get_jugadores() -> Array:
	return jugadores

func get_tiempo_juego() -> int:
	return tiempo_juego

func get_tiempo_restante() -> int:
	return tiempo_restante

func get_cant_jugadores() -> int:
	return cant_jugadores

func restar_tiempo(minutos: int):
	tiempo_restante -= minutos
	if tiempo_restante < 0:
		tiempo_restante = 0
	print("⏳ Tiempo restante: " + str(tiempo_restante) + " min")
