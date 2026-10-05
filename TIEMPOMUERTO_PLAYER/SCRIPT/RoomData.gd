extends Node

const RUTA_HABITACIONES = "res://DATA/HABITACIONES.JSON"

var datos_habitaciones: Dictionary = {}
var config_general: Dictionary = {}
var habitaciones: Dictionary = {}

# Habitaciones colocadas
var habitaciones_colocadas: Array = []

# Conexiones entre habitaciones
var conexiones: Dictionary = {}

# ✅ Estado guardado de cada habitación visitada
# {
#     "Room15": {
#         "puertas": {
#             "arriba": {"estado": "cerrada"},
#             "izquierda": {"estado": "abierta"},
#             "abajo": {"estado": "sin_puerta"},
#             "derecha": {"estado": "cerrada"}
#         }
#     }
# }
var estado_habitaciones: Dictionary = {}

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
	
	print("✅ HABITACIONES.JSON cargado")
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
# HABITACIONES COLOCADAS
# ============================================
func habitacion_ya_colocada(nombre: String) -> bool:
	return nombre in habitaciones_colocadas

func agregar_habitacion_colocada(nombre: String):
	if not habitacion_ya_colocada(nombre):
		habitaciones_colocadas.append(nombre)
		print("📌 Habitación agregada: " + nombre)
		print("   Total colocadas: " + str(habitaciones_colocadas.size()))

func get_habitaciones_colocadas() -> Array:
	return habitaciones_colocadas

# ============================================
# CONEXIONES ENTRE HABITACIONES
# ============================================
func registrar_conexion(hab_origen: String, direccion: String, hab_destino: String):
	if not hab_origen in conexiones:
		conexiones[hab_origen] = {}
	if not hab_destino in conexiones:
		conexiones[hab_destino] = {}
	
	conexiones[hab_origen][direccion] = hab_destino
	
	var direccion_opuesta = obtener_direccion_opuesta(direccion)
	conexiones[hab_destino][direccion_opuesta] = hab_origen
	
	print("🔗 Conexión: " + hab_origen + "[" + direccion + "] ↔ " + hab_destino)

func get_habitacion_conectada(habitacion: String, direccion: String) -> String:
	if not habitacion in conexiones:
		return ""
	if not direccion in conexiones[habitacion]:
		return ""
	return conexiones[habitacion][direccion]

func hay_conexion(habitacion: String, direccion: String) -> bool:
	return get_habitacion_conectada(habitacion, direccion) != ""

func obtener_direccion_opuesta(direccion: String) -> String:
	match direccion.to_lower():
		"arriba":    return "abajo"
		"abajo":     return "arriba"
		"izquierda": return "derecha"
		"derecha":   return "izquierda"
	return ""

func imprimir_conexiones():
	print("=== CONEXIONES ===")
	for habitacion in conexiones:
		print(habitacion + ": " + str(conexiones[habitacion]))

# ============================================
# ✅ ESTADO DE HABITACIONES (PUERTAS GUARDADAS)
# ============================================

# Verificar si ya se generó el estado de una habitación
func habitacion_ya_generada(nombre: String) -> bool:
	return nombre in estado_habitaciones

# Guardar el estado completo de una habitación
func guardar_estado_habitacion(nombre: String, estado: Dictionary):
	estado_habitaciones[nombre] = estado
	print("💾 Estado guardado de " + nombre)
	print("   Puertas: " + str(estado.get("puertas", {}).keys()))

# Obtener el estado guardado
func get_estado_habitacion(nombre: String) -> Dictionary:
	if nombre in estado_habitaciones:      # ← ✅ CORREGIDO
		return estado_habitaciones[nombre]
	return {}

# ============================================
# VALIDAR CÓDIGO
# ============================================
func validar_codigo_habitacion(codigo: String, habitacion_actual: String) -> Dictionary:
	var resultado = {"valido": false, "error": "", "nombre_habitacion": ""}
	
	var codigo_limpio = codigo.strip_edges()
	
	if codigo_limpio == "":
		resultado["error"] = "Debes ingresar un código"
		return resultado
	
	if not codigo_limpio.is_valid_int():
		resultado["error"] = "El código debe ser un número"
		return resultado
	
	var numero = int(codigo_limpio)
	
	if numero < 0 or numero > 34:
		resultado["error"] = "Código inválido (00-34)"
		return resultado
	
	var nombre_habitacion = "Room%02d" % numero
	
	if nombre_habitacion == habitacion_actual:
		resultado["error"] = "Ya estás en esa habitación"
		return resultado
	
	if habitacion_ya_colocada(nombre_habitacion):
		resultado["error"] = "Esa habitación ya está en el tablero"
		return resultado
	
	var ruta = "res://ASSET/Rooms/" + nombre_habitacion + ".png"
	if not ResourceLoader.exists(ruta):
		resultado["error"] = "No existe la habitación " + nombre_habitacion
		return resultado
	
	resultado["valido"] = true
	resultado["nombre_habitacion"] = nombre_habitacion
	print("✅ Código válido: " + nombre_habitacion)
	
	return resultado

func existe_habitacion(nombre: String) -> bool:
	return nombre in habitaciones

func imprimir_info():
	print("=== INFO ===")
	print("Colocadas: " + str(habitaciones_colocadas))
	imprimir_conexiones()
	# ============================================
# POSICIONES DE JUGADORES
# ============================================
var posiciones_jugadores: Dictionary = {}

func inicializar_posiciones_jugadores(jugadores: Array, habitacion_inicial: String):
	for jugador in jugadores:
		var nombre = jugador.get("nombre", "")
		if nombre != "":
			posiciones_jugadores[nombre] = habitacion_inicial
			print("👤 " + nombre + " → " + habitacion_inicial)

func get_habitacion_jugador(nombre: String) -> String:
	if nombre in posiciones_jugadores:
		return posiciones_jugadores[nombre]
	return ""

func actualizar_posicion_jugador(nombre: String, nueva_habitacion: String):
	posiciones_jugadores[nombre] = nueva_habitacion
	print("👤 " + nombre + " se movió a " + nueva_habitacion)

func get_jugadores_en_habitacion(nombre_habitacion: String) -> Array:
	var jugadores_aqui = []
	for nombre in posiciones_jugadores:
		if posiciones_jugadores[nombre] == nombre_habitacion:
			jugadores_aqui.append(nombre)
	return jugadores_aqui

func imprimir_posiciones_jugadores():
	print("=== POSICIONES ===")
	for nombre in posiciones_jugadores:
		print("  " + nombre + " → " + posiciones_jugadores[nombre])
