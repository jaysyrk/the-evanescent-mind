extends "res://scripts/systems/zone_base.gd"
## Zone 5 — The Laughing Labyrinth.
## Shifting geometry, high contrast, disorienting. The Jester teleports through it.
## Mental state: anxiety rises sharply. But high anxiety opens extra paths (useful).
## The labyrinth doors' state is driven by MC's anxiety level.


@export var jester_scene: PackedScene

@onready var jester_spawns: Node3D       = $JesterSpawns
@onready var projection_trigger: Area3D  = $ProjectionTrigger
@onready var anxiety_doors: Node3D       = $AnxietyDoors  # Doors that open at high anxiety


func _ready() -> void:
	zone_id              = "zone_05_laughing_labyrinth"
	zone_display_name    = "The Laughing Labyrinth"
	mental_state_event   = "zone_enter_labyrinth"
	entry_monologue_beat = "enter_zone_05"
	super()
	_spawn_jesters()
	projection_trigger.body_entered.connect(_on_projection_trigger)
	EventBus.anxiety_threshold_crossed.connect(_on_anxiety_changed)


func _spawn_jesters() -> void:
	if jester_scene == null:
		push_warning("Zone 5: jester_scene not assigned")
		return
	for spawn in jester_spawns.get_children():
		var j: Node3D = jester_scene.instantiate()
		add_child(j)
		j.global_position = spawn.global_position


func _on_projection_trigger(body: Node3D) -> void:
	if body.is_in_group("player"):
		ProjectionSequenceManager.trigger(zone_id)


func _on_anxiety_changed(level: String) -> void:
	if not _player_inside:
		return
	# When anxiety is high, certain doors swing open
	for door in anxiety_doors.get_children():
		if door.has_method("set_open"):
			door.call("set_open", level == "high")


func _on_zone_entered() -> void:
	NarrativeManager.trigger_custom(
		"the corridors keep changing. you can feel your heart rate climbing. somehow that helps."
	)
