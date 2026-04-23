extends Node
## ZoneManager — handles zone ordering, cross-zone transitions, and player spawning.
## Registered as an autoload so any system can call ZoneManager.advance_zone() or
## ZoneManager.load_zone(index).
##
## Flow:
##   1. Fade to black (0.5 s)
##   2. change_scene_to_file to next zone tscn
##   3. Wait two frames for scene to initialise
##   4. Spawn player at scene's "PlayerSpawn" Marker3D
##   5. Fade back in (0.5 s)


const ZONE_PATHS: Array[String] = [
	"res://scenes/world/zones/zone_01_waking_sorrow/zone_01.tscn",
	"res://scenes/world/zones/zone_02_manic_garden/zone_02.tscn",
	"res://scenes/world/zones/zone_03_still_void/zone_03.tscn",
	"res://scenes/world/zones/zone_04_cradle_of_ash/zone_04.tscn",
	"res://scenes/world/zones/zone_05_laughing_labyrinth/zone_05.tscn",
	"res://scenes/world/zones/zone_06_limerent_archive/zone_06.tscn",
	"res://scenes/world/zones/zone_07_crossroads/zone_07.tscn",
	"res://scenes/world/the_threshold/threshold.tscn",
]

const PLAYER_SCENE_PATH := "res://scenes/player/player.tscn"

## Persistent UI scenes — loaded once, never freed across scene changes.
const PERSISTENT_UI: Array[String] = [
	"res://scenes/ui/hud.tscn",
	"res://scenes/ui/pause_menu.tscn",
	"res://scenes/ui/journal.tscn",
]

var current_zone_index: int = -1
var _is_transitioning: bool = false

var _fade_rect: ColorRect
var _canvas: CanvasLayer


func _ready() -> void:
	_build_fade_overlay()
	_load_persistent_ui()


func _build_fade_overlay() -> void:
	_canvas = CanvasLayer.new()
	_canvas.layer = 100
	_canvas.name = "ZoneFadeCanvas"

	_fade_rect = ColorRect.new()
	_fade_rect.color = Color.BLACK
	_fade_rect.anchor_right  = 1.0
	_fade_rect.anchor_bottom = 1.0
	_fade_rect.offset_right  = 0.0
	_fade_rect.offset_bottom = 0.0
	_fade_rect.mouse_filter  = Control.MOUSE_FILTER_IGNORE
	_fade_rect.modulate.a    = 0.0

	_canvas.add_child(_fade_rect)
	add_child(_canvas)


# ── Public API ────────────────────────────────────────────────────────────────

## Load zone by index (0-based). Called from MainMenu for "New Game" / "Continue".
func load_zone(index: int) -> void:
	if _is_transitioning:
		return
	_is_transitioning = true
	current_zone_index = index
	_ensure_persistent_ui()

	await _fade_to(1.0, 0.5)
	get_tree().change_scene_to_file(ZONE_PATHS[index])
	# Persist zone progress so "Continue" resumes here
	GameState.set_flag("current_zone_index", index)
	# Wait two frames for the scene tree to settle
	await get_tree().process_frame
	await get_tree().process_frame
	_spawn_player()
	await _fade_to(0.0, 0.5)
	_is_transitioning = false


## Advance to the next zone. Called by ZoneExitPortal when player reaches exit.
func advance_zone() -> void:
	var next := current_zone_index + 1
	if next >= ZONE_PATHS.size():
		push_warning("ZoneManager: already at final zone, cannot advance further")
		return
	load_zone(next)


## Return the index of the current zone (0-based), or -1 if none loaded yet.
func get_current_zone_index() -> int:
	return current_zone_index


# ── Internal ──────────────────────────────────────────────────────────────────

func _spawn_player() -> void:
	var player_res: PackedScene = load(PLAYER_SCENE_PATH)
	if player_res == null:
		push_error("ZoneManager: player scene not found at " + PLAYER_SCENE_PATH)
		return

	var scene := get_tree().current_scene
	if scene == null:
		push_error("ZoneManager: current_scene is null after scene change")
		return

	var spawn: Node3D = scene.get_node_or_null("PlayerSpawn")
	var player: CharacterBody3D = player_res.instantiate()
	scene.add_child(player)

	if spawn != null:
		player.global_position = spawn.global_position
	else:
		# Fallback: sit one unit above origin
		player.global_position = Vector3(0.0, 1.0, 0.0)
		push_warning("ZoneManager: no PlayerSpawn found in " + scene.name + ", using origin fallback")


func _fade_to(target_alpha: float, duration: float) -> void:
	var tween := create_tween()
	tween.tween_property(_fade_rect, "modulate:a", target_alpha, duration)
	await tween.finished


func _load_persistent_ui() -> void:
	## Instantiate game UI as children of ZoneManager so they survive all
	## change_scene_to_file calls.  Only do this when NOT in the main menu.
	## They'll be added to the tree on first zone load instead.
	pass  # deferred to first load_zone() call


var _ui_loaded: bool = false

func _ensure_persistent_ui() -> void:
	if _ui_loaded:
		return
	_ui_loaded = true
	for ui_path in PERSISTENT_UI:
		var res: PackedScene = load(ui_path)
		if res == null:
			push_error("ZoneManager: could not load persistent UI: " + ui_path)
			continue
		var node := res.instantiate()
		add_child(node)
