extends "res://scripts/systems/zone_base.gd"
## Zone 2 — The Manic Garden.
## Oversaturated, too-bright, dangerously beautiful.
## The Reveler roams in packs. The puzzle of over-stimulation guards the Hedonist.
## Mental state: mood surges on entry. The world looks like it's inviting you in.


@export var reveler_scene: PackedScene

@onready var reveler_spawns: Node3D = $RevelerSpawns
@onready var projection_trigger: Area3D = $ProjectionTrigger


func _ready() -> void:
	zone_id              = "zone_02_manic_garden"
	zone_display_name    = "The Manic Garden"
	mental_state_event   = "zone_enter_manic_garden"
	entry_monologue_beat = "game_start"
	super()
	_spawn_revelers()
	projection_trigger.body_entered.connect(_on_projection_trigger)


func _spawn_revelers() -> void:
	if reveler_scene == null:
		push_warning("Zone 2: reveler_scene not assigned")
		return
	for spawn in reveler_spawns.get_children():
		var r: Node3D = reveler_scene.instantiate()
		add_child(r)
		r.global_position = spawn.global_position


func _on_projection_trigger(body: Node3D) -> void:
	if body.is_in_group("player"):
		ProjectionSequenceManager.trigger(zone_id)


func _on_zone_entered() -> void:
	NarrativeManager.trigger_custom("everything's too bright. you feel like you could run forever.")
