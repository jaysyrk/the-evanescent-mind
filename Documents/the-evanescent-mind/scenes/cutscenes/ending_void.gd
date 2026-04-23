extends Node
## Ending A — The Kindest Void.
## The ritual completes. All light, sensation, and existence ends.
## Tone: quiet. Not triumphant. Not tragic. The MC got what they wanted.
## The question the ending asks: was this mercy, or was it fear?


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_play_sequence()


func _play_sequence() -> void:
	# Full black already — EndingSystem called SaveSystem and loaded this scene
	# Sequence: silence → single line → longer silence → credits fade in
	await get_tree().create_timer(2.5).timeout

	_show_line("it is done.")
	await get_tree().create_timer(3.5).timeout

	_show_line("no more pain.")
	await get_tree().create_timer(4.0).timeout

	_show_line("no more anything.")
	await get_tree().create_timer(5.0).timeout

	_show_line("you were so tired.")
	await get_tree().create_timer(4.5).timeout

	_show_line("...")
	await get_tree().create_timer(6.0).timeout

	# No credits. Just the question.
	_show_line("was this mercy?")
	await get_tree().create_timer(8.0).timeout

	_show_line("or were you just afraid she wouldn't choose you?")
	await get_tree().create_timer(10.0).timeout

	_fade_to_title()


func _show_line(text: String) -> void:
	var label: Label = $CentreLabel
	label.text = text
	label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 1.2)
	await tween.finished
	await get_tree().create_timer(0.3).timeout
	var out := create_tween()
	out.tween_property(label, "modulate:a", 0.0, 1.0)
	await out.finished


func _fade_to_title() -> void:
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
