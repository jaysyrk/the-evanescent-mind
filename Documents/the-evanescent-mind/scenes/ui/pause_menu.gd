extends Control
## PauseMenu — overlaid on the game via CanvasLayer (layer=15).
## Esc toggles. Resumes, saves, and quits.


func _ready() -> void:
	visible = false
	process_mode = Node.PROCESS_MODE_ALWAYS
	$VBox/ResumeBtn.pressed.connect(_on_resume_pressed)
	$VBox/SaveBtn.pressed.connect(_on_save_pressed)
	$VBox/QuitBtn.pressed.connect(_on_quit_pressed)


func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		if visible:
			_resume()
		else:
			_pause()


func _pause() -> void:
	visible = true
	get_tree().paused = true
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)


func _resume() -> void:
	visible = false
	get_tree().paused = false
	Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_resume_pressed() -> void:
	_resume()


func _on_save_pressed() -> void:
	SaveSystem.save_game()
	NarrativeManager.trigger_custom("saved.")


func _on_quit_pressed() -> void:
	SaveSystem.save_game()
	get_tree().quit()
