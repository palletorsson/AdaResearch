extends Node3D
## A console for the existing room floor, not a second procedural substrate.
const Controls = preload("res://commons/ui/control_panel.gd")
const PALETTES := ["stonewall_freedom", "starry_night", "mondrian_grid"]
const INKS := [Color("ff35ac"), Color("22e3cc"), Color("ffe66d"), Color.WHITE]
var colorizer: Node
var cells: Dictionary = {}
var selected := Vector2i(10, 10)
var palette_index := 0
var ink_index := 0
var ready_for_input := false
var marker: Node3D
var swatch: MeshInstance3D
var readout: Label
var buttons: Array[Node3D] = []

func _ready() -> void:
	# The original map may finish its grid asynchronously after this artifact.
	for frame in range(3600):
		if colorizer.find_multimesh() and colorizer.grid_structure != null:
			if colorizer.grid_structure.cube_positions.size() == colorizer.multimesh.instance_count and colorizer.multimesh.instance_count > 0:
				break
		await get_tree().process_frame
	if colorizer.grid_structure == null or colorizer.multimesh == null:
		push_error("Grid address lesson could not find its room floor")
		return
	for i in range(colorizer.grid_structure.cube_positions.size()):
		var xyz: Vector3i = colorizer.grid_structure.cube_positions[i]
		if xyz.y == 0 and xyz.x > 0 and xyz.x < 18 and xyz.z > 0 and xyz.z < 20:
			cells[Vector2i(xyz.x, xyz.z)] = i
	_build_console()
	ready_for_input = true
	apply_rule()

func _box(label: String, at: Vector3, size: Vector3, colour: Color, solid := false) -> MeshInstance3D:
	var n := MeshInstance3D.new()
	n.name = label
	var mesh := BoxMesh.new()
	mesh.size = size
	n.mesh = mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	n.material_override = mat
	n.position = at
	add_child(n)
	if solid: n.create_convex_collision()
	return n

func _build_console() -> void:
	_box("AddressPlinth", Vector3(7.2, 0.45, 15), Vector3(2.65, 0.9, 0.6), Color("dbcacb"), true)
	_box("ConsoleSupport", Vector3(7, 0.99, 14.82), Vector3(0.35, 0.2, 0.14), Color("a79799"))
	var panel := Controls.new()
	panel.name = "AddressConsole"
	panel.title = "FIND THE COLOUR AGAIN"
	panel.position = Vector3(7, 1.15, 15)
	add_child(panel)
	for label in ["X +", "Z +", "COLOUR", "RULE", "PALETTE"]:
		buttons.append(panel.add_button(label))
	readout = panel.add_readout("")
	buttons[0].pressed.connect(func(): step_address(Vector2i.RIGHT))
	buttons[1].pressed.connect(func(): step_address(Vector2i(0, 1)))
	buttons[2].pressed.connect(paint_selected)
	buttons[3].pressed.connect(apply_rule)
	buttons[4].pressed.connect(next_palette)
	_box("SwatchCase", Vector3(8.15, 1.04, 14.98), Vector3(0.29, 0.28, 0.15), Color("a79799"))
	swatch = _box("StoredColour", Vector3(8.15, 1.04, 15.06), Vector3(0.22, 0.22, 0.025), Color.WHITE)
	marker = Node3D.new()
	marker.name = "SelectedCellOutline"
	add_child(marker)
	for edge in [Vector3(-0.47, 0, 0), Vector3(0.47, 0, 0), Vector3(0, 0, -0.47), Vector3(0, 0, 0.47)]:
		var n := _box("SelectionEdge", edge, Vector3(0.025, 0.018, 0.94) if edge.x != 0 else Vector3(0.94, 0.018, 0.025), Color.WHITE)
		n.reparent(marker, false)
		n.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED

func step_address(direction: Vector2i) -> void:
	if not ready_for_input: return
	selected = Vector2i(8 + posmod(selected.x - 8 + direction.x, 5), 8 + posmod(selected.y - 8 + direction.y, 5))
	_refresh()

func paint_selected() -> void:
	if not ready_for_input or not cells.has(selected): return
	colorizer.multimesh.set_instance_color(cells[selected], INKS[ink_index])
	ink_index = (ink_index + 1) % INKS.size()
	_refresh()

func apply_rule() -> void:
	if not ready_for_input: return
	var palette: Array = colorizer._get_palette_colors(PALETTES[palette_index])
	if palette.is_empty(): return
	for address: Vector2i in cells:
		var colour_index: int = (address.x + address.y) % palette.size()
		colorizer.multimesh.set_instance_color(cells[address], palette[colour_index])
	colorizer._adjust_material_for_colors()
	_refresh()

func next_palette() -> void:
	palette_index = (palette_index + 1) % PALETTES.size()
	apply_rule()

func _refresh() -> void:
	if not cells.has(selected): return
	var i: int = cells[selected]
	var colour: Color = colorizer.multimesh.get_instance_color(i)
	readout.text = "(%d,%d)  #%s" % [selected.x, selected.y, colour.to_html(false)]
	swatch.material_override.albedo_color = colour
	var cell_transform: Transform3D = colorizer.multimesh.get_instance_transform(i)
	marker.global_position = colorizer.multimesh_instance.to_global(cell_transform.origin + Vector3(0, 0.515, 0))
