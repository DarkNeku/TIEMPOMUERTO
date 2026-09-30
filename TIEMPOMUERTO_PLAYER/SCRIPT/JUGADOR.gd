extends Control

@onready var imagen_room = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM/IMAGEN_ROOM
@onready var contenedor_room = $VBoxContainer/PNL_ROOM/CONTENEDOR_ROOM

# ============================================
# ALEJAMIENTO INICIAL
# ============================================
var factor_alejamiento: float = 0.9

# ============================================
# RANGO DE ZOOM
# ============================================
var zoom_minimo: float = 0.9
var zoom_maximo: float = 2.0
var velocidad_zoom: float = 0.05

# ============================================
# MOVIMIENTO (dinámico según el zoom)
# ============================================
var sensibilidad_movimiento: float = 0.5
var margen_extra: float = 0.0  # Margen extra (0 = justo hasta el borde)

# Variables internas
var zoom_actual: float = 1.0
var posicion_inicial_imagen: Vector2 = Vector2.ZERO
var offset_movimiento: Vector2 = Vector2.ZERO
var limite_movimiento_actual: Vector2 = Vector2.ZERO  # ← Dinámico según zoom

# Variables para gestos táctiles
var toques_activos: Dictionary = {}
var distancia_inicial: float = 0.0
var zoom_inicial: float = 1.0
var arrastrando: bool = false
var posicion_inicial_mouse: Vector2 = Vector2.ZERO
var offset_inicial_arrastre: Vector2 = Vector2.ZERO

func _ready():
	cargar_habitacion("Room00")
	set_process_input(true)
	print("=== JUGADOR: Iniciado ===")

func cargar_habitacion(nombre_habitacion: String):
	var ruta = "res://ASSET/Rooms/" + nombre_habitacion + ".png"
	var textura = load(ruta)
	
	if textura:
		imagen_room.texture = textura
		await get_tree().process_frame
		ajustar_imagen_inicial()
		print("✅ Habitación cargada: " + nombre_habitacion)
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
	imagen_room.scale = Vector2(zoom_actual, zoom_actual)
	
	centrar_imagen()

func centrar_imagen():
	if not imagen_room.texture:
		return
	
	var tamaño_contenedor = contenedor_room.size
	var tamaño_imagen = imagen_room.texture.get_size()
	
	var ancho_escalado = tamaño_imagen.x * zoom_actual
	var alto_escalado = tamaño_imagen.y * zoom_actual
	
	# Posición base (centrada)
	posicion_inicial_imagen = Vector2(
		(tamaño_contenedor.x - ancho_escalado) / 2,
		(tamaño_contenedor.y - alto_escalado) / 2
	)
	
	# ✅ Calcular el límite de movimiento DINÁMICO
	calcular_limite_movimiento(tamaño_contenedor, ancho_escalado, alto_escalado)
	
	# Aplicar offset dentro del nuevo límite
	offset_movimiento.x = clamp(offset_movimiento.x, -limite_movimiento_actual.x, limite_movimiento_actual.x)
	offset_movimiento.y = clamp(offset_movimiento.y, -limite_movimiento_actual.y, limite_movimiento_actual.y)
	
	imagen_room.position = posicion_inicial_imagen + offset_movimiento

# ============================================
# ✅ CALCULAR LÍMITE DE MOVIMIENTO DINÁMICO
# ============================================
func calcular_limite_movimiento(tamaño_contenedor: Vector2, ancho_escalado: float, alto_escalado: float):
	# Si la imagen es MÁS GRANDE que el contenedor → puede moverse
	# Si la imagen es MÁS PEQUEÑA que el contenedor → no puede moverse (límite 0)
	
	var exceso_x = max(0, ancho_escalado - tamaño_contenedor.x) / 2
	var exceso_y = max(0, alto_escalado - tamaño_contenedor.y) / 2
	
	# Aplicar margen extra si lo quieres
	limite_movimiento_actual = Vector2(
		exceso_x + margen_extra,
		exceso_y + margen_extra
	)
	
	# Debug
	# print("📏 Límite movimiento: X=" + str(limite_movimiento_actual.x) + " Y=" + str(limite_movimiento_actual.y))

# ============================================
# INPUT (mouse, táctil)
# ============================================
func _input(event: InputEvent):
	# ============================================
	# MOUSE (PC)
	# ============================================
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
	
	# ============================================
	# TÁCTIL (Android)
	# ============================================
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

# ============================================
# APLICAR MOVIMIENTO (con límite dinámico)
# ============================================
func aplicar_movimiento(nuevo_offset: Vector2):
	# Limitar según el límite dinámico
	offset_movimiento = Vector2(
		clamp(nuevo_offset.x, -limite_movimiento_actual.x, limite_movimiento_actual.x),
		clamp(nuevo_offset.y, -limite_movimiento_actual.y, limite_movimiento_actual.y)
	)
	
	imagen_room.position = posicion_inicial_imagen + offset_movimiento

# ============================================
# APLICAR ZOOM
# ============================================
func aplicar_zoom(nuevo_zoom: float):
	zoom_actual = clamp(nuevo_zoom, zoom_minimo, zoom_maximo)
	imagen_room.scale = Vector2(zoom_actual, zoom_actual)
	centrar_imagen()  # ← Recalcula límites y reposiciona
