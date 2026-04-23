extends CanvasLayer
## HUD — root of all in-game UI.
## Owns: StaminaBar, MonologueOverlay, IntrusiveThoughtDisplay, MentalStateDebug
## All children listen to EventBus; this script handles top-level coordination only.


@onready var stamina_bar:       Control = $StaminaBar
@onready var monologue_overlay: Control = $MonologueOverlay
@onready var thought_display:   Control = $IntrusiveThoughtDisplay
@onready var debug_overlay:     Control = $MentalStateDebug


func _ready() -> void:
	# Debug overlay is off by default — toggle with F3
	debug_overlay.visible = false


func _input(event: InputEvent) -> void:
	if event is InputEventKey and event.pressed and event.physical_keycode == KEY_F3:
		debug_overlay.visible = not debug_overlay.visible
