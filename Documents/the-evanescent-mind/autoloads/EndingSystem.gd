extends Node
## EndingSystem — evaluates game state at The Threshold and routes to an ending.
## There is exactly one decision point. All prior flags are flavoring.


func _ready() -> void:
	EventBus.ending_triggered.connect(_on_ending_triggered)


# ── Called from the Threshold scene ──────────────────────────────────────────
func trigger_ending(choice: String) -> void:
	assert(choice in ["void", "stay"], "EndingSystem: invalid ending choice '%s'" % choice)
	assert(GameState.get_flag("all_pieces_gathered"),
		"EndingSystem: ending triggered before all pieces gathered — check Threshold logic")

	GameState.set_flag("ending", choice)
	GameState.set_flag("game_complete", true)
	SaveSystem.save_game()
	EventBus.ending_triggered.emit(choice)


func _on_ending_triggered(ending_id: String) -> void:
	var scene_path := "res://scenes/cutscenes/ending_%s.tscn" % ending_id
	if not ResourceLoader.exists(scene_path):
		push_error("EndingSystem: ending scene not found at '%s'" % scene_path)
		return

	# Transition to ending scene with a brief fade
	var tree := get_tree()
	if tree:
		tree.change_scene_to_file(scene_path)
