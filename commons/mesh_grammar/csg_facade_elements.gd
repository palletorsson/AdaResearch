class_name CsgFacadeElements
extends RefCounted

## CSG-based facade element generators for real-time 3D preview.
## Each static method creates a Node3D containing CSG node trees
## for a specific architectural element type.
##
## Complements the MeshData-based FacadeElementLibrary: CSG is used
## for interactive editing (FacadePlanImporter), while MeshData is
## used for the procedural grammar pipeline.


# ─── COLUMNS ───────────────────────────────────────────────────────────────

## Generate a classical column with shaft, base, and capital.
## params: taper, flutes, capital_style ("simple", "volute", "acanthus")
static func column(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "Column"

	var taper: float = params.get("taper", 0.85)
	var flutes: int = params.get("flutes", 0)
	var capital_style: String = params.get("capital_style", "simple")
	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))

	var radius := cell_width * 0.2
	var shaft_height := cell_height * 0.75
	var base_height := cell_height * 0.1
	var capital_height := cell_height * 0.15

	# Material
	var mat := FacadeMaterials.stone_material(color)

	# --- Base (torus-like stepped base) ---
	var base_node := CSGBox3D.new()
	base_node.name = "Base"
	base_node.size = Vector3(radius * 2.4, base_height, radius * 2.4)
	base_node.position.y = base_height * 0.5
	base_node.material = mat
	root.add_child(base_node)

	var base_step := CSGBox3D.new()
	base_step.name = "BaseStep"
	base_step.size = Vector3(radius * 2.8, base_height * 0.3, radius * 2.8)
	base_step.position.y = base_height * 0.15
	base_step.material = mat
	root.add_child(base_step)

	# --- Shaft ---
	var shaft := CSGCylinder3D.new()
	shaft.name = "Shaft"
	shaft.radius = radius
	shaft.height = shaft_height
	shaft.sides = 24
	shaft.cone = true  # Enables taper
	# CSGCylinder3D cone mode tapers to a point; we need to simulate taper
	# by using two stacked cylinders or adjusting manually.
	# Actually in Godot 4, CSGCylinder3D doesn't have a taper property directly.
	# We'll use a full cylinder and note that proper entasis needs CSGPolygon3D.
	shaft.cone = false
	shaft.radius = radius
	shaft.height = shaft_height
	shaft.position.y = base_height + shaft_height * 0.5
	shaft.material = mat
	root.add_child(shaft)

	# --- Fluting (subtraction cylinders around the shaft) ---
	if flutes > 0:
		var flute_combiner := CSGCombiner3D.new()
		flute_combiner.name = "FluteCombiner"
		flute_combiner.operation = CSGShape3D.OPERATION_SUBTRACTION
		flute_combiner.position = shaft.position
		root.add_child(flute_combiner)

		# Add the shaft shape inside the combiner for boolean context
		var shaft_copy := CSGCylinder3D.new()
		shaft_copy.name = "ShaftBody"
		shaft_copy.radius = radius
		shaft_copy.height = shaft_height
		shaft_copy.sides = 24
		shaft_copy.operation = CSGShape3D.OPERATION_UNION
		shaft_copy.material = mat
		flute_combiner.add_child(shaft_copy)

		var flute_radius := radius * 0.12
		var flute_depth := radius * 0.08
		for i in range(flutes):
			var angle := TAU * float(i) / float(flutes)
			var flute_cyl := CSGCylinder3D.new()
			flute_cyl.name = "Flute_%d" % i
			flute_cyl.radius = flute_radius
			flute_cyl.height = shaft_height * 0.95
			flute_cyl.sides = 6
			flute_cyl.operation = CSGShape3D.OPERATION_SUBTRACTION
			var fx := cos(angle) * (radius - flute_depth)
			var fz := sin(angle) * (radius - flute_depth)
			flute_cyl.position = Vector3(fx, 0, fz)
			flute_combiner.add_child(flute_cyl)

		# Remove the separate shaft since the combiner has its own
		root.remove_child(shaft)
		shaft.queue_free()

	# --- Capital ---
	var capital_y := base_height + shaft_height

	# Echinus (curved part)
	var echinus := CSGCylinder3D.new()
	echinus.name = "Echinus"
	echinus.radius = radius * 1.3
	echinus.height = capital_height * 0.6
	echinus.sides = 24
	echinus.position.y = capital_y + capital_height * 0.3
	echinus.material = mat
	root.add_child(echinus)

	# Abacus (flat slab on top)
	var abacus := CSGBox3D.new()
	abacus.name = "Abacus"
	abacus.size = Vector3(radius * 2.8, capital_height * 0.4, radius * 2.8)
	abacus.position.y = capital_y + capital_height * 0.8
	abacus.material = mat
	root.add_child(abacus)

	# Volutes for Ionic
	if capital_style == "volute":
		for side in [-1, 1]:
			var volute := CSGCylinder3D.new()
			volute.name = "Volute_%s" % ("L" if side < 0 else "R")
			volute.radius = radius * 0.4
			volute.height = radius * 0.3
			volute.sides = 16
			volute.rotation_degrees.x = 90
			volute.position = Vector3(float(side) * radius * 1.1, capital_y + capital_height * 0.3, 0)
			volute.material = mat
			root.add_child(volute)

	# Acanthus decoration for Corinthian (simplified as extra cylinders)
	if capital_style == "acanthus":
		for ring in range(2):
			var ring_y := capital_y + capital_height * (0.15 + float(ring) * 0.25)
			for i in range(8):
				var angle := TAU * float(i) / 8.0 + float(ring) * TAU / 16.0
				var leaf := CSGCylinder3D.new()
				leaf.name = "Leaf_%d_%d" % [ring, i]
				leaf.radius = radius * 0.18
				leaf.height = capital_height * 0.25
				leaf.sides = 6
				leaf.position = Vector3(
					cos(angle) * radius * 0.9,
					ring_y,
					sin(angle) * radius * 0.9
				)
				leaf.material = mat
				root.add_child(leaf)

	return root


## Tuscan column: simple, no fluting, strong taper.
static func col_tuscan(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var p := params.duplicate()
	p["taper"] = 0.8
	p["flutes"] = 0
	p["capital_style"] = "simple"
	var node := column(cell_width, cell_height, p)
	node.name = "ColTuscan"
	return node


## Doric column: 20 flutes, moderate taper.
static func col_doric(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var p := params.duplicate()
	p["taper"] = 0.83
	p["flutes"] = 20
	p["capital_style"] = "simple"
	var node := column(cell_width, cell_height, p)
	node.name = "ColDoric"
	return node


## Ionic column: 24 flutes, volute capital.
static func col_ionic(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var p := params.duplicate()
	p["taper"] = 0.85
	p["flutes"] = 24
	p["capital_style"] = "volute"
	var node := column(cell_width, cell_height, p)
	node.name = "ColIonic"
	return node


## Corinthian column: 24 flutes, acanthus capital.
static func col_corinthian(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var p := params.duplicate()
	p["taper"] = 0.87
	p["flutes"] = 24
	p["capital_style"] = "acanthus"
	var node := column(cell_width, cell_height, p)
	node.name = "ColCorinthian"
	return node


## Pilaster: flat column projecting slightly from the wall.
static func pilaster(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "Pilaster"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)

	var depth := cell_width * 0.08
	var width := cell_width * 0.35
	var base_h := cell_height * 0.1
	var shaft_h := cell_height * 0.75
	var cap_h := cell_height * 0.15

	# Base
	var base_box := CSGBox3D.new()
	base_box.name = "PilasterBase"
	base_box.size = Vector3(width * 1.3, base_h, depth * 1.5)
	base_box.position = Vector3(0, base_h * 0.5, depth * 0.75)
	base_box.material = mat
	root.add_child(base_box)

	# Shaft
	var shaft := CSGBox3D.new()
	shaft.name = "PilasterShaft"
	shaft.size = Vector3(width, shaft_h, depth)
	shaft.position = Vector3(0, base_h + shaft_h * 0.5, depth * 0.5)
	shaft.material = mat
	root.add_child(shaft)

	# Capital
	var cap := CSGBox3D.new()
	cap.name = "PilasterCapital"
	cap.size = Vector3(width * 1.3, cap_h, depth * 1.5)
	cap.position = Vector3(0, base_h + shaft_h + cap_h * 0.5, depth * 0.75)
	cap.material = mat
	root.add_child(cap)

	return root


# ─── OPENINGS ──────────────────────────────────────────────────────────────

## Rectangular window: wall void with frame surround.
static func rect_window(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "RectWindow"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)
	var glass_mat := FacadeMaterials.glass_material()

	var frame_width := cell_width * 0.08
	var void_w := cell_width * 0.6
	var void_h := cell_height * 0.7
	var wall_depth := params.get("wall_depth", 0.3) as float

	# Window void (subtraction from wall — placed as a visual marker)
	var void_box := CSGBox3D.new()
	void_box.name = "WindowVoid"
	void_box.size = Vector3(void_w, void_h, wall_depth * 1.2)
	void_box.position = Vector3(0, cell_height * 0.55, 0)
	void_box.operation = CSGShape3D.OPERATION_SUBTRACTION
	void_box.material = glass_mat
	root.add_child(void_box)

	# Glass pane
	var glass := CSGBox3D.new()
	glass.name = "Glass"
	glass.size = Vector3(void_w - 0.02, void_h - 0.02, 0.02)
	glass.position = Vector3(0, cell_height * 0.55, 0)
	glass.material = glass_mat
	root.add_child(glass)

	# Frame — 4 strips
	_add_frame_strips(root, void_w, void_h, frame_width, wall_depth * 0.15,
		Vector3(0, cell_height * 0.55, wall_depth * 0.5), mat)

	# Sill
	var sill := CSGBox3D.new()
	sill.name = "Sill"
	sill.size = Vector3(void_w + frame_width * 2, frame_width * 0.6, wall_depth * 0.3)
	sill.position = Vector3(0, cell_height * 0.55 - void_h * 0.5 - frame_width * 0.3, wall_depth * 0.35)
	sill.material = mat
	root.add_child(sill)

	return root


## Arched window: semicircular top with frame.
static func arched_window(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "ArchedWindow"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)
	var glass_mat := FacadeMaterials.glass_material()

	var void_w := cell_width * 0.55
	var void_h := cell_height * 0.6
	var wall_depth := params.get("wall_depth", 0.3) as float
	var frame_width := cell_width * 0.07
	var arch_radius := void_w * 0.5

	# Rectangular void part
	var rect_void := CSGBox3D.new()
	rect_void.name = "RectVoid"
	rect_void.size = Vector3(void_w, void_h, wall_depth * 1.2)
	rect_void.position = Vector3(0, cell_height * 0.4, 0)
	rect_void.operation = CSGShape3D.OPERATION_SUBTRACTION
	root.add_child(rect_void)

	# Arch void (half cylinder at top)
	var arch_void := CSGCylinder3D.new()
	arch_void.name = "ArchVoid"
	arch_void.radius = arch_radius
	arch_void.height = wall_depth * 1.2
	arch_void.sides = 16
	arch_void.rotation_degrees.x = 90
	arch_void.position = Vector3(0, cell_height * 0.4 + void_h * 0.5, 0)
	arch_void.operation = CSGShape3D.OPERATION_SUBTRACTION
	root.add_child(arch_void)

	# Glass pane
	var glass := CSGBox3D.new()
	glass.name = "Glass"
	glass.size = Vector3(void_w - 0.02, void_h - 0.02, 0.02)
	glass.position = Vector3(0, cell_height * 0.4, 0)
	glass.material = glass_mat
	root.add_child(glass)

	# Archivolt (arch frame)
	var archivolt := CSGCylinder3D.new()
	archivolt.name = "Archivolt"
	archivolt.radius = arch_radius + frame_width
	archivolt.height = frame_width * 1.5
	archivolt.sides = 16
	archivolt.rotation_degrees.x = 90
	archivolt.position = Vector3(0, cell_height * 0.4 + void_h * 0.5, wall_depth * 0.5)
	archivolt.material = mat
	root.add_child(archivolt)

	# Frame strips (sides and bottom)
	_add_frame_strips(root, void_w, void_h, frame_width, wall_depth * 0.15,
		Vector3(0, cell_height * 0.4, wall_depth * 0.5), mat)

	return root


## Door: rectangular opening with paneled door insert.
static func door(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "Door"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)
	var wood_mat := FacadeMaterials.wood_material()

	var door_w := cell_width * 0.55
	var door_h := cell_height * 0.85
	var wall_depth := params.get("wall_depth", 0.3) as float
	var frame_width := cell_width * 0.1

	# Door void
	var void_box := CSGBox3D.new()
	void_box.name = "DoorVoid"
	void_box.size = Vector3(door_w, door_h, wall_depth * 1.2)
	void_box.position = Vector3(0, door_h * 0.5, 0)
	void_box.operation = CSGShape3D.OPERATION_SUBTRACTION
	root.add_child(void_box)

	# Door panel (wood)
	var panel := CSGBox3D.new()
	panel.name = "DoorPanel"
	panel.size = Vector3(door_w - 0.04, door_h - 0.02, 0.06)
	panel.position = Vector3(0, door_h * 0.5, -0.02)
	panel.material = wood_mat
	root.add_child(panel)

	# Frame
	_add_frame_strips(root, door_w, door_h, frame_width, wall_depth * 0.15,
		Vector3(0, door_h * 0.5, wall_depth * 0.5), mat)

	# Threshold
	var threshold := CSGBox3D.new()
	threshold.name = "Threshold"
	threshold.size = Vector3(door_w + frame_width * 2, 0.05, wall_depth * 0.4)
	threshold.position = Vector3(0, 0.025, wall_depth * 0.2)
	threshold.material = mat
	root.add_child(threshold)

	return root


## Arcade arch: full arch with supporting piers.
static func arcade_arch(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "ArcadeArch"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)

	var pier_w := cell_width * 0.15
	var arch_span := cell_width - pier_w * 2
	var arch_radius := arch_span * 0.5
	var pier_h := cell_height - arch_radius
	var depth := cell_width * 0.2

	# Left pier
	var left_pier := CSGBox3D.new()
	left_pier.name = "LeftPier"
	left_pier.size = Vector3(pier_w, pier_h, depth)
	left_pier.position = Vector3(-cell_width * 0.5 + pier_w * 0.5, pier_h * 0.5, depth * 0.5)
	left_pier.material = mat
	root.add_child(left_pier)

	# Right pier
	var right_pier := CSGBox3D.new()
	right_pier.name = "RightPier"
	right_pier.size = Vector3(pier_w, pier_h, depth)
	right_pier.position = Vector3(cell_width * 0.5 - pier_w * 0.5, pier_h * 0.5, depth * 0.5)
	right_pier.material = mat
	root.add_child(right_pier)

	# Arch (cylinder that we'll use as the archivolt)
	var arch := CSGCylinder3D.new()
	arch.name = "Arch"
	arch.radius = arch_radius + pier_w * 0.5
	arch.height = depth
	arch.sides = 24
	arch.rotation_degrees.x = 90
	arch.position = Vector3(0, pier_h, depth * 0.5)
	arch.material = mat
	root.add_child(arch)

	# Arch void (to hollow it out)
	var arch_void := CSGCylinder3D.new()
	arch_void.name = "ArchVoid"
	arch_void.radius = arch_radius
	arch_void.height = depth * 1.2
	arch_void.sides = 24
	arch_void.rotation_degrees.x = 90
	arch_void.position = Vector3(0, pier_h, depth * 0.5)
	arch_void.operation = CSGShape3D.OPERATION_SUBTRACTION
	root.add_child(arch_void)

	return root


# ─── BANDS & CORNICES ──────────────────────────────────────────────────────

## Dentil course: repeated small tooth-like blocks.
static func dentil(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "Dentil"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)

	var tooth_count: int = maxi(int(cell_width / (cell_height * 0.4)), 4)
	var tooth_w := cell_width / float(tooth_count) * 0.6
	var tooth_h := cell_height * 0.6
	var tooth_d := cell_height * 0.4
	var spacing := cell_width / float(tooth_count)

	# Base band
	var band := CSGBox3D.new()
	band.name = "DentilBand"
	band.size = Vector3(cell_width, cell_height * 0.3, tooth_d * 0.5)
	band.position = Vector3(0, cell_height * 0.15, tooth_d * 0.25)
	band.material = mat
	root.add_child(band)

	# Individual teeth
	for i in range(tooth_count):
		var tooth := CSGBox3D.new()
		tooth.name = "Tooth_%d" % i
		tooth.size = Vector3(tooth_w, tooth_h, tooth_d)
		var x := -cell_width * 0.5 + spacing * 0.5 + float(i) * spacing
		tooth.position = Vector3(x, cell_height * 0.3 + tooth_h * 0.5, tooth_d * 0.5)
		tooth.material = mat
		root.add_child(tooth)

	return root


## Cyma recta molding: S-curved cornice profile (approximated with stacked boxes).
static func cyma_recta(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "CymaRecta"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)

	var depth := cell_height * 0.5
	var layers := 5
	var layer_h := cell_height / float(layers)

	for i in range(layers):
		var t := float(i) / float(layers - 1)
		# S-curve profile: sin gives the outward projection
		var proj := sin(t * PI) * depth
		var layer := CSGBox3D.new()
		layer.name = "Layer_%d" % i
		layer.size = Vector3(cell_width, layer_h * 0.95, maxf(proj, depth * 0.15))
		layer.position = Vector3(0, float(i) * layer_h + layer_h * 0.5, layer.size.z * 0.5)
		layer.material = mat
		root.add_child(layer)

	return root


## String course: thin horizontal dividing band.
static func string_course(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "StringCourse"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)

	var band_depth := cell_height * 0.3

	var band := CSGBox3D.new()
	band.name = "Band"
	band.size = Vector3(cell_width, cell_height * 0.7, band_depth)
	band.position = Vector3(0, cell_height * 0.5, band_depth * 0.5)
	band.material = mat
	root.add_child(band)

	return root


## Fascia: flat horizontal band (simpler than string course).
static func fascia(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "Fascia"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)

	var band := CSGBox3D.new()
	band.name = "FasciaBand"
	band.size = Vector3(cell_width, cell_height * 0.8, cell_height * 0.15)
	band.position = Vector3(0, cell_height * 0.5, cell_height * 0.075)
	band.material = mat
	root.add_child(band)

	return root


# ─── SURFACE TREATMENTS ───────────────────────────────────────────────────

## Rusticated blocks: grid of offset stone blocks.
static func rusticated_block(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "RusticatedBlock"

	var color: Color = _parse_color(params.get("color", ""), Color(0.75, 0.7, 0.62))
	var mat := FacadeMaterials.stone_material(color, 0.92)

	var cols: int = params.get("block_cols", 2) as int
	var rows: int = params.get("block_rows", 3) as int
	var gap := 0.02
	var max_offset := 0.04

	var block_w := (cell_width - gap * float(cols + 1)) / float(cols)
	var block_h := (cell_height - gap * float(rows + 1)) / float(rows)
	var block_d := cell_height * 0.12

	# Use a deterministic seed based on params for consistent look
	var rng := RandomNumberGenerator.new()
	rng.seed = hash(str(params.get("col", 0)) + str(params.get("row", 0)))

	for r in range(rows):
		for c in range(cols):
			var offset := rng.randf_range(-max_offset, max_offset)
			var depth_var := rng.randf_range(0.8, 1.0) * block_d

			var block := CSGBox3D.new()
			block.name = "Block_%d_%d" % [r, c]
			block.size = Vector3(block_w - 0.005, block_h - 0.005, depth_var)

			var x := -cell_width * 0.5 + gap + block_w * 0.5 + float(c) * (block_w + gap)
			var y := gap + block_h * 0.5 + float(r) * (block_h + gap)
			block.position = Vector3(x + offset, y, depth_var * 0.5)
			block.material = mat
			root.add_child(block)

	return root


## Balustrade: repeated balusters with top rail and bottom rail.
static func balustrade(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "Balustrade"

	var color: Color = _parse_color(params.get("color", ""), Color(0.85, 0.8, 0.72))
	var mat := FacadeMaterials.stone_material(color)

	var count: int = maxi(params.get("baluster_count", 6) as int, 2)
	var rail_h := cell_height * 0.1
	var baluster_h := cell_height - rail_h * 2
	var baluster_r := cell_width / float(count) * 0.2
	var spacing := cell_width / float(count)
	var depth := cell_width * 0.08

	# Bottom rail
	var bottom_rail := CSGBox3D.new()
	bottom_rail.name = "BottomRail"
	bottom_rail.size = Vector3(cell_width, rail_h, depth)
	bottom_rail.position = Vector3(0, rail_h * 0.5, depth * 0.5)
	bottom_rail.material = mat
	root.add_child(bottom_rail)

	# Top rail
	var top_rail := CSGBox3D.new()
	top_rail.name = "TopRail"
	top_rail.size = Vector3(cell_width, rail_h, depth * 1.2)
	top_rail.position = Vector3(0, cell_height - rail_h * 0.5, depth * 0.6)
	top_rail.material = mat
	root.add_child(top_rail)

	# Balusters
	for i in range(count):
		var bal := CSGCylinder3D.new()
		bal.name = "Baluster_%d" % i
		bal.radius = baluster_r
		bal.height = baluster_h
		bal.sides = 8
		var x := -cell_width * 0.5 + spacing * 0.5 + float(i) * spacing
		bal.position = Vector3(x, rail_h + baluster_h * 0.5, depth * 0.5)
		bal.material = mat
		root.add_child(bal)

	return root


## Plain wall: no additional geometry (wall shows through).
static func plain_wall(_cell_width: float, _cell_height: float, _params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "PlainWall"
	# No geometry — the base wall is visible
	return root


# ─── CROWNING ELEMENTS ─────────────────────────────────────────────────────

## Triangular pediment: classical gable.
static func triangular_pediment(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "TriangularPediment"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)

	var depth := cell_height * 0.3
	var peak_h := cell_height * 0.7

	# Use CSGPolygon3D for the triangular cross-section
	var polygon := CSGPolygon3D.new()
	polygon.name = "PedimentShape"
	var pts := PackedVector2Array([
		Vector2(-cell_width * 0.5, 0),
		Vector2(0, peak_h),
		Vector2(cell_width * 0.5, 0),
	])
	polygon.polygon = pts
	polygon.depth = depth
	polygon.position = Vector3(0, cell_height * 0.1, 0)
	polygon.material = mat
	root.add_child(polygon)

	# Cornice band at the base of the pediment
	var cornice := CSGBox3D.new()
	cornice.name = "PedimentCornice"
	cornice.size = Vector3(cell_width * 1.05, cell_height * 0.12, depth * 1.1)
	cornice.position = Vector3(0, cell_height * 0.06, depth * 0.5)
	cornice.material = mat
	root.add_child(cornice)

	return root


## Broken pediment: pediment with center gap and optional finial.
static func broken_pediment(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "BrokenPediment"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)

	var depth := cell_height * 0.3
	var peak_h := cell_height * 0.65
	var gap_w := cell_width * 0.25

	# Left ramp
	var left_poly := CSGPolygon3D.new()
	left_poly.name = "LeftRamp"
	var left_pts := PackedVector2Array([
		Vector2(-cell_width * 0.5, 0),
		Vector2(-gap_w * 0.5, peak_h * 0.8),
		Vector2(-gap_w * 0.5, 0),
	])
	left_poly.polygon = left_pts
	left_poly.depth = depth
	left_poly.position = Vector3(0, cell_height * 0.1, 0)
	left_poly.material = mat
	root.add_child(left_poly)

	# Right ramp
	var right_poly := CSGPolygon3D.new()
	right_poly.name = "RightRamp"
	var right_pts := PackedVector2Array([
		Vector2(gap_w * 0.5, 0),
		Vector2(gap_w * 0.5, peak_h * 0.8),
		Vector2(cell_width * 0.5, 0),
	])
	right_poly.polygon = right_pts
	right_poly.depth = depth
	right_poly.position = Vector3(0, cell_height * 0.1, 0)
	right_poly.material = mat
	root.add_child(right_poly)

	# Center finial (decorative sphere/urn)
	var finial := CSGCylinder3D.new()
	finial.name = "Finial"
	finial.radius = gap_w * 0.3
	finial.height = peak_h * 0.4
	finial.sides = 12
	finial.position = Vector3(0, cell_height * 0.1 + peak_h * 0.9, depth * 0.5)
	finial.material = mat
	root.add_child(finial)

	# Base cornice band
	var cornice := CSGBox3D.new()
	cornice.name = "PedimentCornice"
	cornice.size = Vector3(cell_width * 1.05, cell_height * 0.12, depth * 1.1)
	cornice.position = Vector3(0, cell_height * 0.06, depth * 0.5)
	cornice.material = mat
	root.add_child(cornice)

	return root


# ─── ZONE MARKERS ──────────────────────────────────────────────────────────

## Plinth: stepped base at the bottom of the facade.
static func plinth_element(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "Plinth"

	var color: Color = _parse_color(params.get("color", ""), Color(0.7, 0.65, 0.58))
	var mat := FacadeMaterials.stone_material(color, 0.9)

	var steps := 3
	var step_h := cell_height / float(steps)
	var max_depth := cell_height * 0.4

	for i in range(steps):
		var t := 1.0 - float(i) / float(steps)
		var step := CSGBox3D.new()
		step.name = "Step_%d" % i
		step.size = Vector3(cell_width, step_h * 0.9, max_depth * t)
		step.position = Vector3(0, float(i) * step_h + step_h * 0.5, step.size.z * 0.5)
		step.material = mat
		root.add_child(step)

	return root


## Piano nobile zone marker: taller proportions signifier (decorative band).
static func piano_nobile(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "PianoNobile"

	var color: Color = _parse_color(params.get("color", ""), Color(0.85, 0.8, 0.72))
	var mat := FacadeMaterials.stone_material(color)

	# Subtle projecting band at top and bottom of zone
	var band_h := cell_height * 0.06
	var band_d := cell_height * 0.08

	var top_band := CSGBox3D.new()
	top_band.name = "TopBand"
	top_band.size = Vector3(cell_width, band_h, band_d)
	top_band.position = Vector3(0, cell_height - band_h * 0.5, band_d * 0.5)
	top_band.material = mat
	root.add_child(top_band)

	var bottom_band := CSGBox3D.new()
	bottom_band.name = "BottomBand"
	bottom_band.size = Vector3(cell_width, band_h, band_d)
	bottom_band.position = Vector3(0, band_h * 0.5, band_d * 0.5)
	bottom_band.material = mat
	root.add_child(bottom_band)

	return root


## Entablature: tripartite horizontal band (architrave + frieze + cornice).
static func entablature(cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	var root := Node3D.new()
	root.name = "Entablature"

	var color: Color = _parse_color(params.get("color", ""), Color(0.82, 0.76, 0.66))
	var mat := FacadeMaterials.stone_material(color)

	var architrave_h := cell_height * 0.3
	var frieze_h := cell_height * 0.4
	var cornice_h := cell_height * 0.3
	var depth := cell_height * 0.25

	# Architrave (bottom band)
	var architrave := CSGBox3D.new()
	architrave.name = "Architrave"
	architrave.size = Vector3(cell_width, architrave_h, depth * 0.8)
	architrave.position = Vector3(0, architrave_h * 0.5, depth * 0.4)
	architrave.material = mat
	root.add_child(architrave)

	# Frieze (middle band — slightly recessed)
	var frieze := CSGBox3D.new()
	frieze.name = "Frieze"
	frieze.size = Vector3(cell_width, frieze_h, depth * 0.6)
	frieze.position = Vector3(0, architrave_h + frieze_h * 0.5, depth * 0.3)
	frieze.material = mat
	root.add_child(frieze)

	# Cornice (top band — projecting)
	var cornice := CSGBox3D.new()
	cornice.name = "Cornice"
	cornice.size = Vector3(cell_width * 1.05, cornice_h, depth * 1.2)
	cornice.position = Vector3(0, architrave_h + frieze_h + cornice_h * 0.5, depth * 0.6)
	cornice.material = mat
	root.add_child(cornice)

	return root


# ─── ELEMENT FACTORY ──────────────────────────────────────────────────────

## Generate the CSG element for a given element type ID.
## Returns a Node3D containing the CSG assembly, or an empty Node3D for unknown types.
static func create_element(element_type: String, cell_width: float, cell_height: float, params: Dictionary = {}) -> Node3D:
	match element_type:
		"col_tuscan":
			return col_tuscan(cell_width, cell_height, params)
		"col_doric":
			return col_doric(cell_width, cell_height, params)
		"col_ionic":
			return col_ionic(cell_width, cell_height, params)
		"col_corinthian":
			return col_corinthian(cell_width, cell_height, params)
		"pilaster":
			return pilaster(cell_width, cell_height, params)
		"rect_window":
			return rect_window(cell_width, cell_height, params)
		"arched_window":
			return arched_window(cell_width, cell_height, params)
		"door":
			return door(cell_width, cell_height, params)
		"arcade_arch":
			return arcade_arch(cell_width, cell_height, params)
		"dentil":
			return dentil(cell_width, cell_height, params)
		"cyma_recta":
			return cyma_recta(cell_width, cell_height, params)
		"string_course":
			return string_course(cell_width, cell_height, params)
		"fascia":
			return fascia(cell_width, cell_height, params)
		"rusticated_block":
			return rusticated_block(cell_width, cell_height, params)
		"balustrade":
			return balustrade(cell_width, cell_height, params)
		"plain_wall":
			return plain_wall(cell_width, cell_height, params)
		"triangular_pediment":
			return triangular_pediment(cell_width, cell_height, params)
		"broken_pediment":
			return broken_pediment(cell_width, cell_height, params)
		"plinth":
			return plinth_element(cell_width, cell_height, params)
		"piano_nobile":
			return piano_nobile(cell_width, cell_height, params)
		"entablature":
			return entablature(cell_width, cell_height, params)
		_:
			push_warning("CsgFacadeElements: Unknown element type '%s'" % element_type)
			var empty := Node3D.new()
			empty.name = "Unknown_%s" % element_type
			return empty


# ─── HELPERS ───────────────────────────────────────────────────────────────

## Parse a color from hex string or return default.
static func _parse_color(hex: String, fallback: Color = Color(0.82, 0.76, 0.66)) -> Color:
	if hex is String and hex.begins_with("#") and hex.length() >= 7:
		return Color.html(hex)
	return fallback


## Add window/door frame strips around a void.
static func _add_frame_strips(
	parent: Node3D, void_w: float, void_h: float,
	frame_w: float, frame_d: float, center: Vector3, mat: Material
) -> void:
	# Left strip
	var left := CSGBox3D.new()
	left.name = "FrameLeft"
	left.size = Vector3(frame_w, void_h + frame_w * 2, frame_d)
	left.position = center + Vector3(-void_w * 0.5 - frame_w * 0.5, 0, 0)
	left.material = mat
	parent.add_child(left)

	# Right strip
	var right := CSGBox3D.new()
	right.name = "FrameRight"
	right.size = Vector3(frame_w, void_h + frame_w * 2, frame_d)
	right.position = center + Vector3(void_w * 0.5 + frame_w * 0.5, 0, 0)
	right.material = mat
	parent.add_child(right)

	# Top strip
	var top := CSGBox3D.new()
	top.name = "FrameTop"
	top.size = Vector3(void_w + frame_w * 2, frame_w, frame_d)
	top.position = center + Vector3(0, void_h * 0.5 + frame_w * 0.5, 0)
	top.material = mat
	parent.add_child(top)

	# Bottom strip
	var bottom := CSGBox3D.new()
	bottom.name = "FrameBottom"
	bottom.size = Vector3(void_w + frame_w * 2, frame_w, frame_d)
	bottom.position = center + Vector3(0, -void_h * 0.5 - frame_w * 0.5, 0)
	bottom.material = mat
	parent.add_child(bottom)
