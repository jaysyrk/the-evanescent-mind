extends Node
## LimerenceTracker — tracks the MC's attachment to Celeste.
## limerence_level: 0.0 (no attachment) → 1.0 (all-consuming)
## Drives intrusive thoughts, projection sequences, and the ending weight.


const PROJECTION_UNLOCK_THRESHOLD := 0.55
const INTRUSIVE_THOUGHT_INTERVAL_MIN := 30.0   # seconds
const INTRUSIVE_THOUGHT_INTERVAL_MAX := 120.0

var limerence_level: float = 0.0:
	set(value):
		var prev := limerence_level
		limerence_level = clampf(value, 0.0, 1.0)
		EventBus.limerence_changed.emit(limerence_level)
		_check_projection_unlock(prev)

var _projection_unlocked := false
var _intrusive_thought_timer := 0.0
var _next_thought_interval := 60.0

# Intrusive thoughts indexed by approximate limerence range
const _INTRUSIVE_THOUGHTS: Array[String] = [
	"You're thinking about her again.",
	"You wonder what she's doing right now.",
	"Her voice. You keep hearing it.",
	"She looked at you like you were worth staying for.",
	"What would she think of what you're about to do?",
	"She doesn't know. She can't know.",
	"Is this what it feels like to want to stay?",
	"You keep rehearsing things you'll never say to her.",
	"The mission doesn't feel smaller. She just feels bigger.",
	"You've felt this before. It wasn't real then either. But it feels real.",
]


func _ready() -> void:
	EventBus.lo_interaction.connect(_on_lo_interaction)
	_next_thought_interval = _random_interval()


func _process(delta: float) -> void:
	if limerence_level < 0.15:
		return
	_intrusive_thought_timer += delta
	if _intrusive_thought_timer >= _next_thought_interval:
		_intrusive_thought_timer = 0.0
		_next_thought_interval = _random_interval()
		_trigger_intrusive_thought()


# ── Interaction handlers ──────────────────────────────────────────────────────
func _on_lo_interaction(interaction_type: String) -> void:
	match interaction_type:
		"proximity":
			limerence_level += 0.01
		"dialogue":
			limerence_level += 0.06
		"help":
			limerence_level += 0.10
		"conflict":
			limerence_level += 0.04   # Conflict still increases limerence — it's attention
		"projection_sequence_viewed":
			limerence_level += 0.08


func record_interaction(interaction_type: String) -> void:
	EventBus.lo_interaction.emit(interaction_type)


# ── Internal ──────────────────────────────────────────────────────────────────
func _check_projection_unlock(prev: float) -> void:
	if not _projection_unlocked and limerence_level >= PROJECTION_UNLOCK_THRESHOLD \
			and prev < PROJECTION_UNLOCK_THRESHOLD:
		_projection_unlocked = true
		EventBus.projection_sequence_unlocked.emit()


func _trigger_intrusive_thought() -> void:
	var idx := randi() % _INTRUSIVE_THOUGHTS.size()
	var text := _INTRUSIVE_THOUGHTS[idx]
	EventBus.intrusive_thought_triggered.emit(text)


func _random_interval() -> float:
	return randf_range(
		lerpf(INTRUSIVE_THOUGHT_INTERVAL_MAX, INTRUSIVE_THOUGHT_INTERVAL_MIN, limerence_level),
		INTRUSIVE_THOUGHT_INTERVAL_MAX
	)
