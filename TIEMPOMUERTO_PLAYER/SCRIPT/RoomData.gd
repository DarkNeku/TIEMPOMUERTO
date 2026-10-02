extends Node

const RUTA_HABITACIONES = "res://DATA/habitaciones.json"

var datos_habitaciones: Dictionary = {}
var config_general: Dictionary = {}
var habitaciones: Dictionary = {}

func _ready():
	cargar_datos()
	print("=== RoomData: Inicializado ===")

# ============================================
# CARGAR DATOS DEL JSON
# ============================================
func cargar_datos() -> bool:
	if not FileAccess.file_exists(RUTA_HABITACIONES):
		print("❌ No se encontró: " + RUTA_HABITACIONES)
		return false
	
	var archivo = FileAccess.open(RUTA_HABITACIONES, FileAccess.READ)
	if not archivo:
		print("❌ No se pudo abrir: " + RUTA_HABITACIONES)
		return false
	
	var contenido = archivo.get_as_text()
	archivo.close()
	
	var datos = JSON.parse_string(contenido)
	if not datos:
		print("❌ Error al parsear el JSON")
		return false
	
	datos_habitaciones = datos
	config_general = datos.get("configuracion_general", {})
	habitaciones = datos.get("habitaciones", {})
	
	print("✅ habitaciones.json cargado")
	print("   Configuración general: " + str(config_general.size()) + " entradas")
	print("   Habitaciones: " + str(habitaciones.size()))
	
	return true

# ============================================
# CONFIGURACIÓN GENERAL
# ============================================
func get_tamaño_habitacion() -> Vector2:
	var tamaño = config_general.get("tamaño_habitacion", {"ancho": 512, "alto": 512})
	return Vector2(tamaño.get("ancho", 512), tamaño.get("alto", 512))

func get_posiciones_puertas() -> Dictionary:
	return config_general.get("posiciones_puertas", {})

func get_posicion_puerta(direccion: String) -> Vector2:
	var posiciones = get_posiciones_puertas()
	if direccion in posiciones:
		var pos = posiciones[direccion]
		return Vector2(pos.get("x", 0), pos.get("y", 0))
	return Vector2.ZERO

# ============================================
# HABITACIONES
# ============================================
func get_habitacion(nombre: String) -> Dictionary:
	if nombre in habitaciones:
		return habitaciones[nombre]
	return {}

func get_nombre_habitacion(nombre: String) -> String:
	var hab = get_habitacion(nombre)
	return hab.get("nombre", nombre)

func get_puertas_iniciales(nombre_habitacion: String) -> Array:
	var hab = get_habitacion(nombre_habitacion)
	return hab.get("puertas_iniciales", [])

func get_puntos_interes(nombre_habitacion: String) -> Array:
	var hab = get_habitacion(nombre_habitacion)
	return hab.get("puntos_interes", [])

# ============================================
# UTILIDADES
# ============================================
func existe_habitacion(nombre: String) -> bool:
	return nombre in habitaciones

func imprimir_info():
	print("=== INFO DE HABITACIONES ===")
	print("Tamaño: " + str(get_tamaño_habitacion()))
	print("Posiciones de puertas:")
	var pos = get_posiciones_puertas()
	for dir in pos:
		print("  • " + dir + ": " + str(pos[dir]))
	print("Habitaciones: " + str(habitaciones.keys()))
