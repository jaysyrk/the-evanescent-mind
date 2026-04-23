extends Node
## MentalStateManager — tracks the MC's four mental state axes.
## mood:      -1.0 (depressive) → 0.0 (baseline) → 1.0 (manic)
## anxiety:    0.0 (calm)       → 1.0 (panic)
## focus:      0.0 (scattered)  → 1.0 (hyperfocus)
## All systems read from here; all changes go through the setters so signals fire.


# ── Thresholds ────────────────────────────────────────────────────────────────
const MOOD_DEPRESSIVE_THRESHOLD := -0.5
const MOOD_MANIC_THRESHOLD      :=  0.5
const ANXIETY_HIGH_THRESHOLD    :=  0.65
const FOCUS_HYPERFOCUS_THRESHOLD:=  0.8
const FOCUS_SCATTER_THRESHOLD   :=  0.25

# Drift targets — mutable so ritual pieces can permanently shift them
var MOOD_DRIFT_TARGET: float  = -0.25   # Slight depressive pull (the condition)
const MOOD_DRIFT_RATE    :=  0.008
const ANXIETY_DRIFT_TARGET := 0.35
const ANXIETY_DRIFT_RATE   := 0.015
const FOCUS_DRIFT_TARGET   := 0.3
const FOCUS_DRIFT_RATE     := 0.012


# ── State axes ────────────────────────────────────────────────────────────────
var mood: float = -0.3:
	set(value):
		var prev := mood
		mood = clampf(value, -1.0, 1.0)
		_on_changed("mood", prev, mood)

var anxiety: float = 0.4:
	set(value):
		var prev := anxiety
		anxiety = clampf(value, 0.0, 1.0)
		_on_changed("anxiety", prev, anxiety)

var focus: float = 0.3:
	set(value):
		var prev := focus
		focus = clampf(value, 0.0, 1.0)
		_on_changed("focus", prev, focus)


# ── Named state queries ───────────────────────────────────────────────────────
func is_depressive() -> bool: return mood <= MOOD_DEPRESSIVE_THRESHOLD
func is_manic()      -> bool: return mood >= MOOD_MANIC_THRESHOLD
func is_anxious()    -> bool: return anxiety >= ANXIETY_HIGH_THRESHOLD
func is_hyperfocused()-> bool: return focus >= FOCUS_HYPERFOCUS_THRESHOLD
func is_scattered()  -> bool: return focus <= FOCUS_SCATTER_THRESHOLD

func get_tone() -> String:
	if is_manic():       return "manic"
	if is_depressive():  return "depressive"
	if is_anxious():     return "anxious"
	if is_scattered():   return "scattered"
	if is_hyperfocused():return "hyperfocus"
	return "baseline"


# ── Process ───────────────────────────────────────────────────────────────────
func _process(delta: float) -> void:
	# Axes drift back toward their resting values when nothing is pushing them
	mood    = move_toward(mood,    MOOD_DRIFT_TARGET,    MOOD_DRIFT_RATE    * delta * 60.0)
	anxiety = move_toward(anxiety, ANXIETY_DRIFT_TARGET, ANXIETY_DRIFT_RATE * delta * 60.0)
	focus   = move_toward(focus,   FOCUS_DRIFT_TARGET,   FOCUS_DRIFT_RATE   * delta * 60.0)


# ── Narrative event modifiers ─────────────────────────────────────────────────
func apply_event(event_id: String) -> void:
	match event_id:
		"met_celeste":
			mood    += 0.25
			anxiety += 0.20
		"philosophical_engagement":
			mood    += 0.08
			anxiety -= 0.05
		"ritual_piece_collected":
			mood    += 0.05
			focus   += 0.10
		"zone_enter_waking_sorrow":
			mood    -= 0.30
			anxiety += 0.10
		"zone_enter_manic_garden":
			mood    += 0.50
			anxiety += 0.20
		"zone_enter_void":
			focus   -= 0.40
			mood    -= 0.10
		"zone_enter_labyrinth":
			anxiety += 0.45
		"zone_enter_limerent_archive":
			anxiety += 0.15
		"zone_enter_crossroads":
			focus   += 0.30
		"zone_enter_threshold":
			# All states move toward a quiet, final convergence
			mood    = move_toward(mood,    0.0, 0.3)
			anxiety = move_toward(anxiety, 0.2, 0.3)
			focus   = move_toward(focus,   0.7, 0.3)
		"combat_start":
			anxiety += 0.15
			focus   += 0.10
		"player_damaged":
			anxiety += 0.10
		"perfect_dodge":
			focus   += 0.25


# ── Internal ──────────────────────────────────────────────────────────────────
func _on_changed(axis: String, old_val: float, new_val: float) -> void:
	EventBus.mental_state_changed.emit(axis, new_val)
	_check_thresholds(axis, old_val, new_val)


func _check_thresholds(axis: String, old_val: float, new_val: float) -> void:
	match axis:
		"mood":
			if old_val > MOOD_DEPRESSIVE_THRESHOLD and new_val <= MOOD_DEPRESSIVE_THRESHOLD:
				EventBus.mood_threshold_crossed.emit("depressive")
			elif old_val < MOOD_MANIC_THRESHOLD and new_val >= MOOD_MANIC_THRESHOLD:
				EventBus.mood_threshold_crossed.emit("manic")
			elif old_val <= MOOD_DEPRESSIVE_THRESHOLD and new_val > MOOD_DEPRESSIVE_THRESHOLD \
				and new_val < MOOD_MANIC_THRESHOLD:
				EventBus.mood_threshold_crossed.emit("baseline")
		"anxiety":
			if old_val < ANXIETY_HIGH_THRESHOLD and new_val >= ANXIETY_HIGH_THRESHOLD:
				EventBus.anxiety_threshold_crossed.emit("high")
			elif old_val >= ANXIETY_HIGH_THRESHOLD and new_val < ANXIETY_HIGH_THRESHOLD:
				EventBus.anxiety_threshold_crossed.emit("low")
		"focus":
			if old_val < FOCUS_HYPERFOCUS_THRESHOLD and new_val >= FOCUS_HYPERFOCUS_THRESHOLD:
				EventBus.focus_threshold_crossed.emit("hyperfocus")
			elif old_val > FOCUS_SCATTER_THRESHOLD and new_val <= FOCUS_SCATTER_THRESHOLD:
				EventBus.focus_threshold_crossed.emit("scatter")
