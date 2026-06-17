extends "res://commons/artifacts/_embodied/embodied_prop.gd"
class_name TenPrintToy
## @identity
## lineage: 10 PRINT CHR$(205.5+RND(1)); : GOTO 10 — Commodore 64, one line
## essence: a coin flip per cell becomes a maze you can read but never planned
## truth: chance, repeated, draws a wall that was always there to find

@export var cells: int = 10
@export var panel: float = 0.4

var _grid: Node3D
var _bars: Array = []
var _step := 0.0

func _ready() -> void:
	_rng.randomize(); _build(); set_process(not Engine.is_editor_hint())

func apply_grid_config(config: Dictionary) -> void:
	if config.has("emissive"): emissive = bool(config["emissive"])
	for c in get_children(): remove_child(c); c.queue_free()
	_build()

func _build() -> void:
	_bars.clear()
	var frame := _matte_mat(Color(0.08, 0.09, 0.12), 0.7)
	add_child(_box(Vector3(0, panel * 0.5, -0.01), Vector3(panel + 0.04, panel + 0.04, 0.02), frame))
	_grid = Node3D.new()
	add_child(_grid)
	# Full maze already drawn: a diagonal per cell by coin flip.
	for r in range(cells):
		var row: Array = []
		for c in range(cells):
			row.append(_make_cell(r, c))
		_bars.append(row)

func _make_cell(r: int, c: int) -> MeshInstance3D:
	var step := panel / float(cells)
	var cx := -panel * 0.5 + (float(c) + 0.5) * step
	var cy := panel - (float(r) + 0.5) * step + step * 0.5
	var slash := _rng.randf() < 0.5
	var hue := 0.45 + _rng.randf() * 0.18
	var mat := _glow_mat(Color.from_hsv(hue, 0.5, 1.0), 2.4)
	var bar := _box(Vector3(cx, cy, 0.01), Vector3(step * 0.82, step * 0.14, 0.02), mat)
	bar.rotation.z = (PI * 0.25) if slash else (-PI * 0.25)
	_grid.add_child(bar)
	return bar

func _process(delta: float) -> void:
	if Engine.is_editor_hint(): return
	_grid.rotation.y = sin(Time.get_ticks_msec() * 0.0004) * 0.12
	_step += delta
	if _step < 0.45: return
	_step = 0.0
	# Scroll the maze: shift every row up one, regenerate fresh bottom row.
	var step := panel / float(cells)
	for r in range(cells):
		for c in range(cells):
			var bar: MeshInstance3D = _bars[r][c]
			bar.position.y += step
	# Top row scrolled off -> recycle it as new bottom row.
	var top_row: Array = _bars.pop_front()
	for c in range(cells):
		var bar: MeshInstance3D = top_row[c]
		var cx := -panel * 0.5 + (float(c) + 0.5) * step
		bar.position = Vector3(cx, -panel * 0.5 + step * 0.5 + step * 0.5, 0.01)
		bar.rotation.z = (PI * 0.25) if _rng.randf() < 0.5 else (-PI * 0.25)
	_bars.append(top_row)
