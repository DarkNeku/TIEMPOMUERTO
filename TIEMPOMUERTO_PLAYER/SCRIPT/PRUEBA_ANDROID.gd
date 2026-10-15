extends Control

@onready var nombres_label: RichTextLabel = $Panel/NOMBRES
@onready var btn_listo: Button = $Panel/BTN_LISTO_PRUEBA

var jugadores_disponibles: Array = []
var reservados: Dictionary = {}
var nombre_seleccionado: String = ""
var color_seleccionado: String = ""
var saliendo: bool = false

func _ready():
	print("")
	print("=== PRUEBA_ANDROID: Iniciando ===")
	
	# Configurar RichTextLabel
	nombres_label.bbcode_enabled = true
	if not nombres_label.meta_clicked.is_connected(_on_nombre_clickeado):
		nombres_label.meta_clicked.connect(_on_nombre_clickeado)
	nombres_label.text = "[center]Conectando al host...[/center]"
	
	# Deshabilitar botón hasta elegir nombre
	btn_listo.disabled = true
	if not btn_listo.pressed.is_connected(_on_btn_listo_pressed):
		btn_listo.pressed.connect(_on_btn_listo_pressed)
	
	# Conectar señales de Network
	if not Network.jugadores_prueba_recibidos.is_connected(_on_jugadores_recibidos):
		Network.jugadores_prueba_recibidos.connect(_on_jugadores_recibidos)
	if not Network.reserva_exitosa.is_connected(_on_reserva_exitosa):
		Network.reserva_exitosa.connect(_on_reserva_exitosa)
	if not Network.reserva_fallida.is_connected(_on_reserva_fallida):
		Network.reserva_fallida.connect(_on_reserva_fallida)
	if not Network.reservas_actualizadas.is_connected(_on_reservas_actualizadas):
		Network.reservas_actualizadas.connect(_on_reservas_actualizadas)
	
	# Conectar al host automáticamente
	conectar_al_host()

func conectar_al_host():
	if saliendo:
		return
	
	print("🔎 Buscando host...")
	var hosts = await Network.descubrir_host(3.0)
	
	if saliendo:
		return
	
	if hosts.size() == 0:
		nombres_label.text = "[center][color=red]❌ No se encontró el host[/color]\nReintentando...[/center]"
		await get_tree().create_timer(2.0).timeout
		if not saliendo:
			conectar_al_host()
		return
	
	var ip = hosts[0]
	print("✅ Host encontrado en " + ip)
	
	if not Network.preparar_cliente(ip, 12345):
		nombres_label.text = "[center][color=red]❌ Error al preparar cliente[/color][/center]"
		return
	
	var ok = await Network.esperar_conexion(5.0)
	if saliendo:
		return
	
	if not ok:
		nombres_label.text = "[center][color=red]❌ No se pudo conectar[/color]\nReintentando...[/center]"
		await get_tree().create_timer(2.0).timeout
		if not saliendo:
			conectar_al_host()
		return
	
	print("✅ Conectado al host. Pidiendo lista de jugadores...")
	nombres_label.text = "[center]Conectado. Cargando jugadores...[/center]"
	
	# Pedir lista de jugadores al host
	Network.solicitar_lista_jugadores_prueba()

func _on_jugadores_recibidos(jugadores: Array, reservados_actuales: Dictionary):
	if saliendo:
		return
	print("📋 Jugadores recibidos: " + str(jugadores.size()))
	jugadores_disponibles = jugadores
	reservados = reservados_actuales
	actualizar_lista()

func _on_reservas_actualizadas(reservados_actuales: Dictionary):
	if saliendo:
		return
	reservados = reservados_actuales
	actualizar_lista()

func actualizar_lista():
	if saliendo:
		return
	
	var texto = "[center][b]ELEGÍ TU PERSONAJE[/b][/center]\n\n"
	
	for jugador in jugadores_disponibles:
		var nombre = jugador.get("nombre", "???")
		var color = jugador.get("color", "")
		var color_hex = obtener_color_hex(color)
		
		if nombre in reservados:
			if nombre == nombre_seleccionado:
				texto += "[center][color=#" + color_hex + "][b]▶ " + nombre + " (vos)[/b][/color][/center]\n"
			else:
				texto += "[center][color=#555555][s]" + nombre + " (ocupado)[/s][/color][/center]\n"
		else:
			texto += "[center][url=" + nombre + "][color=#" + color_hex + "][b]" + nombre + "[/b][/color][/url][/center]\n"
	
	# ✅ Esperar un frame antes de reemplazar el texto (evita el error de RichTextLabel)
	await get_tree().process_frame
	if saliendo:
		return
	nombres_label.text = texto

func _on_nombre_clickeado(meta):
	if saliendo:
		return
	
	var nombre = str(meta)
	print("👆 Click en: " + nombre)
	
	if nombre in reservados:
		print("⚠️ Ya está reservado")
		return
	
	nombre_seleccionado = nombre
	
	for j in jugadores_disponibles:
		if j.get("nombre", "") == nombre:
			color_seleccionado = j.get("color", "")
			break
	
	print("✅ Seleccionado: " + nombre_seleccionado + " → " + color_seleccionado)
	
	btn_listo.disabled = false
	actualizar_lista()

func _on_btn_listo_pressed():
	if saliendo:
		return
	if nombre_seleccionado == "":
		return
	
	print("📤 Reservando: " + nombre_seleccionado)
	btn_listo.disabled = true
	Network.solicitar_reserva_jugador(nombre_seleccionado)

func _on_reserva_exitosa(nombre: String):
	if saliendo:
		return
	saliendo = true
	
	print("✅ ¡Reserva exitosa! " + nombre)
	
	Global.set_mi_nombre(nombre)
	Global.actualizar_color_jugador(nombre, color_seleccionado)
	
	await get_tree().create_timer(0.3).timeout
	get_tree().change_scene_to_file("res://SCENE/JUGADOR.tscn")

func _on_reserva_fallida(nombre: String, razon: String):
	if saliendo:
		return
	print("❌ Reserva fallida: " + razon)
	nombre_seleccionado = ""
	btn_listo.disabled = true
	actualizar_lista()

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
