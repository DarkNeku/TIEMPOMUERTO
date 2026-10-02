extends Node

const DataManagerScript = preload("res://SCRIPT/DataManager.gd")

var data_manager: Node = null
var jugadores: Array = []
var nombre_sala: String = ""
var ip_host: String = ""
var puerto: int = 12345
var datos_cargados: bool = false

func _ready():
	print("=== GLOBAL: Iniciando ===")
	
	data_manager = DataManagerScript.new()
	add_child(data_manager)
	
	await get_tree().create_timer(0.2).timeout
	
	nombre_sala = data_manager.get_sala()
	ip_host = data_manager.get_ip()
	puerto = data_manager.get_puerto()
	jugadores = data_manager.get_jugadores()
	
	datos_cargados = true
	
	print("=== GLOBAL: Datos cargados ===")
	print("Sala: " + nombre_sala)
	print("Jugadores: " + str(jugadores.size()))

func get_jugadores() -> Array:
	return jugadores

func get_jugador_por_nombre(nombre: String) -> Dictionary:
	if data_manager:
		return data_manager.get_jugador_por_nombre(nombre)
	return {}

func get_color_jugador(nombre: String) -> String:
	var jugador = get_jugador_por_nombre(nombre)
	if jugador.has("color"):
		return jugador.color
	return ""

func actualizar_color_jugador(nombre: String, color: String):
	if data_manager:
		data_manager.actualizar_color_jugador(nombre, color)
		jugadores = data_manager.get_jugadores()

func actualizar_avatar_jugador(nombre: String, avatar: String):
	if data_manager:
		data_manager.actualizar_avatar_jugador(nombre, avatar)
		jugadores = data_manager.get_jugadores()

func actualizar_conexion_jugador(nombre: String, estado: bool):
	if data_manager:
		data_manager.actualizar_conexion_jugador(nombre, estado)
		jugadores = data_manager.get_jugadores()
