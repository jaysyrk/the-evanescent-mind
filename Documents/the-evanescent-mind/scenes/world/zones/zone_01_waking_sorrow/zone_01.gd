extends "res://scripts/systems/zone_base.gd"
## Zone 1 — The Waking Sorrow
##
## The world as it is. Heavy grey light, slow fog, architecture of exhaustion.
## The MC's depressive baseline is strongest here. The Hollow roams freely.
## The Stoic philosopher waits in the centre.
##
## Atmosphere targets:
##   - Desaturated palette, slight blue-grey tint
##   - Dense low fog
##   - Sparse directional light (overcast sky)
##   - Ambient sounds: distant hum, rain, muffled city noise


const ZONE_ID    := "zone_01_waking_sorrow"
const HOLLOW_COUNT := 4

@export var hollow_scene: PackedScene

@onready var hollow_spawns: Node3D       = $HollowSpawns
@onready var stoic_spawn: Marker3D       = $PhilosopherSpawns/StoicSpawn
@onready var ritual_piece_trigger: Area3D = $RitualPieceTrigger


func _ready() -> void:
	zone_id              = ZONE_ID
	zone_display_name    = "The Waking Sorrow"
	mental_state_event   = "zone_enter_waking_sorrow"
	entry_monologue_beat = "game_start"
	super()
	_spawn_hollows()
	ritual_piece_trigger.body_entered.connect(_on_ritual_area_entered)


func _spawn_hollows() -> void:
	if hollow_scene == null:
		push_warning("Zone 1: hollow_scene not assigned in Inspector")
		return
	var spawn_points := hollow_spawns.get_children()
	for i in mini(HOLLOW_COUNT, spawn_points.size()):
		var hollow: Node3D = hollow_scene.instantiate()
		add_child(hollow)
		hollow.global_position = spawn_points[i].global_position


func _on_zone_entered() -> void:
	# Fog and desaturation are handled by WorldVisualManager reacting to
	# MentalStateManager — no manual env changes needed here.
	# Play zone ambient via DynamicAudioManager (triggered by zone_entered signal)
	pass


func _on_ritual_area_entered(body: Node3D) -> void:
	if body.is_in_group("player") and GameState.get_flag("piece_stoic"):
		# Already collected — show reminder monologue
		NarrativeManager.trigger_custom("You've already taken what he had to give.")
