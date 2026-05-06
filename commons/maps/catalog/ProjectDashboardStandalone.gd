extends Node

## Standalone launcher for the Project Dashboard.
## Run project_dashboard_standalone.tscn directly — the dashboard opens automatically.
## Press P to toggle, ESC to quit.

func _ready() -> void:
	# Dark background so the dashboard feels like its own app
	RenderingServer.set_default_clear_color(Color(0.02, 0.03, 0.05, 1.0))

	# Auto-open the dashboard after one frame (let overlay _ready() finish first)
	_open_dashboard.call_deferred()


func _open_dashboard() -> void:
	var overlay := $ProjectDashboardOverlay
	if overlay and overlay.has_method("_toggle"):
		overlay._toggle()


func _input(event: InputEvent) -> void:
	if event is InputEventKey:
		var key := event as InputEventKey
		if key.pressed and not key.echo:
			if key.keycode == KEY_ESCAPE:
				get_tree().quit()
