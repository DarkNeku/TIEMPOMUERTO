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

var nombres_reservados: Dictionary = {}

var _udp_host: PacketPeerUDP = null
var _udp_busqueda: PacketPeerUDP = null
var _puerto_juego: int = PUERTO_JUEGO_DEFECTO
var _hosts_encontrados: Array[String] = []

signal jugadores_actualizados_signal
signal habitacion_actualizada_signal
signal sync_puerta_visual(habitacion: String, direccion: String, nuevo_estado: String)

func _ready():
	print("=== NETWORK: INICIALIZADO (PC-HOST) ===")
	multiplayer.connected_to_server.connect(_on_connected_to_server)
	multiplayer.connection_failed.connect(_on_connection_failed)
	multiplayer.server_disconnected.connect(_on_server_disconnected)
	multiplayer.peer_connected.connect(_on_peer_connected)
	multiplayer.peer_disconnected.connect(_on_peer_disconnected)

func _process(_delta: float) -> void:
	_poll_descubrimiento()

func start_host(port: int = PUERTO_JUEGO_DEFECTO) -> bool:
	desconectar()
	_puerto_juego = port
	
	peer = ENetMultiplayerPeer.new()
	var result: int = peer.create_server(port, MAX_CONEXIONES)
	
	if result != OK:
		peer = null
		return false
	
	multiplayer.multiplayer_peer = peer
	conectado = true
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
		return false
	
	_udp_host = udp
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

func _on_connected_to_server() -> void:
	conectado = true
	conexion_establecida.emit()

func _on_connection_failed() -> void:
	conectado = false
	conexion_fallida.emit()

func _on_server_disconnected() -> void:
	conectado = false
	host_desconectado.emit()

func _on_peer_connected(id: int) -> void:
	print("🔌 Cliente conectado: " + str(id))
	await get_tree().create_timer(0.5).timeout
	enviar_estado_completo_a(id)

func _on_peer_disconnected(id: int) -> void:
	print("🔌 Cliente desconectado: " + str(id))

func enviar_estado_completo_a(id: int):
	var paquete = {
		"jugadores": Global.get_jugadores(),
		"posiciones": RoomData.posiciones_jugadores,
		"habitaciones_colocadas": RoomData.habitaciones_colocadas,
		"conexiones": RoomData.conexiones,
		"estado_habitaciones": RoomData.estado_habitaciones,
		"malla_habitaciones": RoomData.malla_habitaciones
	}
	print("📤 HOST: Enviando estado completo a " + str(id))
	sync_estado_completo.rpc_id(id, paquete)

# =====================================================================
#  RPCs
# =====================================================================

@rpc("any_peer")
func pedir_salas():
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		sync_salas.rpc_id(sender_id, salas)
		sync_datos_salas.rpc_id(sender_id, datos_salas)

@rpc("any_peer")
func sync_salas(salas_dict: Dictionary):
	salas = salas_dict
	emit_signal("salas_actualizadas")

@rpc("any_peer")
func sync_datos_salas(datos_dict: Dictionary):
	datos_salas = datos_dict

@rpc("any_peer")
func unirse_sala(nombre_sala: String, nombre_usuario: String):
	if multiplayer.is_server():
		if nombre_sala in jugadores:
			var cant_max = 6
			if nombre_sala in datos_salas:
				cant_max = datos_salas[nombre_sala].get("cant_jugadores", 6)
			
			var nombre_normalizado = nombre_usuario.strip_edges().to_upper()
			
			if jugadores[nombre_sala].size() >= cant_max:
				sala_llena.rpc_id(multiplayer.get_remote_sender_id(), nombre_sala)
				return
			
			var ya_existe = false
			for j in jugadores[nombre_sala]:
				if j.to_upper() == nombre_normalizado:
					ya_existe = true
					break
			
			if not ya_existe:
				jugadores[nombre_sala].append(nombre_normalizado)
				Global.agregar_jugador(nombre_normalizado)
				sync_jugadores.rpc(jugadores)

@rpc("any_peer")
func sala_llena(nombre_sala: String):
	sala_llena_signal.emit(nombre_sala)

@rpc("any_peer")
func sync_jugadores(jugadores_dict: Dictionary):
	jugadores = jugadores_dict
	emit_signal("jugadores_actualizados")

@rpc("any_peer")
func pedir_jugadores(nombre_sala: String):
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		sync_jugadores.rpc_id(sender_id, jugadores)

@rpc("authority")
func iniciar_juego():
	get_tree().change_scene_to_file("res://SCENE/COLORES.tscn")

@rpc("authority")
func iniciar_partida():
	recibir_jugadores_partida.rpc(Global.get_jugadores())
	await get_tree().create_timer(0.5).timeout
	get_tree().change_scene_to_file("res://SCENE/PC.tscn")

@rpc("authority")
func recibir_jugadores_partida(_jugadores_array: Array):
	pass

@rpc("any_peer")
func pedir_jugadores_partida_rpc():
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		recibir_jugadores_partida.rpc_id(sender_id, Global.get_jugadores())

# =====================================================================
#  MODO PRUEBA
# =====================================================================

@rpc("any_peer")
func pedir_jugadores_prueba():
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		sync_jugadores_prueba.rpc_id(sender_id, Global.get_jugadores(), nombres_reservados)

@rpc("any_peer")
func sync_jugadores_prueba(jugadores_array: Array, reservados: Dictionary):
	jugadores_prueba_recibidos.emit(jugadores_array, reservados)

@rpc("any_peer")
func reservar_jugador_prueba(nombre: String):
	var nombre_normalizado = nombre.strip_edges().to_upper()
	
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		
		if nombre_normalizado in nombres_reservados:
			reserva_rechazada.rpc_id(sender_id, nombre_normalizado, "Ese nombre ya está en uso")
			return
		
		var existe = false
		for j in Global.get_jugadores():
			if j.get("nombre", "").to_upper() == nombre_normalizado:
				existe = true
				break
		
		if not existe:
			reserva_rechazada.rpc_id(sender_id, nombre_normalizado, "Ese jugador no existe")
			return
		
		nombres_reservados[nombre_normalizado] = sender_id
		
		var jugadores_actualizados = Global.get_jugadores()
		for i in range(jugadores_actualizados.size()):
			var n = jugadores_actualizados[i].get("nombre", "").to_upper()
			if n == nombre_normalizado:
				jugadores_actualizados[i]["conectado"] = true
			elif n in nombres_reservados:
				jugadores_actualizados[i]["conectado"] = true
			else:
				jugadores_actualizados[i]["conectado"] = false
		
		if Global.data_manager:
			Global.data_manager.datos_actuales["jugadores"] = jugadores_actualizados
			Global.data_manager.guardar_datos()
		Global.jugadores = jugadores_actualizados
		
		RoomData.inicializar_posicion_jugador(nombre_normalizado, "Room00")
		
		reserva_confirmada.rpc_id(sender_id, nombre_normalizado)
		sync_reservas.rpc(nombres_reservados)
		recibir_jugadores_partida.rpc(Global.get_jugadores())
		
		jugadores_actualizados_signal.emit()

@rpc("any_peer")
func reserva_confirmada(nombre: String):
	reserva_exitosa.emit(nombre)

@rpc("any_peer")
func reserva_rechazada(nombre: String, razon: String):
	reserva_fallida.emit(nombre, razon)

@rpc("any_peer")
func sync_reservas(reservados: Dictionary):
	nombres_reservados = reservados
	reservas_actualizadas.emit(reservados)

# =====================================================================
#  ✅ SINCRONIZACIÓN DE ESTADO
# =====================================================================

@rpc("any_peer")
func solicitar_estado_completo():
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		enviar_estado_completo_a(sender_id)

@rpc("any_peer")
func sync_estado_completo(_paquete: Dictionary):
	pass

@rpc("any_peer")
func solicitar_abrir_puerta(habitacion: String, direccion: String):
	if multiplayer.is_server():
		var estado = RoomData.get_estado_habitacion(habitacion)
		if estado.is_empty():
			estado = {"puertas": {}}
		if not "puertas" in estado:
			estado["puertas"] = {}
		
		estado["puertas"][direccion] = {"estado": "abierta"}
		RoomData.guardar_estado_habitacion(habitacion, estado)
		
		# ✅ Abrir la puerta opuesta en la habitación vecina (si existe)
		var coord = RoomData.get_coord_habitacion(habitacion)
		var coord_vecino = RoomData.calcular_coord_vecina(coord.x, coord.y, direccion)
		var hab_vecina = RoomData.get_habitacion_en_coord(coord_vecino.x, coord_vecino.y)
		
		if hab_vecina != "":
			var direccion_opuesta = RoomData.obtener_direccion_opuesta(direccion)
			RoomData.guardar_estado_habitacion_puerta(hab_vecina, direccion_opuesta, "abierta")
			sync_puerta_estado.rpc(hab_vecina, direccion_opuesta, "abierta")
		
		sync_puerta_visual.emit(habitacion, direccion, "abierta")
		sync_puerta_estado.rpc(habitacion, direccion, "abierta")

@rpc("any_peer")
func sync_puerta_estado(habitacion: String, direccion: String, nuevo_estado: String):
	RoomData.guardar_estado_habitacion_puerta(habitacion, direccion, nuevo_estado)
	sync_puerta_visual.emit(habitacion, direccion, nuevo_estado)

# ✅ NUEVO: solicitud de habitación nueva con toda la lógica centralizada
@rpc("any_peer")
func solicitar_nueva_habitacion(codigo: String, direccion: String, habitacion_origen: String):
	if multiplayer.is_server():
		var sender_id = multiplayer.get_remote_sender_id()
		print("📥 HOST: Cliente pide habitación nueva: código=" + codigo + " dir=" + direccion + " desde=" + habitacion_origen)
		
		# 1) Coordenada de origen
		var coord_origen = RoomData.get_coord_habitacion(habitacion_origen)
		if coord_origen.x == -999:
			print("❌ HOST: habitación origen no está en la malla")
			return
		
		# 2) Coordenada destino
		var coord_destino = RoomData.calcular_coord_vecina(coord_origen.x, coord_origen.y, direccion)
		
		# 3) Validar rango
		if not RoomData.es_coord_valida(coord_destino.x, coord_destino.y):
			print("❌ HOST: coord destino fuera del rango")
			habitacion_rechazada.rpc_id(sender_id, "No puedes ir más allá del límite del tablero")
			return
		
		# 4) ¿Ya hay habitación en esa coord?
		var hab_existente = RoomData.get_habitacion_en_coord(coord_destino.x, coord_destino.y)
		if hab_existente != "":
			print("ℹ️ HOST: Ya hay habitación en esa coord: " + hab_existente)
			habitacion_rechazada.rpc_id(sender_id, "Ya hay una habitación en esa dirección")
			return
		
		# 5) Validar código
		var resultado = RoomData.validar_codigo_habitacion(codigo, habitacion_origen)
		if not resultado["valido"]:
			print("❌ HOST: código inválido: " + resultado["error"])
			habitacion_rechazada.rpc_id(sender_id, resultado["error"])
			return
		
		var nombre_habitacion = resultado["nombre_habitacion"]
		
		# 6) Generar puertas
		var direccion_entrada_opuesta = RoomData.obtener_direccion_opuesta(direccion)
		var estado_puertas = RoomData.generar_puertas_para_habitacion(nombre_habitacion, coord_destino, direccion_entrada_opuesta)
		
		# 7) Guardar estado y registrar en malla
		var estado = {"puertas": {}}
		for d in estado_puertas:
			estado["puertas"][d] = {"estado": estado_puertas[d]}
		
		RoomData.guardar_estado_habitacion(nombre_habitacion, estado)
		RoomData.agregar_habitacion_colocada(nombre_habitacion)
		RoomData.agregar_a_malla(nombre_habitacion, coord_destino.x, coord_destino.y)
		
		print("✅ HOST: Habitación " + nombre_habitacion + " registrada en (" + str(coord_destino.x) + "," + str(coord_destino.y) + ")")
		
		# 8) Registrar conexión origen↔destino
		RoomData.registrar_conexion(habitacion_origen, direccion, nombre_habitacion)
		
		# 9) Forzar puertas opuestas en los vecinos existentes (no en el origen, ya está)
		var direcciones = ["arriba", "abajo", "izquierda", "derecha"]
		for d in direcciones:
			if d == direccion_entrada_opuesta:
				continue  # ya está forzada
			var coord_vecino = RoomData.calcular_coord_vecina(coord_destino.x, coord_destino.y, d)
			var hab_vecina = RoomData.get_habitacion_en_coord(coord_vecino.x, coord_vecino.y)
			if hab_vecina != "":
				var dir_opuesta = RoomData.obtener_direccion_opuesta(d)
				RoomData.forzar_puerta_opuesta_en_vecino(hab_vecina, dir_opuesta)
		
		# 10) Broadcast
		habitacion_actualizada_signal.emit(nombre_habitacion)
		sync_habitacion_nueva.rpc(nombre_habitacion, codigo, direccion, habitacion_origen, estado_puertas, coord_destino)

@rpc("any_peer")
func sync_habitacion_nueva(nombre_habitacion: String, _codigo: String, direccion: String, habitacion_origen: String, estado_puertas: Dictionary, coord: Vector2i):
	RoomData.agregar_habitacion_colocada(nombre_habitacion)
	
	var estado = {"puertas": {}}
	for d in estado_puertas:
		estado["puertas"][d] = {"estado": estado_puertas[d]}
	RoomData.guardar_estado_habitacion(nombre_habitacion, estado)
	
	RoomData.agregar_a_malla(nombre_habitacion, coord.x, coord.y)
	
	# Registrar conexión
	RoomData.registrar_conexion(habitacion_origen, direccion, nombre_habitacion)
	
	print("🔄 HOST: (sync) " + nombre_habitacion + " en (" + str(coord.x) + "," + str(coord.y) + ") conectada desde " + habitacion_origen + "[" + direccion + "]")
	
	habitacion_actualizada_signal.emit(nombre_habitacion)

@rpc("any_peer")
func habitacion_rechazada(motivo: String):
	print("❌ HOST: habitación rechazada: " + motivo)
	habitacion_rechazada_signal.emit(motivo)

@rpc("any_peer")
func solicitar_mover_jugador(nombre_jugador: String, habitacion_destino: String):
	if multiplayer.is_server():
		RoomData.actualizar_posicion_jugador(nombre_jugador, habitacion_destino)
		habitacion_actualizada_signal.emit(habitacion_destino)
		sync_jugador_movido.rpc(nombre_jugador, habitacion_destino)

@rpc("any_peer")
func sync_jugador_movido(nombre_jugador: String, habitacion_destino: String):
	RoomData.actualizar_posicion_jugador(nombre_jugador, habitacion_destino)
	habitacion_actualizada_signal.emit(habitacion_destino)

# =====================================================================
#  COLORES
# =====================================================================

@rpc("any_peer")
func enviar_color_jugador(nombre: String, color: String):
	var nombre_normalizado = nombre.strip_edges().to_upper()
	
	if multiplayer.is_server():
		if color in colores_usados:
			var jugador_con_ese_color = colores_usados[color]
			if jugador_con_ese_color != nombre_normalizado:
				color_ya_usado.rpc_id(multiplayer.get_remote_sender_id(), color, jugador_con_ese_color)
				return
		
		colores_usados[color] = nombre_normalizado
		Global.actualizar_color_jugador(nombre_normalizado, color)
		sync_colores.rpc(nombre_normalizado, color)
		colores_actualizados.emit(nombre_normalizado, color)

@rpc("any_peer")
func sync_colores(nombre: String, color: String):
	colores_usados[color] = nombre
	colores_actualizados.emit(nombre, color)

@rpc("any_peer")
func color_ya_usado(color: String, jugador_que_lo_tiene: String):
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
signal jugadores_prueba_recibidos(jugadores: Array, reservados: Dictionary)
signal reserva_exitosa(nombre: String)
signal reserva_fallida(nombre: String, razon: String)
signal reservas_actualizadas(reservados: Dictionary)
signal habitacion_rechazada_signal(motivo: String)
