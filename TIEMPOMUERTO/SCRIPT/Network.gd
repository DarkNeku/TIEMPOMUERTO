extends Node

var salas: Dictionary = {}
var jugadores: Dictionary = {}
var peer: MultiplayerPeer = null
var sala_actual: String = ""
var conectado: bool = false

func _ready():
	print("=== NETWORK: INICIALIZADO ===")
	print("SO: " + OS.get_name())

func start_host(port: int = 12345) -> bool:
	print("=== START_HOST: INICIANDO SERVIDOR ===")
	
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, 5)
	
	if result != OK:
		print("=== ERROR: No se pudo crear el servidor - Código: " + str(result))
		return false
	
	multiplayer.multiplayer_peer = peer
	
	print("=== HOST: Servidor iniciado en puerto " + str(port))
	print("=== HOST: IP local: " + get_local_ip())
	return true

func connect_to_host(ip: String, port: int = 12345) -> bool:
	print("=== CONNECT_TO_HOST: INICIO ===")
	print("IP: " + ip + " Puerto: " + str(port))
	print("OS: " + OS.get_name())
	
	if ip.strip_edges() == "":
		print("ERROR: IP vacía")
		return false
	
	# En Android, esperar un poco antes de conectar
	if OS.get_name() == "Android":
		print("ANDROID: Esperando 0.5s antes de conectar...")
		# ✅ CORREGIDO: Usar await aquí también
		await get_tree().create_timer(0.5).timeout
	
	peer = ENetMultiplayerPeer.new()
	print("Creando cliente para " + ip + ":" + str(port))
	var result = peer.create_client(ip, port)
	print("Resultado de create_client: " + str(result))
	
	if result != OK:
		print("ERROR: No se pudo conectar - Código: " + str(result))
		peer = null
		return false
	
	multiplayer.multiplayer_peer = peer
	conectado = true
	print("¡CONECTADO EXITOSAMENTE!")
	print("Peer ID: " + str(peer.get_unique_id()))
	return true

func get_local_ip() -> String:
	var ip_list = IP.get_local_addresses()
	for ip in ip_list:
		if ip.begins_with("192.168.") or ip.begins_with("10.") or ip.begins_with("172."):
			return ip
	return "127.0.0.1"

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

signal salas_actualizadas
signal jugadores_actualizados
