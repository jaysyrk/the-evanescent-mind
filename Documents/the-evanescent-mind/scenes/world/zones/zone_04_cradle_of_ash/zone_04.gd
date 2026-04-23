extends "res://scripts/systems/zone_base.gd"
## Zone 4 — The Cradle of Ash.
## Warm-grey, ash-covered, birth and death as the same event.
## The Infant Eternal spawns in groups. Two altars gate the Antinatalist.
## Mental state: focus rises, mood falls — clarity of grief.


@export var infant_scene: PackedScene

@onready var infant_spawns: Node3D       = $InfantSpawns
@onready var projection_trigger: Area3D  = $ProjectionTrigger
@onready var birth_altar: Area3D         = $BirthAltar
@onready var never_born_altar: Area3D    = $NeverBornAltar


func _ready() -> void:
	zone_id              = "zone_04_cradle_of_ash"
	zone_display_name    = "The Cradle of Ash"
	mental_state_event   = "zone_enter_void"  # Shares void event: quiet grief
	entry_monologue_beat = "game_start"
	super()
	_spawn_infants()
	projection_trigger.body_entered.connect(_on_projection_trigger)
	birth_altar.body_entered.connect(_on_birth_altar)
	never_born_altar.body_entered.connect(_on_never_born_altar)


func _spawn_infants() -> void:
	if infant_scene == null:
		push_warning("Zone 4: infant_scene not assigned")
		return
	for spawn in infant_spawns.get_children():
		# Spawn 3 per point
		for _i in range(3):
			var inf: Node3D = infant_scene.instantiate()
			add_child(inf)
			inf.global_position = spawn.global_position + Vector3(
				randf_range(-1.5, 1.5), 0, randf_range(-1.5, 1.5)
			)


func _on_projection_trigger(body: Node3D) -> void:
	if body.is_in_group("player"):
		ProjectionSequenceManager.trigger(zone_id)


func _on_birth_altar(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("zone04_altar_choice", "birth")
	NarrativeManager.trigger_custom(
		"born into it. you think of all the things they never chose. and the things they did."
	)


func _on_never_born_altar(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	GameState.set_flag("zone04_altar_choice", "never_born")
	NarrativeManager.trigger_custom(
		"never begun. no consent, no harm, no moment. is that mercy or is that nothing?"
	)


func _on_zone_entered() -> void:
	NarrativeManager.trigger_custom("there's ash everywhere. something was here. recently.")
