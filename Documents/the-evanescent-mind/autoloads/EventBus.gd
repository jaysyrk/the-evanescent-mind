extends Node
## EventBus — central signal bus. All systems communicate through here.
## Nothing should hold a direct reference to another system; emit and listen instead.


# ── Mental State ─────────────────────────────────────────────────────────────
signal mental_state_changed(axis: String, value: float)
signal mood_threshold_crossed(direction: String)   # "manic" | "depressive" | "baseline"
signal anxiety_threshold_crossed(direction: String) # "high" | "low"
signal focus_threshold_crossed(direction: String)   # "hyperfocus" | "scatter" | "baseline"

# ── Combat ───────────────────────────────────────────────────────────────────
signal player_damaged(amount: float, source: Node)
signal player_died()
signal player_dodged()
signal enemy_damaged(enemy: Node, amount: float)
signal enemy_died(enemy: Node)
signal stamina_changed(current: float, maximum: float)
signal hyperfocus_triggered()   # Perfect dodge slow-motion window

# ── Narrative ────────────────────────────────────────────────────────────────
signal flag_set(flag_name: String, value: Variant)
signal inner_monologue_triggered(text: String, tone: String)
signal journal_entry_added(entry_id: String)
signal dialogue_started(dialogue_name: String)
signal dialogue_ended(dialogue_name: String)

# ── Limerence ────────────────────────────────────────────────────────────────
signal limerence_changed(new_level: float)
signal projection_sequence_unlocked()
signal intrusive_thought_triggered(text: String)
signal lo_interaction(interaction_type: String)  # "proximity" | "dialogue" | "help" | "conflict"

# ── World ─────────────────────────────────────────────────────────────────────
signal zone_entered(zone_id: String)
signal zone_exited(zone_id: String)
signal ritual_piece_collected(piece_id: String)
signal all_ritual_pieces_gathered()

# ── Endings ───────────────────────────────────────────────────────────────────
signal threshold_reached()
signal ending_triggered(ending_id: String)  # "void" | "stay"
