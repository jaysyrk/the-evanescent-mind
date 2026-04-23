extends Node3D
## PuzzleBase — abstract base for all 6 zone puzzles.
## Each puzzle gates access to its zone's philosopher.
## When solved: emits `solved`, sets GameState flag, notifies zone.


signal solved(puzzle_id: String)

@export var puzzle_id: String = ""
@export var philosopher: Node = null  # Assign the zone philosopher; unlocked on solve.

var is_solved: bool = false


func _ready() -> void:
	assert(puzzle_id != "", "PuzzleBase: puzzle_id must be set on " + name)
	is_solved = GameState.get_flag(puzzle_id + "_solved")
	if is_solved:
		_apply_solved_state()
	else:
		_setup()


# ── Overrideable ──────────────────────────────────────────────────────────────
## Called once on _ready if puzzle is not already solved.
func _setup() -> void:
	pass


## Called to apply the visual/mechanical solved state (on load AND after solving).
func _apply_solved_state() -> void:
	if philosopher != null and philosopher.has_method("set_locked"):
		philosopher.call("set_locked", false)


# ── Solve ─────────────────────────────────────────────────────────────────────
func complete_puzzle() -> void:
	if is_solved:
		return
	is_solved = true
	GameState.set_flag(puzzle_id + "_solved", true)
	_apply_solved_state()
	_on_puzzle_solved()
	solved.emit(puzzle_id)
	MentalStateManager.apply_event("puzzle_solved")


## Override for custom solve effects.
func _on_puzzle_solved() -> void:
	pass
