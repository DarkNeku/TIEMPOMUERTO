extends Node

var salas: Dictionary = {}
var jugadores: Dictionary = {}
var peer: MultiplayerPeer = null
var sala_actual: String = ""

func start_host(port: int = 12345) -> bool:
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_server(port, 5)
	if result != OK:
		return false
	multiplayer.multiplayer_peer = peer
	return true

func connect_to_host(ip: String, port: int = 12345) -> bool:
	peer = ENetMultiplayerPeer.new()
	var result = peer.create_client(ip, port)
	if result != OK:
		return false
	multiplayer.multiplayer_peer = peer
	return true

@rpc("authority")
func crear_sala(nombre_sala: String, nombre_usuario: String):
	salas[nombre_sala] = []
	jugadores[nombre_sala] = [nombre_usuario]
	sala_actual = nombre_sala
	sync_salas.rpc(salas)
	sync_jugadores.rpc(jugadores)

@rpc("any_peer")
func unirse_sala(nombre_sala: String, nombre_usuario: String):
	if soy_host():
		if nombre_sala in jugadores:
			jugadores[nombre_sala].append(nombre_usuario)
			print("=== HOST: Usuario " + nombre_usuario + " se unió a la sala: " + nombre_sala)
			print("=== HOST: Jugadores actuales: " + str(jugadores[nombre_sala]))
			# Sincronizar con todos los peers
			sync_jugadores.rpc(jugadores)
			print("=== HOST: Lista de jugadores sincronizada con todos los peers")
		else:
			print("=== HOST ERROR: La sala " + nombre_sala + " no existe!")
	else:
		print("=== CLIENTE: Intentando unirse, pero no soy host")

func get_salas() -> Array:
	return salas.keys()

func get_jugadores(nombre_sala: String) -> Array:
	if nombre_sala in jugadores:
		return jugadores[nombre_sala]
	return []

func soy_host() -> bool:
	return multiplayer.is_server()

@rpc("any_peer")
func sync_salas(salas_dict: Dictionary):
	salas = salas_dict

@rpc("any_peer")
func sync_jugadores(jugadores_dict: Dictionary):
	jugadores = jugadores_dict
	print("=== SYNC: Lista de jugadores actualizada: " + str(jugadores))

@rpc("any_peer")
func pedir_salas():
	if soy_host():
		sync_salas.rpc_id(multiplayer.get_remote_sender_id(), salas)

@rpc("any_peer")
func pedir_jugadores(_nombre_sala: String):
	if soy_host():
		sync_jugadores.rpc_id(multiplayer.get_remote_sender_id(), jugadores)
