extends Area3D
## Hitbox — attach to a weapon or attack source.
## When monitoring is enabled and it enters a Hurtbox, damage is dealt.
## Set metadata "damage" and optionally "knockback_force" on this node.


signal hit_landed(hurtbox: Area3D, damage: float)

## Base damage this hitbox deals. Can be overridden per-attack via set_meta.
@export var damage: float = 10.0
## Knockback impulse magnitude applied to target on hit.
@export var knockback_force: float = 6.0
## If true, this hitbox belongs to an enemy (used by hurtboxes to filter).
@export var is_enemy_hitbox: bool = false

var _already_hit: Array[Area3D] = []   # prevents multi-hit in one swing


func _ready() -> void:
	monitoring = false   # enabled only during active attack frames
	area_entered.connect(_on_area_entered)
	if is_enemy_hitbox:
		add_to_group("enemy_hitbox")
	else:
		add_to_group("player_hitbox")


func enable_hit() -> void:
	_already_hit.clear()
	monitoring = true


func disable_hit() -> void:
	monitoring = false
	_already_hit.clear()


func _on_area_entered(area: Area3D) -> void:
	if area in _already_hit:
		return
	if area.is_in_group("hurtbox"):
		_already_hit.append(area)
		var dmg := get_meta("damage", damage) as float
		area.receive_hit(dmg, knockback_force, global_position)
		hit_landed.emit(area, dmg)
