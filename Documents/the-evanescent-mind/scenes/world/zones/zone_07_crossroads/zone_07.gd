extends "res://scripts/systems/zone_base.gd"
## Zone 7 — The Crossroads.
## All paths from all zones meet here. No enemy. No combat.
## The Nihilist stands at the centre. The Threshold is visible from here.
## Mental state converges toward a quiet, still centre. Focus rises.


@onready var projection_trigger: Area3D  = $ProjectionTrigger
@onready var threshold_gate: Area3D      = $ThresholdGate


func _ready() -> void:
	zone_id              = "zone_07_crossroads"
	zone_display_name    = "The Crossroads"
	mental_state_event   = "zone_enter_crossroads"
	entry_monologue_beat = "all_pieces_gathered"
	super()
	projection_trigger.body_entered.connect(_on_projection_trigger)
	threshold_gate.body_entered.connect(_on_threshold_gate)


func _on_projection_trigger(body: Node3D) -> void:
	if body.is_in_group("player"):
		ProjectionSequenceManager.trigger(zone_id)


func _on_threshold_gate(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	if GameState.all_pieces_collected():
                # Use ZoneManager to load threshold — index 7 in ZONE_PATHS
                ZoneManager.load_zone(7)


func _on_zone_entered() -> void:
	NarrativeManager.trigger_custom("all roads. one place. you've been here before. just not from this direction.")
