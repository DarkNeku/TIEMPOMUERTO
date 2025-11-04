extends CanvasLayer

@onready var time_label = $HUD/TimeLabel
@onready var score_label = $HUD/ScoreLabel
@onready var game_over_panel = $GameOver
@onready var final_score_label = $GameOver/Container/FinalScore

func update_time(time_left: float):
	time_label.text = str(ceil(time_left))
	
	# Cambiar color según el tiempo restante
	if time_left < 10:
		time_label.modulate = Color(1, 0.2, 0.2)
	elif time_left < 30:
		time_label.modulate = Color(1, 0.8, 0.2)
	else:
		time_label.modulate = Color(1, 1, 1)

func update_score(score: int):
	score_label.text = "Score: " + str(score)

func show_game_over(final_score: int):
	final_score_label.text = "Puntuación Final: " + str(final_score)
	game_over_panel.visible = true

func _input(event):
	if event.is_action_pressed("ui_accept") or (event is InputEventKey and event.pressed and event.keycode == KEY_R):
		if game_over_panel.visible:
			get_tree().paused = false
			get_tree().reload_current_scene()
