extends Node2D

var timer: Timer
var conectado: bool = false

func _ready():
	$Panel/BTN_VOLVER.connect("pressed", Callable(self, "on_btn_volver_pressed"))
	$Panel/BTN_UNIRSE_SALA.connect("pressed", Callable(self, "on_btn_unirse_sala_pressed"))

	# Conectar al host automáticamente al entrar
	var ip_host = "127.0.0.1" # IP del host (localhost para pruebas)
	if Network.connect_to_host(ip_host):
		print("Conectado al host en: " + ip_host)
		conectado = true
		# Esperar un momento para que la conexión se establezca
		await get_tree().create_timer(0.5).timeout
		# Solicitar la lista de salas al host
		Network.pedir_salas.rpc_id(1)
	else:
		print("No se pudo conectar al host")

	mostrar_salas()

	# Timer para refrescar la lista de salas
	timer = Timer.new()
	timer.wait_time = 1.0
	timer.autostart = true
	timer.one_shot = false
	timer.connect("timeout", Callable(self, "on_timer_timeout"))
	add_child(timer)

func on_timer_timeout():
	if conectado:
		Network.pedir_salas.rpc_id(1)
	mostrar_salas()

func mostrar_salas():
	$Panel/LISTA_SALA.clear()
	var salas = Network.get_salas()
	print("Salas disponibles: " + str(salas))
	for sala in salas:
		$Panel/LISTA_SALA.add_item(sala)

func on_btn_volver_pressed():
	get_tree().change_scene_to_file("res://SCENE/MAIN_MENU.tscn")

func on_btn_unirse_sala_pressed():
	# Verificar que los nodos existan
	if not has_node("Panel/TXT_NOMBRE"):
		print("ERROR: No se encontró el nodo Panel/TXT_NOMBRE")
		print("Estructura de nodos disponible:")
		print_tree_pretty()
		return

	if not has_node("Panel/LISTA_SALA"):
		print("ERROR: No se encontró el nodo Panel/LISTA_SALA")
		return

	var nombre_usuario = $Panel/TXT_NOMBRE.text

	# Validar que el nombre de usuario no esté vacío
	if nombre_usuario.strip_edges() == "":
		print("ERROR: Debes ingresar un nombre de usuario")
		return

	var sala_seleccionada = $Panel/LISTA_SALA.get_selected_items()

	if sala_seleccionada.size() > 0:
		var nombre_sala = $Panel/LISTA_SALA.get_item_text(sala_seleccionada[0])
		print("Uniéndose a la sala: " + nombre_sala)
		print("Usuario: " + nombre_usuario)

		# Enviar al host la solicitud de unirse
		Network.unirse_sala.rpc_id(1, nombre_sala, nombre_usuario)
		Network.sala_actual = nombre_sala

		# Ir al lobby
		get_tree().change_scene_to_file("res://SCENE/LOBBY.tscn")
	else:
		print("Debes seleccionar una sala primero")
