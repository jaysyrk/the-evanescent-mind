extends "res://scripts/combat/enemy_base.gd"
## The Reveler — Zone 2: The Manic Garden.
## Embodies manic episode energy: too fast, too bright, genuinely dangerous because of it.
## Mechanic: Frenzy mode after 3 hits in 4 seconds (speed ×1.5, double attack rate).
## When MC is manic: Reveler gains 30% more speed (mania recognises mania).
## Weakness: perfect dodge during frenzy auto-triggers MC hyperfocus.


const FRENZY_HIT_WINDOW  := 4.0   # seconds
const FRENZY_HIT_THRESH  := 3     # hits to trigger frenzy
const FRENZY_DURATION    := 5.0
const FRENZY_SPEED_MULT  := 1.5
const MANIC_SPEED_BONUS  := 0.3   # extra chase_speed fraction when MC is manic

var _frenzy_hits: int = 0
var _frenzy_timer: float = 0.0
var _in_frenzy: bool = false
var _frenzy_remaining: float = 0.0


func _ready() -> void:
	max_hp          = 65.0
	move_speed      = 3.5
	chase_speed     = 5.0
	attack_range    = 2.5
	detect_range    = 12.0
	stagger_duration= 0.5
	attack_cooldown = 1.2
	super()


func _physics_process(delta: float) -> void:
	super(delta)
	_update_frenzy(delta)

	# When manic, Reveler speeds up — mania amplifies mania
	if MentalStateManager.is_manic():
		chase_speed = 5.0 * (1.0 + MANIC_SPEED_BONUS)
	else:
		chase_speed = 5.0


func _update_frenzy(delta: float) -> void:
	if _in_frenzy:
		_frenzy_remaining -= delta
		if _frenzy_remaining <= 0.0:
			_exit_frenzy()
		return

	if _frenzy_hits > 0:
		_frenzy_timer -= delta
		if _frenzy_timer <= 0.0:
			_frenzy_hits = 0


func _on_hit_received(amount: float, knockback_force: float, source_pos: Vector3) -> void:
	# Called via take_damage — track frenzy hits
	if not _in_frenzy:
		_frenzy_hits += 1
		_frenzy_timer = FRENZY_HIT_WINDOW
		if _frenzy_hits >= FRENZY_HIT_THRESH:
			_enter_frenzy()


func _enter_frenzy() -> void:
	_in_frenzy = true
	_frenzy_remaining = FRENZY_DURATION
	_frenzy_hits = 0
	chase_speed *= FRENZY_SPEED_MULT
	attack_cooldown *= 0.5
	NarrativeManager.trigger_custom("it's getting faster. matching something inside you.")


func _exit_frenzy() -> void:
	_in_frenzy = false
	chase_speed = 5.0
	attack_cooldown = 1.2


func take_damage(amount: float, knockback_force: float, source_pos: Vector3) -> void:
	_on_hit_received(amount, knockback_force, source_pos)
	super(amount, knockback_force, source_pos)


func _attack() -> void:
	if _player == null:
		return
	# Rapid 3-hit combo
	if anim != null and anim.has_animation("attack_combo"):
		anim.play("attack_combo")
	await get_tree().create_timer(0.3).timeout
	hitbox.enable_hit()
	await get_tree().create_timer(0.15).timeout
	hitbox.disable_hit()
	await get_tree().create_timer(0.2).timeout
	hitbox.enable_hit()
	await get_tree().create_timer(0.15).timeout
	hitbox.disable_hit()
	if _in_frenzy:
		await get_tree().create_timer(0.2).timeout
		hitbox.enable_hit()
		await get_tree().create_timer(0.15).timeout
		hitbox.disable_hit()
