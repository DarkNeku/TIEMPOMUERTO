extends Control

@onready var avatar_node = $Panel/AVATAR
@onready var avatar_sprite = $Panel/AVATAR/AVATAR_ANIMACION
var color_seleccionado = ""
var listo = false
var timer_espera = Timer.new()

func _ready():
	print("")
	print("=== COLORES (CELULAR): Iniciando ===")
	print("Mi nombre: " + Global.get_mi_nombre())
	
	avatar_node.visible = false
	
	if avatar_sprite == null:
		print("❌ ERROR: No se encontró AnimatedSprite2D")
		return
	
	timer_espera.wait_time = 3.0
	timer_espera.one_shot = true
	timer_espera.timeout.connect(_reproducir_animacion_nuevamente)
	add_child(timer_espera)
	
	avatar_sprite.animation_finished.connect(_on_animacion_terminada)
	
	# Conectar señales de red
	Network.connect("colores_actualizados", Callable(self, "_on_color_actualizado"))
	Network.connect("color_ya_usado_signal", Callable(self, "_on_color_ya_usado"))
	
	# Conectar botones
	$Panel/VBoxContainer/HBoxContainer/BTN_ROJO.pressed.connect(_on_btn_color_pressed.bind("ROJO"))
	$Panel/VBoxContainer/HBoxContainer/BTN_AZUL.pressed.connect(_on_btn_color_pressed.bind("AZUL"))
	$Panel/VBoxContainer/HBoxContainer/BTN_AMARILLO.pressed.connect(_on_btn_color_pressed.bind("AMARILLO"))
	$Panel/VBoxContainer/HBoxContainer/BTN_MORADO.pressed.connect(_on_btn_color_pressed.bind("MORADO"))
	
	$Panel/VBoxContainer/HBoxContainer2/BTN_CAFE.pressed.connect(_on_btn_color_pressed.bind("CAFE"))
	$Panel/VBoxContainer/HBoxContainer2/BTN_ROSADO.pressed.connect(_on_btn_color_pressed.bind("ROSADO"))
	$Panel/VBoxContainer/HBoxContainer2/BTN_VERDE.pressed.connect(_on_btn_color_pressed.bind("VERDE"))
	$Panel/VBoxContainer/HBoxContainer2/BTN_GRIS.pressed.connect(_on_btn_color_pressed.bind("GRIS"))
	
	$Panel/BTN_LISTO.pressed.connect(_on_btn_listo_pressed)
	
	cargar_colores_ya_usados()

func cargar_colores_ya_usados():
	var jugadores = Global.get_jugadores()
	
	for jugador in jugadores:
		var nombre = jugador.get("nombre", "")
		var color = jugador.get("color", "")
		
		if color != "":
			Network.colores_usados[color] = nombre
			bloquear_boton_color(color, nombre)
			
			if nombre == Global.get_mi_nombre():
				color_seleccionado = color
				listo = true
				desactivar_botones_colores()

# ============================================
# AL PRESIONAR UN COLOR (solo previsualiza)
# ============================================
func _on_btn_color_pressed(color: String):
	if listo:
		print("⚠️ Ya confirmaste un color.")
		return
	
	if color in Network.colores_usados:
		var jugador_con_ese_color = Network.colores_usados[color]
		if jugador_con_ese_color != Global.get_mi_nombre():
			print("❌ El color " + color + " ya está en uso por " + jugador_con_ese_color)
			return
	
	color_seleccionado = color
	avatar_node.visible = true
	
	var animacion = "AVATAR_" + color
	
	if not avatar_sprite.sprite_frames.has_animation(animacion):
		print("❌ ERROR: Animación '" + animacion + "' no existe")
		return
	
	avatar_sprite.animation = animacion
	avatar_sprite.play()
	avatar_sprite.speed_scale = 1.0
	
	print("🎨 Color SELECCIONADO (sin confirmar): " + color)

# ============================================
# AL PRESIONAR LISTO (aquí SÍ se bloquea)
# ============================================
func _on_btn_listo_pressed():
	if color_seleccionado == "":
		print("⚠️ Selecciona un color primero")
		return
	
	if listo:
		print("ℹ️ Ya estás listo. Color: " + color_seleccionado)
		return
	
	if color_seleccionado in Network.colores_usados:
		var jugador_con_ese_color = Network.colores_usados[color_seleccionado]
		if jugador_con_ese_color != Global.get_mi_nombre():
			print("❌ El color " + color_seleccionado + " ya está en uso por " + jugador_con_ese_color)
			return
	
	listo = true
	
	# ENVIAR COLOR AL HOST
	enviar_color_al_host(color_seleccionado)
	
	# Bloquear todos los botones en este celular
	desactivar_botones_colores()
	colocar_sello_sobre_boton(color_seleccionado)
	
	print("✅ ¡LISTO! Color confirmado: " + color_seleccionado)

# ============================================
# ENVIAR COLOR AL HOST
# ============================================
func enviar_color_al_host(color: String):
	var mi_nombre = Global.get_mi_nombre()
	
	if mi_nombre == "":
		print("❌ ERROR: No sé quién soy.")
		return
	
	print("📤 Confirmando color al host: " + mi_nombre + " → " + color)
	Network.colores_usados[color] = mi_nombre
	Network.enviar_mi_color(mi_nombre, color)

# ============================================
# CUANDO OTRO JUGADOR CONFIRMA SU COLOR
# ============================================
func _on_color_actualizado(nombre: String, color: String):
	print("🎨 Color confirmado por otro: " + nombre + " → " + color)
	
	if nombre != Global.get_mi_nombre():
		bloquear_boton_color(color, nombre)

func _on_color_ya_usado(color: String, jugador_que_lo_tiene: String):
	print("❌ El color " + color + " ya está en uso por " + jugador_que_lo_tiene)

# ============================================
# BLOQUEAR UN BOTÓN CON SELLO
# ============================================
func bloquear_boton_color(color: String, nombre_jugador: String):
	var boton = get_boton_por_color(color)
	if not boton:
		return
	
	for child in boton.get_children():
		if child is Sprite2D and child.name == "SELLO":
			return
	
	var sello = Sprite2D.new()
	sello.name = "SELLO"
	sello.texture = load("res://ASSET/Avatars/NO DISPONIBLE.png")
	
	var tamaño = boton.size
	sello.position = Vector2(tamaño.x / 2, tamaño.y / 2)
	sello.scale = Vector2(0.35, 0.35)
	
	boton.add_child(sello)
	boton.disabled = true
	
	print("📍 Sello colocado en " + color + " (usado por " + nombre_jugador + ")")

# ============================================
# OTROS
# ============================================
func _on_animacion_terminada():
	timer_espera.start()

func _reproducir_animacion_nuevamente():
	avatar_sprite.play()

func colocar_sello_sobre_boton(color: String):
	bloquear_boton_color(color, Global.get_mi_nombre())

func get_boton_por_color(color: String):
	match color:
		"ROJO": return $Panel/VBoxContainer/HBoxContainer/BTN_ROJO
		"AZUL": return $Panel/VBoxContainer/HBoxContainer/BTN_AZUL
		"AMARILLO": return $Panel/VBoxContainer/HBoxContainer/BTN_AMARILLO
		"MORADO": return $Panel/VBoxContainer/HBoxContainer/BTN_MORADO
		"CAFE": return $Panel/VBoxContainer/HBoxContainer2/BTN_CAFE
		"ROSADO": return $Panel/VBoxContainer/HBoxContainer2/BTN_ROSADO
		"VERDE": return $Panel/VBoxContainer/HBoxContainer2/BTN_VERDE
		"GRIS": return $Panel/VBoxContainer/HBoxContainer2/BTN_GRIS
	return null

func desactivar_botones_colores():
	$Panel/VBoxContainer/HBoxContainer/BTN_ROJO.disabled = true
	$Panel/VBoxContainer/HBoxContainer/BTN_AZUL.disabled = true
	$Panel/VBoxContainer/HBoxContainer/BTN_AMARILLO.disabled = true
	$Panel/VBoxContainer/HBoxContainer/BTN_MORADO.disabled = true
	
	$Panel/VBoxContainer/HBoxContainer2/BTN_CAFE.disabled = true
	$Panel/VBoxContainer/HBoxContainer2/BTN_ROSADO.disabled = true
	$Panel/VBoxContainer/HBoxContainer2/BTN_VERDE.disabled = true
	$Panel/VBoxContainer/HBoxContainer2/BTN_GRIS.disabled = true
