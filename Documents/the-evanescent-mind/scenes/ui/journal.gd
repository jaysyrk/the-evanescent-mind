extends Control
## Journal — in-world notebook listing philosophical fragments collected so far.
## Toggle with J key (input action "ui_toggle_journal").
## Sits above HUD (layer=12, below pause at 15).


## Content for each philosopher piece, written in 2nd-person inner voice.
const ENTRY_CONTENT: Dictionary = {
	"piece_stoic": "[b]The Stoic[/b]\n\nHe said suffering is not the wound, but the resistance to it. You turned that over for a long time. There was no comfort in it — but there was a strange, cold clarity. Perhaps clarity is all he had to give.",
	"piece_hedonist": "[b]The Hedonist[/b]\n\nShe laughed when you asked what the point was. Said the point is the point — pleasure, sensation, the warm weight of another body. You didn't believe her. But you envied her ease.",
	"piece_buddhist": "[b]The Buddhist[/b]\n\nHe pointed at the place you attach to most strongly and said: that is the door. You didn't want to open it. He didn't push. He just waited, the way still water waits.",
	"piece_antinatalist": "[b]The Antinatalist[/b]\n\nShe asked if you would have chosen this, given the choice. You already knew your answer. She nodded. There was no cruelty in her — only the kind of honesty that feels like surgery.",
	"piece_absurdist": "[b]The Absurdist[/b]\n\nHe danced through the argument and arrived nowhere, and seemed delighted about it. You found him maddening. Then you found him useful. The maze has no exit — so run.",
	"piece_theist": "[b]The Theist[/b]\n\nShe held the piece like it weighed something only she could feel. Said love outlasts the lover. You don't believe that. But you felt something when she said it. You're still not sure what.",
	"piece_nihilist": "[b]The Nihilist[/b]\n\nHe said nothing means anything, and said it with a voice like someone who has made peace with a cold house. You asked if that includes kindness. He paused. Then he gave you the piece.",
}

const INPUT_ACTION := "ui_toggle_journal"

var _is_open: bool = false


func _ready() -> void:
	visible = false
	EventBus.journal_entry_added.connect(_on_entry_added)
	_refresh_content()


func _unhandled_input(event: InputEvent) -> void:
	if event.is_action_pressed(INPUT_ACTION):
		_toggle()
		get_viewport().set_input_as_handled()


func _toggle() -> void:
	_is_open = not _is_open
	visible = _is_open
	if _is_open:
		_refresh_content()
		Input.set_mouse_mode(Input.MOUSE_MODE_VISIBLE)
		get_tree().paused = false  # journal does not pause the game
	else:
		Input.set_mouse_mode(Input.MOUSE_MODE_CAPTURED)


func _on_entry_added(_entry_id: String) -> void:
	if _is_open:
		_refresh_content()


func _refresh_content() -> void:
	var rich: RichTextLabel = $Panel/MarginContainer/VBox/ScrollContainer/RichText
	if rich == null:
		return

	if GameState.journal_entries.is_empty():
		rich.text = "[i]Nothing yet. The fragments are still out there.[/i]"
		return

	var full_text := ""
	for entry_id in GameState.journal_entries:
		if ENTRY_CONTENT.has(entry_id):
			full_text += ENTRY_CONTENT[entry_id] + "\n\n───\n\n"
	if full_text.ends_with("───\n\n"):
		full_text = full_text.left(full_text.length() - 7)

	rich.text = full_text
