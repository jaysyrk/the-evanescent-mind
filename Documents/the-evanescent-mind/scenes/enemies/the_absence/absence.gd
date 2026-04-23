extends "res://scripts/combat/enemy_base.gd"
## The Absence — Zone 3: The Still Void.
## Embodies anhedonia and dissociation: invisible, slow, impossible to locate until you stop.
## Mechanic: invisible unless MC is still (velocity < 0.2) OR attacking.
## Only attacks once per encounter, then resets position to a random spawn.
## "The Touch": grabs and drains 12 HP/s for 2 seconds instead of knockback.
## Does NOT use NavigationAgent — moves directly through space, ignoring walls.


const VISIBILITY_PLAYER_SPEED_THRESHOLD := 0.25
const DRAIN_DPS    := 12.0
const DRAIN_DURATION := 2.0
const INVISIBLE_ALPHA := 0.04
const VISIBLE_ALPHA  := 0.82

var _is_visible_to_player: bool = false
var _has_attacked_this_encounter: bool = false
var _draining: bool = false


func _ready() -> void:
	max_hp          = 45.0
	move_speed      = 0.8
	chase_speed     = 1.5
	attack_range    = 2.8
	detect_range    = 9.0
	stagger_duration= 0.0   # never staggers
	attack_cooldown = 999.0  # effectively unlimited — resets position after each attack
	super()
	_set_mesh_alpha(INVISIBLE_ALPHA)


func _physics_process(delta: float) -> void:
	super(delta)
	_update_visibility_state()


func _update_visibility_state() -> void:
	if _player == null:
		return
	var player_speed := _player.velocity.length()
	var should_be_visible := player_speed < VISIBILITY_PLAYER_SPEED_THRESHOLD
	if should_be_visible != _is_visible_to_player:
		_is_visible_to_player = should_be_visible
		_tween_alpha(VISIBLE_ALPHA if should_be_visible else INVISIBLE_ALPHA)


func _set_mesh_alpha(alpha: float) -> void:
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mesh == null:
		return
	var mat := mesh.get_active_material(0)
	if mat is StandardMaterial3D:
		mat.albedo_color.a = alpha


func _tween_alpha(target: float) -> void:
	var mesh: MeshInstance3D = get_node_or_null("MeshInstance3D")
	if mesh == null:
		return
	var mat := mesh.get_active_material(0)
	if mat is StandardMaterial3D:
		var tween := create_tween()
		tween.tween_property(mat, "albedo_color:a", target, 0.6)


# Override: direct movement, ignore NavigationAgent
func _move_toward_player(delta: float) -> void:
	if _player == null:
		return
	var dir := (_player.global_position - global_position).normalized()
	velocity = dir * chase_speed
	move_and_slide()


func _attack() -> void:
	if _has_attacked_this_encounter or _player == null:
		return
	_has_attacked_this_encounter = true
	# The Touch: drain, not knockback
	NarrativeManager.trigger_custom("something cold. not pain exactly. like the will to move going missing.")
	_draining = true
	EventBus.player_damaged.emit(DRAIN_DPS, Vector3.ZERO)
	await get_tree().create_timer(DRAIN_DURATION / 2.0).timeout
	if _draining:
		EventBus.player_damaged.emit(DRAIN_DPS, Vector3.ZERO)
	await get_tree().create_timer(DRAIN_DURATION / 2.0).timeout
	_draining = false
	_reset_to_random_position()


func _reset_to_random_position() -> void:
	_has_attacked_this_encounter = false
	var offset := Vector3(randf_range(-14, 14), 0, randf_range(-14, 14))
	global_position += offset
