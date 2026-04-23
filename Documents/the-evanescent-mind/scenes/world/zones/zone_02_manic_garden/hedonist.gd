extends "res://scripts/systems/philosopher_base.gd"
## The Hedonist — Zone 2: The Manic Garden.
## Position: pleasure is the only honest metric. your suffering is unoptimised experience.
## Piece: "The Sweetness" — something that tastes like joy, and leaves you hungrier than before.
## Mechanical effect: limerence gain rate increases slightly (everything feels more vivid)


func _ready() -> void:
	philosopher_name     = "The Hedonist"
	piece_id             = "piece_hedonist"
	dialogue_timeline    = "hedonist_dialogue"
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
	# The Hedonist laughs — not cruelly. genuinely. it was always going to end this way.
	NarrativeManager.trigger_custom(
		"she pressed it into your hand still warm. 'you'll understand it when you stop fighting it,' she said."
	)
	# Mechanical: limerence drift becomes slightly faster
	LimerenceTracker.base_limerence_drift = \
		clampf(LimerenceTracker.base_limerence_drift * 1.1, 0.0, 0.02)
