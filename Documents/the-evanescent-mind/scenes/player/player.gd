extends CharacterBody3D
## Player — base character controller for the MC.
## Combat state machine: Idle → Move → Attack → Recovery → Dodge → Hit → Dead
## All behaviour is modified by MentalStateManager axes at runtime.


# ── Exports ───────────────────────────────────────────────────────────────────
@export var walk_speed      := 4.5
@export var run_speed       := 7.5
@export var jump_velocity   := 6.0
@export var gravity         := 20.0

# Combat
@export var max_stamina     := 100.0
@export var stamina_regen   := 18.0   # per second
@export var attack_stamina_cost := 22.0
@export var dodge_stamina_cost  := 30.0
@export var dodge_duration      := 0.4
@export var i_frame_duration    := 0.38

# Zoom/FOV
@export var base_fov        := 75.0

# ── Node refs ─────────────────────────────────────────────────────────────────
@onready var _anim: AnimationPlayer        = $AnimationPlayer
@onready var _camera_pivot: Node3D         = $CameraPivot
@onready var _hitbox: Area3D               = $WeaponHitbox
@onready var _hurtbox: Area3D              = $Hurtbox
@onready var _camera: Camera3D            = $CameraPivot/Camera3D

# ── State ──────────────────────────────────────────────────────────────────────
enum State { IDLE, MOVE, ATTACK, RECOVERY, DODGE, HIT, DEAD }
var _state: State = State.IDLE

var _stamina: float = 100.0:
	set(value):
		_stamina = clampf(value, 0.0, max_stamina)
		EventBus.stamina_changed.emit(_stamina, max_stamina)

var _is_invulnerable := false
var _dodge_timer     := 0.0
var _recovery_timer  := 0.0
const RECOVERY_DURATION := 0.35

var _hp: float = 100.0


func _ready() -> void:
	add_to_group("player")
	_hitbox.monitoring = false
	_hurtbox.area_entered.connect(_on_hurtbox_entered)
	EventBus.mental_state_changed.connect(_on_mental_state_changed)


# ── Main loop ─────────────────────────────────────────────────────────────────
func _physics_process(delta: float) -> void:
	_apply_gravity(delta)

	match _state:
		State.IDLE, State.MOVE:
			_handle_movement(delta)
			_handle_combat_input()
			_regen_stamina(delta)
		State.ATTACK:
			_handle_attack_movement(delta)
		State.RECOVERY:
			_recovery_timer -= delta
			if _recovery_timer <= 0.0:
				_set_state(State.IDLE)
		State.DODGE:
			_handle_dodge_movement(delta)
			_dodge_timer -= delta
			if _dodge_timer <= 0.0:
				_end_dodge()
		State.HIT:
			pass  # AnimationPlayer callback re-enters IDLE
		State.DEAD:
			pass

	move_and_slide()
	_update_fov(delta)


# ── Movement ──────────────────────────────────────────────────────────────────
func _handle_movement(delta: float) -> void:
	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()

	# Depressive: slower; Manic: faster
	var mood_mod: float = 1.0 + MentalStateManager.mood * 0.3
	var speed := (run_speed if Input.is_action_pressed("run") else walk_speed) * mood_mod

	if direction.length() > 0.1:
		velocity.x = direction.x * speed
		velocity.z = direction.z * speed
		if _state != State.MOVE:
			_set_state(State.MOVE)
	else:
		velocity.x = move_toward(velocity.x, 0.0, speed * delta * 10.0)
		velocity.z = move_toward(velocity.z, 0.0, speed * delta * 10.0)
		if _state == State.MOVE:
			_set_state(State.IDLE)


func _handle_attack_movement(delta: float) -> void:
	# Slight forward momentum on attack
	velocity.x = move_toward(velocity.x, 0.0, 12.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 12.0 * delta)


func _handle_dodge_movement(delta: float) -> void:
	velocity.x = move_toward(velocity.x, 0.0, 5.0 * delta)
	velocity.z = move_toward(velocity.z, 0.0, 5.0 * delta)


func _apply_gravity(delta: float) -> void:
	if not is_on_floor():
		velocity.y -= gravity * delta
	elif Input.is_action_just_pressed("jump"):
		velocity.y = jump_velocity


# ── Combat input ──────────────────────────────────────────────────────────────
func _handle_combat_input() -> void:
	if Input.is_action_just_pressed("attack"):
		_try_attack()
	elif Input.is_action_just_pressed("dodge"):
		_try_dodge()


func _try_attack() -> void:
	if _stamina < attack_stamina_cost:
		return
	_stamina -= attack_stamina_cost
	_set_state(State.ATTACK)

	# Manic: faster animation; Depressive: slower
	var anim_speed: float = 1.0 + MentalStateManager.mood * 0.35
	_anim.speed_scale = anim_speed
	_anim.play("attack_01")
	_hitbox.monitoring = true

	await _anim.animation_finished
	_hitbox.monitoring = false
	_recovery_timer = RECOVERY_DURATION
	_set_state(State.RECOVERY)


func _try_dodge() -> void:
	if _stamina < dodge_stamina_cost:
		return
	_stamina -= dodge_stamina_cost

	var input_dir := Input.get_vector("move_left", "move_right", "move_forward", "move_back")
	var direction := (transform.basis * Vector3(input_dir.x, 0, input_dir.y)).normalized()
	if direction.length() < 0.1:
		direction = -transform.basis.z   # dodge backward if no input

	velocity = direction * 12.0
	_dodge_timer = dodge_duration
	_is_invulnerable = true
	_set_state(State.DODGE)
	_anim.play("dodge")


func _end_dodge() -> void:
	_is_invulnerable = false
	# Check for perfect dodge (enemy attack landed during i-frame window)
	_set_state(State.IDLE)


# ── Stamina regen ─────────────────────────────────────────────────────────────
func _regen_stamina(delta: float) -> void:
	# Depressive: slower regen; Manic: faster but lower effective max (handled in take_damage)
	var regen_mod := 1.0 - absf(MentalStateManager.mood) * 0.2
	_stamina += stamina_regen * regen_mod * delta


func _drain_stamina(amount: float) -> void:
	_stamina -= amount


# ── Damage ────────────────────────────────────────────────────────────────────
func take_damage(amount: float, source: Node = null) -> void:
	if _is_invulnerable or _state == State.DEAD:
		return

	# Manic: slightly more damage (reckless); depressive: longer stagger
	var damage_mod := 1.0 + MentalStateManager.mood * 0.15
	_hp -= amount * damage_mod
	EventBus.player_damaged.emit(amount * damage_mod, source)
	MentalStateManager.apply_event("player_damaged")

	if _hp <= 0.0:
		_die()
		return

	_set_state(State.HIT)
	_is_invulnerable = true
	var stagger_duration := 0.5 + absf(minf(MentalStateManager.mood, 0.0)) * 0.4
	_anim.play("hit")

	await get_tree().create_timer(i_frame_duration).timeout
	_is_invulnerable = false
	_set_state(State.IDLE)


func _die() -> void:
	_set_state(State.DEAD)
	_anim.play("death")
	EventBus.player_died.emit()


# ── Hitbox ────────────────────────────────────────────────────────────────────
func _on_hurtbox_entered(area: Area3D) -> void:
	if area.is_in_group("enemy_hitbox"):
		var dmg: float = area.get_meta("damage", 10.0)
		take_damage(dmg, area.get_parent())


# ── Visual FOV response ───────────────────────────────────────────────────────
func _update_fov(delta: float) -> void:
	if _camera == null:
		return
	# Manic: wider FOV (slightly unhinged); hyperfocus: slight zoom
	var fov_target := base_fov
	fov_target += MentalStateManager.mood * 8.0
	if MentalStateManager.is_hyperfocused():
		fov_target -= 6.0
	_camera.fov = lerpf(_camera.fov, fov_target, delta * 3.0)


# ── Mental state reactions ────────────────────────────────────────────────────
func _on_mental_state_changed(axis: String, _value: float) -> void:
	if axis == "focus" and MentalStateManager.is_hyperfocused() and _state == State.DODGE:
		# Perfect dodge triggered hyperfocus
		EventBus.hyperfocus_triggered.emit()
		Engine.time_scale = 0.35
		await get_tree().create_timer(0.6, true, false, true).timeout
		Engine.time_scale = 1.0


# ── State helpers ─────────────────────────────────────────────────────────────
func _set_state(new_state: State) -> void:
	_state = new_state
