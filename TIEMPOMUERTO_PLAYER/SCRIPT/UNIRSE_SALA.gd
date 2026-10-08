extends Control

var timer: Timer
var conectado: bool = false
var conectando: bool = false
var intentos: int = 0
var log_text: String = ""
var log_label: Label = null
var log_panel: Control = null

func _ready():
	crear_panel_log()
	
	agregar_log("=== 🚀 INICIO DE UNIRSE_SALA ===")
	agregar_log("SO: " + OS.get_name())
	
	if OS.get_name() == "Android":
		agregar_log("📱 ANDROID DETECTADO")
		var ips = IP.get_local_addresses()
		agregar_log("📡 IPs de este dispositivo:")
		for ip in ips:
			agregar_log("  • " + ip)
	else:
		agregar_log("💻 PC/WINDOWS DETECTADO")
	
	# Conectar botones
	if has_node("Panel/BTN_VOLVER"):
		$Panel/BTN_VOLVER.connect("pressed", Callable(self, "on_btn_volver_pressed"))
	
	if has_node("Panel/BTN_UNIRSE_SALA"):
		$Panel/BTN_UNIRSE_SALA.connect("pressed", Callable(self, "on_btn_unirse_sala_pressed"))
	
	# Conectar señal
	if Network.has_signal("salas_actualizadas"):
		Network.connect("salas_actualizadas", Callable(self, "_on_salas_actualizadas"))
	
	# INICIAR CONEXIÓN AUTOMÁTICA
	agregar_log("=== 🌐 INICIANDO CONEXIÓN AUTOMÁTICA ===")
	conectar_al_host()
	
	# TIMER
	timer = Timer.new()
	timer.wait_time = 2.0
	timer.autostart = true
	timer.one_shot = false
	timer.timeout.connect(Callable(self, "on_timer_timeout"))
	add_child(timer)

func crear_panel_log():
	if has_node("Panel/LOG_PANEL"):
		log_panel = $Panel/LOG_PANEL
		if has_node("Panel/LOG_PANEL/LOG_LABEL"):
			log_label = $Panel/LOG_PANEL/LOG_LABEL
			return
	
	var panel = get_node_or_null("Panel")
	if not panel:
		panel = Panel.new()
		panel.name = "Panel"
		panel.size = Vector2(400, 600)
		add_child(panel)
	
	var scroller := ScrollContainer.new()
	scroller.name = "LOG_PANEL"
	scroller.position = Vector2(20, 350)
	scroller.size = Vector2(360, 200)
	scroller.set_h_scroll(ScrollContainer.SCROLL_MODE_DISABLED)
	panel.add_child(scroller)
	log_panel = scroller
	
	log_label = Label.new()
	log_label.name = "LOG_LABEL"
	log_label.autowrap = true
	log_label.size = Vector2(340, 0)
	log_label.text = "=== INICIANDO LOG ===\n"
	scroller.add_child(log_label)

func agregar_log(mensaje: String):
	var timestamp = Time.get_time_string_from_system()
	var mensaje_completo = "[" + timestamp + "] " + mensaje
	
	log_text += mensaje_completo + "\n"
	
	if log_label:
		log_label.text = log_text
	elif has_node("Panel/LOG_PANEL/LOG_LABEL"):
		log_label = $Panel/LOG_PANEL/LOG_LABEL
		log_label.text = log_text
	
	print(mensaje_completo)

func conectar_al_host():
	if conectando:
		return
	conectando = true
	intentos += 1
	
	agregar_log("")
	agregar_log("=== 🔌 INTENTO #" + str(intentos) + " ===")
	
	if not Network:
		agregar_log("❌ ERROR: Network no está cargado")
		conectando = false
		return
	
	var puerto: int = 12345
	if Global and Global.puerto > 0:
		puerto = Global.puerto
	
	var ip_guardada: String = ""
	if Global and Global.ip_host:
		ip_guardada = Global.ip_host
	
	agregar_log("🔎 Buscando host en la red local...")
	var hosts: Array[String] = await Network.descubrir_host(3.0, ip_guardada)
	agregar_log("📡 Hosts que respondieron: " + str(hosts))
	
	var candidatas: Array[String] = []
	candidatas.append_array(hosts)
	
	if candidatas.size() == 0 and ip_guardada.strip_edges() != "":
		agregar_log("ℹ️ Probando IP guardada " + ip_guardada)
		candidatas.append(ip_guardada.strip_edges())
	
	if candidatas.size() == 0:
		agregar_log("❌ NO SE ENCONTRÓ NINGÚN HOST")
		_conexion_fallida()
		return
	
	for ip in candidatas:
		var margen: float = 4.0 if hosts.has(ip) else 1.5
		if await intentar_conexion(ip, puerto, margen):
			return
	
	agregar_log("❌ NO ME PUDE CONECTAR A NINGÚN HOST")
	_conexion_fallida()

func intentar_conexion(ip: String, puerto: int, margen: float = 4.0) -> bool:
	agregar_log("📡 Probando " + ip + ":" + str(puerto) + " ...")
	
	if not Network.preparar_cliente(ip, puerto):
		agregar_log("❌ No se pudo iniciar el intento con " + ip)
		return false
	
	var ok: bool = await Network.esperar_conexion(margen)
	
	if not ok:
		agregar_log("❌ " + ip + " no respondió")
		Network.desconectar()
		return false
	
	agregar_log("✅ ¡CONECTADO AL HOST!")
	agregar_log("🆔 Peer ID: " + str(Network.multiplayer.get_unique_id()))
	conectado = true
	conectando = false
	
	if Global and Global.data_manager:
		Global.data_manager.actualizar_ip_host(ip)
		Global.ip_host = ip
	
	await get_tree().create_timer(0.5).timeout
	agregar_log("📤 Solicitando lista de salas...")
	Network.pedir_salas.rpc_id(1)
	
	await get_tree().create_timer(0.5).timeout
	mostrar_salas()
	return true

func _conexion_fallida():
	agregar_log("🔍 Posibles causas:")
	agregar_log("  1. 🔥 Firewall del host")
	agregar_log("  2. 💻 El host no está en CREAR SALA")
	agregar_log("  3. 🌐 No están en la misma red wifi")
	
	if intentos <= 3:
		agregar_log("⏳ Reintentando en 2 segundos...")
	
	conectando = false

func _on_salas_actualizadas():
	agregar_log("📡 Salas actualizadas: " + str(Network.salas))
	mostrar_salas()

# ✅ FIX: return después de detectar desconexión para no usar peer muerto
func on_timer_timeout():
	if conectando:
		return
	
	if conectado and not Network.esta_conectado():
		agregar_log("⚠️ SE PERDIÓ LA CONEXIÓN. Volviendo a buscar...")
		conectado = false
		Network.salas = {}
		Network.desconectar()
		mostrar_salas()
		return  # ← ✅ evita intentar pedir_salas con peer ya cerrado
	
	if conectado:
		Network.pedir_salas.rpc_id(1)
		await get_tree().create_timer(0.3).timeout
		mostrar_salas()
	else:
		conectar_al_host()

func mostrar_salas():
	if not has_node("Panel/LISTA_SALA"):
		return
	
	$Panel/LISTA_SALA.clear()
	
	var salas = Network.get_salas()
	
	agregar_log("=== 📋 LISTA DE SALAS === (" + str(salas.size()) + ")")
	
	if salas.size() > 0:
		for sala in salas:
			$Panel/LISTA_SALA.add_item(sala)
			agregar_log("  ✅ " + sala)
		
		$Panel/LISTA_SALA.select(0)
	else:
		$Panel/LISTA_SALA.add_item("--- No hay salas ---")

func on_btn_volver_pressed():
	get_tree().change_scene_to_file("res://SCENE/MAIN_MENU.tscn")

# ============================================
# ✅ UNIRSE A SALA (GUARDA EL NOMBRE)
# ============================================
func on_btn_unirse_sala_pressed():
	agregar_log("")
	agregar_log("=== 🎮 BOTÓN UNIRSE PRESIONADO ===")
	
	if not conectado:
		agregar_log("❌ No estás conectado al host")
		return
	
	if not has_node("Panel/TXT_NOMBRE"):
		agregar_log("❌ ERROR: No se encontró TXT_NOMBRE")
		return
	
	var nombre_usuario = $Panel/TXT_NOMBRE.text
	agregar_log("👤 Nombre: '" + nombre_usuario + "'")
	
	if nombre_usuario.strip_edges() == "":
		agregar_log("❌ Debes ingresar un nombre")
		return
	
	if not has_node("Panel/LISTA_SALA"):
		agregar_log("❌ ERROR: No se encontró LISTA_SALA")
		return
	
	var selected = $Panel/LISTA_SALA.get_selected_items()
	
	if selected.size() > 0:
		var nombre_sala = $Panel/LISTA_SALA.get_item_text(selected[0])
		agregar_log("🏠 Sala: '" + nombre_sala + "'")
		
		if nombre_sala != "--- No hay salas ---" and nombre_sala != "Error: Función no encontrada":
			# ✅ GUARDAR MI NOMBRE EN GLOBAL
			Global.set_mi_nombre(nombre_usuario)
			agregar_log("💾 Mi nombre guardado: " + Global.get_mi_nombre())
			
			agregar_log("📤 Enviando solicitud de unión...")
			Network.unirse_sala.rpc_id(1, nombre_sala, nombre_usuario)
			Network.sala_actual = nombre_sala
			agregar_log("✅ Solicitud enviada")
			
			await get_tree().create_timer(0.3).timeout
			get_tree().change_scene_to_file("res://SCENE/LOBBY.tscn")
		else:
			agregar_log("❌ No hay salas disponibles")
	else:
		agregar_log("❌ Debes seleccionar una sala")
