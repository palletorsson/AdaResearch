extends Node3D
class_name ModifierGridDemo

# @identity
# essence: a proof of the grid MODIFIER STACK — a plane of cells with a
#          non-destructive op-stack (colorize, random_colors(seed), shift,
#          normalize) applied on top. The bracelet's editing made predictable.
# truth: a modifier is not a thing in a cell; it is an operation over cells, and
#        the ordered stack of operations is the trace of care (the λ-tending log).

const ModifierStack := preload("res://commons/modifiers/modifier_stack.gd")

@export var grid_n: int = 9
@export var apply_modifiers: bool = true

# The op-stack — exactly the `modifiers` section shape from map_data.json.
var _mods: Array = [
	{"op": "colorize", "target": {"region": [3, 3, 5, 5]}, "params": {"color": "#e08a2a"}},
	{"op": "random_colors", "target": {"region": [0, 0, 8, 1]}, "params": {"palette": "cool"}, "seed": 7341},
	{"op": "random_colors", "target": {"region": [0, 7, 8, 8]}, "params": {"palette": "warm"}, "seed": 99},
	{"op": "shift", "target": {"cells": [[4, 4]]}, "params": {"dy": 3}},
]


func _ready() -> void:
	_build()


func apply_grid_config(config: Dictionary) -> void:
	if config.has("grid_n"): grid_n = int(config["grid_n"])
	if config.has("apply_modifiers"): apply_modifiers = bool(config["apply_modifiers"])
	if config.has("modifiers"): _mods = config["modifiers"]
	for c in get_children():
		c.queue_free()
	call_deferred("_build")


func _build() -> void:
	# Base grid: a flat plane of identical grey cells (the "normalized" grid).
	var base: Dictionary = {}
	for r in range(grid_n):
		for c in range(grid_n):
			base[Vector2i(r, c)] = {"height": 1, "color": Color(0.55, 0.56, 0.62)}

	# Apply the stack non-destructively (base is untouched; result is new).
	var result: Dictionary = ModifierStack.apply(base, _mods) if apply_modifiers else base

	var off: float = -float(grid_n - 1) * 0.5
	for k in result.keys():
		var cell: Dictionary = result[k]
		var h: int = int(cell["height"])
		var col: Color = cell["color"]
		var mi := MeshInstance3D.new()
		var bm := BoxMesh.new()
		bm.size = Vector3(0.92, 0.18 * float(h), 0.92)
		mi.mesh = bm
		mi.position = Vector3(off + float(k.y), 0.09 * float(h), off + float(k.x))
		var m := StandardMaterial3D.new()
		m.albedo_color = col
		m.emission_enabled = true
		m.emission = col
		m.emission_energy_multiplier = 0.35
		m.roughness = 0.6
		mi.material_override = m
		add_child(mi)

	var label := Label3D.new()
	label.text = "MODIFIER STACK\ncolorize · random(seed) · shift · normalize"
	label.font_size = 40
	label.pixel_size = 0.004
	label.position = Vector3(0, 2.0, off - 0.5)
	label.modulate = Color(0.95, 0.95, 0.98)
	label.outline_size = 6
	label.outline_modulate = Color(0, 0, 0, 0.7)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
