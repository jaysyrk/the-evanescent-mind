extends "res://scripts/combat/enemy_base.gd"
## The Hollow — Zone 1 (The Waking Sorrow) enemy.
##
## Design intent: embodies depressive inertia. Slow, inevitable, heavy.
## - Passively drains MC stamina when within drain_range (the weight of their presence)
## - Moves faster when MC's mood is depressive (depression feeding depression)
## - Attack: a slow, telegraphed grab — long windup, hard to dodge when depressed
## - High poise: only staggers after 3 consecutive hits, not one


const DRAIN_RANGE     := 5.0    # metres — passive stamina drain radius
const DRAIN_RATE      := 4.0    # stamina per second drained
const POISE_THRESHOLD := 3      # hits before stagger

var _poise_count: int = 0
var _drain_active: bool = false


func _ready() -> void:
	# Override base stats for The Hollow
	max_hp         = 80.0
	move_speed     = 1.4
	chase_speed    = 2.2
	attack_range   = 2.0
	detect_range   = 9.0
	stagger_duration = 0.8
	attack_cooldown  = 2.4
	super()


func _physics_process(delta: float) -> void:
	_apply_speed_mood_modifier()
	_tick_stamina_drain(delta)
	super(delta)


# ── Passive stamina drain ─────────────────────────────────────────────────────
func _tick_stamina_drain(delta: float) -> void:
	if _player == null or is_dead:
		return
	var dist := global_position.distance_to(_player.global_position)
	if dist <= DRAIN_RANGE:
		if not _drain_active:
			_drain_active = true
		# Drain scales with proximity — closer = worse
		var proximity_factor := 1.0 - (dist / DRAIN_RANGE)
		var drain := DRAIN_RATE * proximity_factor * delta
		# Access stamina through player; player.gd exposes _stamina via a setter
		if _player.has_method("_drain_stamina"):
			_player._drain_stamina(drain)
		else:
			# Fallback: emit a signal that player.gd can listen to
			EventBus.player_damaged.emit(0.0, self)   # 0 HP, just triggers anxiety tick
	else:
		_drain_active = false


# ── Mood-based speed modifier ─────────────────────────────────────────────────
func _apply_speed_mood_modifier() -> void:
	# When MC is depressive, The Hollow moves up to 40% faster
	var mood_bonus := clampf(-MentalStateManager.mood * 0.4, 0.0, 0.4)
	chase_speed = 2.2 + (2.2 * mood_bonus)


# ── Poise system (3-hit stagger threshold) ───────────────────────────────────
func take_damage(amount: float, knockback_force: float, source_pos: Vector3) -> void:
	if is_dead:
		return
	_hp -= amount
	EventBus.enemy_damaged.emit(self, amount)

	var dir := (global_position - source_pos).normalized()
	dir.y = 0.3

	_poise_count += 1
	if _poise_count >= POISE_THRESHOLD:
		_poise_count = 0
		# Full stagger + knockback
		velocity += dir * knockback_force
		if _hp <= 0.0:
			_die()
		else:
			_set_state(State.STAGGERED)
			anim.play("hit")
	else:
		# Absorb hit — slight flinch visual but no stagger
		velocity += dir * (knockback_force * 0.15)
		if _hp <= 0.0:
			_die()
		else:
			anim.play("flinch")


# ── Attack: the Reaching Grab ─────────────────────────────────────────────────
func _attack() -> void:
	anim.play("attack_grab")
	# Hitbox enabled mid-animation via AnimationPlayer track (or signal below)
	await get_tree().create_timer(0.9).timeout   # long telegraph
	if _state == State.ATTACK and not is_dead:
		hitbox.set_meta("damage", 18.0)
		hitbox.set_meta("knockback_force", 3.0)   # low knockback — it grabs, it doesn't push
		hitbox.enable_hit()
		await get_tree().create_timer(0.35).timeout
		_end_attack()


func _on_state_enter(state: State) -> void:
	match state:
		State.IDLE, State.PATROL:
			# The Hollow has no patrol animation — it drifts
			if anim.has_animation("drift"):
				anim.play("drift")
			else:
				anim.play("idle")
		State.CHASE:
			if anim.has_animation("walk"):
				anim.play("walk")
		State.STAGGERED:
			_poise_count = 0
		_:
			super(state)
