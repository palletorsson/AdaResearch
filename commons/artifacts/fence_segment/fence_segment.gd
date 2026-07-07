extends Node3D
class_name FenceSegment

# @identity
# essence: a framed chain-link fence panel — a rectangular galvanized-steel tube frame divided into a grid of cells, the interior webbed with a generated diamond-wire mesh, and a razor/barbed-wire outrigger leaning off the top. The fence is the lab's drawn line: the place where INSIDE stops and OUTSIDE begins. It does not house anything; it excludes. The fence carries the cold language of the perimeter — the chain-link you can see through but not pass, the wire that says "looking is allowed, touching is not". It is the room admitting it has an edge it must defend.
# desire: every secured space wants a boundary that is LEGIBLE before it is physical — a fence reads as "keep out" from across the yard, recognition before any sign is read. The panel wants to be the THRESHOLD MADE VISIBLE: transparent enough to show what it guards, hostile enough at the top to mean it. Even at rest it implies a beyond — a thing behind it worth fencing, a thing in front of it kept away.
# critical_parameter: cols / rows + show_razor + dimensions — cols×rows sets how finely the panel is gridded (the visual rhythm of the cells); show_razor flips the whole statement: razor ON reads as a SECURE / hostile boundary (a prison yard, a depot, a border), razor OFF reads as a plain partition (a tennis court, a garden run, a builder's hoarding); width/height set whether this is a low run or a tall barrier. Same mesh, two very different perimeters.
# triggers: _ready() builds the tube frame + cell-grid dividers + diamond-wire chain-link panel + optional razor outrigger from exports; apply_grid_config rebuilds when DNA changes.
# emerges: a single panel reads as A GAP BEING CLOSED — a breach, a gate-side, a temporary seal. A RUN of panels reads as PERIMETER — institutional, defended, a place with a clear inside. Razor-topped reads as HIGH SECURITY; plain reads as MERELY DIVIDED. The fence is a spatial verb: it CUTS, it SORTS, it names one side as kept and the other as out.
# needs: a rectangular tube frame [present]; cell-grid divider tubes [present]; a generated diamond-wire chain-link panel [present]; an optional razor/barbed outrigger along the top [present]; galvanized steel material [present]
# relationships: peer to crate (both are PERIMETER-LOGIC made object, but the crate's edge contains and the fence's edge excludes); cousin to fire_extinguisher (both are infrastructure-not-instrument, the lab's lived-in plumbing of safety and limit); sibling to any gate or barrier — the grammar of THIS-FAR-AND-NO-FURTHER.
# truth: a fence is the architectural form of the DRAWN LINE. By raising one, a space declares that not everyone belongs, that there is an inside to protect and an outside to hold off. The chain-link is honest about its violence — it lets you see exactly what you cannot reach. The razor on top is the line refusing to be merely symbolic. Every fence is a small monument to the decision that space can be owned, sorted, and closed.

## A framed chain-link fence panel with a razor-wire outrigger.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of
## the panel, on the floor. The panel stands in the X-Y plane (width along
## X, height along Y) and faces ±Z. Default panel is 2.5m wide × 2.0m tall,
## a 4×2 cell grid, razor-topped.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Dimensions")
@export var fence_width: float = 2.5
@export var fence_height: float = 2.0
## Cells across the panel (vertical dividers = cols - 1).
@export var cols: int = 4
## Cells up the panel (horizontal mid-rails = rows - 1).
@export var rows: int = 2
## Radius of the frame / divider tubes. Visual thickness is ~2x this.
@export var tube_radius: float = 0.035

@export_group("Security")
## Show the razor/barbed-wire outrigger leaning off the top rail.
## ON = secure / hostile boundary; OFF = plain partition.
@export var show_razor: bool = true

@export_group("Material")
## Galvanized steel — light gray frame.
@export var frame_color: Color = Color(0.66, 0.68, 0.71)
## Slightly lighter gray for the chain-link wire.
@export var mesh_color: Color = Color(0.72, 0.74, 0.77)

# ── Constants ─────────────────────────────────────────────────────────

const TEX_SIZE: int = 128
const RAZOR_ARM_TILT_DEG: float = 45.0          # lean of the outrigger arms
const RAZOR_WIRE_COUNT: int = 3                 # horizontal wires through arm tips

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_fence_width"):
		fence_width = float(str(get_meta("config_fence_width")))
	if has_meta("config_fence_height"):
		fence_height = float(str(get_meta("config_fence_height")))
	if has_meta("config_cols"):
		cols = int(str(get_meta("config_cols")))
	if has_meta("config_rows"):
		rows = int(str(get_meta("config_rows")))
	if has_meta("config_tube_radius"):
		tube_radius = float(str(get_meta("config_tube_radius")))
	if has_meta("config_show_razor"):
		var s: String = str(get_meta("config_show_razor")).to_lower()
		show_razor = s == "true" or s == "1" or s == "yes" or s == "on"
	if has_meta("config_frame_color"):
		frame_color = _parse_color(str(get_meta("config_frame_color")), frame_color)
	if has_meta("config_mesh_color"):
		mesh_color = _parse_color(str(get_meta("config_mesh_color")), mesh_color)


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var hw := fence_width * 0.5
	var hh := fence_height * 0.5
	var tube_thick := tube_radius * 2.0

	# Shared galvanized-steel material for all the metal tubes.
	var steel_mat := _make_steel_mat(frame_color)

	# ── 1. Chain-link diamond-wire panel (built first, sits behind frame) ─
	_build_chainlink_panel()

	# ── 2. Rectangular tube frame: top + bottom rails, two side posts ─────
	# Top rail (along X, at top edge).
	_add_tube_x("TopRail", Vector3(0.0, fence_height, 0.0), fence_width, steel_mat)
	# Bottom rail (along X, at floor).
	_add_tube_x("BottomRail", Vector3(0.0, 0.0, 0.0), fence_width, steel_mat)
	# Left post (along Y).
	_add_tube_y("LeftPost", Vector3(-hw, hh, 0.0), fence_height, steel_mat)
	# Right post (along Y).
	_add_tube_y("RightPost", Vector3(hw, hh, 0.0), fence_height, steel_mat)

	# ── 3. Cell-grid dividers ─────────────────────────────────────────────
	# (cols - 1) vertical dividers spread across the width.
	var n_cols: int = maxi(1, cols)
	for i in range(1, n_cols):
		var x: float = -hw + fence_width * float(i) / float(n_cols)
		_add_tube_y("VDivider_%d" % i, Vector3(x, hh, 0.0), fence_height, steel_mat)

	# (rows - 1) horizontal mid-rails spread up the height.
	var n_rows: int = maxi(1, rows)
	for j in range(1, n_rows):
		var y: float = fence_height * float(j) / float(n_rows)
		_add_tube_x("HMidRail_%d" % j, Vector3(0.0, y, 0.0), fence_width, steel_mat)

	# ── 4. Razor / barbed outrigger along the top ─────────────────────────
	if show_razor:
		_build_razor_top(steel_mat)


func _make_steel_mat(c: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = 0.6
	m.roughness = 0.4
	return m


# A frame/divider tube running along the local X axis.
func _add_tube_x(tube_name: String, pos: Vector3, length: float,
		mat: StandardMaterial3D) -> void:
	var t := MeshInstance3D.new()
	t.name = tube_name
	var cm := CylinderMesh.new()
	cm.top_radius = tube_radius
	cm.bottom_radius = tube_radius
	cm.height = length
	t.mesh = cm
	t.material_override = mat
	# CylinderMesh stands along +Y by default; rotate about Z to lie along X.
	t.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
	t.position = pos
	add_child(t)


# A frame/divider tube running along the local Y axis (already upright).
func _add_tube_y(tube_name: String, pos: Vector3, length: float,
		mat: StandardMaterial3D) -> void:
	var t := MeshInstance3D.new()
	t.name = tube_name
	var cm := CylinderMesh.new()
	cm.top_radius = tube_radius
	cm.bottom_radius = tube_radius
	cm.height = length
	t.mesh = cm
	t.material_override = mat
	t.position = pos
	add_child(t)


# Fill the frame interior with a thin panel wearing a generated diamond-wire
# (chain-link) texture: opaque wire on the diagonal grid lines, transparent
# everywhere else, scissor-cut so the holes read as see-through.
func _build_chainlink_panel() -> void:
	var panel := MeshInstance3D.new()
	panel.name = "ChainLinkPanel"
	var bm := BoxMesh.new()
	# A very thin slab spanning the frame interior; thickness keeps it
	# visible from both sides.
	bm.size = Vector3(fence_width * 0.985, fence_height * 0.985, 0.004)
	panel.mesh = bm
	panel.material_override = _make_chainlink_material()
	panel.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	panel.position = Vector3(0.0, fence_height * 0.5, 0.0)
	add_child(panel)


# Generate the diamond-grid wire image and wrap it in an alpha-scissor
# StandardMaterial3D. Two sets of diagonal lines (slope +1 and -1) at a
# regular spacing form the diamonds; on-line pixels are opaque wire, the
# rest is fully transparent.
func _make_chainlink_material() -> StandardMaterial3D:
	var img := Image.create(TEX_SIZE, TEX_SIZE, false, Image.FORMAT_RGBA8)
	var clear := Color(0.0, 0.0, 0.0, 0.0)
	var wire := Color(mesh_color.r, mesh_color.g, mesh_color.b, 1.0)
	img.fill(clear)

	# Diamond spacing (period of each diagonal family) and wire thickness,
	# both in pixels.
	var spacing: int = 16
	var wire_half: int = 1            # half-width of the painted line
	for x in range(TEX_SIZE):
		for y in range(TEX_SIZE):
			# Distance to the nearest "+1 slope" diagonal line: lines occur
			# where (x + y) mod spacing == 0.
			var d_pos: int = (x + y) % spacing
			if d_pos > spacing / 2:
				d_pos = spacing - d_pos
			# Distance to the nearest "-1 slope" diagonal line: where
			# (x - y) mod spacing == 0.
			var d_neg: int = ((x - y) % spacing + spacing) % spacing
			if d_neg > spacing / 2:
				d_neg = spacing - d_neg
			if d_pos <= wire_half or d_neg <= wire_half:
				img.set_pixel(x, y, wire)

	var tex := ImageTexture.create_from_image(img)

	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA_SCISSOR
	mat.alpha_scissor_threshold = 0.5
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_LINEAR
	mat.metallic = 0.6
	mat.roughness = 0.45
	# Repeat the diamonds several times across the panel.
	mat.uv1_scale = Vector3(fence_width * 3.0, fence_height * 3.0, 1.0)
	return mat


# The razor/barbed-wire outrigger: short arms tilted ~45° leaning off the
# top rail, with a few horizontal wires threaded through their tips and a
# scatter of tiny barbs crossing the wires.
func _build_razor_top(steel_mat: StandardMaterial3D) -> void:
	var root := Node3D.new()
	root.name = "RazorTop"
	add_child(root)

	var hw := fence_width * 0.5
	var arm_len: float = fence_height * 0.16
	var arm_radius: float = tube_radius * 0.7
	var tilt := deg_to_rad(RAZOR_ARM_TILT_DEG)

	# Lean direction: arms tilt toward +Z (one side), about the X axis.
	# How many arms to space along the width.
	var arm_count: int = maxi(2, cols + 1)

	# Collect arm-tip positions so the wires can thread through them.
	var tip_positions: Array[Vector3] = []

	for i in range(arm_count):
		var t: float = float(i) / float(arm_count - 1)
		var x: float = -hw + fence_width * t
		var base_pos := Vector3(x, fence_height, 0.0)

		var arm := MeshInstance3D.new()
		arm.name = "RazorArm_%d" % i
		var am := CylinderMesh.new()
		am.top_radius = arm_radius
		am.bottom_radius = arm_radius
		am.height = arm_len
		arm.mesh = am
		arm.material_override = steel_mat
		# Tilt about X so the arm leans toward +Z while rising in +Y.
		arm.rotation = Vector3(tilt, 0.0, 0.0)
		# Centre the arm so its base sits at the top rail.
		var up := Vector3(0.0, cos(tilt), sin(tilt))
		arm.position = base_pos + up * (arm_len * 0.5)
		root.add_child(arm)

		tip_positions.append(base_pos + up * arm_len)

	# Horizontal wires (along X) threaded through the arm tips. Spread them
	# along the arm so they sit at a few heights between rail and tip.
	var first_tip: Vector3 = tip_positions[0]
	var last_tip: Vector3 = tip_positions[tip_positions.size() - 1]
	var up_dir := Vector3(0.0, cos(tilt), sin(tilt))
	var wire_radius: float = tube_radius * 0.45

	for w in range(RAZOR_WIRE_COUNT):
		# Fraction along the arm (avoid the very base and very tip).
		var frac: float = lerp(0.45, 1.0, float(w) / float(maxi(1, RAZOR_WIRE_COUNT - 1)))
		# Slide both endpoints back toward the rail by (1 - frac) of arm_len.
		var slide: float = -arm_len * (1.0 - frac)
		var a: Vector3 = first_tip + up_dir * slide
		var b: Vector3 = last_tip + up_dir * slide
		var mid: Vector3 = (a + b) * 0.5
		var span: float = (b - a).length()

		var wire := MeshInstance3D.new()
		wire.name = "RazorWire_%d" % w
		var wm := CylinderMesh.new()
		wm.top_radius = wire_radius
		wm.bottom_radius = wire_radius
		wm.height = span
		wire.mesh = wm
		wire.material_override = steel_mat
		# Lie along X.
		wire.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))
		wire.position = mid
		root.add_child(wire)

		# A few tiny barbs crossing this wire.
		var barb_count: int = maxi(2, cols)
		var barb_len: float = tube_radius * 1.6
		var barb_radius: float = tube_radius * 0.3
		for bi in range(barb_count):
			var bt: float = (float(bi) + 0.5) / float(barb_count)
			var bx: float = -hw + fence_width * bt
			var barb := MeshInstance3D.new()
			barb.name = "RazorBarb_%d_%d" % [w, bi]
			var bm := CylinderMesh.new()
			bm.top_radius = barb_radius
			bm.bottom_radius = barb_radius
			bm.height = barb_len
			barb.mesh = bm
			barb.material_override = steel_mat
			# Cross the wire diagonally (tilt about Z so it splays off X).
			barb.rotation = Vector3(0.0, 0.0, deg_to_rad(40.0))
			barb.position = Vector3(bx, mid.y, mid.z)
			root.add_child(barb)
