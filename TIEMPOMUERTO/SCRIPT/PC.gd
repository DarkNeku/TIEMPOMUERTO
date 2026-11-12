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

var lbl_jugador: Label = null
var lbl_tiempo: Label = null
var txt_nfc: LineEdit = null
var indice_turno_actual: int = 0
var habitacion_actual_turno: String = "Room00"

var acciones_restantes: int = 2
var btn_siguiente_turno: Button = null

var ventana_codigo: Control = null
var txt_codigo: LineEdit = null
var lbl_error: Label = null
var btn_ok_ventana: Button = null
var btn_cancelar_ventana: Button = null
var direccion_pendiente: String = ""

func _ready():
	print("=== PC: Iniciando Tablero DM ===")
	
	panel_mapa = get_node("Panel/PANEL_MAPA")
	mapa_contenido = get_node("Panel/PANEL_MAPA/MAPA_CONTENIDO")
	panel_mapa.mouse_filter = Control.MOUSE_FILTER_STOP
	
	lbl_jugador = find_child("LBL_JUGADOR", true, false)
	lbl_tiempo = find_child("LBL_TIEMPO", true, false)
	txt_nfc = find_child("TXT_NFC", true, false)
	btn_siguiente_turno = find_child("BTN_SIGUIENTE_TURNO", true, false)
	
	if txt_nfc:
		txt_nfc.text_submitted.connect(_on_nfc_escaneado)
		txt_nfc.grab_focus() 
	
	if btn_siguiente_turno:
		btn_siguiente_turno.visible = false
		btn_siguiente_turno.pressed.connect(_on_btn_siguiente_turno_pressed)
	
	ventana_codigo = find_child("VENTANA_CODIGO", true, false)
	if ventana_codigo:
		txt_codigo = ventana_codigo.find_child("TXT_CODIGO", true, false)
		lbl_error = ventana_codigo.find_child("LBL_ERROR", true, false)
		btn_ok_ventana = ventana_codigo.find_child("BTN_OK", true, false)
		btn_cancelar_ventana = ventana_codigo.find_child("BTN_CANCELAR", true, false)
		
		if btn_ok_ventana: btn_ok_ventana.pressed.connect(_on_btn_ok_codigo)
		if btn_cancelar_ventana: btn_cancelar_ventana.pressed.connect(_on_btn_cancelar_codigo)
		if txt_codigo: txt_codigo.text_submitted.connect(_on_txt_codigo_submitted)
		
		ventana_codigo.visible = false
	
	RoomData.inicializar_room00_por_defecto()
	
	var jugadores = Global.get_jugadores()
	for jugador in jugadores:
		var color = jugador.get("color", "")
		if color != "":
			RoomData.actualizar_posicion_jugador(color, "Room00")
	
	crear_tablero()
	await get_tree().process_frame
	await refrescar_tablero_completo()
	centrar_en_room00()
	
	iniciar_turno(0)

func iniciar_turno(indice: int):
	if indice >= Global.get_jugadores().size(): return
	indice_turno_actual = indice
	var jugador = Global.get_jugadores()[indice]
	var color = jugador["color"]
	
	habitacion_actual_turno = RoomData.get_habitacion_jugador(color)
	if habitacion_actual_turno == "":
		habitacion_actual_turno = "Room00"
	
	acciones_restantes = 2
	if btn_siguiente_turno:
		btn_siguiente_turno.visible = false
	
	if lbl_jugador:
		lbl_jugador.text = "TURNO DE: JUGADOR " + color + " (Acciones: 2/2)"
	
	actualizar_tiempo_ui()

func _on_btn_siguiente_turno_pressed():
	if btn_siguiente_turno:
		btn_siguiente_turno.visible = false
	
	var siguiente_indice = indice_turno_actual + 1
	if siguiente_indice >= Global.get_jugadores().size():
		siguiente_indice = 0
		
	iniciar_turno(siguiente_indice)

func actualizar_tiempo_ui():
	if lbl_tiempo:
		lbl_tiempo.text = "TIEMPO: " + str(Global.get_tiempo_restante()) + " min"

func restar_accion():
	if acciones_restantes > 0:
		acciones_restantes -= 1
	
	var jugadores = Global.get_jugadores()
	var color = jugadores[indice_turno_actual]["color"]
	
	if lbl_jugador:
		lbl_jugador.text = "TURNO DE: JUGADOR " + color + " (Acciones: " + str(acciones_restantes) + "/2)"
	
	if acciones_restantes <= 0 and btn_siguiente_turno:
		btn_siguiente_turno.visible = true

func _on_nfc_escaneado(texto: String):
	if texto.strip_edges() == "": return
	txt_nfc.text = "" 
	txt_nfc.grab_focus()
	procesar_codigo(texto)

func mostrar_ventana_codigo(direccion: String):
	direccion_pendiente = direccion
	if ventana_codigo:
		ventana_codigo.visible = true
		if txt_codigo: 
			txt_codigo.text = ""
			txt_codigo.grab_focus()
		if lbl_error: 
			lbl_error.text = ""

func ocultar_ventana_codigo():
	if ventana_codigo:
		ventana_codigo.visible = false
		direccion_pendiente = ""

func _on_btn_ok_codigo():
	if txt_codigo: procesar_codigo(txt_codigo.text)
func _on_txt_codigo_submitted(texto: String):
	procesar_codigo(texto)
func _on_btn_cancelar_codigo():
	ocultar_ventana_codigo()

func procesar_codigo(codigo_ingresado: String):
	var resultado = RoomData.validar_codigo_habitacion(codigo_ingresado, habitacion_actual_turno)
	
	if not resultado["valido"]:
		if lbl_error: 
			lbl_error.text = "❌ " + resultado["error"]
			lbl_error.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		return
	
	var nueva_hab = resultado["nombre_habitacion"]
	var coord_origen = RoomData.get_coord_habitacion(habitacion_actual_turno)
	var coord_destino = RoomData.calcular_coord_vecina(coord_origen.x, coord_origen.y, direccion_pendiente)
	var dir_opuesta = RoomData.obtener_direccion_opuesta(direccion_pendiente)
	
	var estado_puertas = RoomData.generar_puertas_para_habitacion(nueva_hab, coord_destino, dir_opuesta)
	estado_puertas[dir_opuesta] = "abierta"
	
	var direcciones = ["arriba", "abajo", "izquierda", "derecha"]
	for d in direcciones:
		var coord_vecino = RoomData.calcular_coord_vecina(coord_destino.x, coord_destino.y, d)
		var hab_vecina = RoomData.get_habitacion_en_coord(coord_vecino.x, coord_vecino.y)
		
		if hab_vecina != "":
			var dir_op = RoomData.obtener_direccion_opuesta(d)
			var estado_vecino = RoomData.get_estado_habitacion(hab_vecina)
			if not estado_vecino.is_empty() and "puertas" in estado_vecino and dir_op in estado_vecino["puertas"]:
				if estado_vecino["puertas"][dir_op].get("estado", "cerrada") == "abierta":
					estado_puertas[d] = "abierta"

	var estado = {"puertas": {}}
	for d in estado_puertas:
		estado["puertas"][d] = {"estado": estado_puertas[d]}
	
	RoomData.guardar_estado_habitacion(nueva_hab, estado)
	RoomData.agregar_habitacion_colocada(nueva_hab)
	RoomData.agregar_a_malla(nueva_hab, coord_destino.x, coord_destino.y)
	
	RoomData.guardar_estado_habitacion_puerta(habitacion_actual_turno, direccion_pendiente, "abierta")
	RoomData.registrar_conexion(habitacion_actual_turno, direccion_pendiente, nueva_hab)
	
	mover_jugador_a_habitacion(nueva_hab)
	
	ocultar_ventana_codigo()
	refrescar_tablero_completo()

func mover_jugador_a_habitacion(nueva_hab: String):
	var jugadores = Global.get_jugadores()
	if indice_turno_actual < jugadores.size():
		var color_actual = jugadores[indice_turno_actual]["color"]
		RoomData.actualizar_posicion_jugador(color_actual, nueva_hab)
		habitacion_actual_turno = nueva_hab
		print("✅ Posición actualizada: " + color_actual + " -> " + nueva_hab)

# ✅ LÓGICA DE CLIC CON VALIDACIÓN DE HABITACIÓN
func _on_ficha_clickeada(habitacion_ficha: String, direccion: String, tipo: String):
	# ✅ BLOQUEO: Solo dejamos interactuar si la ficha es de la habitación actual
	if habitacion_ficha != habitacion_actual_turno:
		print("⛔ Intento de interactuar con la habitación " + habitacion_ficha + " pero el jugador está en " + habitacion_actual_turno)
		return
		
	print("🖱️ DM hizo clic en ficha " + tipo + " en dirección " + direccion + " de " + habitacion_ficha)
	
	if acciones_restantes <= 0:
		print("❌ No hay acciones restantes en este turno.")
		return
	
	if tipo == "lupa":
		RoomData.guardar_estado_habitacion_puerta(habitacion_actual_turno, direccion, "abierta")
		var coord_actual = RoomData.get_coord_habitacion(habitacion_actual_turno)
		var coord_vecino = RoomData.calcular_coord_vecina(coord_actual.x, coord_actual.y, direccion)
		var hab_vecina = RoomData.get_habitacion_en_coord(coord_vecino.x, coord_vecino.y)
		
		if hab_vecina != "":
			var dir_opuesta = RoomData.obtener_direccion_opuesta(direccion)
			RoomData.guardar_estado_habitacion_puerta(hab_vecina, dir_opuesta, "abierta")
		
		Global.restar_tiempo(1)
		restar_accion()
		actualizar_tiempo_ui()
		refrescar_tablero_completo()
		
	elif tipo == "caminar":
		var coord_actual = RoomData.get_coord_habitacion(habitacion_actual_turno)
		var coord_destino = RoomData.calcular_coord_vecina(coord_actual.x, coord_actual.y, direccion)
		var hab_vecina = RoomData.get_habitacion_en_coord(coord_destino.x, coord_destino.y)
		
		if hab_vecina != "":
			print("🚶‍♂️ Jugador se mueve a habitación ya explorada: " + hab_vecina)
			Global.restar_tiempo(2)
			restar_accion()
			actualizar_tiempo_ui()
			
			RoomData.registrar_conexion(habitacion_actual_turno, direccion, hab_vecina)
			var dir_opuesta = RoomData.obtener_direccion_opuesta(direccion)
			RoomData.guardar_estado_habitacion_puerta(hab_vecina, dir_opuesta, "abierta")
			RoomData.guardar_estado_habitacion_puerta(habitacion_actual_turno, direccion, "abierta")
			
			mover_jugador_a_habitacion(hab_vecina)
			refrescar_tablero_completo()
		else:
			print("❓ Habitación desconocida al " + direccion + ". Pidiendo código.")
			mostrar_ventana_codigo(direccion)

# ============================================
# RESTO DE LAS FUNCIONES (DIBUJADO)
# ============================================
func crear_tablero():
	for child in mapa_contenido.get_children():
		child.queue_free()
	tablero = Node2D.new()
	tablero.name = "TABLERO"
	mapa_contenido.add_child(tablero)

func centrar_en_room00():
	if not tablero: return
	var tamaño_hab = RoomData.get_tamaño_habitacion()
	var centro_room00 = Vector2(tamaño_hab.x / 2, tamaño_hab.y / 2)
	var tamaño_panel = panel_mapa.size
	var centro_panel = tamaño_panel / 2
	mapa_contenido.position = centro_panel - (centro_room00 * zoom_actual)

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
	if refrescando: return
	refrescando = true
	for child in tablero.get_children():
		if is_instance_valid(child): child.queue_free()
	habitaciones_nodos.clear()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var posiciones = calcular_posiciones_habitaciones()
	for nombre_habitacion in posiciones:
		crear_habitacion_en_tablero(nombre_habitacion, posiciones[nombre_habitacion])
	
	await get_tree().process_frame
	
	for nombre_habitacion in habitaciones_nodos.keys():
		if not is_instance_valid(habitaciones_nodos.get(nombre_habitacion)): continue
		dibujar_puertas_y_fichas_habitacion(nombre_habitacion)
		await cargar_avatares_en_habitacion(nombre_habitacion)
	
	refrescando = false

func crear_habitacion_en_tablero(nombre_habitacion: String, posicion: Vector2):
	var textura = load("res://ASSET/Rooms/" + nombre_habitacion + ".png")
	if not textura: return
	
	var room_node = Node2D.new()
	room_node.name = "ROOM_" + nombre_habitacion
	room_node.position = posicion
	
	var sprite = Sprite2D.new()
	sprite.texture = textura
	sprite.name = "FONDO"
	sprite.centered = false
	room_node.add_child(sprite)
	
	for capa_nombre in ["CAPA_PUERTAS", "CAPA_FICHAS", "CAPA_AVATARES"]:
		var capa = Node2D.new()
		capa.name = capa_nombre
		room_node.add_child(capa)
	
	tablero.add_child(room_node)
	habitaciones_nodos[nombre_habitacion] = room_node

func dibujar_puertas_y_fichas_habitacion(nombre_habitacion: String):
	if not nombre_habitacion in habitaciones_nodos: return
	var room_node = habitaciones_nodos.get(nombre_habitacion)
	if not is_instance_valid(room_node): return
	
	var capa_puertas = room_node.get_node_or_null("CAPA_PUERTAS")
	var capa_fichas = room_node.get_node_or_null("CAPA_FICHAS")
	if not is_instance_valid(capa_puertas) or not is_instance_valid(capa_fichas): return
	
	for child in capa_puertas.get_children():
		if is_instance_valid(child): child.queue_free()
	for child in capa_fichas.get_children():
		if is_instance_valid(child): child.queue_free()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var estado = RoomData.get_estado_habitacion(nombre_habitacion)
	if estado.is_empty(): return
	
	var puertas = estado.get("puertas", {})
	for direccion in puertas:
		var info = puertas[direccion]
		var estado_puerta = info.get("estado", "cerrada")
		var posicion = RoomData.get_posicion_puerta(direccion)
		
		if estado_puerta == "sin_puerta": continue
		
		crear_puerta_en_room(direccion, posicion, estado_puerta, capa_puertas)
		if estado_puerta == "abierta":
			crear_ficha_en_room(nombre_habitacion, direccion, "caminar", posicion, capa_fichas)
		else:
			crear_ficha_en_room(nombre_habitacion, direccion, "lupa", posicion, capa_fichas)

func crear_puerta_en_room(direccion: String, posicion: Vector2, estado: String, capa: Node2D):
	if not is_instance_valid(capa): return
	var puerta = PUERTA_SCENE.instantiate()
	puerta.name = "PUERTA_" + direccion.to_upper()
	
	var escala_puerta = escala_puerta_cerrada.get(direccion, Vector2(0.4, 0.4)) if estado == "cerrada" else escala_puerta_abierta.get(direccion, Vector2(0.4, 0.4))
	var offset_puerta = offset_puerta_cerrada.get(direccion, Vector2.ZERO) if estado == "cerrada" else offset_puerta_abierta.get(direccion, Vector2.ZERO)
	
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
		if puertas_abiertas: puertas_abiertas.visible = false
	else:
		if puertas_abiertas:
			var animacion = "PUERTA_" + codigo_dir + "_ABIERTA"
			if puertas_abiertas.sprite_frames.has_animation(animacion):
				puertas_abiertas.animation = animacion
				puertas_abiertas.play()
				puertas_abiertas.visible = true
		if puertas_cerradas: puertas_cerradas.visible = false
	
	capa.add_child(puerta)

func crear_ficha_en_room(nombre_habitacion: String, direccion: String, tipo: String, posicion: Vector2, capa: Node2D):
	if not is_instance_valid(capa): return
	var escena_ficha = null
	match tipo.to_lower():
		"lupa":        escena_ficha = FICHA_LUPA
		"caminar":     escena_ficha = FICHA_CAMINAR
		"interactuar": escena_ficha = FICHA_INTERACTUAR
		"objeto":      escena_ficha = FICHA_OBJETO
	
	if not escena_ficha: return
	var ficha = escena_ficha.instantiate()
	ficha.name = "FICHA_" + direccion.to_upper() + "_" + tipo.to_upper()
	
	var offset = obtener_offset_ficha(direccion)
	ficha.position = posicion + offset
	ficha.scale = Vector2(escala_ficha, escala_ficha)
	
	# ✅ PASAMOS EL NOMBRE DE LA HABITACIÓN A LA SEÑAL
	if ficha.has_signal("pressed"):
		ficha.pressed.connect(_on_ficha_clickeada.bind(nombre_habitacion, direccion, tipo))
	
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
	if not nombre_habitacion in habitaciones_nodos: return
	var room_node = habitaciones_nodos.get(nombre_habitacion)
	if not is_instance_valid(room_node): return
	var capa_avatares = room_node.get_node_or_null("CAPA_AVATARES")
	if not is_instance_valid(capa_avatares): return
	
	for child in capa_avatares.get_children():
		if is_instance_valid(child): child.queue_free()
	
	await get_tree().process_frame
	await get_tree().process_frame
	
	var nombres_aqui = RoomData.get_jugadores_en_habitacion(nombre_habitacion)
	if nombres_aqui.size() == 0: return
	
	var posiciones = calcular_posiciones_avatares(nombres_aqui.size(), Vector2(256, 256))
	
	for i in range(nombres_aqui.size()):
		var color = nombres_aqui[i]
		var avatar = AVATAR_SCENE.instantiate()
		avatar.name = "AVATAR_" + color
		avatar.scale = Vector2(escala_avatar, escala_avatar)
		avatar.position = posiciones[i]
		capa_avatares.add_child(avatar)
		await get_tree().process_frame
		configurar_animacion_avatar(avatar, color)

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
		posiciones.append(centro + Vector2(cos(angulo), sin(angulo)) * radio)
	return posiciones

func configurar_animacion_avatar(avatar: Node, color: String):
	if not is_instance_valid(avatar): return
	var animated_sprite = avatar.find_child("AVATAR_ANIMACION", true, false)
	if not animated_sprite: return
	var nombre_animacion = "AVATAR_" + color.to_upper().strip_edges()
	if animated_sprite.sprite_frames.has_animation(nombre_animacion):
		animated_sprite.animation = nombre_animacion
		animated_sprite.frame = 0
		animated_sprite.play()

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
		mapa_contenido.position = posicion_inicial_mapa + (pos_mouse - posicion_inicial_mouse)

func aplicar_zoom_en_posicion(nuevo_zoom: float, punto_pantalla: Vector2):
	var zoom_clamped = clamp(nuevo_zoom, zoom_minimo, zoom_maximo)
	var mundo_bajo_punto = (punto_pantalla - mapa_contenido.position) / zoom_actual
	zoom_actual = zoom_clamped
	mapa_contenido.scale = Vector2(zoom_actual, zoom_actual)
	mapa_contenido.position = punto_pantalla - (mundo_bajo_punto * zoom_actual)
