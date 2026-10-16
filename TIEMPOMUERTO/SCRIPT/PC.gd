extends Node2D

var panel_mapa
var mapa_contenido
var tablero: Node2D

var arrastrando = false
var posicion_inicial_mouse = Vector2()
var posicion_inicial_mapa = Vector2()

var zoom_actual = 1.0
var zoom_minimo = 0.15
var zoom_maximo = 3.0
var velocidad_zoom = 0.1

const MARGEN_ENTRE_HABITACIONES = 20
const LIMITE_HABITACIONES_POR_LADO = 5

var habitaciones_nodos: Dictionary = {}
var refrescando: bool = false

var escala_ficha: float = 0.05
var escala_avatar: float = 0.11
var radio_circulo: float = 60.0

var escala_puerta_cerrada = {
	"arriba":    Vector2(0.4, 0.4),
	"abajo":     Vector2(0.4, 0.4),
	"izquierda": Vector2(0.4, 0.5),
	"derecha":   Vector2(0.4, 0.5)
}

var escala_puerta_abierta = {
	"arriba":    Vector2(0.4, 0.4),
	"abajo":     Vector2(0.4, 0.4),
	"izquierda": Vector2(0.4, 0.4),
	"derecha":   Vector2(0.4, 0.4)
}

var offset_puerta_cerrada = {
	"arriba":    Vector2(0, 0),
	"abajo":     Vector2(0, 0),
	"izquierda": Vector2(0, 0),
	"derecha":   Vector2(0, 0)
}

var offset_puerta_abierta = {
	"arriba":    Vector2(0, 27),
	"abajo":     Vector2(0, -25),
	"izquierda": Vector2(25, 10),
	"derecha":   Vector2(-25, 5)
}

var offset_ficha_arriba:    Vector2 = Vector2(-8, 0)
var offset_ficha_abajo:     Vector2 = Vector2(-8, -18)
var offset_ficha_izquierda: Vector2 = Vector2(0, 0)
var offset_ficha_derecha:   Vector2 = Vector2(-15, -10)

const AVATAR_SCENE = preload("res://SPRITE/AVATAR.tscn")
const PUERTA_SCENE = preload("res://SPRITE/PUERTAS.tscn")
const FICHA_LUPA = preload("res://SPRITE/LUPA.tscn")
const FICHA_CAMINAR = preload("res://SPRITE/CAMINAR.tscn")
const FICHA_INTERACTUAR = preload("res://SPRITE/INTERACTUAR.tscn")
const FICHA_OBJETO = preload("res://SPRITE/OBJETO.tscn")

func _ready():
	print("=== PC: Iniciando ===")
	
	panel_mapa = get_node("Panel/PANEL_MAPA")
	mapa_contenido = get_node("Panel/PANEL_MAPA/MAPA_CONTENIDO")
	panel_mapa.mouse_filter = Control.MOUSE_FILTER_STOP
	
	RoomData.inicializar_room00_por_defecto()
	
	if not Network.sync_puerta_visual.is_connected(_on_sync_puerta_visual):
		Network.sync_puerta_visual.connect(_on_sync_puerta_visual)
	
	if not Network.jugadores_actualizados_signal.is_connected(_on_jugadores_actualizados):
		Network.jugadores_actualizados_signal.connect(_on_jugadores_actualizados)
	
	if not Network.habitacion_actualizada_signal.is_connected(_on_habitacion_actualizada):
		Network.habitacion_actualizada_signal.connect(_on_habitacion_actualizada)
	
	crear_tablero()
	await refrescar_tablero_completo()
	
	centrar_en_room00()

func crear_tablero():
	for child in mapa_contenido.get_children():
		child.queue_free()
	
	tablero = Node2D.new()
	tablero.name = "TABLERO"
	mapa_contenido.add_child(tablero)

func centrar_en_room00():
	if not tablero:
		return
	
	var tamaño_hab = RoomData.get_tamaño_habitacion()
	var centro_room00 = Vector2(tamaño_hab.x / 2, tamaño_hab.y / 2)
	
	var tamaño_panel = panel_mapa.size
	var centro_panel = tamaño_panel / 2
	
	var pos_deseada = centro_panel - (centro_room00 * zoom_actual)
	mapa_contenido.position = pos_deseada

func calcular_posiciones_habitaciones() -> Dictionary:
	var posiciones = {}
	var tamaño_hab = RoomData.get_tamaño_habitacion()
	var paso = Vector2(tamaño_hab.x + MARGEN_ENTRE_HABITACIONES, tamaño_hab.y + MARGEN_ENTRE_HABITACIONES)
	
	for key in RoomData.malla_habitaciones:
		var nombre = RoomData.malla_habitaciones[key]
		var coord = RoomData.string_a_coord(key)
		posiciones[nombre] = Vector2(coord.x * paso.x, coord.y * paso.y)
	
	return posiciones

func refrescar_tablero_completo():
	if refrescando:
		return
	refrescando = true
	
	print("🗺️ PC: Refrescando tablero completo")
	
	for child in tablero.get_children():
		if is_instance_valid(child):
			child.queue_free()
	habitaciones_nodos.clear()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var posiciones = calcular_posiciones_habitaciones()
	
	print("🗺️ PC: Dibujando " + str(posiciones.size()) + " habitaciones")
	
	for nombre_habitacion in posiciones:
		var pos = posiciones[nombre_habitacion]
		crear_habitacion_en_tablero(nombre_habitacion, pos)
	
	await get_tree().process_frame
	
	for nombre_habitacion in habitaciones_nodos.keys():
		if not is_instance_valid(habitaciones_nodos.get(nombre_habitacion)):
			continue
		dibujar_puertas_y_fichas_habitacion(nombre_habitacion)
		await cargar_avatares_en_habitacion(nombre_habitacion)
	
	refrescando = false
	print("✅ PC: Tablero refrescado")

func crear_habitacion_en_tablero(nombre_habitacion: String, posicion: Vector2):
	var ruta = "res://ASSET/Rooms/" + nombre_habitacion + ".png"
	var textura = load(ruta)
	if not textura:
		return
	
	var room_node = Node2D.new()
	room_node.name = "ROOM_" + nombre_habitacion
	room_node.position = posicion
	
	var sprite = Sprite2D.new()
	sprite.texture = textura
	sprite.name = "FONDO"
	sprite.centered = false
	sprite.position = Vector2.ZERO
	room_node.add_child(sprite)
	
	var capa_puertas = Node2D.new()
	capa_puertas.name = "CAPA_PUERTAS"
	room_node.add_child(capa_puertas)
	
	var capa_fichas = Node2D.new()
	capa_fichas.name = "CAPA_FICHAS"
	room_node.add_child(capa_fichas)
	
	var capa_avatares = Node2D.new()
	capa_avatares.name = "CAPA_AVATARES"
	room_node.add_child(capa_avatares)
	
	tablero.add_child(room_node)
	habitaciones_nodos[nombre_habitacion] = room_node

func dibujar_puertas_y_fichas_habitacion(nombre_habitacion: String):
	if not nombre_habitacion in habitaciones_nodos:
		return
	
	var room_node = habitaciones_nodos.get(nombre_habitacion)
	if not is_instance_valid(room_node):
		return
	
	var capa_puertas = room_node.get_node_or_null("CAPA_PUERTAS")
	var capa_fichas = room_node.get_node_or_null("CAPA_FICHAS")
	if not is_instance_valid(capa_puertas) or not is_instance_valid(capa_fichas):
		return
	
	for child in capa_puertas.get_children():
		if is_instance_valid(child):
			child.queue_free()
	for child in capa_fichas.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	await get_tree().process_frame
	
	if not is_instance_valid(capa_puertas) or not is_instance_valid(capa_fichas):
		return
	
	var estado = RoomData.get_estado_habitacion(nombre_habitacion)
	if estado.is_empty():
		return
	
	var puertas = estado.get("puertas", {})
	for direccion in puertas:
		var info = puertas[direccion]
		var estado_puerta = info.get("estado", "cerrada")
		var posicion = RoomData.get_posicion_puerta(direccion)
		
		if estado_puerta == "sin_puerta":
			continue
		
		crear_puerta_en_room(direccion, posicion, estado_puerta, capa_puertas)
		
		if estado_puerta == "abierta":
			crear_ficha_en_room(direccion, "caminar", posicion, capa_fichas)
		else:
			crear_ficha_en_room(direccion, "lupa", posicion, capa_fichas)

func crear_puerta_en_room(direccion: String, posicion: Vector2, estado: String, capa: Node2D):
	if not is_instance_valid(capa):
		return
	
	var puerta = PUERTA_SCENE.instantiate()
	puerta.name = "PUERTA_" + direccion.to_upper()
	
	var escala_puerta
	var offset_puerta
	
	if estado == "cerrada":
		escala_puerta = escala_puerta_cerrada.get(direccion, Vector2(0.4, 0.4))
		offset_puerta = offset_puerta_cerrada.get(direccion, Vector2.ZERO)
	else:
		escala_puerta = escala_puerta_abierta.get(direccion, Vector2(0.4, 0.4))
		offset_puerta = offset_puerta_abierta.get(direccion, Vector2.ZERO)
	
	puerta.position = posicion + offset_puerta
	puerta.scale = escala_puerta
	
	var puertas_cerradas = puerta.get_node("PUERTAS_CERRADAS")
	var puertas_abiertas = puerta.get_node("PUERTAS_ABIERTAS")
	var codigo_dir = obtener_codigo_direccion(direccion)
	
	if estado == "cerrada":
		if puertas_cerradas:
			var animacion = "PUERTA_" + codigo_dir + "_CERRADA"
			if puertas_cerradas.sprite_frames.has_animation(animacion):
				puertas_cerradas.animation = animacion
				puertas_cerradas.play()
				puertas_cerradas.visible = true
		if puertas_abiertas:
			puertas_abiertas.visible = false
	else:
		if puertas_abiertas:
			var animacion = "PUERTA_" + codigo_dir + "_ABIERTA"
			if puertas_abiertas.sprite_frames.has_animation(animacion):
				puertas_abiertas.animation = animacion
				puertas_abiertas.play()
				puertas_abiertas.visible = true
		if puertas_cerradas:
			puertas_cerradas.visible = false
	
	capa.add_child(puerta)

func crear_ficha_en_room(direccion: String, tipo: String, posicion: Vector2, capa: Node2D):
	if not is_instance_valid(capa):
		return
	
	var escena_ficha = null
	match tipo.to_lower():
		"lupa":        escena_ficha = FICHA_LUPA
		"caminar":     escena_ficha = FICHA_CAMINAR
		"interactuar": escena_ficha = FICHA_INTERACTUAR
		"objeto":      escena_ficha = FICHA_OBJETO
	
	if not escena_ficha:
		return
	
	var ficha = escena_ficha.instantiate()
	ficha.name = "FICHA_" + direccion.to_upper() + "_" + tipo.to_upper()
	
	var offset = obtener_offset_ficha(direccion)
	ficha.position = posicion + offset
	ficha.scale = Vector2(escala_ficha, escala_ficha)
	
	capa.add_child(ficha)

func obtener_offset_ficha(direccion: String) -> Vector2:
	match direccion.to_lower():
		"arriba":    return offset_ficha_arriba
		"abajo":     return offset_ficha_abajo
		"izquierda": return offset_ficha_izquierda
		"derecha":   return offset_ficha_derecha
	return Vector2.ZERO

func obtener_codigo_direccion(direccion: String) -> String:
	match direccion.to_lower():
		"arriba":    return "ARR"
		"abajo":     return "ABA"
		"izquierda": return "IZQ"
		"derecha":   return "DER"
	return "ARR"

func cargar_avatares_en_habitacion(nombre_habitacion: String):
	if not nombre_habitacion in habitaciones_nodos:
		return
	
	var room_node = habitaciones_nodos.get(nombre_habitacion)
	if not is_instance_valid(room_node):
		return
	
	var capa_avatares = room_node.get_node_or_null("CAPA_AVATARES")
	if not is_instance_valid(capa_avatares):
		return
	
	for child in capa_avatares.get_children():
		if is_instance_valid(child):
			child.queue_free()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	if not is_instance_valid(capa_avatares):
		return
	
	var nombres_aqui = RoomData.get_jugadores_en_habitacion(nombre_habitacion)
	var jugadores_conectados_aqui: Array = []
	
	for nombre in nombres_aqui:
		var j = Global.get_jugador_por_nombre(nombre)
		if j.get("conectado", false) == true:
			jugadores_conectados_aqui.append(j)
	
	if jugadores_conectados_aqui.size() == 0:
		return
	
	var centro_habitacion = Vector2(256, 256)
	var posiciones = calcular_posiciones_avatares(jugadores_conectados_aqui.size(), centro_habitacion)
	
	var indice = 0
	for jugador in jugadores_conectados_aqui:
		var nombre = jugador.get("nombre", "???")
		var color = jugador.get("color", "")
		
		if not is_instance_valid(capa_avatares):
			return
		
		var avatar = AVATAR_SCENE.instantiate()
		avatar.name = "AVATAR_" + nombre
		avatar.scale = Vector2(escala_avatar, escala_avatar)
		
		if indice < posiciones.size():
			avatar.position = posiciones[indice]
		
		capa_avatares.add_child(avatar)
		
		await get_tree().process_frame
		
		if is_instance_valid(avatar):
			configurar_animacion_avatar(avatar, color)
		
		indice += 1

func calcular_posiciones_avatares(cantidad: int, centro: Vector2) -> Array:
	var posiciones = []
	if cantidad == 1:
		posiciones.append(centro)
		return posiciones
	
	var radio = radio_circulo
	var angulo_inicial = -PI / 2
	var angulo_entre = (2 * PI) / cantidad
	
	for i in range(cantidad):
		var angulo = angulo_inicial + (angulo_entre * i)
		var pos = centro + Vector2(cos(angulo), sin(angulo)) * radio
		posiciones.append(pos)
	
	return posiciones

func configurar_animacion_avatar(avatar: Node, color: String):
	if not is_instance_valid(avatar):
		return
	var animated_sprite = avatar.find_child("AVATAR_ANIMACION", true, false)
	if not animated_sprite:
		return
	var nombre_animacion = "AVATAR_" + color.to_upper().strip_edges()
	if animated_sprite.sprite_frames.has_animation(nombre_animacion):
		animated_sprite.animation = nombre_animacion
		animated_sprite.frame = 0
		animated_sprite.play()

# ============================================
# ✅ NUEVO: refrescar solo los avatares de TODAS las habitaciones
# ============================================
func refrescar_todos_los_avatares():
	for nombre_hab in habitaciones_nodos.keys():
		if is_instance_valid(habitaciones_nodos.get(nombre_hab)):
			await cargar_avatares_en_habitacion(nombre_hab)

func _on_jugadores_actualizados():
	await refrescar_todos_los_avatares()

func _on_habitacion_actualizada(_nombre_habitacion: String):
	# ✅ Refrescar solo avatares, no todo el tablero
	# Esto elimina avatares viejos y los redibuja donde corresponde.
	await refrescar_todos_los_avatares()
	
	# Si la habitación no existe en el tablero (fue recién agregada), refrescar todo
	if not _nombre_habitacion in habitaciones_nodos:
		await refrescar_tablero_completo()

func _on_sync_puerta_visual(habitacion: String, direccion: String, nuevo_estado: String):
	if not habitacion in habitaciones_nodos:
		return
	
	var room_node = habitaciones_nodos.get(habitacion)
	if not is_instance_valid(room_node):
		return
	
	var capa_puertas = room_node.get_node_or_null("CAPA_PUERTAS")
	var capa_fichas = room_node.get_node_or_null("CAPA_FICHAS")
	if not is_instance_valid(capa_puertas) or not is_instance_valid(capa_fichas):
		return
	
	var puerta_node = capa_puertas.get_node_or_null("PUERTA_" + direccion.to_upper())
	if puerta_node and is_instance_valid(puerta_node):
		puerta_node.queue_free()
		await get_tree().process_frame
	
	if not is_instance_valid(capa_puertas):
		return
	
	var posicion = RoomData.get_posicion_puerta(direccion)
	crear_puerta_en_room(direccion, posicion, nuevo_estado, capa_puertas)
	
	var nombre_base = "FICHA_" + direccion.to_upper()
	for child in capa_fichas.get_children():
		if is_instance_valid(child) and child.name.begins_with(nombre_base):
			child.queue_free()
	
	await get_tree().process_frame
	
	if not is_instance_valid(capa_fichas):
		return
	
	if nuevo_estado == "abierta":
		crear_ficha_en_room(direccion, "caminar", posicion, capa_fichas)
	else:
		crear_ficha_en_room(direccion, "lupa", posicion, capa_fichas)

# ============================================
# INPUT (zoom centrado en mouse)
# ============================================
func _input(event: InputEvent):
	if event is InputEventMouseButton:
		var pos_mouse = get_global_mouse_position()
		
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			aplicar_zoom_en_posicion(zoom_actual + velocidad_zoom, pos_mouse)
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			aplicar_zoom_en_posicion(zoom_actual - velocidad_zoom, pos_mouse)
		elif event.button_index == MOUSE_BUTTON_LEFT:
			var rect_panel = Rect2(panel_mapa.global_position, panel_mapa.size)
			if rect_panel.has_point(pos_mouse):
				if event.pressed:
					arrastrando = true
					posicion_inicial_mouse = pos_mouse
					posicion_inicial_mapa = mapa_contenido.position
				else:
					arrastrando = false
	
	if event is InputEventMouseMotion and arrastrando:
		var pos_mouse = get_global_mouse_position()
		var delta = pos_mouse - posicion_inicial_mouse
		mapa_contenido.position = posicion_inicial_mapa + delta

func aplicar_zoom_en_posicion(nuevo_zoom: float, punto_pantalla: Vector2):
	var zoom_clamped = clamp(nuevo_zoom, zoom_minimo, zoom_maximo)
	
	var mundo_bajo_punto = (punto_pantalla - mapa_contenido.position) / zoom_actual
	
	zoom_actual = zoom_clamped
	mapa_contenido.scale = Vector2(zoom_actual, zoom_actual)
	
	mapa_contenido.position = punto_pantalla - (mundo_bajo_punto * zoom_actual)
