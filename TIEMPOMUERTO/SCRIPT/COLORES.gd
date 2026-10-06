extends Control

var colores_seleccionados: Dictionary = {}
var timer_actualizacion: Timer
var juego_iniciado: bool = false

@onready var label = $Panel/Label
@onready var rich_label = $Panel/RichTextLabel
@onready var btn_listo = $Panel/BTN_LISTO

func _ready():
	print("")
	print("=== COLORES (PC-DM): Iniciando ===")
	print("Sala: " + Network.sala_actual)
	
	# Desactivar BTN_LISTO al inicio
	if btn_listo:
		btn_listo.disabled = true
		if not btn_listo.pressed.is_connected(_on_btn_listo_pressed):
			btn_listo.pressed.connect(_on_btn_listo_pressed)
		print("✅ BTN_LISTO desactivado al inicio")
	
	# Conectar señales
	Network.connect("colores_actualizados", Callable(self, "_on_color_actualizado"))
	
	# Configurar RichTextLabel
	if rich_label:
		rich_label.bbcode_enabled = true
		rich_label.fit_content = true
		rich_label.scroll_active = true
		rich_label.size = Vector2(500, 400)
	
	if label:
		label.text = "🎨 SELECCIÓN DE COLORES"
		label.add_theme_font_size_override("font_size", 24)
	
	# Cargar colores actuales
	cargar_colores_actuales()
	
	# Timer
	timer_actualizacion = Timer.new()
	timer_actualizacion.wait_time = 1.0
	timer_actualizacion.autostart = true
	timer_actualizacion.timeout.connect(_on_timer_timeout)
	add_child(timer_actualizacion)

func cargar_colores_actuales():
	var jugadores = Global.get_jugadores()
	
	for jugador in jugadores:
		var nombre = jugador.get("nombre", "???")
		var color = jugador.get("color", "")
		
		if color != "":
			colores_seleccionados[nombre] = color
			colocar_sello_en_boton(color, nombre)
	
	actualizar_lista()
	verificar_todos_listos()

func _on_timer_timeout():
	cargar_colores_actuales()

func _on_color_actualizado(nombre: String, color: String):
	print("🎨 Color confirmado: " + nombre + " → " + color)
	colores_seleccionados[nombre] = color
	actualizar_lista()
	colocar_sello_en_boton(color, nombre)
	verificar_todos_listos()

# ============================================
# VERIFICAR SI TODOS ELIGIERON COLOR
# ============================================
func verificar_todos_listos():
	var jugadores = Global.get_jugadores()
	var total = jugadores.size()
	var listos = 0
	
	for jugador in jugadores:
		var nombre = jugador.get("nombre", "")
		if nombre in colores_seleccionados:
			listos += 1
	
	print("📊 Jugadores con color: " + str(listos) + "/" + str(total))
	
	if btn_listo:
		if listos >= total and total > 0:
			if btn_listo.disabled:
				btn_listo.disabled = false
				print("✅ ¡TODOS ELIGIERON COLOR! BTN_LISTO habilitado")
		else:
			if not btn_listo.disabled:
				btn_listo.disabled = true
				print("⏳ Faltan colores: " + str(listos) + "/" + str(total))

# ============================================
# BOTÓN LISTO (INICIAR PARTIDA)
# ============================================
func _on_btn_listo_pressed():
	if juego_iniciado:
		return
	
	juego_iniciado = true
	
	print("")
	print("╔═══════════════════════════════════════╗")
	print("║     ¡INICIANDO PARTIDA!               ║")
	print("╚═══════════════════════════════════════╝")
	
	# Notificar a todos los clientes que empieza la PARTIDA
	Network.iniciar_partida.rpc()
	print("✅ Notificación enviada a todos los clientes")
	
	# El PC cambia a la escena del mapa
	await get_tree().create_timer(0.5).timeout
	print("🔄 Host cambiando al MAPA...")
	get_tree().change_scene_to_file("res://SCENE/PC.tscn")

# ============================================
# COLOCAR SELLO EN EL PC
# ============================================
func colocar_sello_en_boton(color: String, nombre_jugador: String):
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
	
	print("📍 Sello colocado en PC: " + color + " (" + nombre_jugador + ")")

# ============================================
# ACTUALIZAR LISTA
# ============================================
func actualizar_lista():
	if not rich_label:
		return
	
	var texto = "[center][b]JUGADORES Y SUS COLORES[/b][/center]\n\n"
	
	var jugadores = Global.get_jugadores()
	
	if jugadores.size() == 0:
		texto += "[color=#888888]Esperando jugadores...[/color]"
	else:
		for jugador in jugadores:
			var nombre = jugador.get("nombre", "???")
			var color = colores_seleccionados.get(nombre, "")
			
			if color != "":
				var color_hex = obtener_color_hex(color)
				texto += "[color=#" + color_hex + "]"
				texto += "✅ " + nombre + " → " + color
				texto += "[/color]\n"
			else:
				texto += "[color=#888888]⏳ " + nombre + " → Esperando...[/color]\n"
	
	rich_label.text = texto

func obtener_color_hex(color_nombre: String) -> String:
	match color_nombre.to_upper():
		"ROJO":     return "FF3333"
		"VERDE":    return "00FF00"
		"AZUL":     return "0088FF"
		"AMARILLO": return "FFFF00"
		"GRIS":     return "AAAAAA"
		"MORADO":   return "9933FF"
		"ROSADO":   return "FF69B4"
		"CAFE":     return "8B4513"
	return "FFFFFF"

# ============================================
# OBTENER BOTÓN POR COLOR
# ============================================
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
