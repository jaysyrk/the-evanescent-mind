extends Node
## GameState — flat flags dictionary. Single source of truth for all narrative state.
## Never nest dicts. Never branch on flags outside EndingSystem.


# ── Flags ─────────────────────────────────────────────────────────────────────
var flags: Dictionary = {
	# Zone completion
	"zone_waking_sorrow_complete":      false,
	"zone_manic_garden_complete":       false,
	"zone_void_complete":               false,
	"zone_labyrinth_complete":          false,
	"zone_limerent_archive_complete":   false,
	"zone_crossroads_complete":         false,
	"threshold_reached":                false,

	# Ritual pieces (one per philosopher)
	"piece_stoic":        false,
	"piece_hedonist":     false,
	"piece_buddhist":     false,
	"piece_antinatalist": false,
	"piece_absurdist":    false,
	"piece_theist":       false,
	"piece_nihilist":     false,
	"all_pieces_gathered": false,

	# Puzzle completion
	"puzzle_projection_calibration_solved": false,
	"puzzle_stillness_solved":              false,
	"puzzle_stimulation_overload_solved":   false,
	"puzzle_integration_solved":            false,

	# Philosopher encounters
	"met_stoic":        false,
	"met_hedonist":     false,
	"met_buddhist":     false,
	"met_antinatalist": false,
	"met_absurdist":    false,
	"met_theist":       false,
	"met_nihilist":     false,

	# Celeste / LO
	"met_celeste":           false,
	"celeste_helped_mc":     false,
	"celeste_knows_plan":    false,
	"celeste_at_threshold":  false,

	# Ending
	"ending": "",           # "void" | "stay"
	"game_complete": false,

	# Save metadata
	"current_zone_index": 0,
}

const _RITUAL_PIECES: Array[String] = [
	"piece_stoic", "piece_hedonist", "piece_buddhist",
	"piece_antinatalist", "piece_absurdist", "piece_theist", "piece_nihilist",
]


# ── Public API ────────────────────────────────────────────────────────────────
func set_flag(flag_name: String, value: Variant) -> void:
	if not flags.has(flag_name):
		push_warning("GameState.set_flag: unknown flag '%s'" % flag_name)
		return
	flags[flag_name] = value
	EventBus.flag_set.emit(flag_name, value)
	_check_derived_flags()


func get_flag(flag_name: String) -> bool:
	if not flags.has(flag_name):
		push_warning("GameState.get_flag: unknown flag '%s'" % flag_name)
		return false
	return flags[flag_name]


func all_pieces_collected() -> bool:
	return _RITUAL_PIECES.all(func(p: String) -> bool: return flags.get(p, false))


## Journal — ordered list of entry IDs the player has collected.
var journal_entries: Array[String] = []


func add_journal_entry(entry_id: String) -> void:
	if entry_id in journal_entries:
		return
	journal_entries.append(entry_id)
	EventBus.journal_entry_added.emit(entry_id)


# ── Internal ──────────────────────────────────────────────────────────────────
func _check_derived_flags() -> void:
	if not flags["all_pieces_gathered"] and all_pieces_collected():
		flags["all_pieces_gathered"] = true
		EventBus.all_ritual_pieces_gathered.emit()
