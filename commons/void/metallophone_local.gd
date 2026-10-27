extends "res://algorithms/wavefunctions/resonance/ResonatingMetallophone.gd"
## Jolt cannot immobilize a dynamic body by locking all six axes. The source
## strike Area3D still detects the held tip when its table-mounted bar is frozen.
func _create_bars() -> void:
	if stand != "table":
		super._create_bars()
		return
	var scale_hz: Array = _tuned_scale()
	var root_hz: float = float(scale_hz[0])
	_bar_container = Node3D.new()
	_bar_container.name = "Bars"
	_bar_container.position.y = _lift
	add_child(_bar_container)
	for i in scale_hz.size():
		var bar = _create_single_bar(i, scale_hz, root_hz)
		bar.freeze = true
		bar.position = Vector3((i - scale_hz.size() * 0.5) * bar_spacing, 0, 0)
		bars.append(bar)
		_bar_container.add_child(bar)
