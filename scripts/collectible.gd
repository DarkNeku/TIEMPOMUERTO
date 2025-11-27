extends Area2D

signal collected

func _on_body_entered(body):
	if body is CharacterBody2D:
		collected.emit()
		queue_free()
