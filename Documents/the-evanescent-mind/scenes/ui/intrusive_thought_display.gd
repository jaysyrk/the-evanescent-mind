extends Control
## IntrusiveThoughtDisplay — flashes Celeste-related intrusive thoughts at screen edges.
## High limerence = more frequent, more intense. Thoughts appear at random screen positions
## along the margins and fade quickly — peripheral, not central.


@onready var thought_label: RichTextLabel = $ThoughtLabel
@onready var tween: Tween

const MARGIN := 80.0   # pixels from edge
const FADE_DURATION := 2.2


func _ready() -> void:
	modulate.a = 0.0
	thought_label.text = ""
	EventBus.intrusive_thought_triggered.connect(_on_intrusive_thought)


func _on_intrusive_thought(text: String) -> void:
	var vp := get_viewport_rect().size
	var limerence := LimerenceTracker.limerence_level

	# Position: random edge placement, weighted toward corners at high limerence
	var pos := _random_edge_position(vp, limerence)
	thought_label.position = pos

	# Opacity scales with limerence
	var peak_alpha := lerpf(0.25, 0.72, limerence)

	thought_label.text = "[i]" + text + "[/i]"
	thought_label.modulate = Color(0.85, 0.80, 0.90, 1.0)

	if tween: tween.kill()
	tween = create_tween().set_trans(Tween.TRANS_QUART)
	tween.tween_property(self, "modulate:a", peak_alpha, 0.3)
	tween.tween_interval(FADE_DURATION * lerpf(0.6, 1.4, limerence))
	tween.tween_property(self, "modulate:a", 0.0, 1.0)


func _random_edge_position(vp: Vector2, limerence: float) -> Vector2:
	# At low limerence: always bottom corners. At high: any edge.
	var edge := randi() % (2 if limerence < 0.4 else 4)
	match edge:
		0: return Vector2(randf_range(MARGIN, vp.x * 0.35), vp.y - MARGIN * 1.5)           # bottom-left
		1: return Vector2(randf_range(vp.x * 0.65, vp.x - MARGIN), vp.y - MARGIN * 1.5)   # bottom-right
		2: return Vector2(MARGIN * 0.5, randf_range(vp.y * 0.2, vp.y * 0.8))               # left edge
		3: return Vector2(vp.x - MARGIN * 3.0, randf_range(vp.y * 0.2, vp.y * 0.8))       # right edge
	return Vector2(MARGIN, vp.y - MARGIN)
