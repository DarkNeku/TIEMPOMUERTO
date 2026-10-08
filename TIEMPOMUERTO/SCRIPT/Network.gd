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
	print("=== NETWORK: INICIALIZADO (PC-HOST) ===")
	print("SO: " + OS.get_name())
	print("=== RED: IPv4 de este equipo: " + str(get_ips_ipv4()))
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)

func _process(_delta: float) -> void:
	_poll_descubrimiento()

func start_host(port: int = PUERTO_JUEGO_DEFECTO) -> bool:
	print("=== START_HOST: INICIANDO SERVIDOR ===")
	desconectar()
	_puerto_juego = port
	
	peer = ENetMultiplayerPeer.new()
	var result: int = peer.create_server(port, MAX_CONEXIONES)
	
	if result != OK:
		print("=== ERROR: No se pudo crear el servidor - Código: " + str(result))
		peer = null
		return false
	
	multiplayer.multiplayer_peer = peer
	conectado = true
	
	print("=== HOST: Servidor iniciado en puerto " + str(port))
	print("=== HOST: IP local: " + get_local_ip())
	
	iniciar_descubrimiento(port)
	return true

func desconectar() -> void:
	if peer != null:
		peer.close()
		peer = null
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	conectado = false
	detener_descubrimiento()

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

func iniciar_descubrimiento(puerto_juego: int = PUERTO_JUEGO_DEFECTO) -> bool:
	_puerto_juego = puerto_juego
	detener_descubrimiento()
	
	var udp := PacketPeerUDP.new()
	var err: int = udp.bind(PUERTO_DESCUBRIMIENTO, "0.0.0.0")
	if err != OK:
		print("=== HOST: no pude abrir UDP " + str(PUERTO_DESCUBRIMIENTO))
		return false
	
	_udp_host = udp
	print("=== HOST: descubrimiento activo en UDP " + str(PUERTO_DESCUBRIMIENTO))
	return true

func detener_descubrimiento() -> void:
	if _udp_host != null:
		_udp_host.close()
		_udp_host = null

func _poll_descubrimiento() -> void:
	if _udp_host == null:
		return
	while _udp_host.get_available_packet_count() > 0:
		var datos: PackedByteArray = _udp_host.get_packet()
		if datos.get_string_from_utf8() != MAGIC:
			continue
		var ip_origen: String = _udp_host.get_packet_ip()
		var puerto_origen: int = _udp_host.get_packet_port()
		_udp_host.set_dest_address(ip_origen, puerto_origen)
		_udp_host.put_packet((MAGIC + "|" + str(_puerto_juego)).to_utf8_buffer())
		print("=== HOST: respondo la sonda de " + ip_origen)

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

# =====================================================================
#  SALAS
# =====================================================================
@rpc("any_peer")
func pedir_salas():
	print("=== PEDIR_SALAS: SOLICITANDO ===")
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		print("HOST: Enviando salas al peer " + str(sender_id))
		sync_salas.rpc_id(sender_id, salas)
		sync_datos_salas.rpc_id(sender_id, datos_salas)

@rpc("any_peer")
func sync_salas(salas_dict: Dictionary):
	salas = salas_dict
	emit_signal("salas_actualizadas")

@rpc("any_peer")
func sync_datos_salas(datos_dict: Dictionary):
	datos_salas = datos_dict
	print("=== SYNC_DATOS_SALAS: " + str(datos_salas))

@rpc("any_peer")
func unirse_sala(nombre_sala: String, nombre_usuario: String):
	print("=== UNIRSE_SALA: " + nombre_usuario + " -> " + nombre_sala)
	
	if multiplayer.is_server():
		if nombre_sala in jugadores:
			var cant_max = 6
			if nombre_sala in datos_salas:
				cant_max = datos_salas[nombre_sala].get("cant_jugadores", 6)
			
			print("HOST: Jugadores: " + str(jugadores[nombre_sala].size()) + "/" + str(cant_max))
			
			var nombre_normalizado = nombre_usuario.strip_edges().to_upper()
			
			if jugadores[nombre_sala].size() >= cant_max:
				print("❌ HOST: Sala llena")
				sala_llena.rpc_id(multiplayer.get_remote_sender_id(), nombre_sala)
				return
			
			var ya_existe = false
			for j in jugadores[nombre_sala]:
				if j.to_upper() == nombre_normalizado:
					ya_existe = true
					break
			
			if not ya_existe:
				jugadores[nombre_sala].append(nombre_normalizado)
				print("✅ HOST: Usuario agregado. Jugadores: " + str(jugadores[nombre_sala]))
				
				Global.agregar_jugador(nombre_normalizado)
				
				sync_jugadores.rpc(jugadores)
			else:
				print("HOST: Usuario ya existe")
		else:
			print("❌ HOST ERROR: La sala no existe")

@rpc("any_peer")
func sala_llena(nombre_sala: String):
	print("❌ La sala " + nombre_sala + " está llena")
	sala_llena_signal.emit(nombre_sala)

@rpc("any_peer")
func sync_jugadores(jugadores_dict: Dictionary):
	jugadores = jugadores_dict
	emit_signal("jugadores_actualizados")

@rpc("any_peer")
func pedir_jugadores(nombre_sala: String):
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		print("HOST: Enviando jugadores al peer " + str(sender_id))
		sync_jugadores.rpc_id(sender_id, jugadores)

# =====================================================================
#  INICIAR JUEGO Y PARTIDA
# =====================================================================
@rpc("authority")
func iniciar_juego():
	print("🎨 ¡El host inició la selección de COLORES!")
	get_tree().change_scene_to_file("res://SCENE/COLORES.tscn")

# ✅ NUEVO: Enviar jugadores PRIMERO, luego cambiar de escena
@rpc("authority")
func iniciar_partida():
	print("🎮 ¡El host inició la PARTIDA! Enviando jugadores a clientes...")
	
	# ✅ PRIMERO: enviar la lista de jugadores a TODOS los clientes
	recibir_jugadores_partida.rpc(Global.get_jugadores())
	print("✅ Lista de jugadores enviada: " + str(Global.get_jugadores()))
	
	# ✅ Dar tiempo a que el RPC llegue ANTES del cambio de escena
	await get_tree().create_timer(0.5).timeout
	
	# DESPUÉS: cambiar de escena
	get_tree().change_scene_to_file("res://SCENE/PC.tscn")

# =====================================================================
#  RECIBIR JUGADORES (el host no recibe, solo envía)
# =====================================================================
@rpc("authority")
func recibir_jugadores_partida(_jugadores_array: Array):
	# El host no recibe, solo envía
	pass

# =====================================================================
#  COLORES DE JUGADORES
# =====================================================================
@rpc("any_peer")
func enviar_color_jugador(nombre: String, color: String):
	var nombre_normalizado = nombre.strip_edges().to_upper()
	
	print("🎨 Color confirmado en HOST: " + nombre_normalizado + " → " + color)
	
	if multiplayer.is_server():
		if color in colores_usados:
			var jugador_con_ese_color = colores_usados[color]
			if jugador_con_ese_color != nombre_normalizado:
				print("❌ El color " + color + " ya está en uso por " + jugador_con_ese_color)
				color_ya_usado.rpc_id(multiplayer.get_remote_sender_id(), color, jugador_con_ese_color)
				return
		
		colores_usados[color] = nombre_normalizado
		Global.actualizar_color_jugador(nombre_normalizado, color)
		
		sync_colores.rpc(nombre_normalizado, color)
		colores_actualizados.emit(nombre_normalizado, color)

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
	# ✅ FIX: Verificar estado PRIMERO, sin tocar unique_id si no está conectado
	if peer.get_connection_status() != MultiplayerPeer.CONNECTION_CONNECTED:
		return false
	# Recién ahora es seguro pedir el unique_id
	return multiplayer.get_unique_id() > 1

signal salas_actualizadas
signal jugadores_actualizados
signal conexion_establecida
signal conexion_fallida
signal host_desconectado
signal sala_llena_signal
signal colores_actualizados(nombre, color)
signal color_ya_usado_signal(color, jugador)
