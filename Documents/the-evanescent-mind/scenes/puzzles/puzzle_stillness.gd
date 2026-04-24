extends "res://scripts/systems/puzzle_base.gd"
## Puzzle: Stillness — Zone 3, The Still Void.
## Player must remain still (velocity < threshold) for a sustained duration.
## The Absence phases in and out, threatening to trigger movement.
## Required still time scales inversely with current focus.
## Teaches: the void isn't empty. it has texture, if you stop running.


const BASE_STILL_DURATION := 30.0
const VELOCITY_THRESHOLD  := 0.15

@onready var still_timer_label: Label3D = $StillTimerLabel   # Optional visual feedback

var _still_elapsed: float = 0.0
var _required_duration: float = BASE_STILL_DURATION
var _player_ref: Node3D = null
var _monitoring: bool = false


func _setup() -> void:
	puzzle_id = "puzzle_stillness"
	_required_duration = BASE_STILL_DURATION
	# Find player when puzzle activates
	await get_tree().create_timer(0.5).timeout
	_player_ref = get_tree().get_first_node_in_group("player")
	_monitoring = true

	if still_timer_label:
		still_timer_label.visible = true


func _process(delta: float) -> void:
	if is_solved or not _monitoring or _player_ref == null:
		return

	# Adjust required duration based on focus (high focus = shorter)
	_required_duration = BASE_STILL_DURATION * (1.0 - MentalStateManager.focus * 0.4)

	var speed: float = (_player_ref as CharacterBody3D).velocity.length()
	if speed < VELOCITY_THRESHOLD:
		_still_elapsed += delta
		if still_timer_label:
			still_timer_label.text = "%.1f / %.1f" % [_still_elapsed, _required_duration]
		if _still_elapsed >= _required_duration:
			complete_puzzle()
	else:
		if _still_elapsed > 0.5:
			NarrativeManager.trigger_custom("you moved. the void reset.")
		_still_elapsed = 0.0
		if still_timer_label:
			still_timer_label.text = ""


func _on_puzzle_solved() -> void:
	_monitoring = false
	if still_timer_label:
		still_timer_label.visible = false
	NarrativeManager.trigger_custom(
		"thirty seconds of not running. something in the dark looked back. it didn't hurt."
	)
