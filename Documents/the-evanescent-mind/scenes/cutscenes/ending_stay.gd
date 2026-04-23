extends Node
## Ending B — The Weight Worth Bearing.
## The MC looks at Celeste. Really looks. And stays.
## Tone: not happy. Not healed. But present.
## The world doesn't fix itself. The MC doesn't fix themselves.
## They just decide to remain in it.


func _ready() -> void:
	Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
	_play_sequence()


func _play_sequence() -> void:
	await get_tree().create_timer(2.0).timeout

	_show_line("she's looking back.")
	await get_tree().create_timer(4.0).timeout

	_show_line("not with the answer.")
	await get_tree().create_timer(3.5).timeout

	_show_line("just looking.")
	await get_tree().create_timer(5.0).timeout

	_show_line("you don't know what you are to her.")
	await get_tree().create_timer(4.5).timeout

	_show_line("you don't know what tomorrow will do to you.")
	await get_tree().create_timer(4.5).timeout

	_show_line("...")
	await get_tree().create_timer(5.0).timeout

	_show_line("but you're here.")
	await get_tree().create_timer(4.0).timeout

	_show_line("right now, in this exact moment, you're here.")
	await get_tree().create_timer(6.0).timeout

	_show_line("that's not nothing.")
	await get_tree().create_timer(8.0).timeout

	_fade_to_title()


func _show_line(text: String) -> void:
	var label: Label = $CentreLabel
	label.text = text
	label.modulate.a = 0.0
	var tween := create_tween()
	tween.tween_property(label, "modulate:a", 1.0, 1.4)
	await tween.finished
	await get_tree().create_timer(0.5).timeout
	var out := create_tween()
	out.tween_property(label, "modulate:a", 0.0, 1.1)
	await out.finished


func _fade_to_title() -> void:
	await get_tree().create_timer(2.0).timeout
	get_tree().change_scene_to_file("res://scenes/ui/main_menu.tscn")
