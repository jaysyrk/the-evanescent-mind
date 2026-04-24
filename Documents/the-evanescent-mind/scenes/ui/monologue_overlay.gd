extends Control
## MonologueOverlay — displays inner monologue lines at bottom of screen.
## Tone controls typography: depressive=slow fade/lowercase, manic=fast/uppercase, etc.


@onready var label: RichTextLabel = $Label
@onready var tween: Tween

const TONE_STYLES: Dictionary = {
	"depressive":  { "color": Color(0.65, 0.68, 0.75, 1.0), "speed": 0.045, "upper": false },
	"manic":       { "color": Color(1.0,  0.92, 0.6,  1.0), "speed": 0.018, "upper": true  },
	"anxious":     { "color": Color(0.85, 0.75, 0.75, 1.0), "speed": 0.03,  "upper": false },
	"scattered":   { "color": Color(0.70, 0.70, 0.70, 1.0), "speed": 0.055, "upper": false },
	"hyperfocus":  { "color": Color(0.85, 0.95, 1.0,  1.0), "speed": 0.025, "upper": false },
	"baseline":    { "color": Color(0.80, 0.80, 0.80, 1.0), "speed": 0.035, "upper": false },
}


func _ready() -> void:
	modulate.a = 0.0
	label.text = ""
	NarrativeManager.monologue_display_requested.connect(_on_monologue)


func _on_monologue(text: String, tone: String, duration: float) -> void:
	var style: Dictionary = TONE_STYLES.get(tone, TONE_STYLES["baseline"])
	var display_text := text.to_upper() if style["upper"] else text.to_lower()

	label.modulate = style["color"]
	label.visible_ratio = 0.0
	label.text = display_text

	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_SINE)

	# Fade in
	tween.tween_property(self, "modulate:a", 1.0, 0.4)
	# Typewriter effect via visible_ratio
	var char_duration: float = display_text.length() * float(style["speed"])
	tween.tween_property(label, "visible_ratio", 1.0, char_duration)
	# Hold
	tween.tween_interval(duration)
	# Fade out
	tween.tween_property(self, "modulate:a", 0.0, 0.8)
