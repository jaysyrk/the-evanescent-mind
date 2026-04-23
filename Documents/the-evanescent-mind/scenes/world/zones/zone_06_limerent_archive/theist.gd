extends "res://scripts/systems/philosopher_base.gd"
## The Theist — Zone 6: The Limerent Archive.
## Position: meaning exists. not as a rule. as a fact of your experience.
## She doesn't argue for God. She argues that love is already evidence of something beyond chemistry.
## Most likely to provoke contempt — that's the test.
## Compassion path: not accepting her position, but sitting with the fact that she's right about love.
## Piece: "The Thread" — gossamer-thin. connects to nothing you can see.
## Mechanical effect: LimerenceTracker.PROJECTION_UNLOCK_THRESHOLD drops to 0.45 (easier to project)


func _ready() -> void:
	philosopher_name     = "The Theist"
	piece_id             = "piece_theist"
	dialogue_timeline    = "theist_dialogue"
	compassion_threshold = 2.0
	super()
	Dialogic.signal_event.connect(_on_dialogic_signal)


func _on_dialogic_signal(argument: String) -> void:
	match argument:
		"add_compassion_1":
			add_compassion(1.0)
		"add_compassion_2":
			add_compassion(2.0)


func _on_piece_given() -> void:
	NarrativeManager.trigger_custom(
		"she gave it without making a point of it. like she'd always known you'd come around to the question."
	)
	LimerenceTracker.PROJECTION_UNLOCK_THRESHOLD = \
		clampf(LimerenceTracker.PROJECTION_UNLOCK_THRESHOLD - 0.10, 0.20, 0.55)
