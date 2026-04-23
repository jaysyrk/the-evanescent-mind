extends "res://scripts/systems/philosopher_base.gd"
## The Stoic — Zone 1 philosopher.
##
## Position: Endure. Suffering is the discipline that proves you were here.
## The MC's efilism says: your discipline is a cope. The Stoic says: yours is cowardice.
## Neither is entirely wrong. That's the point.
##
## Compassion path: MC must acknowledge that the Stoic *genuinely* doesn't fear
## suffering — not as performance, but as practice. Dismissing it as delusion closes the dialogue.
##
## Piece: "The Weight" — a smooth stone, impossibly heavy, that makes the MC's hand ache.
## Gameplay: collected piece slightly increases stamina regen (bearing weight)
##           but also raises the depressive drift target by 0.05 (the cost of the lesson).


func _ready() -> void:
	philosopher_name  = "The Stoic"
	piece_id          = "piece_stoic"
	dialogue_timeline = "stoic_dialogue"
	compassion_threshold = 2.0   # requires two compassionate exchanges
	super()
	# Dialogic emits signal events from timeline using signal_name field
	Dialogic.signal_event.connect(_on_dialogic_signal)


func _on_dialogic_signal(argument: String) -> void:
	match argument:
		"add_compassion_1":
			add_compassion(1.0)
		"add_compassion_2":
			add_compassion(2.0)


func _on_piece_given() -> void:
	# Visual: Stoic sits down slowly, closes eyes, becomes still
	# (placeholder until animation is available)
	var tween := create_tween()
	tween.tween_property(self, "scale", Vector3(0.95, 0.95, 0.95), 1.2)

	# Mechanical effect: permanent buff/debuff via MentalStateManager drift
	MentalStateManager.MOOD_DRIFT_TARGET = \
		clampf(MentalStateManager.MOOD_DRIFT_TARGET - 0.05, -1.0, 0.0)

	NarrativeManager.trigger_custom(
		"he gave it to you without looking up. as if he'd been expecting you for years."
	)
