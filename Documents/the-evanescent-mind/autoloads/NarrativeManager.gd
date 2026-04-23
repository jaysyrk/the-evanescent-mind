extends Node
## NarrativeManager — inner monologue queue and story context.
## Inner monologue tone is shaped by MentalStateManager.get_tone() at time of trigger.


signal monologue_display_requested(text: String, tone: String, duration: float)

const _BASE_DURATION := 3.5  # seconds a monologue line stays on screen

# Per-tone text variants for the same narrative beat.
# Each entry: { beat_id: { tone: text } }
# "default" is the fallback if current tone has no variant.
const _MONOLOGUE_BEATS: Dictionary = {
	"game_start": {
		"default":    "Another day. The weight is familiar by now.",
		"depressive": "You wake up and immediately wish you hadn't.",
		"manic":      "Today feels different. Today you might actually do it.",
		"anxious":    "Something is wrong. Something is always wrong.",
	},
	"met_celeste": {
		"default":    "Something is different about her.",
		"depressive": "You don't deserve to be looked at like that.",
		"manic":      "She's extraordinary. She must see it in you too.",
		"anxious":    "She's going to find out everything. She can't find out.",
		"scattered":  "Wait— what were you saying? She's... wait.",
	},
	"ritual_piece_collected": {
		"default":    "One more piece. The end is getting closer.",
		"depressive": "One more. As if any of this matters anymore.",
		"manic":      "Yes. YES. It's all coming together.",
		"hyperfocus": "The pattern is clear now. You can see the whole shape of it.",
	},
	"all_pieces_gathered": {
		"default":    "That's all of them. There's nothing left to find. Only to do.",
		"depressive": "You have everything. You feel nothing.",
		"manic":      "You have everything. This is the moment everything changes.",
		"anxious":    "You have everything. There's no more stalling.",
	},
	"celeste_at_threshold": {
		"default":    "She followed you here. Of course she did.",
		"depressive": "She shouldn't have come. This was supposed to be clean.",
		"anxious":    "She knows. She has to know. How much does she know?",
		"manic":      "She's here. She's actually here. You didn't ruin it.",
	},
}


func _ready() -> void:
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.lo_interaction.connect(_on_lo_interaction)


# ── Public API ────────────────────────────────────────────────────────────────
func trigger_beat(beat_id: String) -> void:
	if not _MONOLOGUE_BEATS.has(beat_id):
		push_warning("NarrativeManager: unknown beat '%s'" % beat_id)
		return

	var tone := MentalStateManager.get_tone()
	var variants: Dictionary = _MONOLOGUE_BEATS[beat_id]
	var text: String = variants.get(tone, variants.get("default", ""))

	if text.is_empty():
		return

	var duration := _BASE_DURATION + text.length() * 0.04
	EventBus.inner_monologue_triggered.emit(text, tone)
	monologue_display_requested.emit(text, tone, duration)


func trigger_custom(text: String) -> void:
	var tone := MentalStateManager.get_tone()
	var duration := _BASE_DURATION + text.length() * 0.04
	EventBus.inner_monologue_triggered.emit(text, tone)
	monologue_display_requested.emit(text, tone, duration)


# ── Internal ──────────────────────────────────────────────────────────────────
func _on_flag_set(flag_name: String, value: Variant) -> void:
	if not value:
		return
	match flag_name:
		"met_celeste":          trigger_beat("met_celeste")
		"all_pieces_gathered":  trigger_beat("all_pieces_gathered")
		"celeste_at_threshold": trigger_beat("celeste_at_threshold")


func _on_lo_interaction(interaction_type: String) -> void:
	if interaction_type == "dialogue":
		MentalStateManager.apply_event("met_celeste")
