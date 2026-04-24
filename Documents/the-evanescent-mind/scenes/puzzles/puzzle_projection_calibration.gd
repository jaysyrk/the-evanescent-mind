extends "res://scripts/systems/puzzle_base.gd"
## Puzzle: Projection Calibration — Zone 6, The Limerent Archive.
## 5 memory orbs scattered in the zone. Player touches them in the correct order.
## Correct sequence: 3, 1, 5, 2, 4 — non-obvious. Can be decoded from orb names/labels.
## Wrong order: brief visual flash + reset.
## Teaches: memories have an order. not all of it is yours.


const CORRECT_ORDER := [3, 1, 5, 2, 4]

## The MemoryOrbs node lives in the zone scene, not inside this puzzle.
## This export is assigned in the zone inspector OR falls back to a sibling search.
@export var memory_orbs_node: Node3D

var _touch_sequence: Array[int] = []
var _orb_refs: Array[Area3D] = []


func _setup() -> void:
	puzzle_id = "puzzle_projection_calibration"
	# Resolve MemoryOrbs: use export if set, else search in parent
	var orbs: Node3D = memory_orbs_node
	if orbs == null:
		orbs = get_parent().get_node_or_null("MemoryOrbs")
	if orbs == null:
		push_warning("PuzzleProjectionCalibration: MemoryOrbs not found — assign memory_orbs_node in Inspector")
		return
	for i in range(1, 6):
		var orb: Area3D = orbs.get_node_or_null("Orb%d" % i)
		if orb:
			_orb_refs.append(orb)
			var orb_index := i
			orb.body_entered.connect(func(body): _on_orb_touched(body, orb_index))


func _on_orb_touched(body: Node3D, orb_index: int) -> void:
	if not body.is_in_group("player") or is_solved:
		return

	_touch_sequence.append(orb_index)
	var pos := _touch_sequence.size() - 1

	if _touch_sequence[pos] != CORRECT_ORDER[pos]:
		# Wrong order — flash and reset
		NarrativeManager.trigger_custom("that memory doesn't go there.")
		_touch_sequence.clear()
		_flash_reset()
		return

	if _touch_sequence.size() == CORRECT_ORDER.size():
		complete_puzzle()


func _flash_reset() -> void:
	# Brief visual feedback (shader could handle this; use a simple tween for now)
	for orb in _orb_refs:
		var mat := orb.get_node_or_null("MeshInstance3D")
		if mat:
			var tween := create_tween()
			tween.tween_property(mat, "modulate", Color(1, 0.2, 0.2), 0.15)
			tween.tween_property(mat, "modulate", Color(1, 1, 1), 0.3)


func _on_puzzle_solved() -> void:
	NarrativeManager.trigger_custom(
		"all five. in order. the archive opened something. you're not sure what it was, but it was yours."
	)
