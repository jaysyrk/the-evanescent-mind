extends Node3D
## The Threshold — the final scene.
## All 7 ritual pieces must be gathered before this scene becomes active.
## Celeste is present. The MC stands at the altar.
## One decision point: "Begin the Ritual" vs "Look at her."
## No combat. No puzzle. Just the choice.


const DECISION_COOLDOWN := 3.0  # seconds before choices appear — silence before the decision

@onready var ritual_altar: Node3D    = $RitualAltar
@onready var celeste_instance: Node3D = $CelesteNPC
@onready var choice_ui: Control      = $ThresholdChoiceUI
@onready var begin_btn: Button       = $ThresholdChoiceUI/VBox/BeginRitualBtn
@onready var look_btn: Button        = $ThresholdChoiceUI/VBox/LookAtHerBtn
@onready var entry_trigger: Area3D   = $EntryTrigger

var _player_arrived: bool = false
var _choice_made: bool = false


func _ready() -> void:
	choice_ui.visible = false
	entry_trigger.body_entered.connect(_on_player_arrived)
	begin_btn.pressed.connect(_on_begin_ritual)
	look_btn.pressed.connect(_on_look_at_her)

	# Lock if not all pieces gathered
	if not GameState.all_pieces_collected():
		NarrativeManager.trigger_custom(
			"the altar waits. but you aren't ready yet. you can feel the gaps in what you know."
		)
		entry_trigger.set_deferred("monitoring", false)


func _on_player_arrived(body: Node3D) -> void:
	if not body.is_in_group("player") or _player_arrived:
		return
	_player_arrived = true
	GameState.set_flag("threshold_reached", true)
	EventBus.threshold_reached.emit()
	MentalStateManager.apply_event("zone_enter_threshold")
	NarrativeManager.trigger_beat("celeste_at_threshold")

	await get_tree().create_timer(DECISION_COOLDOWN).timeout
	_show_choices()


func _show_choices() -> void:
	choice_ui.visible = true
	var tween := create_tween()
	tween.tween_property(choice_ui, "modulate:a", 1.0, 1.5).from(0.0)

	# Keyboard shortcuts also work
	set_process_input(true)


func _input(event: InputEvent) -> void:
	if not choice_ui.visible or _choice_made:
		return
	# "Begin the Ritual" — action mapped or hardcoded
	if event.is_action_pressed("ui_accept") and begin_btn.has_focus():
		_on_begin_ritual()
	if event.is_action_pressed("interact") and look_btn.has_focus():
		_on_look_at_her()


func _on_begin_ritual() -> void:
	if _choice_made:
		return
	_choice_made = true
	choice_ui.visible = false
	NarrativeManager.trigger_custom(
		"you reach for it. the ritual. the answer you built out of every broken thing."
	)
	await get_tree().create_timer(2.0).timeout
	EndingSystem.trigger_ending("void")


func _on_look_at_her() -> void:
	if _choice_made:
		return
	_choice_made = true
	choice_ui.visible = false
	NarrativeManager.trigger_custom(
		"you don't do it. you just — look at her. really look."
	)
	await get_tree().create_timer(2.0).timeout
	EndingSystem.trigger_ending("stay")
