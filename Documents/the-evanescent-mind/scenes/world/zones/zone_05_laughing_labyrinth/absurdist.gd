extends "res://scripts/systems/philosopher_base.gd"
## The Absurdist — Zone 5: The Laughing Labyrinth.
## Position: the universe is silent. we revolt anyway. laugh anyway. love anyway.
## The Absurdist finds the MC's plan funny. not mockingly — with genuine admiration.
## The challenge: their laughter makes the MC feel unseen. is laughter just another avoidance?
## Compassion path: realising the laughter is a response to the same void, not an escape from it.
## Piece: "The Shrug" — a small figure with no expression. slightly smiling. it doesn't help.
## Mechanical effect: mood regen rate increases slightly (resilience in absurdity)


func _ready() -> void:
	philosopher_name     = "The Absurdist"
	piece_id             = "piece_absurdist"
	dialogue_timeline    = "absurdist_dialogue"
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
		"he handed it over still laughing. 'don't take it too seriously,' he said. you almost smiled."
	)
	MentalStateManager.MOOD_DRIFT_RATE = \
		clampf(MentalStateManager.MOOD_DRIFT_RATE * 1.15, 0.0, 0.05)
