extends Area3D
## ZoneExitPortal — place this Area3D at the exit of any zone.
## When the player walks through it, ZoneManager loads the next zone.
##
## Usage:
##   - Instance zone_exit_portal.tscn in the zone scene (or attach this script
##     directly to a named "ZoneExit" Area3D node).
##   - Optionally set `require_piece_collected` to a flag name (e.g. "piece_stoic")
##     to block exit until that piece has been obtained.
##   - The portal becomes visible (glowing label) only when the condition is met.


@export var require_piece_flag: String = ""
@export var blocked_monologue: String  = "Something holds you here. You haven't finished."


func _ready() -> void:
	body_entered.connect(_on_body_entered)
	_refresh_visibility()
	EventBus.flag_set.connect(_on_flag_set)


func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return

	if require_piece_flag != "" and not GameState.get_flag(require_piece_flag):
		NarrativeManager.trigger_custom(blocked_monologue)
		return

	ZoneManager.advance_zone()


func _on_flag_set(flag_name: String, _value) -> void:
	if flag_name == require_piece_flag:
		_refresh_visibility()


func _refresh_visibility() -> void:
	if require_piece_flag == "":
		return
	# Show a subtle label hint once piece is collected
	var label: Label3D = get_node_or_null("HintLabel")
	if label != null:
		label.visible = GameState.get_flag(require_piece_flag)
