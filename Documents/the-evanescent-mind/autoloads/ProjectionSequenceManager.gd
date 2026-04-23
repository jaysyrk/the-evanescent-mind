extends CanvasLayer
## ProjectionSequenceManager — autoload.
## Orchestrates Celeste projection sequences across all zones.
## Each zone has exactly one sequence of 3 inner-monologue beats.
## Requires limerence >= LimerenceTracker.PROJECTION_UNLOCK_THRESHOLD.
## The visual effect: warm dark overlay + NarrativeManager monologue chain.


signal sequence_completed(zone_id: String)

var _active: bool = false
var _overlay: ColorRect

# Three beats per zone — written in 2nd-person, present tense, lowercase.
const SEQUENCES: Dictionary = {
	"zone_01_waking_sorrow": [
		"she would have known what to say to you. you invented that certainty.",
		"the distance between who she is and who you need her to be — you've been living in that gap.",
		"maybe that's all this is. grief for someone who never quite existed."
	],
	"zone_02_manic_garden": [
		"when you were manic you were sure of it. you were sure of everything.",
		"she looked at you and you thought: this is the thing. this is what makes it worth it.",
		"the high needed a face. you gave it hers. that wasn't her fault."
	],
	"zone_03_still_void": [
		"in the quiet, you could almost hear her thinking.",
		"you don't know what she thinks about when she's alone. you never asked.",
		"the silence doesn't belong to either of you. it never did."
	],
	"zone_04_cradle_of_ash": [
		"would she have chosen this? existence, with all its weight?",
		"you realise you've been deciding for every living thing. her included.",
		"she didn't ask for your mercy. neither did anyone who ever breathed."
	],
	"zone_05_laughing_labyrinth": [
		"she laughed at something once. genuinely. you thought: that's what's worth saving.",
		"then you thought: by saving nothing, I save that laugh from everything that will ruin it.",
		"you still don't hear the flaw in that."
	],
	"zone_06_limerent_archive": [
		"there is a version of her you've built from 40% observation and 60% need.",
		"you look at her and see yourself reflected back, perfected. given back.",
		"she is not a mirror. she is a separate person. this is the most terrifying thing you know."
	],
	"zone_07_crossroads": [
		"she is real. she is standing somewhere right now, breathing, wanting things, being afraid.",
		"she exists without your permission and without your understanding.",
		"and you love her. not the idea. her."
	]
}


func _ready() -> void:
	layer = 20  # Above HUD (layer 10)
	_overlay = ColorRect.new()
	_overlay.set_anchors_preset(Control.PRESET_FULL_RECT)
	_overlay.color = Color(0.08, 0.05, 0.02, 0.0)  # Near-black warm tint
	_overlay.mouse_filter = Control.MOUSE_FILTER_IGNORE
	add_child(_overlay)


# ── Public API ────────────────────────────────────────────────────────────────
func trigger(zone_id: String) -> void:
	if _active:
		return
	if LimerenceTracker.limerence_level < LimerenceTracker.PROJECTION_UNLOCK_THRESHOLD:
		NarrativeManager.trigger_custom(
			"there's something here. you can almost see it. not yet."
		)
		return

	var beats: Array = SEQUENCES.get(zone_id, [])
	if beats.is_empty():
		push_warning("ProjectionSequenceManager: no sequence defined for " + zone_id)
		return

	_active = true
	LimerenceTracker.record_interaction("projection_sequence_viewed")
	_play_sequence(zone_id, beats)


# ── Sequence playback ─────────────────────────────────────────────────────────
func _play_sequence(zone_id: String, beats: Array) -> void:
	var in_tween := create_tween()
	in_tween.tween_property(_overlay, "color:a", 0.65, 1.4)
	await in_tween.finished

	for beat in beats:
		NarrativeManager.trigger_custom(beat)
		await get_tree().create_timer(4.8).timeout

	var out_tween := create_tween()
	out_tween.tween_property(_overlay, "color:a", 0.0, 1.6)
	await out_tween.finished

	_active = false
	sequence_completed.emit(zone_id)
	MentalStateManager.apply_event("projection_sequence_viewed")
	EventBus.lo_interaction.emit("projection_viewed")
