extends Node2D

var timer: Timer
var conectado: bool = false
var intentos: int = 0
var log_text: String = ""
var log_label: Label = null
var log_panel: ScrollContainer = null

func _ready():
	# CREAR EL PANEL DE LOG SI NO EXISTE
	crear_panel_log()
	
	agregar_log("=== 🚀 INICIO DE UNIRSE_SALA ===")
	agregar_log("SO: " + OS.get_name())
	agregar_log("Versión: " + OS.get_version())
	agregar_log("Timestamp: " + str(Time.get_ticks_msec()))
	
	# Verificar si estamos en Android
	if OS.get_name() == "Android":
		agregar_log("📱 ANDROID DETECTADO")
		agregar_log("Verificando permisos...")
		
		# Mostrar IPs del dispositivo
		var ips = IP.get_local_addresses()
		agregar_log("📡 IPs de este dispositivo:")
		for ip in ips:
			agregar_log("  • " + ip)
	else:
		agregar_log("💻 PC/WINDOWS DETECTADO")
	
	# Conectar botones
	agregar_log("🔗 Conectando botones...")
	if has_node("Panel/BTN_VOLVER"):
		$Panel/BTN_VOLVER.connect("pressed", Callable(self, "on_btn_volver_pressed"))
		agregar_log("✅ Botón VOLVER conectado")
	else:
		agregar_log("❌ ERROR: No se encontró BTN_VOLVER")
	
	if has_node("Panel/BTN_UNIRSE_SALA"):
		$Panel/BTN_UNIRSE_SALA.connect("pressed", Callable(self, "on_btn_unirse_sala_pressed"))
		agregar_log("✅ Botón UNIRSE conectado")
	else:
		agregar_log("❌ ERROR: No se encontró BTN_UNIRSE_SALA")
	
	# Conectar señal de Network
	agregar_log("🔗 Conectando señal de Network...")
	if Network.has_signal("salas_actualizadas"):
		Network.connect("salas_actualizadas", Callable(self, "_on_salas_actualizadas"))
		agregar_log("✅ Señal conectada")
	else:
		agregar_log("❌ ERROR: Network no tiene señal 'salas_actualizadas'")
	
	# INICIAR CONEXIÓN AUTOMÁTICA
	agregar_log("=== 🌐 INICIANDO CONEXIÓN AUTOMÁTICA ===")
	conectar_al_host()
	
	# TIMER para actualizar cada 2 segundos
	agregar_log("⏰ Creando timer de actualización...")
	timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(Callable(self, "on_timer_timeout"))
	add_child(timer)
	agregar_log("✅ Timer iniciado (cada 2 segundos)")
	
	agregar_log("=== ✅ LISTO - ESPERANDO CONEXIÓN ===")

func crear_panel_log():
	# Verificar si existe el panel de log
	if has_node("Panel/LOG_PANEL"):
		log_panel = $Panel/LOG_PANEL
		if has_node("Panel/LOG_PANEL/LOG_LABEL"):
			log_label = $Panel/LOG_PANEL/LOG_LABEL
			agregar_log("📋 Panel de log encontrado")
			return
	
	# Si no existe, CREARLO
	agregar_log("📋 Creando panel de log...")
	
	# Buscar o crear Panel
	var panel = get_node_or_null("Panel")
	if not panel:
		panel = Panel.new()
		panel.name = "Panel"
		panel.size = Vector2(400, 600)
		add_child(panel)
		agregar_log("✅ Panel creado")
	
	# Crear ScrollContainer para el log
	log_panel = ScrollContainer.new()
	log_panel.name = "LOG_PANEL"
	log_panel.position = Vector2(20, 350)
	log_panel.size = Vector2(360, 200)
	log_panel.set_h_scroll(ScrollContainer.SCROLL_MODE_DISABLED)
	panel.add_child(log_panel)
	agregar_log("✅ LOG_PANEL creado")
	
	# Crear Label dentro del ScrollContainer
	log_label = Label.new()
	log_label.name = "LOG_LABEL"
	log_label.autowrap = true
	log_label.size = Vector2(340, 0)
	log_label.text = "=== INICIANDO LOG ===\n"
	log_panel.add_child(log_label)
	agregar_log("✅ LOG_LABEL creado")

func agregar_log(mensaje: String):
	# Agregar timestamp
	var timestamp = Time.get_time_string_from_system()
	var mensaje_completo = "[" + timestamp + "] " + mensaje
	
	# Guardar en la variable
	log_text += mensaje_completo + "\n"
	
	# Actualizar el label si existe
	if log_label:
		log_label.text = log_text
	else:
		# Si no hay label, buscar uno
		if has_node("Panel/LOG_PANEL/LOG_LABEL"):
			log_label = $Panel/LOG_PANEL/LOG_LABEL
			log_label.text = log_text
	
	# También imprimir en consola
	print(mensaje_completo)

func conectar_al_host():
	var ip = "192.168.1.102"
	intentos += 1
	
	agregar_log("")
	agregar_log("=== 🔌 INTENTO #" + str(intentos) + " ===")
	agregar_log("📡 Conectando a: " + ip + ":12345")
	
	# Verificar que el objeto Network existe
	if not Network:
		agregar_log("❌ ERROR: Network no está cargado")
		return
	
	agregar_log("⏳ Llamando a Network.connect_to_host()...")
	
	# ✅ CORREGIDO: Usar AWAIT porque es una coroutine
	var resultado = await Network.connect_to_host(ip)
	
	agregar_log("📊 Resultado: " + str(resultado))
	
	if resultado:
		agregar_log("✅ ¡CONECTADO EXITOSAMENTE!")
		agregar_log("🆔 Peer ID: " + str(Network.peer.get_unique_id()))
		conectado = true
		
		agregar_log("⏳ Esperando 0.5s para estabilizar...")
		await get_tree().create_timer(0.5).timeout
		
		agregar_log("📤 Solicitando lista de salas al host...")
		Network.pedir_salas.rpc_id(1)
		agregar_log("✅ Solicitud enviada")
		
		agregar_log("⏳ Esperando respuesta...")
		await get_tree().create_timer(0.5).timeout
		
		agregar_log("📋 Mostrando salas disponibles...")
		mostrar_salas()
	else:
		agregar_log("❌ FALLO EN CONEXIÓN")
		agregar_log("🔍 Posibles causas:")
		agregar_log("  1. 🔥 Firewall bloqueando el puerto 12345")
		agregar_log("  2. 💻 El host no está ejecutándose")
		agregar_log("  3. 🌐 No están en la misma red")
		agregar_log("  4. 📡 IP incorrecta (debe ser 192.168.1.102)")
		agregar_log("  5. 🔒 Faltan permisos INTERNET en Android")
		
		if intentos < 5:
			agregar_log("⏳ Reintentando en 2 segundos...")
		else:
			agregar_log("⚠️ No se pudo conectar después de 5 intentos")
			agregar_log("🔧 SOLUCIONES:")
			agregar_log("  • Desactiva firewall en PC")
			agregar_log("  • Exporta con permisos INTERNET")
			agregar_log("  • Verifica la IP del PC con ipconfig")

func _on_salas_actualizadas():
	agregar_log("")
	agregar_log("=== 📡 SEÑAL RECIBIDA: salas_actualizadas ===")
	agregar_log("📦 Datos recibidos: " + str(Network.salas))
	mostrar_salas()

func on_timer_timeout():
	if conectado:
		agregar_log("🔄 Timer: Solicitando salas...")
		Network.pedir_salas.rpc_id(1)
		await get_tree().create_timer(0.3).timeout
		mostrar_salas()
	else:
		if intentos < 5:
			agregar_log("⏳ Timer: No conectado, reintentando...")
			conectar_al_host()

func mostrar_salas():
	# Verificar que existe LISTA_SALA
	if not has_node("Panel/LISTA_SALA"):
		agregar_log("❌ ERROR: No se encontró LISTA_SALA en la escena")
		return
	
	$Panel/LISTA_SALA.clear()
	
	# Verificar que Network tiene get_salas
	if not Network.has_method("get_salas"):
		agregar_log("❌ ERROR: Network.get_salas no existe")
		$Panel/LISTA_SALA.add_item("Error: Función no encontrada")
		return
	
	var salas = Network.get_salas()
	
	agregar_log("")
	agregar_log("=== 📋 LISTA DE SALAS ===")
	agregar_log("Cantidad: " + str(salas.size()))
	
	if salas.size() > 0:
		for sala in salas:
			$Panel/LISTA_SALA.add_item(sala)
			agregar_log("  ✅ " + sala)
		
		$Panel/LISTA_SALA.select(0)
		agregar_log("✅ Primera sala seleccionada")
	else:
		$Panel/LISTA_SALA.add_item("--- No hay salas ---")
		agregar_log("❌ No hay salas disponibles")
		
		if conectado:
			agregar_log("ℹ️ Conectado pero sin salas")
			agregar_log("ℹ️ Asegúrate de haber creado una sala en el PC")

func on_btn_volver_pressed():
	agregar_log("🔙 Volviendo al menú principal")
	get_tree().change_scene_to_file("res://SCENE/MAIN_MENU.tscn")

func on_btn_unirse_sala_pressed():
	agregar_log("")
	agregar_log("=== 🎮 BOTÓN UNIRSE PRESIONADO ===")
	
	if not conectado:
		agregar_log("❌ No estás conectado al host")
		agregar_log("ℹ️ Espera a que la conexión se establezca automáticamente")
		return
	
	if not has_node("Panel/TXT_NOMBRE"):
		agregar_log("❌ ERROR: No se encontró TXT_NOMBRE")
		return
	
	var nombre_usuario = $Panel/TXT_NOMBRE.text
	agregar_log("👤 Nombre de usuario: '" + nombre_usuario + "'")
	
	if nombre_usuario.strip_edges() == "":
		agregar_log("❌ Debes ingresar un nombre de usuario")
		return
	
	if not has_node("Panel/LISTA_SALA"):
		agregar_log("❌ ERROR: No se encontró LISTA_SALA")
		return
	
	var selected = $Panel/LISTA_SALA.get_selected_items()
	agregar_log("📋 Items seleccionados: " + str(selected))
	
	if selected.size() > 0:
		var nombre_sala = $Panel/LISTA_SALA.get_item_text(selected[0])
		agregar_log("🏠 Sala seleccionada: '" + nombre_sala + "'")
		
		if nombre_sala != "--- No hay salas ---" and nombre_sala != "Error: Función no encontrada":
			agregar_log("📤 Enviando solicitud de unión...")
			Network.unirse_sala.rpc_id(1, nombre_sala, nombre_usuario)
			Network.sala_actual = nombre_sala
			agregar_log("✅ Solicitud enviada")
			agregar_log("🔄 Cambiando a LOBBY...")
			await get_tree().create_timer(0.3).timeout
			get_tree().change_scene_to_file("res://SCENE/LOBBY.tscn")
		else:
			agregar_log("❌ No hay salas disponibles para unirse")
	else:
		agregar_log("❌ Debes seleccionar una sala de la lista")
