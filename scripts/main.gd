extends Node2D

@onready var game_timer = $GameTimer
@onready var ui = $UI
@onready var player = $Player
@onready var objects_container = $Objects

var score = 0
var game_over = false

# Escena del objeto coleccionable
const COLLECTIBLE_SCENE = preload("res://scenes/collectible.tscn")

func _ready():
	ui.update_time(game_timer.time_left)
	ui.update_score(score)

func _process(delta):
	if not game_over and game_timer.time_left > 0:
		ui.update_time(game_timer.time_left)

func _on_game_timer_timeout():
	game_over = true
	ui.show_game_over(score)
	get_tree().paused = true

func _on_object_spawner_timeout():
	if game_over:
		return
	spawn_collectible()

func spawn_collectible():
	var collectible = COLLECTIBLE_SCENE.instantiate()
	
	# Posición aleatoria en pantalla
	var viewport_size = get_viewport_rect().size
	var margin = 50
	collectible.position = Vector2(
		randf_range(margin, viewport_size.x - margin),
		randf_range(margin, viewport_size.y - margin)
	)
	
	objects_container.add_child(collectible)
	collectible.collected.connect(_on_collectible_collected)

func _on_collectible_collected():
	score += 10
	ui.update_score(score)
	# Añadir tiempo bonus
	var new_time = game_timer.time_left + 2.0
	game_timer.wait_time = new_time
	game_timer.start()
