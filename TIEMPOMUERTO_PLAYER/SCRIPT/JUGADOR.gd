extends Control

@onready var mundo = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM/MUNDO
@onready var imagen_room = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM/MUNDO/IMAGEN_ROOM
@onready var contenedor_room = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM
@onready var capa_avatares = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM/MUNDO/CAPA_AVATARES

const AVATAR_SCENE = preload("res://SPRITE/AVATAR.tscn")

# ============================================
# CONFIGURACIÓN
# ============================================
var factor_alejamiento: float = 0.9
var zoom_minimo: float = 0.9
var zoom_maximo: float = 1.8
var velocidad_zoom: float = 0.05
var sensibilidad_movimiento: float = 0.5
var margen_extra: float = 0.0

# ============================================
# AVATARES
# ============================================
var escala_avatar: float = 0.15
var tamaño_avatar_base: float = 64.0
var radio_circulo: float = 60.0
var radio_circulo_con_obstaculos: float = 90.0
var distancia_minima_obstaculo: float = 50.0

# ✅ ANIMACIONES
var tiempo_entre_animaciones: float = 3.0  # ← Cada 3 segundos animar

# ============================================
# VARIABLES INTERNAS
# ============================================
var zoom_actual: float = 1.0
var posicion_inicial_mundo: Vector2 = Vector2.ZERO
var offset_movimiento: Vector2 = Vector2.ZERO
var limite_movimiento_actual: Vector2 = Vector2.ZERO

var toques_activos: Dictionary = {}
var distancia_inicial: float = 0.0
var zoom_inicial: float = 1.0
var arrastrando: bool = false
var posicion_inicial_mouse: Vector2 = Vector2.ZERO
var offset_inicial_arrastre: Vector2 = Vector2.ZERO

func _ready():
	print("=== JUGADOR: Iniciando ===")
	
	cargar_habitacion("Room00")
	await get_tree().process_frame
	await get_tree().process_frame
	cargar_avatares()
	
	set_process_input(true)
	print("=== JUGADOR: Listo ===")

# ============================================
# CARGAR AVATARES
# ============================================
func cargar_avatares():
	print("")
	print("╔═══════════════════════════════════════╗")
	print("║     CARGANDO AVATARES                 ║")
	print("╚═══════════════════════════════════════╝")
	
	for child in capa_avatares.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var jugadores = Global.get_jugadores()
	
	if jugadores.size() == 0:
		print("⚠️ No hay jugadores")
		return
	
	print("👥 Jugadores: " + str(jugadores.size()))
	for j in jugadores:
		print("   • " + j.get("nombre", "?") + " → '" + str(j.get("color", "")) + "'")
	
	var tamaño_habitacion = imagen_room.texture.get_size() if imagen_room.texture else Vector2(512, 512)
	var centro_habitacion = tamaño_habitacion / 2
	
	var obstaculos = obtener_obstaculos_habitacion("Room00")
	print("📦 Obstáculos: " + str(obstaculos.size()))
	
	var posiciones = calcular_posiciones_avatares(jugadores.size(), centro_habitacion, obstaculos)
	print("📍 Posiciones calculadas: " + str(posiciones.size()))
	
	var indice = 0
	for jugador in jugadores:
		var nombre = jugador.get("nombre", "???")
		var color = jugador.get("color", "")
		
		var avatar = AVATAR_SCENE.instantiate()
		avatar.name = "AVATAR_" + nombre
		avatar.scale = Vector2(escala_avatar, escala_avatar)
		
		if indice < posiciones.size():
			avatar.position = posiciones[indice]
		
		capa_avatares.add_child(avatar)
		
		await get_tree().process_frame
		configurar_animacion_avatar(avatar, color)
		
		indice += 1
	
	print("")
	print("✅ Avatares cargados")

# ============================================
# OBTENER OBSTÁCULOS DE LA HABITACIÓN
# ============================================
func obtener_obstaculos_habitacion(nombre_habitacion: String) -> Array:
	var obstaculos = []
	
	# TODO: Cargar desde JSON de habitaciones
	if nombre_habitacion == "Room15":
		# obstaculos.append({"id": "cama", "x": 150.0, "y": 100.0, "radio": 50.0})
		pass
	
	return obstaculos

# ============================================
# CALCULAR POSICIONES DE AVATARES
# ============================================
func calcular_posiciones_avatares(cantidad: int, centro: Vector2, obstaculos: Array) -> Array:
	var posiciones = []
	
	# CASO 1: Un solo avatar sin obstáculos → Centro
	if cantidad == 1 and obstaculos.size() == 0:
		posiciones.append(centro)
		print("  📍 Caso: 1 avatar, sin obstáculos → Centro")
		return posiciones
	
	# CASO 2: Varios avatares → Círculo
	var radio = radio_circulo
	if obstaculos.size() > 0:
		radio = radio_circulo_con_obstaculos
	
	var angulo_inicial = -PI / 2
	var angulo_entre = (2 * PI) / cantidad if cantidad > 1 else 0
	
	print("  📍 Caso: " + str(cantidad) + " avatares, radio " + str(radio))
	
	for i in range(cantidad):
		var angulo = angulo_inicial + (angulo_entre * i)
		var pos = centro + Vector2(cos(angulo), sin(angulo)) * radio
		
		var intentos = 0
		while hay_obstaculo_cerca(pos, obstaculos) and intentos < 8:
			angulo += PI / 4
			pos = centro + Vector2(cos(angulo), sin(angulo)) * radio
			intentos += 1
		
		posiciones.append(pos)
	
	return posiciones

# ============================================
# VERIFICAR OBSTÁCULO CERCA
# ============================================
func hay_obstaculo_cerca(posicion: Vector2, obstaculos: Array) -> bool:
	for obs in obstaculos:
		var pos_obs = Vector2(obs.get("x", 0.0), obs.get("y", 0.0))
		if posicion.distance_to(pos_obs) < distancia_minima_obstaculo:
			return true
	return false

# ============================================
# CONFIGURAR ANIMACIÓN DEL AVATAR
# ============================================
func configurar_animacion_avatar(avatar: Node, color: String):
	var animated_sprite = avatar.find_child("AVATAR_ANIMACION", true, false)
	
	if not animated_sprite:
		print("  ❌ No se encontró AVATAR_ANIMACION en " + avatar.name)
		return
	
	var nombre_animacion = "AVATAR_" + color.to_upper().strip_edges()
	
	if animated_sprite.sprite_frames.has_animation(nombre_animacion):
		# ✅ Establecer la animación
		animated_sprite.animation = nombre_animacion
		
		# ✅ Iniciar en el frame 0 (quieto)
		animated_sprite.frame = 0
		animated_sprite.stop()
		
		print("  ✅ " + avatar.name + " → " + nombre_animacion)
		
		# ✅ Iniciar el ciclo de animación
		iniciar_ciclo_animacion(animated_sprite)
	else:
		print("  ❌ No existe: " + nombre_animacion)

# ============================================
# CICLO DE ANIMACIÓN
# ============================================
func iniciar_ciclo_animacion(animated_sprite: AnimatedSprite2D):
	# Espera inicial aleatoria (para que no todos animen al mismo tiempo)
	var espera_inicial = randf_range(0.5, tiempo_entre_animaciones)
	await get_tree().create_timer(espera_inicial).timeout
	
	while is_instance_valid(animated_sprite):
		# Reproducir la animación
		animated_sprite.play()
		
		# Esperar a que termine
		await animated_sprite.animation_finished
		
		# Detener en el frame 0 (quieto)
		animated_sprite.stop()
		animated_sprite.frame = 0
		
		# Esperar X segundos antes de la siguiente animación
		await get_tree().create_timer(tiempo_entre_animaciones).timeout

# ============================================
# CARGAR HABITACIÓN
# ============================================
func cargar_habitacion(nombre_habitacion: String):
	var ruta = "res://ASSET/Rooms/" + nombre_habitacion + ".png"
	var textura = load(ruta)
	
	if textura:
		imagen_room.texture = textura
		imagen_room.size = textura.get_size()
		await get_tree().process_frame
		ajustar_imagen_inicial()
		print("✅ Habitación: " + nombre_habitacion)
	else:
		print("❌ No se encontró: " + ruta)

func ajustar_imagen_inicial():
	if not imagen_room.texture:
		return
	
	var tamaño_contenedor = contenedor_room.size
	var tamaño_imagen = imagen_room.texture.get_size()
	
	var escala_x = tamaño_contenedor.x / tamaño_imagen.x
	var escala_y = tamaño_contenedor.y / tamaño_imagen.y
	var escala_base = min(escala_x, escala_y)
	
	var escala_inicial = escala_base * factor_alejamiento
	
	zoom_actual = escala_inicial
	offset_movimiento = Vector2.ZERO
	mundo.scale = Vector2(zoom_actual, zoom_actual)
	
	centrar_imagen()

func centrar_imagen():
	if not imagen_room.texture:
		return
	
	var tamaño_contenedor = contenedor_room.size
	var tamaño_imagen = imagen_room.texture.get_size()
	
	var ancho_escalado = tamaño_imagen.x * zoom_actual
	var alto_escalado = tamaño_imagen.y * zoom_actual
	
	posicion_inicial_mundo = Vector2(
		(tamaño_contenedor.x - ancho_escalado) / 2,
		(tamaño_contenedor.y - alto_escalado) / 2
	)
	
	calcular_limite_movimiento(tamaño_contenedor, ancho_escalado, alto_escalado)
	
	offset_movimiento.x = clamp(offset_movimiento.x, -limite_movimiento_actual.x, limite_movimiento_actual.x)
	offset_movimiento.y = clamp(offset_movimiento.y, -limite_movimiento_actual.y, limite_movimiento_actual.y)
	
	mundo.position = posicion_inicial_mundo + offset_movimiento

func calcular_limite_movimiento(tamaño_contenedor: Vector2, ancho_escalado: float, alto_escalado: float):
	var exceso_x = max(0, ancho_escalado - tamaño_contenedor.x) / 2
	var exceso_y = max(0, alto_escalado - tamaño_contenedor.y) / 2
	limite_movimiento_actual = Vector2(exceso_x + margen_extra, exceso_y + margen_extra)

# ============================================
# INPUT (zoom + arrastre)
# ============================================
func _input(event: InputEvent):
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			aplicar_zoom(zoom_actual + velocidad_zoom)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			aplicar_zoom(zoom_actual - velocidad_zoom)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			if event.pressed:
				arrastrando = true
				posicion_inicial_mouse = event.position
				offset_inicial_arrastre = offset_movimiento
			else:
				arrastrando = false
	
	if event is InputEventMouseMotion and arrastrando:
		var delta = event.position - posicion_inicial_mouse
		var nuevo_offset = offset_inicial_arrastre + (delta * sensibilidad_movimiento)
		aplicar_movimiento(nuevo_offset)
	
	if event is InputEventScreenTouch:
		if event.pressed:
			toques_activos[event.index] = event.position
			if toques_activos.size() == 1:
				arrastrando = true
				posicion_inicial_mouse = event.position
				offset_inicial_arrastre = offset_movimiento
			elif toques_activos.size() == 2:
				arrastrando = false
				var toques = toques_activos.values()
				distancia_inicial = toques[0].distance_to(toques[1])
				zoom_inicial = zoom_actual
		else:
			toques_activos.erase(event.index)
			if toques_activos.size() == 1:
				var toques = toques_activos.values()
				posicion_inicial_mouse = toques[0]
				offset_inicial_arrastre = offset_movimiento
				arrastrando = true
			elif toques_activos.size() < 2:
				distancia_inicial = 0.0
				if toques_activos.size() == 0:
					arrastrando = false
	
	if event is InputEventScreenDrag:
		toques_activos[event.index] = event.position
		if toques_activos.size() == 2 and distancia_inicial > 0:
			var toques = toques_activos.values()
			var distancia_actual = toques[0].distance_to(toques[1])
			var factor = distancia_actual / distancia_inicial
			aplicar_zoom(zoom_inicial * factor)
		elif toques_activos.size() == 1 and arrastrando:
			var delta = event.position - posicion_inicial_mouse
			var nuevo_offset = offset_inicial_arrastre + (delta * sensibilidad_movimiento)
			aplicar_movimiento(nuevo_offset)

func aplicar_movimiento(nuevo_offset: Vector2):
	offset_movimiento = Vector2(
		clamp(nuevo_offset.x, -limite_movimiento_actual.x, limite_movimiento_actual.x),
		clamp(nuevo_offset.y, -limite_movimiento_actual.y, limite_movimiento_actual.y)
	)
	mundo.position = posicion_inicial_mundo + offset_movimiento

func aplicar_zoom(nuevo_zoom: float):
	zoom_actual = clamp(nuevo_zoom, zoom_minimo, zoom_maximo)
	mundo.scale = Vector2(zoom_actual, zoom_actual)
	centrar_imagen()
