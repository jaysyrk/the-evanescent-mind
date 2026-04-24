extends Control
## MentalStateDebug — F3 overlay showing live mental state axes.
## Dev tool only. Hidden in release builds.


@onready var mood_bar:     ProgressBar = $Panel/VBox/Grid/MoodBar
@onready var anxiety_bar:  ProgressBar = $Panel/VBox/Grid/AnxietyBar
@onready var focus_bar:    ProgressBar = $Panel/VBox/Grid/FocusBar
@onready var limerence_bar:ProgressBar = $Panel/VBox/Grid/LimerenceBar
@onready var tone_label:   Label       = $Panel/VBox/ToneLabel


func _process(_delta: float) -> void:
	if not visible:
		return
	# mood is -1..1; map to 0..100 for ProgressBar
	mood_bar.value     = (MentalStateManager.mood + 1.0) * 50.0
	anxiety_bar.value  = MentalStateManager.anxiety  * 100.0
	focus_bar.value    = MentalStateManager.focus     * 100.0
	limerence_bar.value= LimerenceTracker.limerence_level * 100.0
	tone_label.text    = "tone: " + MentalStateManager.get_tone()
