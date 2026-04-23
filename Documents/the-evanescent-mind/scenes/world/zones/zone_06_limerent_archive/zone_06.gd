extends "res://scripts/systems/zone_base.gd"
## Zone 6 — The Limerent Archive.
## Warm sepia, golden dust, books and memories. The Shade walks through it.
## Most intimate zone. Projection trigger is mandatory — can't reach Theist without it.
## Mental state: limerence rises throughout. Anxiety is secondary.


@export var shade_scene: PackedScene

@onready var shade_spawns: Node3D          = $ShadeSpawns
@onready var projection_trigger: Area3D    = $ProjectionTrigger
@onready var memory_orbs: Node3D           = $MemoryOrbs   # For projection calibration puzzle


func _ready() -> void:
	zone_id              = "zone_06_limerent_archive"
	zone_display_name    = "The Limerent Archive"
	mental_state_event   = "zone_enter_limerent_archive"
	entry_monologue_beat = "game_start"
	super()
	_spawn_shades()
	projection_trigger.body_entered.connect(_on_projection_trigger)


func _spawn_shades() -> void:
	if shade_scene == null:
		push_warning("Zone 6: shade_scene not assigned")
		return
	for spawn in shade_spawns.get_children():
		var s: Node3D = shade_scene.instantiate()
		add_child(s)
		s.global_position = spawn.global_position


func _on_projection_trigger(body: Node3D) -> void:
	if body.is_in_group("player"):
		ProjectionSequenceManager.trigger(zone_id)


func _on_zone_entered() -> void:
	NarrativeManager.trigger_custom(
		"she's everywhere here. her handwriting on pages you've never seen. you must have imagined it."
	)
