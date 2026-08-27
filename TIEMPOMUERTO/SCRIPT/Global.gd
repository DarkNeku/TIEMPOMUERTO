extends Node

# PRECARGAR el script DataManager
const DataManager = preload("res://SCRIPT/DataManager.gd")

var data_manager: DataManager = null
var jugadores: Array = []
var nombre_sala: String = ""
var ip_host: String = ""
var puerto: int = 12345

func _ready():
	# Crear instancia del DataManager
	data_manager = DataManager.new()
	add_child(data_manager)
	
	# Esperar a que cargue
	await get_tree().create_timer(0.1).timeout
	
	# Cargar datos
	nombre_sala = data_manager.get_sala()
	ip_host = data_manager.get_ip()
	puerto = data_manager.get_puerto()
	jugadores = data_manager.get_jugadores()
	
	print("✅ Datos cargados en Global")
	print("Sala: " + nombre_sala)
	print("IP: " + ip_host)
	print("Jugadores: " + str(jugadores.size()))
