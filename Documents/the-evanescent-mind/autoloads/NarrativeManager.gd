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
	# ── Zone entry beats ────────────────────────────────────────────────────
	"enter_zone_01": {
		"default":    "The familiar weight. You've been here before, in every room.",
		"depressive": "Everything is grey here. Everything is always grey.",
		"manic":      "You can move through this. You can move through anything.",
		"anxious":    "Something in this place is watching. Something is always watching.",
	},
	"enter_zone_02": {
		"default":    "The lights are beautiful. You remember when that was enough.",
		"manic":      "Yes. This. This is what it feels like to be alive.",
		"depressive": "Even the beauty feels like a threat. It will go. It always goes.",
		"scattered":  "Bright. Too bright. You want to touch everything and none of it.",
	},
	"enter_zone_03": {
		"default":    "Nothing here. Just the ringing in your ears.",
		"depressive": "The void is comfortable. Familiar. That should bother you.",
		"anxious":    "Too quiet. The quiet means something is about to happen.",
		"hyperfocus": "In the stillness you can hear it. Whatever it is. It's underneath everything.",
	},
	"enter_zone_04": {
		"default":    "Ash. The residue of everything that stopped.",
		"depressive": "This is where everything ends up. You've always known that.",
		"anxious":    "Were you supposed to stop something? Could you have?",
		"manic":      "Out of the ash, then. Again. Always again.",
	},
	"enter_zone_05": {
		"default":    "Laughter. Somewhere. It doesn't include you.",
		"anxious":    "Are they laughing at something? Are they laughing at you?",
		"manic":      "The joke is that none of this matters. The joke is very funny right now.",
		"depressive": "You forgot what laughing feels like. Genuinely forgot.",
	},
	"enter_zone_06": {
		"default":    "This place remembers things. Not accurately.",
		"manic":      "Her face, everywhere. You put it here. You've been putting it everywhere.",
		"depressive": "You built an entire world in someone else's image. Now you have to look at it.",
		"anxious":    "What if she could see this? What you've done with her, in your head?",
	},
	"enter_zone_07": {
		"default":    "The crossroads. Every path you took, every one you didn't.",
		"depressive": "All those choices. Here, at the end, they look like nothing.",
		"manic":      "This is it. This is the moment it all converges.",
		"anxious":    "You have to choose. You've always been bad at choosing.",
		"hyperfocus": "You see all of it. The whole map. You're standing at the centre.",
	},
	"player_died": {
		"default":    "You come back. You always come back.",
		"depressive": "Again. What's the point of that?",
		"manic":      "Not yet. Apparently not yet.",
		"anxious":    "What happened? What did you miss? What went wrong?",
	},
}


func _ready() -> void:
	EventBus.flag_set.connect(_on_flag_set)
	EventBus.lo_interaction.connect(_on_lo_interaction)
	EventBus.player_died.connect(_on_player_died)


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


func _on_player_died() -> void:
	await get_tree().create_timer(0.8).timeout
	trigger_beat("player_died")
