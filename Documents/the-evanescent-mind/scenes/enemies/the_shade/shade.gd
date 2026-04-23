extends "res://scripts/combat/enemy_base.gd"
## The Shade — Zone 6: The Limerent Archive.
## Embodies limerence as threat: looks like Celeste. Cannot be hurt directly.
## Only vulnerable when MC faces AWAY (attacking while running from it).
## High limerence (>0.7): Shade becomes passive. Won't attack.
## Proximity slowly raises limerence and drops mood.
## Attack "The Weight of Her": no physical hit — raises anxiety 0.15.


const LIMERENCE_PASSIVE_THRESHOLD := 0.70
const PROXIMITY_LIMERENCE_RATE    := 0.002   # per second
const PROXIMITY_MOOD_DRAIN        := 0.001   # per second
const ANXIETY_ON_HIT              := 0.15
const FACING_AWAY_DOT_THRESHOLD   := -0.5    # dot product: negative = facing away

var _is_passive: bool = false


func _ready() -> void:
	max_hp           = 90.0
	move_speed       = 2.2
	chase_speed      = 3.0
	attack_range     = 2.2
	detect_range     = 15.0
	stagger_duration = 0.4
	attack_cooldown  = 3.0
	super()
	LimerenceTracker.limerence_changed.connect(_on_limerence_changed)
	_check_passive()


func _check_passive() -> void:
	_is_passive = LimerenceTracker.limerence_level >= LIMERENCE_PASSIVE_THRESHOLD


func _on_limerence_changed(level: float) -> void:
	_is_passive = level >= LIMERENCE_PASSIVE_THRESHOLD
	if _is_passive and _current_state == State.CHASE:
		_current_state = State.IDLE


func _physics_process(delta: float) -> void:
	super(delta)
	if _player != null and _current_state != State.DEAD:
		var dist := global_position.distance_to(_player.global_position)
		if dist < detect_range:
			LimerenceTracker.limerence_level += PROXIMITY_LIMERENCE_RATE * delta
			MentalStateManager.mood -= PROXIMITY_MOOD_DRAIN * delta


func _can_attack() -> bool:
	if _is_passive:
		return false
	return super()


func take_damage(amount: float, knockback_force: float, source_pos: Vector3) -> void:
	# Only take damage if player is facing away
	if _player == null:
		return
	var to_shade := (global_position - _player.global_position).normalized()
	var player_forward := -_player.global_basis.z  # player's forward vector
	var dot := player_forward.dot(to_shade)
	if dot >= FACING_AWAY_DOT_THRESHOLD:
		# Player is facing toward the Shade — no damage
		NarrativeManager.trigger_custom("you can't bring yourself to hurt her. even this.")
		return
	super(amount, knockback_force, source_pos)


func _attack() -> void:
	if _player == null or _is_passive:
		return
	# The Weight of Her — anxiety spike, no hitbox needed
	MentalStateManager.anxiety += ANXIETY_ON_HIT
	NarrativeManager.trigger_custom("she's right there and you can't — it's not her, but it looks like her.")
	EventBus.player_damaged.emit(0.0, Vector3.ZERO)  # Zero damage, just signal for feedback
