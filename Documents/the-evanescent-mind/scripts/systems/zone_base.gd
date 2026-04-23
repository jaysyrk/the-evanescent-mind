extends Node3D
## ZoneBase — parent class for all 7 Reality Fragments.
## Handles: zone entry/exit signals, mental state event, music transition,
##          monologue trigger, and philosopher piece tracking.


## Set this in each zone subclass or via the Inspector.
@export var zone_id: String = ""
@export var zone_display_name: String = ""
@export var mental_state_event: String = ""   # passed to MentalStateManager.apply_event()
@export var entry_monologue_beat: String = "" # passed to NarrativeManager.trigger_beat()

## Collision layer of the zone's entry Area3D trigger
@onready var entry_trigger: Area3D = $EntryTrigger
@onready var world_env: WorldEnvironment = $WorldEnvironment

var _player_inside: bool = false


func _ready() -> void:
	assert(zone_id != "", "ZoneBase: zone_id must be set on " + name)
	entry_trigger.body_entered.connect(_on_body_entered)
	entry_trigger.body_exited.connect(_on_body_exited)


# ── Entry / Exit ──────────────────────────────────────────────────────────────
func _on_body_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or _player_inside:
		return
	_player_inside = true
	EventBus.zone_entered.emit(zone_id)

	if mental_state_event != "":
		MentalStateManager.apply_event(mental_state_event)

	if entry_monologue_beat != "":
		NarrativeManager.trigger_beat(entry_monologue_beat)

	_on_zone_entered()


func _on_body_exited(body: Node3D) -> void:
	if not body.is_in_group("player") or not _player_inside:
		return
	_player_inside = false
	EventBus.zone_exited.emit(zone_id)
	_on_zone_exited()


## Override in subclass for zone-specific entry logic.
func _on_zone_entered() -> void:
	pass


## Override in subclass for zone-specific exit logic.
func _on_zone_exited() -> void:
	pass
