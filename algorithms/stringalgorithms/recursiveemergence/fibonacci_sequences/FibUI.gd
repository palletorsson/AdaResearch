extends Control
# Minimal stub: the original FibUI.gd was lost (not in main or any worktree). The visualisation
# itself runs from FibonacciSequences.gd on the scene root; this exists only to satisfy the
# .tscn's signal connections so the scene loads cleanly. The on-screen panel is hidden in
# wall/curation contexts anyway (GridInteractablesComponent / _clean_loaded suppress UI).

func _on_auto_toggled(_pressed: bool) -> void:
	pass


func _on_step_pressed() -> void:
	pass
