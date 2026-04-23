extends "res://scripts/systems/puzzle_base.gd"
## Puzzle: Integration — Zone 7, The Crossroads.
## Five small platforms, each containing a micro-version of the previous 5 puzzles.
## Must complete all 5 to unlock the path to The Threshold.
## Each completion plays a monologue beat.


const MICRO_BEATS := [
	"the lights. you remember the lights.",
	"the quiet. you remember being still.",
	"the ash. you remember choosing.",
	"the laughter. you remember not taking it personally.",
	"her face. in five memories. yours and hers."
]

@onready var platforms: Node3D = $MicroPlatforms

var _completed: Array[bool] = [false, false, false, false, false]
var _micro_areas: Array[Area3D] = []


func _setup() -> void:
	puzzle_id = "puzzle_integration"
	for i in range(1, 6):
		var platform: Area3D = platforms.get_node_or_null("Platform%d" % i)
		if platform:
			_micro_areas.append(platform)
			var idx := i - 1
			platform.body_entered.connect(func(body): _on_platform_entered(body, idx))


func _on_platform_entered(body: Node3D, idx: int) -> void:
	if not body.is_in_group("player") or _completed[idx]:
		return
	_completed[idx] = true
	NarrativeManager.trigger_custom(MICRO_BEATS[idx])

	# Mark platform as done visually
	var mesh: MeshInstance3D = _micro_areas[idx].get_node_or_null("MeshInstance3D")
	if mesh:
		var mat: StandardMaterial3D = mesh.get_active_material(0)
		if mat:
			mat.emission_energy_multiplier = 2.5

	if _completed.all(func(v): return v):
		await get_tree().create_timer(1.5).timeout
		complete_puzzle()


func _on_puzzle_solved() -> void:
	NarrativeManager.trigger_custom(
		"all of it. all seven truths and none of them enough on their own. together they make something. you're not sure what to call it."
	)
