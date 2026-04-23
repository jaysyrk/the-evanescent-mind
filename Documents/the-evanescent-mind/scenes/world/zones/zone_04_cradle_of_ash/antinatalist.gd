extends "res://scripts/systems/philosopher_base.gd"
## The Antinatalist — Zone 4: The Cradle of Ash.
## Position: consent cannot precede birth. existence is always imposed.
## They are the closest to the MC's worldview — same conclusion, different wound.
## Compassion path: realising their grief is personal, not just theoretical.
## Piece: "The Verdict" — a coin with no tails. both sides read 'no.'
## Mechanical effect: focus drift target increases 0.05 (clarity in refusal)


func _ready() -> void:
	philosopher_name     = "The Antinatalist"
	piece_id             = "piece_antinatalist"
	dialogue_timeline    = "antinatalist_dialogue"
	compassion_threshold = 1.5
	super()
	Dialogic.signal_event.connect(_on_dialogic_signal)


func _on_dialogic_signal(argument: String) -> void:
	match argument:
		"add_compassion_1":
			add_compassion(1.0)
		"add_compassion_half":
			add_compassion(0.5)


func _on_piece_given() -> void:
	NarrativeManager.trigger_custom(
		"she looked at you for a long time before giving it. like she was deciding if you'd earned the grief."
	)
	MentalStateManager.FOCUS_DRIFT_TARGET = \
		clampf(MentalStateManager.FOCUS_DRIFT_TARGET + 0.05, 0.0, 1.0)
