extends Node

const RUTA_HABITACIONES = "res://DATA/HABITACIONES.JSON"

var datos_habitaciones: Dictionary = {}
var config_general: Dictionary = {}
var habitaciones: Dictionary = {}

var habitaciones_colocadas: Array = []
var conexiones: Dictionary = {}
var estado_habitaciones: Dictionary = {}
var posiciones_jugadores: Dictionary = {}

var malla_habitaciones: Dictionary = {}
const LIMITE_MALLA = 5

func _ready():
	cargar_datos()
	print("=== RoomData: Inicializado ===")

func cargar_datos() -> bool:
	if not FileAccess.file_exists(RUTA_HABITACIONES):
		return false
	var archivo = FileAccess.open(RUTA_HABITACIONES, FileAccess.READ)
	if not archivo:
		return false
	var contenido = archivo.get_as_text()
	archivo.close()
	var datos = JSON.parse_string(contenido)
	if not datos:
		return false
	datos_habitaciones = datos
	config_general = datos.get("configuracion_general", {})
	habitaciones = datos.get("habitaciones", {})
	return true

func inicializar_room00_por_defecto():
	if habitacion_ya_generada("Room00"):
		return
	var puertas_iniciales = get_puertas_iniciales("Room00")
	if puertas_iniciales.size() == 0:
		puertas_iniciales = ["arriba", "abajo", "izquierda", "derecha"]
	var estado = {"puertas": {}}
	for direccion in puertas_iniciales:
		estado["puertas"][direccion] = {"estado": "cerrada"}
	guardar_estado_habitacion("Room00", estado)
	agregar_habitacion_colocada("Room00")
	agregar_a_malla("Room00", 0, 0)
	print("✅ Room00 inicializada en coord (0,0)")

# ============================================
# MALLA
# ============================================
func coord_a_string(x: int, y: int) -> String:
	return str(x) + "," + str(y)

func string_a_coord(s: String) -> Vector2i:
	var partes = s.split(",")
	if partes.size() != 2:
		return Vector2i(-999, -999)
	return Vector2i(int(partes[0]), int(partes[1]))

func agregar_a_malla(nombre_habitacion: String, x: int, y: int):
	malla_habitaciones[coord_a_string(x, y)] = nombre_habitacion

func get_habitacion_en_coord(x: int, y: int) -> String:
	var key = coord_a_string(x, y)
	if key in malla_habitaciones:
		return malla_habitaciones[key]
	return ""

func get_coord_habitacion(nombre: String) -> Vector2i:
	for key in malla_habitaciones:
		if malla_habitaciones[key] == nombre:
			return string_a_coord(key)
	return Vector2i(-999, -999)

func es_coord_valida(x: int, y: int) -> bool:
	return x >= -LIMITE_MALLA and x <= LIMITE_MALLA and y >= -LIMITE_MALLA and y <= LIMITE_MALLA

func calcular_coord_vecina(x: int, y: int, direccion: String) -> Vector2i:
	match direccion.to_lower():
		"arriba":    return Vector2i(x, y - 1)
		"abajo":     return Vector2i(x, y + 1)
		"izquierda": return Vector2i(x - 1, y)
		"derecha":   return Vector2i(x + 1, y)
	return Vector2i(x, y)

# ============================================
# CONFIG
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

func get_habitacion(nombre: String) -> Dictionary:
	if nombre in habitaciones:
		return habitaciones[nombre]
	return {}

func get_puertas_iniciales(nombre_habitacion: String) -> Array:
	var hab = get_habitacion(nombre_habitacion)
	return hab.get("puertas_iniciales", [])

func existe_imagen_habitacion(nombre: String) -> bool:
	var ruta = "res://ASSET/Rooms/" + nombre + ".png"
	return ResourceLoader.exists(ruta)

# ============================================
# HABITACIONES COLOCADAS
# ============================================
func habitacion_ya_colocada(nombre: String) -> bool:
	return nombre in habitaciones_colocadas

func agregar_habitacion_colocada(nombre: String):
	if not habitacion_ya_colocada(nombre):
		habitaciones_colocadas.append(nombre)

func get_habitaciones_colocadas() -> Array:
	return habitaciones_colocadas

# ============================================
# CONEXIONES
# ============================================
func registrar_conexion(hab_origen: String, direccion: String, hab_destino: String):
	if not hab_origen in conexiones:
		conexiones[hab_origen] = {}
	if not hab_destino in conexiones:
		conexiones[hab_destino] = {}
	
	conexiones[hab_origen][direccion] = hab_destino
	var direccion_opuesta = obtener_direccion_opuesta(direccion)
	conexiones[hab_destino][direccion_opuesta] = hab_origen

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

# ============================================
# ESTADO DE HABITACIONES
# ============================================
func habitacion_ya_generada(nombre: String) -> bool:
	return nombre in estado_habitaciones

func guardar_estado_habitacion(nombre: String, estado: Dictionary):
	estado_habitaciones[nombre] = estado

func guardar_estado_habitacion_puerta(nombre: String, direccion: String, nuevo_estado: String):
	if not nombre in estado_habitaciones:
		estado_habitaciones[nombre] = {"puertas": {}}
	if not "puertas" in estado_habitaciones[nombre]:
		estado_habitaciones[nombre]["puertas"] = {}
	estado_habitaciones[nombre]["puertas"][direccion] = {"estado": nuevo_estado}

func get_estado_habitacion(nombre: String) -> Dictionary:
	if nombre in estado_habitaciones:
		return estado_habitaciones[nombre]
	return {}

# ============================================
# VALIDACIÓN DE CÓDIGO
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
	if not existe_imagen_habitacion(nombre_habitacion):
		resultado["error"] = "No existe la habitación " + nombre_habitacion
		return resultado
	
	resultado["valido"] = true
	resultado["nombre_habitacion"] = nombre_habitacion
	return resultado

# ============================================
# POSICIONES DE JUGADORES
# ============================================
func inicializar_posiciones_jugadores(jugadores: Array, habitacion_inicial: String):
	for jugador in jugadores:
		var nombre = jugador.get("nombre", "")
		if nombre != "":
			posiciones_jugadores[nombre] = habitacion_inicial

func inicializar_posicion_jugador(nombre: String, habitacion_inicial: String):
	posiciones_jugadores[nombre] = habitacion_inicial

func get_habitacion_jugador(nombre: String) -> String:
	if nombre in posiciones_jugadores:
		return posiciones_jugadores[nombre]
	return ""

func actualizar_posicion_jugador(nombre: String, nueva_habitacion: String):
	posiciones_jugadores[nombre] = nueva_habitacion

func get_jugadores_en_habitacion(nombre_habitacion: String) -> Array:
	var jugadores_aqui = []
	for nombre in posiciones_jugadores:
		if posiciones_jugadores[nombre] == nombre_habitacion:
			jugadores_aqui.append(nombre)
	return jugadores_aqui

# ============================================
# ✅ GENERACIÓN DE PUERTAS (FIX: la entrada no se sobreescribe)
# ============================================
func generar_puertas_para_habitacion(nombre_habitacion: String, coord: Vector2i, direccion_entrada: String) -> Dictionary:
	var direcciones = ["arriba", "abajo", "izquierda", "derecha"]
	var estado_puertas = {}
	
	var distancia = max(abs(coord.x), abs(coord.y))
	var probabilidad = 1.0
	if distancia >= 2:
		probabilidad = max(0.40, 1.0 - ((distancia - 1) * 0.15))
	
	print("🎲 Generando puertas para " + nombre_habitacion + " en (" + str(coord.x) + "," + str(coord.y) + ") dist=" + str(distancia) + " prob=" + str(probabilidad))
	
	# Primera pasada: decidir cada puerta
	for direccion in direcciones:
		# ✅ La puerta de entrada SIEMPRE abierta y no se toca después
		if direccion == direccion_entrada:
			estado_puertas[direccion] = "abierta"
			continue
		
		var coord_vecino = calcular_coord_vecina(coord.x, coord.y, direccion)
		
		if not es_coord_valida(coord_vecino.x, coord_vecino.y):
			estado_puertas[direccion] = "sin_puerta"
			continue
		
		var habitacion_vecina = get_habitacion_en_coord(coord_vecino.x, coord_vecino.y)
		
		if habitacion_vecina != "":
			var direccion_opuesta = obtener_direccion_opuesta(direccion)
			var estado_vecino = get_estado_habitacion(habitacion_vecina)
			var puerta_vecina_estado = ""
			
			if not estado_vecino.is_empty():
				var puertas_vecino = estado_vecino.get("puertas", {})
				if direccion_opuesta in puertas_vecino:
					puerta_vecina_estado = puertas_vecino[direccion_opuesta].get("estado", "")
			
			if puerta_vecina_estado == "sin_puerta" or puerta_vecina_estado == "":
				print("   🚫 Vecino " + habitacion_vecina + " no tiene puerta en " + direccion_opuesta + ". Forzando sin_puerta.")
				estado_puertas[direccion] = "sin_puerta"
			else:
				estado_puertas[direccion] = "cerrada"
			continue
		
		var aleatorio = randf()
		if aleatorio < probabilidad:
			estado_puertas[direccion] = "cerrada"
		else:
			estado_puertas[direccion] = "sin_puerta"
	
	# ✅ Segunda pasada: garantizar mínimo de puertas (SIN contar ni tocar la entrada)
	var minimo_puertas = 2 if distancia <= 3 else 1
	var puertas_actuales = 0
	
	for d in direcciones:
		if d == direccion_entrada:
			continue  # No contar la entrada
		if estado_puertas[d] != "sin_puerta":
			puertas_actuales += 1
	
	if puertas_actuales < minimo_puertas:
		var faltan = minimo_puertas - puertas_actuales
		var candidatos = []
		
		for d in direcciones:
			if d == direccion_entrada:
				continue  # No forzar la entrada
			if estado_puertas[d] == "sin_puerta":
				var coord_v = calcular_coord_vecina(coord.x, coord.y, d)
				if es_coord_valida(coord_v.x, coord_v.y):
					var vecino = get_habitacion_en_coord(coord_v.x, coord_v.y)
					if vecino == "":
						candidatos.append(d)
					else:
						var dir_op = obtener_direccion_opuesta(d)
						var est_v = get_estado_habitacion(vecino)
						if not est_v.is_empty() and "puertas" in est_v and dir_op in est_v["puertas"]:
							if est_v["puertas"][dir_op].get("estado", "") != "sin_puerta":
								candidatos.append(d)
		
		candidatos.shuffle()
		for i in range(min(faltan, candidatos.size())):
			estado_puertas[candidatos[i]] = "cerrada"
	
	var resumen = ""
	for d in direcciones:
		resumen += d + "=" + estado_puertas[d] + " "
	print("   ✅ Resultado: " + resumen)
	
	return estado_puertas

func forzar_puerta_opuesta_en_vecino(nombre_vecino: String, direccion_hacia_esta: String):
	var estado_vecino = get_estado_habitacion(nombre_vecino)
	if estado_vecino.is_empty():
		estado_vecino = {"puertas": {}}
	if not "puertas" in estado_vecino:
		estado_vecino["puertas"] = {}
	
	if not direccion_hacia_esta in estado_vecino["puertas"]:
		estado_vecino["puertas"][direccion_hacia_esta] = {"estado": "cerrada"}
	elif estado_vecino["puertas"][direccion_hacia_esta].get("estado", "") == "sin_puerta":
		estado_vecino["puertas"][direccion_hacia_esta] = {"estado": "cerrada"}
	
	guardar_estado_habitacion(nombre_vecino, estado_vecino)
