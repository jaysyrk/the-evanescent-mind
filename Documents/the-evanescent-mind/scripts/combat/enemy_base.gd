extends CharacterBody3D
## EnemyBase — base class for all enemies.
## State machine: Idle → Patrol → Chase → Attack → Staggered → Dead
## Subclasses override _on_state_enter, _attack, _patrol_tick, and tweak exports.


# ── Exports ───────────────────────────────────────────────────────────────────
@export var max_hp: float            = 60.0
@export var move_speed: float        = 2.5
@export var chase_speed: float       = 4.2
@export var attack_range: float      = 1.8   # metres
@export var detect_range: float      = 10.0  # metres
@export var lose_range: float        = 18.0
@export var attack_cooldown: float   = 1.6
@export var stagger_duration: float  = 0.5
@export var xp_value: int            = 10

# ── State machine ─────────────────────────────────────────────────────────────
enum State { IDLE, PATROL, CHASE, ATTACK, STAGGERED, DEAD }
var _state: State = State.IDLE
var _state_timer: float = 0.0

# ── Internal ──────────────────────────────────────────────────────────────────
var _hp: float
var _attack_timer: float = 0.0
var _player: CharacterBody3D = null
var is_dead: bool = false

const GRAVITY := 20.0

@onready var hurtbox: Area3D        = $Hurtbox
@onready var hitbox: Area3D         = $Hitbox
@onready var anim: AnimationPlayer  = $AnimationPlayer
@onready var nav: NavigationAgent3D = $NavigationAgent3D


func _ready() -> void:
	_hp = max_hp
	_find_player()
	_set_state(State.PATROL)
	# take_damage() is called directly from hurtbox.receive_hit() — no signal needed here


func _physics_process(delta: float) -> void:
	_apply_gravity(delta)
	_attack_timer = maxf(_attack_timer - delta, 0.0)
	_state_timer  = maxf(_state_timer  - delta, 0.0)

	match _state:
		State.IDLE:
			_idle_tick(delta)
		State.PATROL:
			_patrol_tick(delta)
		State.CHASE:
			_chase_tick(delta)
		State.ATTACK:
			_attack_tick(delta)
		State.STAGGERED:
			if _state_timer <= 0.0:
				_set_state(State.IDLE)
		State.DEAD:
			pass

	move_and_slide()


# ── State ticks (overrideable) ────────────────────────────────────────────────
func _idle_tick(_delta: float) -> void:
	if _player_in_range(detect_range):
		_set_state(State.CHASE)


func _patrol_tick(_delta: float) -> void:
	# Base: just scan for player; subclasses implement actual patrol paths
	if _player_in_range(detect_range):
		_set_state(State.CHASE)


func _chase_tick(_delta: float) -> void:
	if not _player_in_range(lose_range):
		_set_state(State.PATROL)
		return
	if _player_in_range(attack_range) and _attack_timer <= 0.0:
		_set_state(State.ATTACK)
		return
	_move_toward_player()


func _attack_tick(_delta: float) -> void:
	# Wait for animation; subclass calls _end_attack() from AnimationPlayer signal
	pass


# ── Public API ────────────────────────────────────────────────────────────────
func take_damage(amount: float, knockback_force: float, source_pos: Vector3) -> void:
	if is_dead:
		return
	_hp -= amount
	EventBus.enemy_damaged.emit(self, amount)

	# Knockback impulse
	var dir := (global_position - source_pos).normalized()
	dir.y = 0.3
	velocity += dir * knockback_force

	if _hp <= 0.0:
		_die()
	else:
		_set_state(State.STAGGERED)
		if anim != null and anim.has_animation("hit"):
			anim.play("hit")


# ── Internal helpers ──────────────────────────────────────────────────────────
func _die() -> void:
	is_dead = true
	hitbox.disable_hit()
	_set_state(State.DEAD)
	EventBus.enemy_died.emit(self)
	if anim != null and anim.has_animation("death"):
		anim.play("death")
		await anim.animation_finished
	queue_free()


func _end_attack() -> void:
	_attack_timer = attack_cooldown
	hitbox.disable_hit()
	_set_state(State.CHASE if _player_in_range(lose_range) else State.PATROL)


func _move_toward_player() -> void:
	if _player == null:
		return
	nav.target_position = _player.global_position
	var next := nav.get_next_path_position()
	var dir  := (next - global_position).normalized()
	dir.y = 0.0
	velocity.x = dir.x * chase_speed
	velocity.z = dir.z * chase_speed
	if dir.length() > 0.1:
		rotation.y = lerp_angle(rotation.y, atan2(-dir.x, -dir.z), 0.15)


func _player_in_range(range_m: float) -> bool:
	if _player == null:
		return false
	return global_position.distance_to(_player.global_position) <= range_m


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= GRAVITY * delta


func _find_player() -> void:
	_player = get_tree().get_first_node_in_group("player") as CharacterBody3D


func _set_state(new_state: State) -> void:
	if new_state == _state:
		return
	_state = new_state
	_state_timer = stagger_duration if new_state == State.STAGGERED else 0.0
	_on_state_enter(new_state)


## Override in subclass to react to state changes (play anims, set timers, etc.)
func _on_state_enter(state: State) -> void:
	match state:
		State.IDLE:
			if anim != null and anim.has_animation("idle"):
				anim.play("idle")
		State.PATROL:
			if anim != null and anim.has_animation("walk"):
				anim.play("walk")
		State.CHASE:
			if anim != null and anim.has_animation("run"):
				anim.play("run")
		State.ATTACK:
			_attack()
		State.DEAD:
			pass


## Override in subclass to define the attack behaviour.
func _attack() -> void:
	pass
