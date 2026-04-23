extends Node3D
## PhilosopherBase — base class for all 7 philosopher NPCs.
##
## Each philosopher holds one ritual piece. They will not give it until
## the MC engages with their position *compassionately* — disagreement is fine,
## contempt or dismissal blocks the piece.
##
## Engagement is tracked via a "compassion_score" that accrues through dialogue choices.
## When it crosses the threshold, piece_ready becomes true and the piece can be collected.


signal piece_given(piece_id: String)

@export var philosopher_name: String = ""
@export var piece_id: String = ""          # must match a flag in GameState
@export var dialogue_timeline: String = "" # Dialogic timeline name
@export var compassion_threshold: float = 1.0
@export var interact_range: float = 3.0

var compassion_score: float = 0.0
var piece_ready: bool = false
var piece_collected: bool = false

@onready var interaction_area: Area3D = $InteractionArea
@onready var prompt_label: Label3D    = $PromptLabel


func _ready() -> void:
	assert(piece_id != "", "PhilosopherBase: piece_id must be set on " + name)
	piece_collected = GameState.get_flag(piece_id)
	prompt_label.visible = false
	interaction_area.body_entered.connect(_on_player_entered)
	interaction_area.body_exited.connect(_on_player_exited)


# ── Interaction ───────────────────────────────────────────────────────────────
func _on_player_entered(body: Node3D) -> void:
	if not body.is_in_group("player") or piece_collected:
		return
	prompt_label.visible = true
	prompt_label.text = "[E] Speak with %s" % philosopher_name


func _on_player_exited(body: Node3D) -> void:
	prompt_label.visible = false


func _input(event: InputEvent) -> void:
	if piece_collected:
		return
	if event.is_action_pressed("interact"):
		var player := get_tree().get_first_node_in_group("player")
		if player and global_position.distance_to(player.global_position) <= interact_range:
			_begin_dialogue()


# ── Dialogue ──────────────────────────────────────────────────────────────────
func _begin_dialogue() -> void:
	if dialogue_timeline == "":
		push_warning("%s: no dialogue_timeline assigned" % name)
		return
	EventBus.dialogue_started.emit(dialogue_timeline)
	MentalStateManager.apply_event("philosophical_engagement")
	Dialogic.start(dialogue_timeline)
	Dialogic.timeline_ended.connect(_on_dialogue_ended, CONNECT_ONE_SHOT)


func _on_dialogue_ended() -> void:
	EventBus.dialogue_ended.emit(dialogue_timeline)
	_evaluate_compassion()


# ── Compassion evaluation ─────────────────────────────────────────────────────
## Called by Dialogic signal events mid-timeline to accumulate score.
func add_compassion(amount: float) -> void:
	compassion_score += amount
	if compassion_score >= compassion_threshold and not piece_ready:
		piece_ready = true
		_on_piece_ready()


func _evaluate_compassion() -> void:
	if piece_ready and not piece_collected:
		_give_piece()


func _on_piece_ready() -> void:
	NarrativeManager.trigger_custom(
		"Something in their words settles into you. Not agreement. Just understanding."
	)


func _give_piece() -> void:
	piece_collected = true
	GameState.set_flag(piece_id, true)
	GameState.add_journal_entry(piece_id)
	EventBus.ritual_piece_collected.emit(piece_id)
	MentalStateManager.apply_event("ritual_piece_collected")
	NarrativeManager.trigger_beat("ritual_piece_collected")
	piece_given.emit(piece_id)
	prompt_label.visible = false
	_on_piece_given()


## Override in subclass for unique piece-giving animation/effect.
func _on_piece_given() -> void:
	pass
