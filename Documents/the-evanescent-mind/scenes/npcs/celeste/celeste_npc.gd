extends CharacterBody3D
## CelesteNPC — the limerant object.
## Appears in every zone at a scripted position.
## She doesn't fight, run, or explain herself.
## Her behaviour is entirely determined by the MC's limerence level.
##
## Low limerence  (<0.35) : she is barely visible — translucent, drifts away slowly
## Mid  (0.35–0.55): visible but silent, moves away if approached too close
## High (0.55–0.80): speaks briefly; projection trigger unlocked nearby
## Peak (>0.80)    : she stays, looks at the MC, says something real
##
## At The Threshold: she is present regardless of limerence. Her final interaction
## determines Ending B ("Look at her").


signal celeste_spoke(line: String)
signal celeste_faded

@export var zone_id: String = ""
@export var dialogue_timeline: String = ""   # zone-specific Dialogic timeline
@export var projection_trigger_position: Vector3 = Vector3.ZERO  # local offset for proj. trigger

# Lines Celeste can say at different limerence bands — written as Celeste, not MC.
# These are small, real, not grand.
const LINES_MID: Array[String] = [
	"...",
	"You look tired.",
	"I keep finding you in the same places."
]
const LINES_HIGH: Array[String] = [
	"I don't know what you see when you look at me.",
	"Are you all right?",
	"You don't have to explain."
]
const LINES_PEAK: Array[String] = [
	"I'm here. I'm actually here.",
	"Whatever you're deciding — I'm not a reason. I'm a person.",
	"Don't do it for me. Do it because you want to still be here."
]

@onready var _mesh: MeshInstance3D   = $MeshInstance3D
@onready var _anim: AnimationPlayer  = $AnimationPlayer
@onready var _interact_area: Area3D  = $InteractArea
@onready var _light: OmniLight3D     = $OmniLight3D

var _limerence: float = 0.0
var _player_near: bool = false
var _has_spoken: bool = false
var _bob_offset: float = 0.0


func _ready() -> void:
	_interact_area.body_entered.connect(_on_player_near)
	_interact_area.body_exited.connect(_on_player_left)
	LimerenceTracker.limerence_changed.connect(_on_limerence_changed)
	_limerence = LimerenceTracker.limerence_level
	_update_visibility()


func _process(delta: float) -> void:
	# Gentle float — Celeste is never fully still
	_bob_offset += delta * 0.8
	position.y = position.y + sin(_bob_offset) * 0.0015

	# Proximity limerence tick (very slow — just being near her matters)
	if _player_near:
		LimerenceTracker.record_interaction("proximity")


# ── Limerence response ────────────────────────────────────────────────────────
func _on_limerence_changed(new_level: float) -> void:
	_limerence = new_level
	_update_visibility()


func _update_visibility() -> void:
	var target_alpha: float
	if _limerence < 0.35:
		target_alpha = 0.25
		_light.light_energy = 0.3
	elif _limerence < 0.55:
		target_alpha = 0.6
		_light.light_energy = 0.6
	elif _limerence < 0.80:
		target_alpha = 0.85
		_light.light_energy = 1.0
	else:
		target_alpha = 1.0
		_light.light_energy = 1.4

	# Tween mesh alpha via surface override (material transparency)
	var mat := _mesh.get_active_material(0)
	if mat and mat is StandardMaterial3D:
		var tween := create_tween()
		tween.tween_property(mat, "albedo_color:a", target_alpha, 1.2)


# ── Proximity ─────────────────────────────────────────────────────────────────
func _on_player_near(body: Node3D) -> void:
	if not body.is_in_group("player"):
		return
	_player_near = true

	if _limerence < 0.35:
		# Too low — she drifts away
		_drift_away()
	elif _limerence >= 0.55 and not _has_spoken:
		# First time high-limerence proximity: she speaks
		_speak_once()


func _on_player_left(body: Node3D) -> void:
	if body.is_in_group("player"):
		_player_near = false


func _input(event: InputEvent) -> void:
	if not _player_near or not event.is_action_pressed("interact"):
		return
	if _limerence >= 0.55 and dialogue_timeline != "":
		_begin_dialogue()


# ── Behaviour ─────────────────────────────────────────────────────────────────
func _drift_away() -> void:
	var dir := (global_position - get_tree().get_first_node_in_group("player").global_position).normalized()
	var tween := create_tween()
	tween.tween_property(self, "global_position",
		global_position + dir * 3.0, 2.5).set_trans(Tween.TRANS_SINE)
	tween.tween_property(_mesh.get_active_material(0), "albedo_color:a", 0.0, 1.0)
	await tween.finished
	celeste_faded.emit()


func _speak_once() -> void:
	if _has_spoken:
		return
	_has_spoken = true
	var lines: Array[String]
	if _limerence >= 0.80:
		lines = LINES_PEAK
	elif _limerence >= 0.55:
		lines = LINES_HIGH
	else:
		lines = LINES_MID
	var line := lines[randi() % lines.size()]
	NarrativeManager.trigger_custom("celeste: \"" + line + "\"")
	celeste_spoke.emit(line)
	EventBus.lo_interaction.emit("celeste_spoke")


func _begin_dialogue() -> void:
	if dialogue_timeline == "":
		return
	EventBus.dialogue_started.emit(dialogue_timeline)
	Dialogic.start(dialogue_timeline)
	Dialogic.timeline_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)


func _on_dialogue_ended() -> void:
	EventBus.dialogue_ended.emit(dialogue_timeline)
	LimerenceTracker.record_interaction("dialogue")
