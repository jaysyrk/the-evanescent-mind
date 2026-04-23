extends "res://scripts/combat/enemy_base.gd"
## The Infant Eternal — Zone 4: The Cradle of Ash.
## Embodies the suffering of new life and the cost of existence.
## Spawns in groups of 3-5. Small, fast, cannot be staggered.
## Death wail raises MC anxiety +0.08.
## Pack behaviour: all target the same point, circling and rushing in turns.


const DEATH_ANXIETY_RAISE := 0.08
const CIRCLE_RADIUS := 2.5
const CIRCLE_SPEED  := 2.2

var _circle_angle: float = 0.0
var _is_circling: bool = true


func _ready() -> void:
	max_hp           = 20.0
	move_speed       = 3.8
	chase_speed      = 4.2
	attack_range     = 1.2
	detect_range     = 6.0
	stagger_duration = 0.0   # cannot be staggered
	attack_cooldown  = 1.8
	# Stagger poise is irrelevant — we block stagger entirely
	super()
	# Vary angle so pack spreads out
	_circle_angle = randf() * TAU


func _physics_process(delta: float) -> void:
	# Custom locomotion: circle the player then rush
	_apply_gravity(delta)
	if _player == null or is_dead:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist > detect_range:
		_set_state(State.IDLE)
		velocity.x = 0
		velocity.z = 0
		move_and_slide()
		return

	if dist > attack_range:
		# Circle
		_circle_angle += CIRCLE_SPEED * delta
		var circle_pos := _player.global_position + Vector3(
			cos(_circle_angle) * CIRCLE_RADIUS, 0, sin(_circle_angle) * CIRCLE_RADIUS
		)
		var dir := (circle_pos - global_position).normalized()
		velocity.x = dir.x * chase_speed
		velocity.z = dir.z * chase_speed
		move_and_slide()
	else:
		if _attack_timer <= 0.0:
			_set_state(State.ATTACK)
			_attack()


func _die() -> void:
	MentalStateManager.anxiety += DEATH_ANXIETY_RAISE
	NarrativeManager.trigger_custom("the sound it makes when it falls. you'll carry that.")
	super()


func _attack() -> void:
	if _player == null:
		return
	hitbox.enable_hit()
	await get_tree().create_timer(0.12).timeout
	hitbox.disable_hit()
	_attack_timer = attack_cooldown
	_set_state(State.CHASE)
