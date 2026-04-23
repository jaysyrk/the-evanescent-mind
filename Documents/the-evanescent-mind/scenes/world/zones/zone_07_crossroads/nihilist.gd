extends "res://scripts/systems/philosopher_base.gd"
## The Nihilist — Zone 7: The Crossroads.
## Position: nothing means anything. including this conversation. including the ritual. including her.
## He's the last philosopher before The Threshold. He is choosing to be present anyway.
## That's the gift — not the philosophy, but the choice.
## Compassion path: seeing that he's here, knowing it means nothing, and being here anyway.
## Piece: "The Empty Frame" — a picture frame. nothing in it. you keep looking.
## Mechanical effect: MentalStateManager baseline mood rises slightly (acceptance of meaninglessness)


func _ready() -> void:
	philosopher_name     = "The Nihilist"
	piece_id             = "piece_nihilist"
	dialogue_timeline    = "nihilist_dialogue"
	compassion_threshold = 1.0  # one moment of recognition is enough with him
	super()
	Dialogic.signal_event.connect(_on_dialogic_signal)


func _on_dialogic_signal(argument: String) -> void:
	match argument:
		"add_compassion_1":
			add_compassion(1.0)


func _on_piece_given() -> void:
	NarrativeManager.trigger_custom(
		"he put it in your hand and shrugged. 'doesn't mean anything,' he said. you both knew that wasn't entirely true."
	)
	MentalStateManager.MOOD_DRIFT_TARGET = \
		clampf(MentalStateManager.MOOD_DRIFT_TARGET + 0.08, -1.0, 0.0)
