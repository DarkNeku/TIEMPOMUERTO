extends Node2D

var panel_mapa
var mapa_contenido

# Arrastre
var arrastrando = false
var posicion_inicial_mouse = Vector2()
var posicion_inicial_mapa = Vector2()

# Zoom
var zoom_actual = 1.0
var zoom_minimo = 0.3
var zoom_maximo = 3.0
var velocidad_zoom = 0.1

# Límites de movimiento (en píxeles)
var limite_mapa = 600  # 6 habitaciones * 100px aprox

func _ready():
	panel_mapa = get_node("Panel/PANEL_MAPA")
	mapa_contenido = get_node("Panel/PANEL_MAPA/MAPA_CONTENIDO")
	
	panel_mapa.mouse_filter = Control.MOUSE_FILTER_STOP
	
	cargar_sala("Room00")

func cargar_sala(nombre_sala: String):
	for child in mapa_contenido.get_children():
		child.queue_free()
	
	var ruta = "res://ASSET/Rooms/" + nombre_sala + ".png"
	var textura = load(ruta)
	
	if textura:
		var sprite = Sprite2D.new()
		sprite.texture = textura
		sprite.name = "FONDO_SALA"
		
		var tamaño_panel = panel_mapa.size
		var ancho_original = textura.get_width()
		var alto_original = textura.get_height()
		
		var escala_x = tamaño_panel.x / ancho_original
		var escala_y = tamaño_panel.y / alto_original
		var escala = min(escala_x, escala_y)
		
		sprite.set_meta("escala_base", escala)
		sprite.scale = Vector2(escala, escala)
		sprite.position = tamaño_panel / 2
		
		mapa_contenido.add_child(sprite)
		
		zoom_actual = 1.0
		aplicar_zoom()
		
		print("✅ Sala cargada: " + nombre_sala)
	else:
		print("❌ No se encontró: " + ruta)

func _input(event: InputEvent):
	# ZOOM
	if event is InputEventMouseButton:
		if event.button_index == MOUSE_BUTTON_WHEEL_UP:
			zoom_actual = min(zoom_actual + velocidad_zoom, zoom_maximo)
			aplicar_zoom()
		
		elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
			zoom_actual = max(zoom_actual - velocidad_zoom, zoom_minimo)
			aplicar_zoom()
		
		# ARRASTRE
		if event.button_index == MOUSE_BUTTON_LEFT:
			var pos_mouse = get_global_mouse_position()
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
		
		# Calcular nueva posición
		var nueva_posicion = posicion_inicial_mapa + delta
		
		# Aplicar límites
		nueva_posicion.x = clamp(nueva_posicion.x, -limite_mapa, limite_mapa)
		nueva_posicion.y = clamp(nueva_posicion.y, -limite_mapa, limite_mapa)
		
		mapa_contenido.position = nueva_posicion

func aplicar_zoom():
	var sprite = mapa_contenido.get_node_or_null("FONDO_SALA")
	if not sprite:
		return
	
	var escala_base = sprite.get_meta("escala_base", 1.0)
	var nueva_escala = escala_base * zoom_actual
	sprite.scale = Vector2(nueva_escala, nueva_escala)
	
	var tamaño_panel = panel_mapa.size
	sprite.position = tamaño_panel / 2

func cambiar_sala(nombre_sala: String):
	zoom_actual = 1.0
	cargar_sala(nombre_sala)
