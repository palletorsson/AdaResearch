extends Node

## Standalone launcher for the Lab Evolution Editor.
## Run lab_evolution_editor_standalone.tscn directly — the editor opens automatically.
## Press K to toggle, ESC to quit.

func _ready() -> void:
	# Dark background so the editor feels like its own app
	RenderingServer.set_default_clear_color(Color(0.02, 0.03, 0.05, 1.0))

	# Auto-open the editor after one frame (let overlay _ready() finish first)
	_open_editor.call_deferred()


func _open_editor() -> void:
	var overlay := $LabEvolutionEditor
	if overlay and overlay.has_method("_toggle"):
		overlay._toggle()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			if key.keycode == KEY_ESCAPE:
				get_tree().quit()
