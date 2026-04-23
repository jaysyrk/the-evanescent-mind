extends Node
## DynamicAudioManager — 4-stem layered music system.
## Each zone has four stems: base, rhythm, melody, emotional.
## Stem volumes respond in real-time to MentalStateManager axes.


const CROSSFADE_DURATION := 1.5
const STEM_NAMES := ["base", "rhythm", "melody", "emotional"]

var _layers: Dictionary = {}   # stem_name -> AudioStreamPlayer
var _tween: Tween
var _current_zone: String = ""


func _ready() -> void:
	for stem in STEM_NAMES:
		var player := AudioStreamPlayer.new()
		player.name = stem.capitalize() + "Layer"
		player.bus = "Music"
		player.volume_db = -80.0
		add_child(player)
		_layers[stem] = player

	EventBus.zone_entered.connect(_on_zone_entered)
	EventBus.mental_state_changed.connect(_on_mental_state_changed)
	EventBus.limerence_changed.connect(_on_limerence_changed)


# ── Zone loading ──────────────────────────────────────────────────────────────
func _on_zone_entered(zone_id: String) -> void:
	if zone_id == _current_zone:
		return
	_current_zone = zone_id
	_crossfade_to_zone(zone_id)


func _crossfade_to_zone(zone_id: String) -> void:
	if _tween:
		_tween.kill()

	_tween = create_tween().set_parallel(true)
	for stem in STEM_NAMES:
		_tween.tween_property(_layers[stem], "volume_db", -80.0, CROSSFADE_DURATION)

	await _tween.finished

	for stem in STEM_NAMES:
		var path := "res://assets/audio/music/%s/%s.ogg" % [zone_id, stem]
		if ResourceLoader.exists(path):
			_layers[stem].stream = load(path)
			_layers[stem].play()

	_tween = create_tween().set_parallel(true)
	_tween.tween_property(_layers["base"],     "volume_db", 0.0,   CROSSFADE_DURATION)
	_tween.tween_property(_layers["melody"],   "volume_db", -3.0,  CROSSFADE_DURATION)
	_update_dynamic_volumes()


# ── Dynamic volume updates ────────────────────────────────────────────────────
func _update_dynamic_volumes() -> void:
	if _tween and _tween.is_running():
		return

	# Rhythm layer scales with manic intensity (mood > 0)
	var rhythm_db := lerpf(-20.0, 0.0, maxf(0.0, MentalStateManager.mood))

	# Emotional layer scales with limerence
	var emotional_db := lerpf(-24.0, -3.0, LimerenceTracker.limerence_level)

	var t := create_tween().set_parallel(true)
	t.tween_property(_layers["rhythm"],   "volume_db", rhythm_db,   0.8)
	t.tween_property(_layers["emotional"],"volume_db", emotional_db, 0.8)


func _on_mental_state_changed(_axis: String, _value: float) -> void:
	_update_dynamic_volumes()


func _on_limerence_changed(_new_level: float) -> void:
	_update_dynamic_volumes()
