extends Node

const PUERTO_DESCUBRIMIENTO: int = 12344
const MAGIC: String = "TIEMPOMUERTO/1"
const PUERTO_JUEGO_DEFECTO: int = 12345
const MAX_CONEXIONES: int = 6

var salas: Dictionary = {}
var jugadores: Dictionary = {}
var datos_salas: Dictionary = {}
var colores_usados: Dictionary = {}
var peer: MultiplayerPeer = null
var sala_actual: String = ""
var conectado: bool = false

var _udp_host: PacketPeerUDP = null
var _udp_busqueda: PacketPeerUDP = null
var _puerto_juego: int = PUERTO_JUEGO_DEFECTO
var _hosts_encontrados: Array[String] = []

func _ready():
	print("=== NETWORK: INICIALIZADO (CELULAR-CLIENTE) ===")
	print("SO: " + OS.get_name())
	print("=== RED: IPv4 de este equipo: " + str(get_ips_ipv4()))
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta: float) -> void:
	pass

func preparar_cliente(ip: String, port: int = PUERTO_JUEGO_DEFECTO) -> bool:
	print("=== PREPARAR_CLIENTE: " + ip + ":" + str(port))
	
	if ip.strip_edges() == "":
		return false
	
	desconectar()
	_puerto_juego = port
	
	peer = ENetMultiplayerPeer.new()
	var result: int = peer.create_client(ip.strip_edges(), port)
	
	if result != OK:
		print("ERROR: No se pudo conectar - Código: " + str(result))
		peer = null
		return false
	
	multiplayer.multiplayer_peer = peer
	return true

func esperar_conexion(timeout: float = 5.0) -> bool:
	var t: float = 0.0
	while t < timeout:
		if peer == null:
			return false
		if peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and multiplayer.get_unique_id() > 1:
			conectado = true
			print("=== CLIENTE: CONECTADO. Peer ID: " + str(multiplayer.get_unique_id()))
			return true
		await get_tree().create_timer(0.05).timeout
		t += 0.05
	conectado = false
	return false

func connect_to_host(ip: String, port: int = PUERTO_JUEGO_DEFECTO) -> bool:
	return preparar_cliente(ip, port)

func desconectar() -> void:
	if peer != null:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	conectado = false
	detener_busqueda()

func get_ips_ipv4() -> Array[String]:
	var resultado: Array[String] = []
	for ip in IP.get_local_addresses():
		if ip.contains(":") or ip.begins_with("127.") or ip.begins_with("169.254."):
			continue
		if resultado.find(ip) == -1:
			resultado.append(ip)
	return resultado

func get_local_ip() -> String:
	var ips: Array[String] = get_ips_ipv4()
	for ip in ips:
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return ips[0] if ips.size() > 0 else "127.0.0.1"

func detener_busqueda() -> void:
	if _udp_busqueda != null:
		_udp_busqueda.close()
		_udp_busqueda = null

func construir_candidatos(ip_extra: String = "") -> Array[String]:
	var candidatos: Array[String] = []
	var mis_ips: Array[String] = get_ips_ipv4()
	
	candidatos.append("255.255.255.255")
	
	for ip in mis_ips:
		var partes: PackedStringArray = ip.split(".")
		if partes.size() == 4:
			candidatos.append(partes[0] + "." + partes[1] + "." + partes[2] + ".255")
	
	candidatos.append("127.0.0.1")
	
	var extra: String = ip_extra.strip_edges()
	if extra != "" and candidatos.find(extra) == -1:
		candidatos.append(extra)
	
	for ip in mis_ips:
		var partes: PackedStringArray = ip.split(".")
		if partes.size() != 4:
			continue
		var prefijo: String = partes[0] + "." + partes[1] + "." + partes[2] + "."
		for ultimo in range(1, 255):
			var candidato: String = prefijo + str(ultimo)
			if candidato != ip and candidatos.find(candidato) == -1:
				candidatos.append(candidato)
	
	return candidatos

func descubrir_host(timeout: float = 3.0, ip_extra: String = "") -> Array[String]:
	detener_busqueda()
	_hosts_encontrados = []
	
	var udp := PacketPeerUDP.new()
	udp.set_broadcast_enabled(true)
	var err: int = udp.bind(0, "0.0.0.0")
	if err != OK:
		return _hosts_encontrados
	_udp_busqueda = udp
	
	var candidatos: Array[String] = construir_candidatos(ip_extra)
	var enviados: int = 0
	var t: float = 0.0
	print("=== BUSQUEDA: sondeando " + str(candidatos.size()) + " direcciones")
	
	while t < timeout:
		if enviados < candidatos.size():
			var lote: int = mini(32, candidatos.size() - enviados)
			for i in range(lote):
				udp.set_dest_address(candidatos[enviados], PUERTO_DESCUBRIMIENTO)
				udp.put_packet(MAGIC.to_utf8_buffer())
				enviados += 1
		
		while udp.get_available_packet_count() > 0:
			var datos: PackedByteArray = udp.get_packet()
			if not datos.get_string_from_utf8().begins_with(MAGIC):
				continue
			var ip_host: String = udp.get_packet_ip()
			if _hosts_encontrados.find(ip_host) == -1:
				_hosts_encontrados.append(ip_host)
				print("=== BUSQUEDA: host encontrado en " + ip_host)
		
		if _hosts_encontrados.size() > 0:
			break
		
		await get_tree().create_timer(0.05).timeout
		t += 0.05
	
	detener_busqueda()
	return _hosts_encontrados

func _on_connected_to_server() -> void:
	conectado = true
	print("=== RED: conectado al host. Peer ID: " + str(multiplayer.get_unique_id()))
	conexion_establecida.emit()

func _on_connection_failed() -> void:
	conectado = false
	print("=== RED: no se pudo establecer la conexión")
	conexion_fallida.emit()

func _on_server_disconnected() -> void:
	conectado = false
	print("=== RED: el host cerró la conexión")
	host_desconectado.emit()

@rpc("any_peer")
func pedir_salas():
	pass

@rpc("any_peer")
func sync_salas(salas_dict: Dictionary):
	print("=== SYNC_SALAS: RECIBIDO ===")
	salas = salas_dict
	emit_signal("salas_actualizadas")

@rpc("any_peer")
func sync_datos_salas(datos_dict: Dictionary):
	print("=== SYNC_DATOS_SALAS: " + str(datos_dict))
	datos_salas = datos_dict

@rpc("any_peer")
func unirse_sala(nombre_sala: String, nombre_usuario: String):
	pass

@rpc("any_peer")
func sala_llena(nombre_sala: String):
	print("❌ La sala " + nombre_sala + " está llena")
	sala_llena_signal.emit(nombre_sala)

@rpc("any_peer")
func sync_jugadores(jugadores_dict: Dictionary):
	print("=== SYNC_JUGADORES: RECIBIDO ===")
	jugadores = jugadores_dict
	emit_signal("jugadores_actualizados")

@rpc("any_peer")
func pedir_jugadores(nombre_sala: String):
	pass

# =====================================================================
#  INICIAR JUEGO Y PARTIDA
# =====================================================================
@rpc("authority")
func iniciar_juego():
	print("🎨 ¡El host inició la selección de COLORES!")
	get_tree().change_scene_to_file("res://SCENE/COLORES.tscn")

@rpc("authority")
func iniciar_partida():
	print("🎮 ¡El host inició la PARTIDA! Pasando a JUGADOR...")
	
	await get_tree().create_timer(0.7).timeout
	
	if Global.get_jugadores().size() == 0:
		print("⚠️ ADVERTENCIA: No llegó la lista de jugadores del host")
	else:
		print("✅ Jugadores disponibles al entrar: " + str(Global.get_jugadores().size()))
	
	get_tree().change_scene_to_file("res://SCENE/JUGADOR.tscn")

# =====================================================================
#  ✅ RECIBIR JUGADORES DEL HOST
# =====================================================================
@rpc("authority")
func recibir_jugadores_partida(jugadores_array: Array):
	print("📥 Recibiendo jugadores del host: " + str(jugadores_array))
	
	Global.jugadores = jugadores_array
	
	if Global.data_manager:
		Global.data_manager.datos_actuales["jugadores"] = jugadores_array
		Global.data_manager.guardar_datos()
	
	print("✅ Jugadores sincronizados: " + str(Global.get_jugadores().size()))
	for j in Global.get_jugadores():
		print("   • " + j.get("nombre", "?") + " → " + j.get("color", ""))

# =====================================================================
#  ✅ NUEVO: PEDIR JUGADORES DE LA PARTIDA (para JUGADOR.gd)
# =====================================================================
func pedir_jugadores_partida():
	print("📤 Pidiendo lista de jugadores al host...")
	pedir_jugadores_partida_rpc.rpc_id(1)

@rpc("any_peer")
func pedir_jugadores_partida_rpc():
	# Esta la ejecuta el HOST cuando un cliente la pide
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		print("HOST: Enviando jugadores al peer " + str(sender_id))
		recibir_jugadores_partida.rpc_id(sender_id, Global.get_jugadores())

# =====================================================================
#  ENVIAR COLOR AL HOST
# =====================================================================
func enviar_mi_color(nombre: String, color: String):
	var nombre_normalizado = nombre.strip_edges().to_upper()
	
	print("📤 Confirmando color al host: " + nombre_normalizado + " → " + color)
	enviar_color_jugador.rpc_id(1, nombre_normalizado, color)

@rpc("any_peer")
func enviar_color_jugador(nombre: String, color: String):
	pass

@rpc("any_peer")
func sync_colores(nombre: String, color: String):
	print("🎨 Sync color: " + nombre + " → " + color)
	colores_usados[color] = nombre
	colores_actualizados.emit(nombre, color)

@rpc("any_peer")
func color_ya_usado(color: String, jugador_que_lo_tiene: String):
	print("❌ El color " + color + " ya está en uso por " + jugador_que_lo_tiene)
	color_ya_usado_signal.emit(color, jugador_que_lo_tiene)

# =====================================================================
#  GETTERS
# =====================================================================
func get_salas() -> Array:
	return salas.keys()

func get_jugadores(nombre_sala: String) -> Array:
	if nombre_sala in jugadores:
		return jugadores[nombre_sala]
	return []

func get_datos_sala(nombre_sala: String) -> Dictionary:
	if nombre_sala in datos_salas:
		return datos_salas[nombre_sala]
	return {}

func soy_host() -> bool:
	return multiplayer.is_server()

func esta_conectado() -> bool:
	if peer == null or multiplayer.multiplayer_peer == null:
		return false
	if multiplayer.is_server():
		return true
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return false
	return multiplayer.get_unique_id() > 1

signal salas_actualizadas
signal jugadores_actualizados
signal conexion_establecida
signal conexion_fallida
signal host_desconectado
signal sala_llena_signal
signal colores_actualizados(nombre, color)
signal color_ya_usado_signal(color, jugador)
