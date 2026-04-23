extends Control
## MainMenu — first scene the player sees.
## New Game: loads zone 1.
## Continue: loads save if exists, otherwise greys out.
## Exit: quits.


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	var can_continue := SaveSystem.save_exists()
	$VBox/ContinueBtn.disabled = not can_continue
	$VBox/NewGameBtn.pressed.connect(_on_new_game_pressed)
	$VBox/ContinueBtn.pressed.connect(_on_continue_pressed)
	$VBox/ExitBtn.pressed.connect(_on_exit_pressed)


func _on_new_game_pressed() -> void:
	SaveSystem.reset()
	ZoneManager.load_zone(0)


func _on_continue_pressed() -> void:
	if SaveSystem.load_game():
		var saved_zone: int = GameState.get_flag("current_zone_index") if GameState.get_flag("current_zone_index") != null else 0
		ZoneManager.load_zone(saved_zone)


func _on_exit_pressed() -> void:
	get_tree().quit()
