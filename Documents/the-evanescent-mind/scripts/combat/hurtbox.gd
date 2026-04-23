extends Area3D
## Hurtbox — attach to any entity that can receive damage.
## Calls take_damage() on its parent when hit by a Hitbox.


signal damage_received(amount: float, source_position: Vector3)

## If true, hits from player hitboxes are accepted. If false, only enemy hitboxes.
@export var receives_player_hits: bool = false
@export var receives_enemy_hits: bool = true


func _ready() -> void:
	add_to_group("hurtbox")
	monitoring = false   # passive — hitboxes enter us, we don't scan


func receive_hit(damage: float, knockback_force: float, source_position: Vector3) -> void:
	# Filter by source
	# (Hitbox.is_enemy_hitbox is checked by the calling Hitbox via group membership)
	if not _parent_can_take_damage():
		return

	damage_received.emit(damage, source_position)

	var parent := get_parent()
	if parent.has_method("take_damage"):
		parent.take_damage(damage, knockback_force, source_position)


func _parent_can_take_damage() -> bool:
	var parent := get_parent()
	if parent == null:
		return false
	# Dead check — any parent with a _state == DEAD or is_dead bool
	if parent.get("is_dead") == true:
		return false
	return true
