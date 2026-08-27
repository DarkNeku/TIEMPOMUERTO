extends Node2D

@onready var avatar_node = $Panel/AVATAR
@onready var avatar_sprite = $Panel/AVATAR/AVATAR_ANIMACION
var color_seleccionado = ""
var listo = false
var timer_espera = Timer.new()

func _ready():
	avatar_node.visible = false
	
	if avatar_sprite == null:
		print("❌ ERROR: No se encontró AnimatedSprite2D")
		return
	
	print("📋 Animaciones disponibles:")
	for anim in avatar_sprite.sprite_frames.get_animation_names():
		print("  • " + anim)
	
	timer_espera.wait_time = 3.0
	timer_espera.one_shot = true
	timer_espera.timeout.connect(_reproducir_animacion_nuevamente)
	add_child(timer_espera)
	
	avatar_sprite.animation_finished.connect(_on_animacion_terminada)
	
	$Panel/VBoxContainer/HBoxContainer/BTN_ROJO.pressed.connect(_on_btn_color_pressed.bind("ROJO"))
	$Panel/VBoxContainer/HBoxContainer/BTN_AZUL.pressed.connect(_on_btn_color_pressed.bind("AZUL"))
	$Panel/VBoxContainer/HBoxContainer/BTN_AMARILLO.pressed.connect(_on_btn_color_pressed.bind("AMARILLO"))
	$Panel/VBoxContainer/HBoxContainer/BTN_MORADO.pressed.connect(_on_btn_color_pressed.bind("MORADO"))
	
	$Panel/VBoxContainer/HBoxContainer2/BTN_CAFE.pressed.connect(_on_btn_color_pressed.bind("CAFE"))
	$Panel/VBoxContainer/HBoxContainer2/BTN_ROSADO.pressed.connect(_on_btn_color_pressed.bind("ROSADO"))
	$Panel/VBoxContainer/HBoxContainer2/BTN_VERDE.pressed.connect(_on_btn_color_pressed.bind("VERDE"))
	$Panel/VBoxContainer/HBoxContainer2/BTN_GRIS.pressed.connect(_on_btn_color_pressed.bind("GRIS"))
	
	$Panel/BTN_LISTO.pressed.connect(_on_btn_listo_pressed)

func _on_btn_color_pressed(color: String):
	if listo:
		print("⚠️ Ya seleccionaste un color.")
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
	
	print("🎨 Avatar cambiado a: " + color)

func _on_animacion_terminada():
	# ✅ SIEMPRE reiniciar la animación, incluso después de LISTO
	timer_espera.start()

func _reproducir_animacion_nuevamente():
	# ✅ SIEMPRE reproducir, incluso después de LISTO
	avatar_sprite.play()

func _on_btn_listo_pressed():
	if color_seleccionado == "":
		print("⚠️ Selecciona un color primero")
		return
	
	if listo:
		print("ℹ️ Ya estás listo. Color: " + color_seleccionado)
		return
	
	listo = true
	colocar_sello_sobre_boton(color_seleccionado)
	desactivar_botones_colores()
	
	# ✅ La animación sigue reproduciéndose automáticamente
	# ✅ No detenemos nada
	
	print("✅ ¡LISTO! Color seleccionado: " + color_seleccionado)

func colocar_sello_sobre_boton(color: String):
	var boton = get_boton_por_color(color)
	if boton:
		var sello = Sprite2D.new()
		sello.texture = load("res://ASSET/Avatars/NO DISPONIBLE.png")
		
		var tamaño = boton.size
		sello.position = Vector2(tamaño.x / 2, tamaño.y / 2)
		sello.scale = Vector2(0.35, 0.35)
		
		boton.add_child(sello)
		boton.disabled = true
		
		print("📍 Sello centrado en " + color)

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
