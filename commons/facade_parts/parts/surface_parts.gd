class_name SurfaceParts
extends RefCounted

const _M := preload("res://commons/facade_parts/facade_materials.gd")

## Facade surface parts — wall treatments and block patterns.
## Cell origin (0,0,0) = bottom-left-front of the cell.


# ==========================================================================
# Internal helpers
# ==========================================================================

static func _box(bname: String, size: Vector3, pos: Vector3 = Vector3.ZERO,
		op: CSGShape3D.Operation = CSGShape3D.OPERATION_UNION,
		mat: Material = null) -> CSGBox3D:
	var b := CSGBox3D.new()
	b.name = bname
	b.size = size
	b.position = pos
	b.operation = op
	b.use_collision = false
	if mat: b.material = mat
	return b


static func _root(rname: String) -> Node3D:
	var r := Node3D.new()
	r.name = rname
	return r


# ==========================================================================
# SURFACES
# ==========================================================================

## Plain wall: empty Node3D — the wall surface behind is the visual.
static func plain_wall(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("PlainWall")
	return root


## Rusticated blocks: grid of slightly offset blocks with gaps.
## Ported from CSGFacadeElements.rusticated_block.
static func rusticated_block(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("RusticatedBlock")
	var rows: int = p.get("rows", 4)
	var cols: int = p.get("cols", 2)
	var gap: float = p.get("gap", 0.005)
	var base_depth: float = p.get("depth", 0.02)
	var block_w: float = (w - gap * float(cols + 1)) / float(cols)
	var block_h: float = (h - gap * float(rows + 1)) / float(rows)

	var _mat_rust := _M.stone(Color(0.68, 0.64, 0.58))
	for row in range(rows):
		for col in range(cols):
			var bx := gap + block_w * 0.5 + float(col) * (block_w + gap)
			var by := gap + block_h * 0.5 + float(row) * (block_h + gap)
			var depth_offset: float
			if (row + col) % 2 == 0:
				depth_offset = base_depth
			else:
				depth_offset = base_depth * 0.5
			var block := _box("Block_%d_%d" % [row, col],
				Vector3(block_w, block_h, depth_offset),
				Vector3(bx, by, depth_offset * 0.5),
				CSGShape3D.OPERATION_UNION, _mat_rust)
			root.add_child(block)

	return root


## Stucco: smooth flat panel with very slight depth.
static func stucco(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Stucco")
	var depth: float = p.get("depth", 0.003)

	var panel := _box("Panel", Vector3(w, h, depth),
		Vector3(w * 0.5, h * 0.5, depth * 0.5),
		CSGShape3D.OPERATION_UNION, _M.plaster(Color(0.92, 0.89, 0.84)))
	root.add_child(panel)

	return root


## Ashlar: cut stone blocks with fine joints (thinner gaps than rusticated).
static func ashlar(w: float, h: float, p: Dictionary = {}) -> Node3D:
	var root := _root("Ashlar")
	var rows: int = p.get("rows", 6)
	var cols: int = p.get("cols", 3)
	var gap: float = p.get("gap", 0.002)
	var depth: float = p.get("depth", 0.008)
	var block_w: float = (w - gap * float(cols + 1)) / float(cols)
	var block_h: float = (h - gap * float(rows + 1)) / float(rows)

	var _mat_ashlar := _M.stone(Color(0.78, 0.74, 0.68))
	for row in range(rows):
		# Offset alternate rows for running bond pattern
		var x_offset: float = 0.0
		if row % 2 == 1:
			x_offset = block_w * 0.5

		for col in range(cols):
			var bx := gap + block_w * 0.5 + float(col) * (block_w + gap) + x_offset
			if bx > w:
				continue
			var by := gap + block_h * 0.5 + float(row) * (block_h + gap)
			# Clamp width at edges for offset rows
			var actual_w := block_w
			if bx + block_w * 0.5 > w:
				actual_w = (w - bx + block_w * 0.5) * 0.9

			var block := _box("Block_%d_%d" % [row, col],
				Vector3(actual_w, block_h, depth),
				Vector3(bx, by, depth * 0.5),
				CSGShape3D.OPERATION_UNION, _mat_ashlar)
			root.add_child(block)

	return root


# ==========================================================================
# FACTORY
# ==========================================================================

static func create(part_name: String, w: float, h: float, params: Dictionary = {}) -> Node3D:
	match part_name:
		"plain_wall":
			return plain_wall(w, h, params)
		"rusticated_block":
			return rusticated_block(w, h, params)
		"stucco":
			return stucco(w, h, params)
		"ashlar":
			return ashlar(w, h, params)
		_:
			push_warning("SurfaceParts: unknown part '%s'" % part_name)
			var fallback := Node3D.new()
			fallback.name = part_name
			return fallback


static func get_names() -> PackedStringArray:
	return PackedStringArray([
		"plain_wall", "rusticated_block", "stucco", "ashlar",
	])
