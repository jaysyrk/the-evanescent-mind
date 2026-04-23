extends "res://scripts/systems/zone_base.gd"
## Zone 3 — The Still Void.
## Near-black, sparse, quiet. The Absence moves through it like weather.
## The puzzle of stillness guards the Buddhist.
## Mental state: focus initially scatters. Then, if the player slows, it consolidates.


@export var absence_scene: PackedScene

@onready var absence_spawns: Node3D  = $AbsenceSpawns
@onready var projection_trigger: Area3D = $ProjectionTrigger


func _ready() -> void:
	zone_id              = "zone_03_still_void"
	zone_display_name    = "The Still Void"
	mental_state_event   = "zone_enter_void"
	entry_monologue_beat = "game_start"
	super()
	_spawn_absences()
	projection_trigger.body_entered.connect(_on_projection_trigger)


func _spawn_absences() -> void:
	if absence_scene == null:
		push_warning("Zone 3: absence_scene not assigned")
		return
	for spawn in absence_spawns.get_children():
		var a: Node3D = absence_scene.instantiate()
		add_child(a)
		a.global_position = spawn.global_position


func _on_projection_trigger(body: Node3D) -> void:
	if body.is_in_group("player"):
		ProjectionSequenceManager.trigger(zone_id)


func _on_zone_entered() -> void:
	NarrativeManager.trigger_custom("nothing. a vast, quiet nothing. you thought you wanted this.")
