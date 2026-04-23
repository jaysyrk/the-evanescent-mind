extends "res://scripts/systems/puzzle_base.gd"
## Puzzle: Stimulation Overload — Zone 2, The Manic Garden.
## Moving light triggers fill the arena. Player must reach the centre without contact.
## Being hit teleports the player back to the start marker.
## Teaches: the manic high is not safe, no matter how beautiful.


const RESET_POSITION := Vector3(0, 0, 10)

@onready var light_triggers: Node3D  = $LightTriggers
@onready var goal_area: Area3D       = $GoalArea
@onready var start_marker: Marker3D  = $StartMarker

var _player_ref: Node3D = null


func _setup() -> void:
	puzzle_id = "puzzle_stimulation_overload"
	for trigger in light_triggers.get_children():
		if trigger is Area3D:
			trigger.body_entered.connect(_on_light_hit)
	goal_area.body_entered.connect(_on_goal_reached)


func _process(delta: float) -> void:
	if is_solved:
		return
	# Rotate light triggers — speed scales with MC's mood (manic = faster)
	var speed := 1.0 + MentalStateManager.mood * 0.8
	light_triggers.rotate_y(speed * delta)


func _on_light_hit(body: Node3D) -> void:
	if not body.is_in_group("player") or is_solved:
		return
	_player_ref = body
	NarrativeManager.trigger_custom("too bright. too much. start again.")
	body.global_position = start_marker.global_position


func _on_goal_reached(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	complete_puzzle()


func _on_puzzle_solved() -> void:
	NarrativeManager.trigger_custom(
		"you made it through without being consumed by it. the lights don't stop. you just learned to not need them to."
	)
	light_triggers.visible = false
