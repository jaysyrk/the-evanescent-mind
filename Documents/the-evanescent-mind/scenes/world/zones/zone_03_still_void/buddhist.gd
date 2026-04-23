extends "res://scripts/systems/philosopher_base.gd"
## The Buddhist — Zone 3: The Still Void.
## Position: attachment is the wound. release, and suffering ends.
## Piece: "The Silence" — a hollow sphere. nothing inside. lighter than it should be.
## Mechanical effect: anxiety drift target decreases 0.04 (easier to stay calm)


func _ready() -> void:
	philosopher_name     = "The Buddhist"
	piece_id             = "piece_buddhist"
	dialogue_timeline    = "buddhist_dialogue"
	compassion_threshold = 1.0   # only one exchange needed — the stillness IS the answer
	super()
	Dialogic.signal_event.connect(_on_dialogic_signal)


func _on_dialogic_signal(argument: String) -> void:
	match argument:
		"add_compassion_1":
			add_compassion(1.0)


func _on_piece_given() -> void:
	NarrativeManager.trigger_custom(
		"he didn't hand it to you. he set it down between you and looked away. you picked it up yourself."
	)
	MentalStateManager.ANXIETY_DRIFT_TARGET = \
		clampf(MentalStateManager.ANXIETY_DRIFT_TARGET - 0.04, 0.0, 1.0)
