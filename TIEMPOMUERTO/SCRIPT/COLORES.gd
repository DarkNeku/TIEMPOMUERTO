extends Control

var colores_seleccionados: Array[String] = []
var btn_listo: Button
var lbl_info: Label

func _ready():
	btn_listo = $Panel/BTN_LISTO
	lbl_info = $Panel/Label # Asegurate de tener este Label en la escena
	
	btn_listo.disabled = true
	btn_listo.pressed.connect(_on_btn_listo_pressed)
	
	# Lista de los 8 botones
	var botones = [
		"BTN_ROJO", "BTN_AZUL", "BTN_AMARILLO", "BTN_MORADO",
		"BTN_CAFE", "BTN_ROSADO", "BTN_VERDE", "BTN_GRIS"
	]
	
	for nombre_boton in botones:
		var btn = find_child(nombre_boton, true, false)
		if btn:
			btn.disabled = false 
			btn.mouse_filter = Control.MOUSE_FILTER_STOP
			
			# Limpiar cualquier sello que haya quedado
			for child in btn.get_children():
				if child is Sprite2D and child.name == "SELLO":
					child.queue_free()
			
			btn.pressed.connect(_on_color_pressed.bind(nombre_boton.replace("BTN_", ""), btn))
	
	actualizar_ui()

func _on_color_pressed(color: String, boton: Button):
	if color in colores_seleccionados:
		colores_seleccionados.erase(color)
		quitar_sello(boton)
	else:
		colores_seleccionados.append(color)
		colocar_sello(boton)
	
	actualizar_ui()

func colocar_sello(boton: Button):
	for child in boton.get_children():
		if child is Sprite2D and child.name == "SELLO": return
	
	var sello = Sprite2D.new()
	sello.name = "SELLO"
	sello.texture = load("res://ASSET/Avatars/NO DISPONIBLE.png")
	sello.position = boton.size / 2
	sello.scale = Vector2(0.35, 0.35) 
	boton.add_child(sello)

func quitar_sello(boton: Button):
	for child in boton.get_children():
		if child is Sprite2D and child.name == "SELLO":
			child.queue_free()

func actualizar_ui():
	var cant_jugadores = Global.get_cant_jugadores()
	var elegidos = colores_seleccionados.size()
	
	if lbl_info:
		lbl_info.text = "Elegí los colores (" + str(elegidos) + "/" + str(cant_jugadores) + ")"
	
	if elegidos == cant_jugadores:
		btn_listo.disabled = false
	else:
		btn_listo.disabled = true

func _on_btn_listo_pressed():
	for color in colores_seleccionados:
		Global.agregar_jugador_color(color)
	
	print("✅ Colores confirmados: " + str(colores_seleccionados))
	get_tree().change_scene_to_file("res://SCENE/PC.tscn")
