extends Node3D
## A reversible instruction, a readable 4x4 crop, and its larger consequence.
## No per-frame raster work. The chart uses the SAME texture at different sizes.
const Kit = preload("res://commons/artifacts/regularity/room_tools.gd")
const Pattern = preload("res://commons/artifacts/regularity/tiling_pattern.gd")
const INK := Color(0.065, 0.07, 0.075)
const PAPER := Color(0.94, 0.935, 0.90)
const ACCENT := Color(0.62, 0.22, 0.08)
const NAMES := ["TURN EVERY TILE", "ALTERNATE", "QUARTER TURN", "REFLECT", "SHIFT ROWS", "ONE EXCEPTION"]
const RULES := ["turn = source + 1", "if (x + y) % 2 == 1: swap black / white", "turn = source + ((x + y) % 4)", "if x % 2 == 1: mirror the tile", "if y % 2 == 1: shift by half a tile", "if x == 3 and y == 3: turn += 1"]
const VERBS := ["Every tile turns one quarter-turn.", "Neighbours exchange black and white.", "One step across or down adds a quarter-turn.", "Every second column is reflected.", "Every second row moves half a tile left.", "Only address [3, 3] turns once more."]
var study: Node3D
var selected := 2
var applied := false
var cell := Vector2i(1, 0)
var desk: Node3D
var chart: Node3D
var before: MeshInstance3D
var after: MeshInstance3D
var field: MeshInstance3D
var chart_samples: Array[MeshInstance3D] = []
var outlines: Array[MeshInstance3D] = []
var title_label: Label3D
var rule_label: Label3D
var effect_label: Label3D
var cell_label: Label3D
var chart_label: Label3D
var next_button: Node3D
var apply_button: Node3D
var cell_button: Node3D
var chart_button: Node3D
var status: Label
var local_texture: ImageTexture
var field_texture: ImageTexture

func _ready() -> void:
	study = get_parent()
	applied = study.walls
	desk = Node3D.new()
	desk.name = "RuleDesk"
	desk.position = Vector3(-4.4, 0, -11.0)
	desk.rotation_degrees.y = 180
	add_child(desk)
	Kit.box(desk, "ReadingBoard", Vector3(0, 2.0, 0), Vector3(5.8, 2.45, 0.08), PAPER)
	for x in [-2.4, 2.4]: Kit.box(desk, "Leg", Vector3(x, 0.55, -0.05), Vector3(0.06, 1.1, 0.08), INK)
	ink(desk, "ONE TILE / ONE CHANGED INSTRUCTION", Vector3(0, 3.02, 0.066), 0.075)
	before = sample(desk, "Before4x4", Vector2(1.25, 1.25), Vector3(-2.05, 2.13, 0.049))
	after = sample(desk, "After4x4", Vector2(1.25, 1.25), Vector3(-0.55, 2.13, 0.049))
	ink(desk, "BEFORE / repeat", Vector3(-2.05, 2.88, 0.055), 0.066)
	ink(desk, "AFTER / 4 x 4", Vector3(-0.55, 2.88, 0.055), 0.066)
	for at_x in [-2.05, -0.55]:
		for i in range(1, 4):
			stroke(desk, Vector3(at_x-0.625+i*0.3125, 2.13, 0.056), Vector3(0.003, 1.25, 0.003), Color(0.55,0.55,0.55))
			stroke(desk, Vector3(at_x, 1.505+i*0.3125, 0.056), Vector3(1.25, 0.003, 0.003), Color(0.55,0.55,0.55))
		var mark := MeshInstance3D.new()
		mark.mesh = outline_mesh(0.3125)
		mark.material_override = flat(ACCENT)
		desk.add_child(mark)
		outlines.append(mark)
	title_label = ink(desk, "", Vector3(1.5, 2.64, 0.05), 0.095)
	rule_label = ink(desk, "", Vector3(1.5, 2.33, 0.05), 0.070, ACCENT)
	effect_label = ink(desk, "", Vector3(1.5, 2.00, 0.05), 0.070)
	cell_label = ink(desk, "", Vector3(1.5, 1.62, 0.05), 0.070)
	ink(desk, "x: right / y: down    |    0, 1, 2, 3", Vector3(-1.3, 1.33, 0.05), 0.054)
	ink(desk, "A rule at each address. A pattern between them.", Vector3(0, 1.00, 0.05), 0.066)
	var controls := Kit.panel(desk, "CHANGE ONE INSTRUCTION", Vector3(0, 1.05, 0.68), 0)
	controls.spacing = 0.40
	next_button = controls.add_button("NEXT RULE")
	apply_button = controls.add_button("APPLY / UNDO")
	cell_button = controls.add_button("NEXT TILE")
	next_button.pressed.connect(next_rule)
	apply_button.pressed.connect(toggle_rule)
	cell_button.pressed.connect(next_cell)
	status = controls.add_readout("")
	if study.walls:
		build_chart()
	else:
		field = Kit.textured_plane(self, "RuleField16x16", Vector2(4.3, 4.3), Vector3(3.5, 0.03, -11), Vector3(-90, 0, 0), null)
		Kit.label(self, "THE SAME RULE / 16 x 16", Vector3(3.5, 0.38, -13.25), 180).font_size = 27
		var window := MeshInstance3D.new()
		window.name = "FourByFourWindow"
		window.mesh = outline_mesh(4.3 / 4.0)
		window.material_override = flat(ACCENT)
		window.position = Vector3(3.5 - 1.6125, 0.041, -11 - 1.6125)
		window.rotation_degrees.x = -90
		add_child(window)
	study.patterns_changed.connect(refresh)
	refresh()

func build_chart() -> void:
	chart = Node3D.new()
	chart.name = "PatternEyeChart"
	chart.position = Vector3(8.8, 0, -11)
	chart.rotation_degrees.y = -90
	add_child(chart)
	Kit.box(chart, "ChartBacking", Vector3(0, 3.55, 0), Vector3(4.5, 5.5, 0.09), PAPER)
	ink(chart, "HOW FAR CAN YOU READ A RULE?", Vector3(0, 5.97, 0.053), 0.095)
	var sizes := [0.84, 0.60, 0.43, 0.30, 0.21]
	var heights := [5.15, 4.20, 3.46, 2.87, 2.40]
	for row in 5:
		var count := row * 2 + 1
		var edge: float = sizes[row]
		for col in count:
			chart_samples.append(sample(chart, "Pattern_%d_%d" % [row,col], Vector2.ONE * edge, Vector3((col-(count-1)*0.5)*(edge+0.13), heights[row], 0.075)))
		ink(chart, "%d" % (row+1), Vector3(-2.03, heights[row], 0.053), 0.070)
	chart_label = ink(chart, "", Vector3(0, 1.86, 0.055), 0.090)
	ink(chart, "Each mark: the same 4 x 4. Only its size changes.", Vector3(0, 1.57, 0.053), 0.060)
	var controls := Kit.panel(chart, "SAME RULE / DIFFERENT DISTANCE", Vector3(0, 1.03, 0.55), 0)
	chart_button = controls.add_button("NEXT RULE")
	chart_button.pressed.connect(next_applied_rule)
	controls.add_button("APPLY / UNDO").pressed.connect(toggle_rule)

func flat(colour: Color) -> StandardMaterial3D:
	var m := Kit.material(colour)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return m

func ink(parent: Node3D, words: String, at: Vector3, height: float, colour: Color = INK) -> Label3D:
	var label := Kit.label(parent, words, at)
	label.font_size = 48
	label.pixel_size = height / 48.0
	label.outline_size = 0
	label.modulate = colour
	label.no_depth_test = false
	return label

func sample(parent: Node3D, title: String, size_: Vector2, at: Vector3) -> MeshInstance3D:
	var n := Kit.textured_plane(parent, title, size_, at, Vector3.ZERO, null)
	n.material_override.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	return n

func stroke(parent: Node3D, at: Vector3, size_: Vector3, colour: Color) -> void:
	var n := Kit.box(parent, "Guide", at, size_, colour, false)
	n.material_override = flat(colour)

func outline_mesh(edge: float) -> ImmediateMesh:
	var m := ImmediateMesh.new()
	m.surface_begin(Mesh.PRIMITIVE_LINES)
	var corners := [Vector3(-edge/2, edge/2, 0), Vector3(edge/2, edge/2, 0), Vector3(edge/2, -edge/2, 0), Vector3(-edge/2, -edge/2, 0)]
	for i in 4:
		m.surface_add_vertex(corners[i]); m.surface_add_vertex(corners[(i+1)%4])
	m.surface_end()
	return m

func next_rule() -> void:
	selected = (selected + 1) % 6
	refresh()

func next_applied_rule() -> void:
	selected = (selected + 1) % 6
	applied = true
	refresh()

func toggle_rule() -> void:
	applied = not applied
	refresh()

func next_cell() -> void:
	var address := (cell.y * 4 + cell.x + 1) % 16
	cell = Vector2i(address % 4, address / 4)
	refresh_cell()

func result_image(tiles: int) -> Image:
	var rule := selected if applied else 0
	var turn: int = study.phase + (1 if selected == 0 and applied else 0)
	return Pattern.image_for(rule, turn, applied and selected == 5, tiles, tiles)

func refresh() -> void:
	before.material_override.albedo_texture = ImageTexture.create_from_image(Pattern.image_for(0, study.phase, false, 4, 4))
	local_texture = ImageTexture.create_from_image(result_image(4))
	after.material_override.albedo_texture = local_texture
	if field != null:
		field_texture = ImageTexture.create_from_image(result_image(16))
		field.material_override.albedo_texture = field_texture
	for glyph in chart_samples: glyph.material_override.albedo_texture = local_texture
	title_label.text = NAMES[selected]
	rule_label.text = ("ADD: " if applied else "READY: ") + RULES[selected]
	effect_label.text = VERBS[selected] if applied else "No extra instruction yet.\nBoth samples repeat the source tile."
	status.text = "%s | %s" % [NAMES[selected], "APPLIED" if applied else "UNCHANGED"]
	if chart_label != null: chart_label.text = NAMES[selected] + (" / ON" if applied else " / OFF")
	refresh_cell()

func refresh_cell() -> void:
	for i in 2:
		outlines[i].position = Vector3((-2.05 if i == 0 else -0.55)-0.625+(cell.x+0.5)*0.3125, 2.755-(cell.y+0.5)*0.3125, 0.061)
	var detail := "repeat the source tile"
	if applied:
		match selected:
			0: detail = "add 1 quarter-turn"
			1: detail = "swap black / white" if (cell.x+cell.y)%2==1 else "keep black / white"
			2: detail = "(%d + %d) %% 4 = %d quarter-turns" % [cell.x,cell.y,(cell.x+cell.y)%4]
			3: detail = "mirror" if cell.x%2==1 else "do not mirror"
			4: detail = "row slides left by half a tile" if cell.y%2==1 else "row stays in place"
			5: detail = "add 1 quarter-turn" if cell==Vector2i(3,3) else "no exception here"
	cell_label.text = "AT [%d, %d]\n%s" % [cell.x,cell.y,detail]
