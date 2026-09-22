extends Node

# =====================================================================
#  RED — descubre el host solo, sin IPs escritas a mano
# ---------------------------------------------------------------------
#  Quien hospeda (CREAR SALA) abre el puerto UDP de descubrimiento y contesta
#  con MAGIC a quien pregunte. Quien se une (UNIRSE SALA) sondea la red local
#  —broadcast, broadcast de su propia subred y barrido de su /24— y aprende la
#  IP del host de la propia respuesta. Así funciona en cualquier PC y en
#  cualquier red local, sin importar qué IP le dé el router a cada equipo.
# =====================================================================

const PUERTO_DESCUBRIMIENTO: int = 12344
const MAGIC: String = "TIEMPOMUERTO/1"
const PUERTO_JUEGO_DEFECTO: int = 12345
const MAX_CONEXIONES: int = 5

var salas: Dictionary = {}
var jugadores: Dictionary = {}
var peer: MultiplayerPeer = null
var sala_actual: String = ""
var conectado: bool = false

# --- sockets del descubrimiento ---
var _udp_host: PacketPeerUDP = null       # escucha sondas (soy host)
var _udp_busqueda: PacketPeerUDP = null   # manda sondas (busco host)
var _puerto_juego: int = PUERTO_JUEGO_DEFECTO
var _hosts_encontrados: Array[String] = []

func _ready():
	print("=== NETWORK: INICIALIZADO ===")
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
		print("=== ¿Hay otra copia del juego ya hospedando en este equipo?")
		peer = null
		return false
	
	multiplayer.multiplayer_peer = peer
	
	conectado = true

	print("=== HOST: Servidor iniciado en puerto " + str(port))
	print("=== HOST: IP local: " + get_local_ip())
	print("=== HOST: IPv4 de este equipo: " + str(get_ips_ipv4()))

	# Publicar el host para que cualquier cliente lo encuentre solo
	iniciar_descubrimiento(port)
	return true

## Arranca el intento de conexión. OJO: ENet es asíncrono, así que que esto
## devuelva true NO significa que ya estés conectado: hay que esperar con
## esperar_conexion() (create_client solo confirma que se envió la petición).
func preparar_cliente(ip: String, port: int = PUERTO_JUEGO_DEFECTO) -> bool:
	print("=== PREPARAR_CLIENTE: " + ip + ":" + str(port))
	
	if ip.strip_edges() == "":
		print("ERROR: IP vacía")
		return false

	desconectar()
	_puerto_juego = port
	
	# Ya no hace falta el retraso especial de Android: el descubrimiento por UDP
	# se encarga de esperar a que la wifi esté operativa.
	
	peer = ENetMultiplayerPeer.new()
	var result: int = peer.create_client(ip.strip_edges(), port)
	print("=== CLIENTE: create_client -> " + error_string(result))
	
	if result != OK:
		print("ERROR: No se pudo conectar - Código: " + str(result))
		peer = null
		return false
	
	multiplayer.multiplayer_peer = peer
	return true


## Espera de verdad: solo devuelve true cuando la conexión ya está establecida.
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


## Se mantiene el nombre viejo por compatibilidad.
func connect_to_host(ip: String, port: int = PUERTO_JUEGO_DEFECTO) -> bool:
	return preparar_cliente(ip, port)


func desconectar() -> void:
	if peer != null:
		peer.close()
		peer = null
	# OfflineMultiplayerPeer = sin red (no dejar el peer viejo colgado)
	multiplayer.multiplayer_peer = OfflineMultiplayerPeer.new()
	conectado = false


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


# =====================================================================
#  DESCUBRIMIENTO AUTOMÁTICO (sin IPs escritas a mano)
# =====================================================================

## El host abre el puerto UDP fijo y contesta a quien pregunte.
func iniciar_descubrimiento(puerto_juego: int = PUERTO_JUEGO_DEFECTO) -> bool:
	_puerto_juego = puerto_juego
	detener_descubrimiento()

	var udp := PacketPeerUDP.new()
	# 0.0.0.0 = IPv4 en todas las interfaces (las sondas son IPv4)
	var err: int = udp.bind(PUERTO_DESCUBRIMIENTO, "0.0.0.0")
	if err != OK:
		print("=== HOST: no pude abrir UDP " + str(PUERTO_DESCUBRIMIENTO) + " (" + error_string(err) + ")")
		print("=== HOST: ¿hay otra copia del juego corriendo en este equipo?")
		return false

	_udp_host = udp
	print("=== HOST: descubrimiento activo en UDP " + str(PUERTO_DESCUBRIMIENTO))
	return true


func detener_descubrimiento() -> void:
	if _udp_host != null:
		_udp_host.close()
		_udp_host = null


func detener_busqueda() -> void:
	if _udp_busqueda != null:
		_udp_busqueda.close()
		_udp_busqueda = null


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
		print("=== HOST: respondo la sonda de " + ip_origen + ":" + str(puerto_origen))


## Direcciones donde mandar la sonda. El broadcast cubre la red normal; el
## barrido de la /24 propia cubre routers que filtran el broadcast (wifi de
## invitados, aislamiento de AP, algunos Android).
func construir_candidatos(ip_extra: String = "") -> Array[String]:
	var candidatos: Array[String] = []
	var mis_ips: Array[String] = get_ips_ipv4()

	candidatos.append("255.255.255.255")

	for ip in mis_ips:
		var partes: PackedStringArray = ip.split(".")
		if partes.size() == 4:
			candidatos.append(partes[0] + "." + partes[1] + "." + partes[2] + ".255")

	# Host y cliente en el mismo equipo (para probar todo en un solo PC)
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


## Sondea la red local y devuelve las IPs de los hosts que respondieron.
func descubrir_host(timeout: float = 3.0, ip_extra: String = "") -> Array[String]:
	detener_busqueda()
	_hosts_encontrados = []

	var udp := PacketPeerUDP.new()
	udp.set_broadcast_enabled(true)
	var err: int = udp.bind(0, "0.0.0.0")
	if err != OK:
		print("=== BUSQUEDA: no pude abrir el socket UDP (" + error_string(err) + ")")
		return _hosts_encontrados
	_udp_busqueda = udp

	var candidatos: Array[String] = construir_candidatos(ip_extra)
	var enviados: int = 0
	var t: float = 0.0
	print("=== BUSQUEDA: sondeando " + str(candidatos.size()) + " direcciones (máx " + str(timeout) + "s)")

	while t < timeout:
		# En tandas, para no saturar la red de golpe
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
	print("=== PEDIR_SALAS: SOLICITANDO ===")
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		print("HOST: Enviando salas al peer " + str(sender_id))
		print("HOST: Salas: " + str(salas))
		sync_salas.rpc_id(sender_id, salas)
	else:
		print("No soy host, ignorando")

@rpc("any_peer")
func sync_salas(salas_dict: Dictionary):
	print("=== SYNC_SALAS: RECIBIDO ===")
	print("Salas: " + str(salas_dict))
	salas = salas_dict
	emit_signal("salas_actualizadas")

@rpc("any_peer")
func unirse_sala(nombre_sala: String, nombre_usuario: String):
	print("=== UNIRSE_SALA: " + nombre_usuario + " -> " + nombre_sala)
	if multiplayer.is_server():
		if nombre_sala in jugadores:
			if nombre_usuario not in jugadores[nombre_sala]:
				jugadores[nombre_sala].append(nombre_usuario)
				print("HOST: Usuario agregado. Jugadores: " + str(jugadores[nombre_sala]))
				sync_jugadores.rpc(jugadores)
			else:
				print("HOST: Usuario ya existe")
		else:
			print("HOST ERROR: La sala no existe")
	else:
		print("CLIENTE: No soy host")

@rpc("any_peer")
func sync_jugadores(jugadores_dict: Dictionary):
	print("=== SYNC_JUGADORES: RECIBIDO ===")
	print("Jugadores: " + str(jugadores_dict))
	jugadores = jugadores_dict
	emit_signal("jugadores_actualizados")

@rpc("any_peer")
func pedir_jugadores(nombre_sala: String):
	print("=== PEDIR_JUGADORES: SOLICITANDO ===")
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		print("HOST: Enviando jugadores al peer " + str(sender_id))
		print("HOST: Jugadores: " + str(jugadores))
		sync_jugadores.rpc_id(sender_id, jugadores)

func get_salas() -> Array:
	print("GET_SALAS: Retornando " + str(salas.keys()))
	return salas.keys()

func get_jugadores(nombre_sala: String) -> Array:
	print("GET_JUGADORES: Buscando en " + nombre_sala)
	if nombre_sala in jugadores:
		return jugadores[nombre_sala]
	return []

func soy_host() -> bool:
	return multiplayer.is_server()

## true si hay conexión viva (soy el host, o soy un cliente ya conectado).
## Sirve para no pedir salas a un peer muerto y para volver a buscar el host.
func esta_conectado() -> bool:
	if peer == null or multiplayer.multiplayer_peer == null:
		return false
	if multiplayer.is_server():
		return true
	return peer.get_connection_status() == MultiplayerPeer.CONNECTION_CONNECTED and multiplayer.get_unique_id() > 1

signal salas_actualizadas
signal jugadores_actualizados
signal conexion_establecida
signal conexion_fallida
signal host_desconectado
