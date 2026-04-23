extends Control
## StaminaBar — shows stamina as a thin horizontal bar.
## When depressive: label text becomes unreliable (wrong words).
## When manic: bar flickers/overflows visually.


@onready var bar:        TextureProgressBar = $Bar
@onready var label:      Label              = $Label
@onready var flicker_timer: Timer          = $FlickerTimer

const FAKE_LABELS_DEPRESSIVE: Array[String] = [
	"stamina", "will", "energy", "point", "enough", "capacity",
	"strength", "purpose", "reason", "drive", "care",
]
const REAL_LABEL := "stamina"

var _current: float = 100.0
var _maximum: float = 100.0
var _is_manic := false
var _flicker_phase := false


func _ready() -> void:
	EventBus.stamina_changed.connect(_on_stamina_changed)
	EventBus.mood_threshold_crossed.connect(_on_mood_threshold)
	flicker_timer.wait_time = 0.12
	flicker_timer.timeout.connect(_on_flicker)


func _on_stamina_changed(current: float, maximum: float) -> void:
	_current = current
	_maximum = maximum
	bar.value = (current / maximum) * 100.0
	_update_label()
	_update_bar_color()


func _on_mood_threshold(direction: String) -> void:
	_is_manic = (direction == "manic")
	if _is_manic:
		flicker_timer.start()
	else:
		flicker_timer.stop()
		bar.modulate = Color.WHITE


func _on_flicker() -> void:
	_flicker_phase = not _flicker_phase
	bar.modulate = Color(1.0, 0.85, 0.4, 1.0) if _flicker_phase else Color.WHITE
	if _is_manic and _current > _maximum * 0.8:
		# Visual overflow — bar appears slightly past full
		bar.value = minf(bar.value + randf_range(0.0, 8.0), 108.0)


func _update_label() -> void:
	if MentalStateManager.is_depressive():
		# Replace label with a random existentially deflated word
		var idx := randi() % FAKE_LABELS_DEPRESSIVE.size()
		label.text = FAKE_LABELS_DEPRESSIVE[idx]
		label.modulate = Color(0.5, 0.5, 0.6, 0.7)
	else:
		label.text = REAL_LABEL
		label.modulate = Color(0.75, 0.75, 0.75, 1.0)


func _update_bar_color() -> void:
	if MentalStateManager.is_depressive():
		bar.tint_progress = Color(0.35, 0.38, 0.50)
	elif _is_manic:
		bar.tint_progress = Color(1.0, 0.85, 0.3)
	else:
		bar.tint_progress = Color(0.6, 0.75, 0.9)
