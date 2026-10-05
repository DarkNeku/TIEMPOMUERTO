extends Control

@onready var mundo = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM/MUNDO
@onready var imagen_room = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM/MUNDO/IMAGEN_ROOM
@onready var contenedor_room = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM
@onready var capa_puertas = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM/MUNDO/CAPA_PUERTAS
@onready var capa_fichas = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM/MUNDO/CAPA_FICHAS
@onready var capa_avatares = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM/MUNDO/CAPA_AVATARES
@onready var pnl_avatar = $VBoxContainer/PNL_AVATAR
@onready var fila_nombres = $VBoxContainer/PNL_AVATAR/CONT_AVATAR_NOMBRE/FILA_NOMBRE
@onready var fila_avatares = $VBoxContainer/PNL_AVATAR/CONT_AVATAR_NOMBRE/FILA_AVATARES
@onready var lbl_nombre = $VBoxContainer/PNL_SUP/HBoxContainer/Panel2/LBL_NOMBRE

@onready var ventana_codigo = $VENTANA_CODIGO
@onready var txt_codigo = $VENTANA_CODIGO/TXT_CODIGO
@onready var lbl_error = $VENTANA_CODIGO/LBL_ERROR
@onready var btn_ok = $VENTANA_CODIGO/BTN_OK
@onready var btn_cancelar = $VENTANA_CODIGO/BTN_CANCELAR

const AVATAR_SCENE = preload("res://SPRITE/AVATAR.tscn")
const PUERTA_SCENE = preload("res://SPRITE/PUERTAS.tscn")
const FICHA_LUPA = preload("res://SPRITE/LUPA.tscn")
const FICHA_CAMINAR = preload("res://SPRITE/CAMINAR.tscn")
const FICHA_INTERACTUAR = preload("res://SPRITE/INTERACTUAR.tscn")
const FICHA_OBJETO = preload("res://SPRITE/OBJETO.tscn")

# ============================================
# CONFIGURACIÓN
# ============================================
var mi_indice_jugador: int = 0

var factor_alejamiento: float = 0.9
var zoom_minimo: float = 0.9
var zoom_maximo: float = 1.8
var velocidad_zoom: float = 0.05
var sensibilidad_movimiento: float = 0.5
var margen_extra: float = 0.0

var habitacion_actual: String = "Room00"
var direccion_puerta_pendiente: String = ""

# Configuración de puertas
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

# Fichas
var escala_ficha: float = 0.05
var offset_ficha_arriba:    Vector2 = Vector2(-8, 0)
var offset_ficha_abajo:     Vector2 = Vector2(-8, -18)
var offset_ficha_izquierda: Vector2 = Vector2(0, 0)
var offset_ficha_derecha:   Vector2 = Vector2(-15, -10)

var probabilidad_puerta: float = 0.6

# Avatares
var escala_avatar: float = 0.11
var radio_circulo: float = 60.0
var tiempo_entre_animaciones: float = 3.0

# Turnos
var turno_actual: int = 0
var avatars_fila: Array = []
var escala_avatar_normal: float = 0.12
var escala_avatar_activo: float = 0.15
var color_avatar_activo: Color = Color(1, 1, 0.5)
var color_avatar_normal: Color = Color(1, 1, 1)

# Fila
var separacion_fila: int = 40
var tamaño_contenedor_avatar: Vector2 = Vector2(50, 60)
var tamaño_label: Vector2 = Vector2(40, 15)

# Estado
var estado_fichas: Dictionary = {}

# Variables internas
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
	
	await get_tree().create_timer(0.3).timeout
	
	asignar_nombre_jugador()
	
	RoomData.agregar_habitacion_colocada("Room00")
	
	# ✅ INICIALIZAR POSICIONES DE TODOS LOS JUGADORES EN Room00
	var todos_jugadores = Global.get_jugadores()
	RoomData.inicializar_posiciones_jugadores(todos_jugadores, "Room00")
	RoomData.imprimir_posiciones_jugadores()
	
	cargar_habitacion("Room00")
	await get_tree().process_frame
	await get_tree().process_frame
	
	cargar_puertas_iniciales("Room00")
	
	# ✅ Cargar solo los avatares que están en Room00
	cargar_avatares_en_habitacion("Room00")
	cargar_fila_avatares()
	
	configurar_ventana_codigo()
	
	set_process_input(true)
	print("=== JUGADOR: Listo ===")

# ============================================
# CONFIGURAR VENTANA
# ============================================
func configurar_ventana_codigo():
	ventana_codigo.visible = false
	lbl_error.text = ""
	
	if not btn_ok.pressed.is_connected(_on_btn_ok_pressed):
		btn_ok.pressed.connect(_on_btn_ok_pressed)
	if not btn_cancelar.pressed.is_connected(_on_btn_cancelar_pressed):
		btn_cancelar.pressed.connect(_on_btn_cancelar_pressed)
	if not txt_codigo.text_submitted.is_connected(_on_txt_codigo_submitted):
		txt_codigo.text_submitted.connect(_on_txt_codigo_submitted)

# ============================================
# ASIGNAR NOMBRE
# ============================================
func asignar_nombre_jugador():
	if not Global:
		return
	
	var jugadores = Global.get_jugadores()
	
	if jugadores.size() == 0:
		return
	
	if mi_indice_jugador >= jugadores.size():
		mi_indice_jugador = 0
	
	var jugador = jugadores[mi_indice_jugador]
	var nombre_jugador = jugador.get("nombre", "JUGADOR")
	
	if lbl_nombre:
		lbl_nombre.text = nombre_jugador
		print("✅ Nombre asignado: " + nombre_jugador)

# ============================================
# CARGAR PUERTAS INICIALES
# ============================================
func cargar_puertas_iniciales(nombre_habitacion: String):
	var puertas_iniciales = RoomData.get_puertas_iniciales(nombre_habitacion)
	
	if puertas_iniciales.size() == 0:
		print("⚠️ No hay puertas en " + nombre_habitacion)
		return
	
	print("🚪 Puertas iniciales: " + str(puertas_iniciales))
	
	var estado = {"puertas": {}}
	
	for direccion in puertas_iniciales:
		var posicion = RoomData.get_posicion_puerta(direccion)
		crear_puerta(direccion, posicion, "cerrada")
		crear_ficha(direccion, "lupa", posicion)
		estado["puertas"][direccion] = {"estado": "cerrada"}
	
	RoomData.guardar_estado_habitacion(nombre_habitacion, estado)

# ============================================
# GENERAR PUERTAS
# ============================================
func generar_puertas_habitacion(nombre_habitacion: String, direccion_entrada: String):
	print("🎲 Generando puertas para " + nombre_habitacion)
	print("   Entrada desde: " + direccion_entrada)
	
	var direcciones = ["arriba", "abajo", "izquierda", "derecha"]
	var estado = {"puertas": {}}
	
	for direccion in direcciones:
		var posicion = RoomData.get_posicion_puerta(direccion)
		
		if direccion == direccion_entrada:
			print("   ✅ " + direccion + ": ENTRADA (abierta)")
			crear_puerta(direccion, posicion, "abierta")
			crear_ficha(direccion, "caminar", posicion)
			estado["puertas"][direccion] = {"estado": "abierta"}
			continue
		
		if RoomData.hay_conexion(nombre_habitacion, direccion):
			var habitacion_conectada = RoomData.get_habitacion_conectada(nombre_habitacion, direccion)
			print("   🔗 " + direccion + ": CONEXIÓN con " + habitacion_conectada)
			crear_puerta(direccion, posicion, "cerrada")
			crear_ficha(direccion, "lupa", posicion)
			estado["puertas"][direccion] = {"estado": "cerrada"}
			continue
		
		var aleatorio = randf()
		if aleatorio < probabilidad_puerta:
			print("   🎲 " + direccion + ": CERRADA (aleatorio)")
			crear_puerta(direccion, posicion, "cerrada")
			crear_ficha(direccion, "lupa", posicion)
			estado["puertas"][direccion] = {"estado": "cerrada"}
		else:
			print("   ❌ " + direccion + ": SIN PUERTA")
			estado["puertas"][direccion] = {"estado": "sin_puerta"}
	
	RoomData.guardar_estado_habitacion(nombre_habitacion, estado)

# ============================================
# CARGAR PUERTAS GUARDADAS
# ============================================
func cargar_puertas_guardadas(nombre_habitacion: String):
	print("📂 Cargando puertas guardadas de " + nombre_habitacion)
	
	var estado = RoomData.get_estado_habitacion(nombre_habitacion)
	
	if estado.is_empty():
		print("⚠️ No hay estado guardado")
		return false
	
	var puertas = estado.get("puertas", {})
	
	for direccion in puertas:
		var info = puertas[direccion]
		var estado_puerta = info.get("estado", "cerrada")
		var posicion = RoomData.get_posicion_puerta(direccion)
		
		if estado_puerta == "sin_puerta":
			print("   ❌ " + direccion + ": SIN PUERTA")
			continue
		
		print("   " + direccion + ": " + estado_puerta)
		crear_puerta(direccion, posicion, estado_puerta)
		
		if estado_puerta == "abierta":
			crear_ficha(direccion, "caminar", posicion)
		else:
			crear_ficha(direccion, "lupa", posicion)
	
	return true

# ============================================
# CREAR PUERTA
# ============================================
func crear_puerta(direccion: String, posicion: Vector2, estado: String):
	print("  🚪 Creando puerta " + direccion + " (" + estado + ")")
	
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
	
	capa_puertas.add_child(puerta)

# ============================================
# CREAR FICHA
# ============================================
func crear_ficha(direccion: String, tipo: String, posicion: Vector2):
	print("     🎯 Creando ficha '" + tipo + "' en " + direccion)
	
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
	
	ficha.pressed.connect(_on_ficha_pressed.bind(direccion, tipo))
	
	capa_fichas.add_child(ficha)

# ============================================
# OBTENER OFFSET DE FICHA
# ============================================
func obtener_offset_ficha(direccion: String) -> Vector2:
	match direccion.to_lower():
		"arriba":    return offset_ficha_arriba
		"abajo":     return offset_ficha_abajo
		"izquierda": return offset_ficha_izquierda
		"derecha":   return offset_ficha_derecha
	return Vector2.ZERO

# ============================================
# AL PRESIONAR FICHA
# ============================================
func _on_ficha_pressed(direccion: String, tipo: String):
	print("")
	print("🎯 Ficha presionada: " + tipo + " en " + direccion)
	
	match tipo.to_lower():
		"lupa":
			investigar_puerta(direccion)
		"interactuar":
			interactuar_puerta(direccion)
		"caminar":
			caminar_por_puerta(direccion)
		"objeto":
			recoger_objeto(direccion)

func investigar_puerta(direccion: String):
	print("🔍 Investigando puerta " + direccion)
	abrir_puerta(direccion)

func interactuar_puerta(direccion: String):
	print("✋ Interactuando con puerta " + direccion)

func caminar_por_puerta(direccion: String):
	print("👣 Caminando por puerta " + direccion)
	
	if RoomData.hay_conexion(habitacion_actual, direccion):
		var habitacion_destino = RoomData.get_habitacion_conectada(habitacion_actual, direccion)
		print("🔗 Conexión existente: " + habitacion_destino)
		cambiar_habitacion(habitacion_destino, direccion)
	else:
		print("❓ No hay conexión, pidiendo código")
		direccion_puerta_pendiente = direccion
		mostrar_ventana_codigo()

func recoger_objeto(direccion: String):
	print("🎁 Recogiendo objeto en " + direccion)

# ============================================
# VENTANA DE CÓDIGO
# ============================================
func mostrar_ventana_codigo():
	ventana_codigo.visible = true
	txt_codigo.text = ""
	lbl_error.text = ""
	txt_codigo.grab_focus()
	print("📝 Ventana de código abierta")

func ocultar_ventana_codigo():
	ventana_codigo.visible = false
	txt_codigo.text = ""
	lbl_error.text = ""
	direccion_puerta_pendiente = ""
	print("📝 Ventana cerrada")

func _on_btn_ok_pressed():
	procesar_codigo()

func _on_txt_codigo_submitted(_text: String):
	procesar_codigo()

func _on_btn_cancelar_pressed():
	ocultar_ventana_codigo()

# ============================================
# PROCESAR CÓDIGO
# ============================================
func procesar_codigo():
	var codigo = txt_codigo.text.strip_edges()
	print("🔢 Procesando código: '" + codigo + "'")
	
	var resultado = RoomData.validar_codigo_habitacion(codigo, habitacion_actual)
	
	if not resultado["valido"]:
		lbl_error.text = "❌ " + resultado["error"]
		lbl_error.add_theme_color_override("font_color", Color(1, 0.2, 0.2))
		print("❌ Error: " + resultado["error"])
		return
	
	var nueva_habitacion = resultado["nombre_habitacion"]
	var direccion_entrada = direccion_puerta_pendiente
	
	print("✅ Código válido: " + nueva_habitacion)
	
	RoomData.registrar_conexion(habitacion_actual, direccion_entrada, nueva_habitacion)
	
	ocultar_ventana_codigo()
	
	cambiar_habitacion(nueva_habitacion, direccion_entrada)

# ============================================
# CAMBIAR DE HABITACIÓN (SOLO EL JUGADOR ACTUAL)
# ============================================
func cambiar_habitacion(nueva_habitacion: String, direccion_entrada: String):
	print("")
	print("╔═══════════════════════════════════════╗")
	print("║     CAMBIANDO DE HABITACIÓN           ║")
	print("╚═══════════════════════════════════════╝")
	print("   De: " + habitacion_actual)
	print("   A:  " + nueva_habitacion)
	
	# ✅ Obtener el nombre del jugador actual
	var jugador_actual = Global.get_jugadores()[mi_indice_jugador].get("nombre", "")
	
	# ✅ Actualizar SOLO la posición del jugador actual
	RoomData.actualizar_posicion_jugador(jugador_actual, nueva_habitacion)
	RoomData.imprimir_posiciones_jugadores()
	
	RoomData.agregar_habitacion_colocada(nueva_habitacion)
	habitacion_actual = nueva_habitacion
	
	# Limpiar puertas y fichas
	for child in capa_puertas.get_children():
		child.queue_free()
	for child in capa_fichas.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	await cargar_habitacion(nueva_habitacion)
	await get_tree().process_frame
	await get_tree().process_frame
	
	# ✅ Cargar solo los avatares de la nueva habitación
	await cargar_avatares_en_habitacion(nueva_habitacion)
	
	# ✅ Cargar puertas
	if RoomData.habitacion_ya_generada(nueva_habitacion):
		print("📂 Habitación ya visitada")
		cargar_puertas_guardadas(nueva_habitacion)
	else:
		print("🆕 Primera visita")
		var direccion_opuesta = RoomData.obtener_direccion_opuesta(direccion_entrada)
		generar_puertas_habitacion(nueva_habitacion, direccion_opuesta)
	
	print("✅ Cambio completado a " + nueva_habitacion)

# ============================================
# CARGAR AVATARES EN UNA HABITACIÓN
# ============================================
func cargar_avatares_en_habitacion(nombre_habitacion: String):
	print("👥 Cargando avatares en " + nombre_habitacion)
	
	for child in capa_avatares.get_children():
		child.queue_free()
	
	await get_tree().process_frame
	
	var nombres_jugadores = RoomData.get_jugadores_en_habitacion(nombre_habitacion)
	
	if nombres_jugadores.size() == 0:
		print("   ⚠️ No hay jugadores aquí")
		return
	
	print("   Jugadores aquí: " + str(nombres_jugadores))
	
	var tamaño_habitacion = imagen_room.texture.get_size() if imagen_room.texture else Vector2(512, 512)
	var centro_habitacion = tamaño_habitacion / 2
	
	var posiciones = calcular_posiciones_avatares(nombres_jugadores.size(), centro_habitacion)
	
	var indice = 0
	for nombre in nombres_jugadores:
		var color = Global.get_color_jugador(nombre)
		
		var avatar = AVATAR_SCENE.instantiate()
		avatar.name = "AVATAR_" + nombre
		avatar.scale = Vector2(escala_avatar, escala_avatar)
		
		if indice < posiciones.size():
			avatar.position = posiciones[indice]
		
		capa_avatares.add_child(avatar)
		
		await get_tree().process_frame
		configurar_animacion_avatar(avatar, color)
		
		indice += 1
	
	print("   ✅ " + str(nombres_jugadores.size()) + " avatares cargados")

# ============================================
# ABRIR PUERTA
# ============================================
func abrir_puerta(direccion: String):
	print("🔓 Abriendo puerta " + direccion)
	
	var puerta = capa_puertas.get_node_or_null("PUERTA_" + direccion.to_upper())
	if puerta:
		var puertas_cerradas = puerta.get_node("PUERTAS_CERRADAS")
		var puertas_abiertas = puerta.get_node("PUERTAS_ABIERTAS")
		
		var codigo_dir = obtener_codigo_direccion(direccion)
		var animacion_abierta = "PUERTA_" + codigo_dir + "_ABIERTA"
		
		if puertas_abiertas and puertas_abiertas.sprite_frames.has_animation(animacion_abierta):
			puertas_abiertas.animation = animacion_abierta
			puertas_abiertas.play()
			puertas_abiertas.visible = true
		
		if puertas_cerradas:
			puertas_cerradas.visible = false
		
		var posicion_base = RoomData.get_posicion_puerta(direccion)
		var offset_abierta = offset_puerta_abierta.get(direccion, Vector2.ZERO)
		var escala_abierta = escala_puerta_abierta.get(direccion, Vector2(0.4, 0.4))
		
		puerta.position = posicion_base + offset_abierta
		puerta.scale = escala_abierta
		
		actualizar_estado_puerta(direccion, "abierta")
	
	cambiar_ficha(direccion, "caminar")

# ============================================
# ACTUALIZAR ESTADO DE PUERTA
# ============================================
func actualizar_estado_puerta(direccion: String, nuevo_estado: String):
	var estado = RoomData.get_estado_habitacion(habitacion_actual)
	
	if estado.is_empty():
		return
	
	if not "puertas" in estado:
		estado["puertas"] = {}
	
	estado["puertas"][direccion] = {"estado": nuevo_estado}
	RoomData.guardar_estado_habitacion(habitacion_actual, estado)

# ============================================
# CAMBIAR FICHA
# ============================================
func cambiar_ficha(direccion: String, nuevo_tipo: String):
	print("🔄 Cambiando ficha de " + direccion + " a " + nuevo_tipo)
	
	estado_fichas[direccion] = nuevo_tipo
	
	var nombre_base = "FICHA_" + direccion.to_upper()
	for child in capa_fichas.get_children():
		if child.name.begins_with(nombre_base):
			child.queue_free()
	
	await get_tree().process_frame
	var posicion = RoomData.get_posicion_puerta(direccion)
	crear_ficha(direccion, nuevo_tipo, posicion)

# ============================================
# CÓDIGO DE DIRECCIÓN
# ============================================
func obtener_codigo_direccion(direccion: String) -> String:
	match direccion.to_lower():
		"arriba":    return "ARR"
		"abajo":     return "ABA"
		"izquierda": return "IZQ"
		"derecha":   return "DER"
	return "ARR"

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
		print("✅ Habitación cargada: " + nombre_habitacion)
	else:
		print("❌ No se encontró: " + ruta)

# ============================================
# CARGAR FILA DE AVATARES
# ============================================
func cargar_fila_avatares():
	fila_nombres.add_theme_constant_override("separation", separacion_fila)
	fila_avatares.add_theme_constant_override("separation", separacion_fila)
	
	for child in fila_nombres.get_children():
		child.queue_free()
	for child in fila_avatares.get_children():
		child.queue_free()
	
	avatars_fila.clear()
	
	await get_tree().process_frame
	
	var jugadores = Global.get_jugadores()
	
	for jugador in jugadores:
		var nombre = jugador.get("nombre", "???")
		var color = jugador.get("color", "")
		
		var label = Label.new()
		label.name = "LBL_" + nombre
		label.text = nombre
		label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		label.vertical_alignment = VERTICAL_ALIGNMENT_TOP
		label.add_theme_font_size_override("font_size", 20)
		label.add_theme_color_override("font_color", Color(1, 1, 1))
		label.custom_minimum_size = tamaño_label
		fila_nombres.add_child(label)
		
		var contenedor_avatar = Control.new()
		contenedor_avatar.custom_minimum_size = tamaño_contenedor_avatar
		
		var avatar = AVATAR_SCENE.instantiate()
		avatar.name = "FILA_" + nombre
		avatar.scale = Vector2(escala_avatar_normal, escala_avatar_normal)
		avatar.position = tamaño_contenedor_avatar / 2
		
		contenedor_avatar.add_child(avatar)
		fila_avatares.add_child(contenedor_avatar)
		
		avatars_fila.append(avatar)
		
		await get_tree().process_frame
		configurar_animacion_fila(avatar, color)
	
	actualizar_turno_visual()

# ============================================
# CONFIGURAR ANIMACIÓN FILA
# ============================================
func configurar_animacion_fila(avatar: Node, color: String):
	var animated_sprite = avatar.find_child("AVATAR_ANIMACION", true, false)
	if not animated_sprite:
		return
	
	var nombre_animacion = "AVATAR_" + color.to_upper().strip_edges()
	if animated_sprite.sprite_frames.has_animation(nombre_animacion):
		animated_sprite.animation = nombre_animacion
		animated_sprite.frame = 0
		animated_sprite.stop()

# ============================================
# ACTUALIZAR TURNO
# ============================================
func actualizar_turno_visual():
	for i in range(avatars_fila.size()):
		var avatar = avatars_fila[i]
		if not is_instance_valid(avatar):
			continue
		
		if i == turno_actual:
			var tween = create_tween()
			tween.tween_property(avatar, "scale", Vector2(escala_avatar_activo, escala_avatar_activo), 0.3)
			avatar.modulate = color_avatar_activo
		else:
			var tween = create_tween()
			tween.tween_property(avatar, "scale", Vector2(escala_avatar_normal, escala_avatar_normal), 0.3)
			avatar.modulate = color_avatar_normal

func siguiente_turno():
	if avatars_fila.size() == 0:
		return
	turno_actual = (turno_actual + 1) % avatars_fila.size()
	actualizar_turno_visual()

# ============================================
# POSICIONES DE AVATARES
# ============================================
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

# ============================================
# CONFIGURAR ANIMACIÓN AVATAR
# ============================================
func configurar_animacion_avatar(avatar: Node, color: String):
	var animated_sprite = avatar.find_child("AVATAR_ANIMACION", true, false)
	if not animated_sprite:
		return
	
	var nombre_animacion = "AVATAR_" + color.to_upper().strip_edges()
	if animated_sprite.sprite_frames.has_animation(nombre_animacion):
		animated_sprite.animation = nombre_animacion
		animated_sprite.frame = 0
		animated_sprite.stop()
		iniciar_ciclo_animacion(animated_sprite)

func iniciar_ciclo_animacion(animated_sprite: AnimatedSprite2D):
	var espera_inicial = randf_range(0.5, tiempo_entre_animaciones)
	await get_tree().create_timer(espera_inicial).timeout
	
	while is_instance_valid(animated_sprite):
		animated_sprite.play()
		await animated_sprite.animation_finished
		animated_sprite.stop()
		animated_sprite.frame = 0
		await get_tree().create_timer(tiempo_entre_animaciones).timeout

# ============================================
# AJUSTAR IMAGEN
# ============================================
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
# INPUT
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
