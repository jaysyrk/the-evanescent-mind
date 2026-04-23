extends "res://scripts/combat/enemy_base.gd"
## The Jester — Zone 5: The Laughing Labyrinth.
## Embodies hysterical deflection — uses humour as a weapon.
## Mechanic: teleports when player enters 4m range (maintains distance).
## Immune for 0.5s after teleport. Copies the player's last attack by name.
## Laughs in AudioStreamPlayer during combat.


const TELEPORT_RANGE    := 4.0
const TELEPORT_DISTANCE := 7.0
const TELEPORT_IMMUNITY := 0.5

var _teleport_immune: bool = false
var _last_player_attack: String = ""
var _immune_timer: float = 0.0


func _ready() -> void:
	max_hp           = 70.0
	move_speed       = 2.0
	chase_speed      = 0.0   # Jester never runs — it teleports
	attack_range     = 2.2
	detect_range     = 10.0
	stagger_duration = 0.6
	attack_cooldown  = 2.0
	super()
	# Listen for player attack events to copy them
	EventBus.player_damaged.connect(_on_player_attacked)


func _physics_process(delta: float) -> void:
	if _teleport_immune:
		_immune_timer -= delta
		if _immune_timer <= 0.0:
			_teleport_immune = false

	if _player == null or is_dead:
		return

	var dist := global_position.distance_to(_player.global_position)
	if dist < TELEPORT_RANGE and not _teleport_immune:
		_teleport_away()
		return

	super(delta)


func _teleport_away() -> void:
	_teleport_immune = true
	_immune_timer = TELEPORT_IMMUNITY

	var away_dir := (global_position - _player.global_position).normalized()
	var candidate := global_position + away_dir * TELEPORT_DISTANCE
	# Add slight random offset
	candidate += Vector3(randf_range(-2, 2), 0, randf_range(-2, 2))
	global_position = candidate

	# Flash effect (handled by shader/animation in editor)
	NarrativeManager.trigger_custom("you blinked and it was somewhere else. laughing.")


func _on_player_attacked(_damage: float, _knockback: Vector3) -> void:
	# Record that the player attacked — use this for mirrored attack
	_last_player_attack = "attack"  # Would pull from animation name if available


func take_damage(amount: float, knockback_force: float, source_pos: Vector3) -> void:
	if _teleport_immune:
		return  # Immune post-teleport
	super(amount, knockback_force, source_pos)


func _attack() -> void:
	if _player == null:
		return
	# Mirror slash — same timing as a typical player attack
	_anim_player.play("attack" if _anim_player.has_animation("attack") else "RESET")
	await get_tree().create_timer(0.25).timeout
	_hitbox.enable_hit()
	await get_tree().create_timer(0.2).timeout
	_hitbox.disable_hit()
