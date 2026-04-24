extends SceneTree
## Deep validator -- launched by check_errors.ps1 via:
##   godot --headless --script res://tools/scene_validator.gd
##
## Pass 1: loads every .gd script (parse + compile check).
## Pass 2: loads + instantiates every .tscn scene (catches missing sub-resources,
##         broken node hierarchies, and @onready path errors).
## Instances are added to the SceneTree root so _ready() fires.


const SKIP_DIRS: Array[String] = ["addons", ".godot", "tools"]

var _to_check: Array[String] = []
var _index: int = 0
var _checked_scripts: int = 0
var _checked_scenes: int = 0
var _fail_count: int = 0
var _current_instance: Node = null


func _initialize() -> void:
	print("")
	print("================================================================")
	print("  DEEP VALIDATOR -- scripts + scenes")
	print("================================================================")
	print("")
	_collect_files("res://", _to_check)
	print("  Found %d files to check. Running..." % _to_check.size())
	print("")


func _process(delta: float) -> bool:
	# Process one file per frame so _ready() fires on the previous instance first
	if _current_instance != null and is_instance_valid(_current_instance):
		_current_instance.queue_free()
		_current_instance = null
		return false  # wait one more frame for queue_free to resolve

	if _index >= _to_check.size():
		_finish()
		return true  # quit

	var path: String = _to_check[_index]
	_index += 1

	if path.ends_with(".gd"):
		_check_script(path)
	elif path.ends_with(".tscn"):
		_check_scene(path)

	return false


func _collect_files(path: String, out: Array[String]) -> void:
	var dir := DirAccess.open(path)
	if dir == null:
		return
	dir.list_dir_begin()
	var entry := dir.get_next()
	while entry != "":
		if dir.current_is_dir():
			if not entry.begins_with(".") and entry not in SKIP_DIRS:
				_collect_files(path + entry + "/", out)
		else:
			if entry.ends_with(".gd") or entry.ends_with(".tscn"):
				out.append(path + entry)
		entry = dir.get_next()
	dir.list_dir_end()


func _check_script(path: String) -> void:
	_checked_scripts += 1
	var res = ResourceLoader.load(path, "GDScript")
	if res == null:
		push_error("VALIDATOR: could not load script -- " + path)
		_fail_count += 1


func _check_scene(path: String) -> void:
	_checked_scenes += 1
	var packed = ResourceLoader.load(path, "PackedScene")
	if packed == null:
		push_error("VALIDATOR: could not load scene -- " + path)
		_fail_count += 1
		return

	var instance: Node = packed.instantiate()
	if instance == null:
		push_error("VALIDATOR: could not instantiate scene -- " + path)
		_fail_count += 1
		return

	# Add to tree so _ready() fires and @onready vars are resolved this frame.
	# Keep a reference so we free it on the next _process tick.
	get_root().add_child(instance)
	_current_instance = instance


func _finish() -> void:
	print("----------------------------------------------------------------")
	print("  Scripts checked : %d" % _checked_scripts)
	print("  Scenes  checked : %d" % _checked_scenes)
	if _fail_count == 0:
		print("  Result          : PASS -- all files loaded and instantiated OK")
	else:
		print("  Result          : FAIL -- %d file(s) had errors" % _fail_count)
	print("================================================================")
	print("")
