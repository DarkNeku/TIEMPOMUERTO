extends Node

const DataManagerScript = preload("res://SCRIPT/DataManager.gd")

var data_manager: Node = null
var jugadores: Array = []
var nombre_sala: String = ""
var ip_host: String = ""
var puerto: int = 12345
var cant_jugadores: int = 2
var tiempo_juego: int = 60
var datos_cargados: bool = false

# ✅ NOMBRE DEL JUGADOR DE ESTE CELULAR
var mi_nombre: String = ""

func _ready():
	print("=== GLOBAL: Iniciando ===")
	
	data_manager = DataManagerScript.new()
	add_child(data_manager)
	
	await get_tree().create_timer(0.2).timeout
	
	cargar_desde_data_manager()
	
	datos_cargados = true
	
	print("=== GLOBAL: Datos cargados ===")
	print("Sala: " + nombre_sala)
	print("Jugadores máx: " + str(cant_jugadores))
	print("Tiempo: " + str(tiempo_juego) + " min")
	print("Jugadores en JSON: " + str(jugadores.size()))

func cargar_desde_data_manager():
	if not data_manager:
		return
	
	nombre_sala = data_manager.get_sala()
	ip_host = data_manager.get_ip()
	puerto = data_manager.get_puerto()
	cant_jugadores = data_manager.get_cant_jugadores()
	tiempo_juego = data_manager.get_tiempo_juego()
	jugadores = data_manager.get_jugadores()

# ============================================
# ✅ MI NOMBRE
# ============================================
func set_mi_nombre(nombre: String):
	mi_nombre = nombre.strip_edges().to_upper()
	print("👤 Mi nombre guardado: " + mi_nombre)

func get_mi_nombre() -> String:
	return mi_nombre

# ============================================
# RECARGAR JUGADORES
# ============================================
func recargar_jugadores():
	if data_manager:
		jugadores = data_manager.get_jugadores()
		print("🔄 Jugadores recargados: " + str(jugadores.size()))

# ============================================
# NUEVA PARTIDA
# ============================================
func nueva_partida(nombre_sala_param: String = "", cant: int = 2, tiempo: int = 60):
	if data_manager:
		data_manager.nueva_partida(nombre_sala_param, cant, tiempo)
		cargar_desde_data_manager()

# ============================================
# AGREGAR JUGADOR
# ============================================
func agregar_jugador(nombre: String):
	if data_manager:
		var nombre_normalizado = nombre.strip_edges().to_upper()
		data_manager.agregar_jugador_partida(nombre_normalizado)
		jugadores = data_manager.get_jugadores()

# ============================================
# GETTERS
# ============================================
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

func get_cant_jugadores() -> int:
	return cant_jugadores

func get_tiempo_juego() -> int:
	return tiempo_juego

# ============================================
# ACTUALIZAR
# ============================================
func actualizar_color_jugador(nombre: String, color: String):
	if data_manager:
		var nombre_normalizado = nombre.strip_edges().to_upper()
		data_manager.actualizar_color_jugador(nombre_normalizado, color)
		jugadores = data_manager.get_jugadores()

func actualizar_avatar_jugador(nombre: String, avatar: String):
	if data_manager:
		var nombre_normalizado = nombre.strip_edges().to_upper()
		data_manager.actualizar_avatar_jugador(nombre_normalizado, avatar)
		jugadores = data_manager.get_jugadores()

func actualizar_conexion_jugador(nombre: String, estado: bool):
	if data_manager:
		var nombre_normalizado = nombre.strip_edges().to_upper()
		data_manager.actualizar_conexion_jugador(nombre_normalizado, estado)
		jugadores = data_manager.get_jugadores()

func guardar_datos_sala(nombre_sala_param: String, cant: int, tiempo: int):
	if data_manager:
		data_manager.nueva_partida(nombre_sala_param, cant, tiempo)
		cargar_desde_data_manager()
