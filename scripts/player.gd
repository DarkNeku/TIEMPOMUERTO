extends CharacterBody2D

const SPEED = 300.0

func _physics_process(delta):
	# Obtener dirección del input
	var direction = Vector2.ZERO
	
	if Input.is_action_pressed("move_right"):
		direction.x += 1
	if Input.is_action_pressed("move_left"):
		direction.x -= 1
	if Input.is_action_pressed("move_down"):
		direction.y += 1
	if Input.is_action_pressed("move_up"):
		direction.y -= 1
	
	# Normalizar para movimiento diagonal consistente
	if direction.length() > 0:
		direction = direction.normalized()
	
	# Aplicar velocidad
	velocity = direction * SPEED
	
	# Mover el personaje
	move_and_slide()
	
	# Mantener dentro de los límites de la pantalla
	var viewport_size = get_viewport_rect().size
	position.x = clamp(position.x, 20, viewport_size.x - 20)
	position.y = clamp(position.y, 20, viewport_size.y - 20)
