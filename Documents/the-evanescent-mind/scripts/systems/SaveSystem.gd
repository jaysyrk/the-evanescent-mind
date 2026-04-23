extends Node
## SaveSystem — serializes and deserializes all persistent game state to JSON.
## Call SaveSystem.save_game() / SaveSystem.load_game() from anywhere.


const SAVE_PATH := "user://save.json"
const SAVE_VERSION := 1


func save_game() -> void:
	var data := {
		"version":         SAVE_VERSION,
		"timestamp":       Time.get_datetime_string_from_system(),
		"flags":           GameState.flags.duplicate(true),
		"journal_entries": GameState.journal_entries.duplicate(),
		"mental_state": {
			"mood":    MentalStateManager.mood,
			"anxiety": MentalStateManager.anxiety,
			"focus":   MentalStateManager.focus,
		},
		"limerence_level": LimerenceTracker.limerence_level,
	}

	var json_string := JSON.stringify(data, "\t")
	var file := FileAccess.open(SAVE_PATH, FileAccess.WRITE)
	if file == null:
		push_error("SaveSystem: could not open save file for writing. Error: %s" \
			% FileAccess.get_open_error())
		return
	file.store_string(json_string)
	file.close()


func load_game() -> bool:
	if not FileAccess.file_exists(SAVE_PATH):
		return false

	var file := FileAccess.open(SAVE_PATH, FileAccess.READ)
	if file == null:
		push_error("SaveSystem: could not open save file for reading.")
		return false

	var json_string := file.get_as_text()
	file.close()

	var parsed: Variant = JSON.parse_string(json_string)
	if parsed == null:
		push_error("SaveSystem: save file is corrupt or invalid JSON.")
		return false

	var data: Dictionary = parsed

	if data.get("version", 0) != SAVE_VERSION:
		push_warning("SaveSystem: save version mismatch. Starting fresh.")
		return false

	# Restore flags (only known keys — guards against schema changes)
	var saved_flags: Dictionary = data.get("flags", {})
	for key in GameState.flags.keys():
		if saved_flags.has(key):
			GameState.flags[key] = saved_flags[key]

	# Restore journal entries
	var saved_journal: Array = data.get("journal_entries", [])
	GameState.journal_entries.clear()
	for entry_id: String in saved_journal:
		GameState.journal_entries.append(entry_id)

	# Restore mental state (direct assignment bypasses setters' threshold signals on load)
	var ms: Dictionary = data.get("mental_state", {})
	if ms.has("mood"):    MentalStateManager.mood    = float(ms["mood"])
	if ms.has("anxiety"): MentalStateManager.anxiety = float(ms["anxiety"])
	if ms.has("focus"):   MentalStateManager.focus   = float(ms["focus"])

	LimerenceTracker.limerence_level = float(data.get("limerence_level", 0.0))

	return true


func save_exists() -> bool:
	return FileAccess.file_exists(SAVE_PATH)


func reset() -> void:
	delete_save()
	# Re-initialize flags to their schema defaults (don't call clear — that removes the keys)
	for key in GameState.flags.keys():
		var default_val = GameState.flags[key]
		match typeof(default_val):
			TYPE_BOOL:   GameState.flags[key] = false
			TYPE_INT:    GameState.flags[key] = 0
			TYPE_FLOAT:  GameState.flags[key] = 0.0
			TYPE_STRING: GameState.flags[key] = ""
	GameState.journal_entries.clear()
	MentalStateManager.mood    = -0.3
	MentalStateManager.anxiety =  0.4
	MentalStateManager.focus   =  0.3
	LimerenceTracker.limerence_level = 0.0


func delete_save() -> void:
	if FileAccess.file_exists(SAVE_PATH):
		DirAccess.remove_absolute(SAVE_PATH)
