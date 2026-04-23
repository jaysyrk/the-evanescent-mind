extends StaticBody3D
## AnxietyDoor — a door that opens when the MC's anxiety is high.
## Used in Zone 5 (The Laughing Labyrinth).
## At low anxiety: door is closed and blocks passage (collision enabled).
## At high anxiety: door rotates open (collision disabled).
##
## The door represents paths that only open under distress —
## routes the MC would only find when already falling apart.


@export var open_rotation_y: float = deg_to_rad(90.0)
@export var closed_rotation_y: float = 0.0
@export var transition_time: float = 0.8
@export var door_label_text: String = ""   # Optional hover hint

@onready var door_mesh: MeshInstance3D     = $MeshInstance3D
@onready var door_collision: CollisionShape3D = $CollisionShape3D
@onready var door_label: Label3D            = $Label3D

var _is_open: bool = false


func _ready() -> void:
	if door_label != null:
		door_label.visible = door_label_text != ""
		door_label.text = door_label_text


func set_open(open: bool) -> void:
	if _is_open == open:
		return
	_is_open = open

	var target_rot := open_rotation_y if open else closed_rotation_y

	var tween := create_tween().set_trans(Tween.TRANS_SINE).set_ease(Tween.EASE_IN_OUT)
	tween.tween_property(self, "rotation:y", target_rot, transition_time)

	# Disable collision immediately on open, re-enable when fully closed
	if open:
		door_collision.disabled = true
		if door_label != null:
			var label_tween := create_tween()
			label_tween.tween_property(door_label, "modulate:a", 0.0, 0.4)
	else:
		await tween.finished
		door_collision.disabled = false
