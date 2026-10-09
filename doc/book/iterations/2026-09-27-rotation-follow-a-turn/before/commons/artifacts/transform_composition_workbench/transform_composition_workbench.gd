extends Node3D
class_name TransformCompositionWorkbench

# @identity
# essence: an interactive transform-composition workbench — the player turns a slider that picks one of four (T1, T2) pairs of transformations, and watches BOTH orderings of that pair applied to a base tetrahedron, side-by-side. Left shape = T2∘T1 (T1 first); right shape = T1∘T2 (T2 first). A ghost of the base sits between them. Two gold trajectory arrows run from the ghost to each result. When the two results coincide (pair 2 — rotation around origin × uniform scale) a "commutes" badge lights up; for the other three pairs the readout says "non-commutative".
# desire: learner viscerally locates the non-abelian-ness of the transformation group — order is not metadata, it's the operation. The slider walks four pairs and the eye sees that ALMOST all of them split.
# critical_parameter: pair_index ∈ {0,1,2,3} — the only knob. Picks T1 and T2; both orderings compute live.
# triggers: _ready() builds slider + ghost + two transformed shapes + two trajectory arrows + readout + badge; _on_slider_changed snaps to the nearest pair and recomputes both compositions and the centroid positions and the badge.
# emerges: SO(3) non-abelianness, the "commuting subgroup" of (rotation around origin × uniform scale around origin), and order-dependence under composition — all made into a single hand-driven instrument
# needs: slider_horizontal [present]; ImmediateMesh for shapes + arrows + axes [present]; BakedTextAlbedo boards for readouts — the composition readout is ONE integrated multi-line panel (no floating Label3D) [present]; mirrors the /transform-composition-gallery cells frozen at the four pairs
# relationships: paired with /transform-composition-gallery (web cells of this exact instrument frozen at all 8 pair×order combinations); sibling to transform_composition (this is the workbench — a single pair selector — that one is the slider-driven dual-shape demo); embodies the transformation sequence's truth "combine transformations and see order matters"
# truth: order is operation. R·T ≠ T·R for most pairs. The slider lets you walk the four cases, and the badge tells you when (and only when) the two operations happen to commute — exactly when both fix the origin and one is a uniform scale.

## A horizontal workbench for transformation composition.
##
## One slider, four detent stops — pair 1 / pair 2 / pair 3 / pair 4. Each
## pair holds two operations (T1, T2). The workbench shows BOTH orderings
## simultaneously:
##   • LEFT shape  : T2 ∘ T1   (T1 applied first, then T2)
##   • RIGHT shape : T1 ∘ T2   (T2 applied first, then T1)
##   • CENTER ghost: the untransformed base
##   • two gold trajectory arrows from the ghost to each result
##   • a "commutes" / "non-commutative" badge — green when the two
##     centroids coincide within a small tolerance, red otherwise
##
## The four pairs match commons/testing/capture_transform_composition_gallery.gd
## so this workbench is the interactive sibling of the /transform-composition-gallery
## web page.

# ── Configuration ─────────────────────────────────────────────────────

@export_group("Plate")
## Tilt of the slider plate toward the player.
@export var plate_tilt_deg: float = -25.0
## Plate height above the artifact origin.
@export var plate_height: float = 0.95
@export var plate_offset_z: float = 0.0
@export var plate_scale: float = 2.0

@export_group("Stage")
## Where the floating stage (the trio of shapes) sits relative to plate origin.
@export var stage_offset: Vector3 = Vector3(0.0, 1.45, -0.20)
## Horizontal spread between the two result shapes (each is +/- this from center).
@export var stage_spread: float = 0.55
## Uniform display scale applied to the base tetrahedron AFTER its math transform,
## so the shape reads at workbench scale rather than at world scale (where the
## pair-3 translation of 0.8 would push the shape off the table).
@export var stage_display_scale: float = 0.45
@export var color_ghost: Color = Color(0.55, 0.65, 0.80, 0.20)
@export var color_left: Color = Color(0.35, 0.65, 1.00)        # T2∘T1
@export var color_right: Color = Color(1.00, 0.45, 0.55)       # T1∘T2
@export var color_trajectory: Color = Color(1.00, 0.78, 0.18)  # gold

@export_group("Commutes Badge")
## L2 distance between centroids below which the two orderings are considered to
## coincide ("commutes"). Default is generous (~0.5% of stage_spread) since
## floating-point round-off can dust pair-2 by tiny amounts.
@export var commutes_tolerance: float = 0.005
@export var badge_color_commutes: Color = Color(0.40, 1.00, 0.55)
@export var badge_color_noncommutes: Color = Color(1.00, 0.40, 0.40)

@export_group("Workings")
## AXIS — HOW MUCH OF ITS WORKING THE BENCH PUTS ON THE TABLE. Every value computes
## the same two compositions; they differ in what the bench is willing to show of the
## computing. The argument underneath is whether a transform is a THING you receive or
## a SEQUENCE you go through — and the four values take that dispute seriously enough
## to change the furniture.
##
##   outcome     the legacy lineage, byte for byte. Ghost in the middle, the two
##               results on their columns, one gold arrow to each. A composition is a
##               destination: you are handed where you ended up, and the arrow is a
##               displacement, not a route.
##   trace       the halfway states get built. A pale tinted tetrahedron stands at
##               half-spread on each side — the shape AFTER T1 alone (left) and AFTER
##               T2 alone (right) — each carrying its operator tag, and the direct
##               arrows go dark while a two-segment arrow bends through the waypoint.
##               Five shapes instead of three. This is the value that pays: on pair 2
##               the two ENDPOINTS coincide and the badge says "commutes", but the two
##               waypoints are visibly different objects. Even a commuting pair takes
##               two different roads to the same place.
##   operands    the ingredients laid out below the stage on a shelf: T1 alone acting
##               on the base, then T2 alone acting on the base, each as a ghost→result
##               couple with a gold link and a stencilled operator tag. The composition
##               is taken apart into the two things it was made of; the stage above
##               keeps showing what they make together.
##   expression  the algebra promoted over the geometry. A wide dark board across the
##               top of the stage writes both orderings out with the operators
##               substituted — "T2∘T1 = S(×1.5) ∘ R_z(+60°)" — and a verdict line, and
##               a small tag pins the expression for each column directly above the
##               shape it names. Order becomes something WRITTEN, read right to left.
##
## The trajectory arrows are the pivot, the way the lit seam is on station_wall: they
## are the brightest non-text pixels on the stage, and `trace` is the only value that
## breaks them in two.
@export_enum("outcome", "trace", "operands", "expression") var workings: String = "outcome"
const WORKINGS: PackedStringArray = ["outcome", "trace", "operands", "expression"]

# ── Internal state ────────────────────────────────────────────────────

const InterfacePresets = preload("res://commons/ui/interface_presets.gd")
const DisplayMount = preload("res://commons/ui/display_mount.gd")
const BakedText = preload("res://commons/utils/baked_text_albedo.gd")

# Four detent stops on the slider — one per pair.
const PAIR_COUNT: int = 4

# Base tetrahedron (matches the gallery's "arrow shape" so the workbench reads
# as the same instrument frozen in the gallery cells). Same five vertices —
# directional tetrahedron with a fin so orientation is legible from any angle:
#   apex points +X (nose)
#   fin points +Y  (up)
#   base widens along ±Z (sides)
const SHAPE_APEX: Vector3 = Vector3(0.55, 0.0, 0.0)
const SHAPE_B: Vector3 = Vector3(-0.30, 0.30, 0.0)
const SHAPE_C: Vector3 = Vector3(-0.30, -0.18, -0.30)
const SHAPE_D: Vector3 = Vector3(-0.30, -0.18, 0.30)
const SHAPE_F: Vector3 = Vector3(-0.10, 0.45, 0.0)

# Per-pair data. Each entry stores:
#   t1_label, t1_short, t1_xform, t2_label, t2_short, t2_xform, pair_title
# All Transform3D math runs through Basis multiplication (NOT Euler sums) so
# the non-commutativity emerges from real linear algebra rather than from a
# coincidence of representation.
var _pairs: Array = []

var _pair_index: int = 0          # default to pair 1

var _plate_root: Node3D
var _display_root: Node3D            # anchor that carries the viz cluster
var _slider: Node                  # canonical slider_smooth (on the console)
var _plate_readout                  # console summary readout (Label)
var _viz_dirty := false
var _viz_cooldown := 0.0
const VIZ_REFRESH_INTERVAL := 0.12

var _stage_root: Node3D
var _ghost_root: Node3D
var _left_root: Node3D             # T2∘T1
var _right_root: Node3D            # T1∘T2

var _left_traj_root: Node3D
var _right_traj_root: Node3D

# WORKINGS dressing lives here and nowhere else — created last inside the stage so
# every child index above it is untouched, and emptied on "outcome".
var _workings_root: Node3D

var _readout_root: Node3D
var _readout_block_root: Node3D       # holds the rebuilt multi-line composition panel

var _badge_root: Node3D
var _badge_mesh_inst: MeshInstance3D
var _badge_material: StandardMaterial3D
var _badge_label_root: Node3D         # holds the rebuilt badge tag board


# ── Lifecycle ─────────────────────────────────────────────────────────

func _ready() -> void:
	_init_pairs()
	_build_plate_and_slider()
	_build_stage()
	_build_readout_panel()
	_build_badge()
	_build_axis_legend()
	_refresh_all()
	_mount_display.call_deferred()


## Gather the viz roots onto a composer-placed anchor + floor stand (DisplayMount).
func _mount_display() -> void:
	var center := stage_offset
	_display_root = DisplayMount.make_anchor(self, "transform_composition_workbench", center, 1.0, 0.0)
	DisplayMount.mount_cluster(_display_root, [_stage_root, _readout_root, _badge_root], center)
	DisplayMount.build_stand(self, _display_root)


# ── Pair definitions ──────────────────────────────────────────────────

func _init_pairs() -> void:
	# Pair 1: rotate +45° Y, then translate +X by 1.0
	var p1_t1: Transform3D = Transform3D(Basis().rotated(Vector3.UP, deg_to_rad(45.0)), Vector3.ZERO)
	var p1_t2: Transform3D = Transform3D(Basis.IDENTITY, Vector3(1.0, 0.0, 0.0))

	# Pair 2: rotate +60° Z, then scale x1.5
	var p2_t1: Transform3D = Transform3D(Basis().rotated(Vector3.FORWARD, deg_to_rad(60.0)), Vector3.ZERO)
	var p2_t2: Transform3D = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 1.5), Vector3.ZERO)

	# Pair 3: translate +X by 0.8, scale x0.6
	var p3_t1: Transform3D = Transform3D(Basis.IDENTITY, Vector3(0.8, 0.0, 0.0))
	var p3_t2: Transform3D = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.6), Vector3.ZERO)

	# Pair 4: rotate +30° X, rotate +45° Y  — two rotations around different axes
	var p4_t1: Transform3D = Transform3D(Basis().rotated(Vector3.RIGHT, deg_to_rad(30.0)), Vector3.ZERO)
	var p4_t2: Transform3D = Transform3D(Basis().rotated(Vector3.UP, deg_to_rad(45.0)), Vector3.ZERO)

	_pairs = [
		{
			"title": "Pair 1: rotate Y+45° + translate +X 1.0",
			"t1_label": "rotate Y+45°", "t1_short": "R_y(+45°)", "t1_xform": p1_t1,
			"t2_label": "translate +X 1.0", "t2_short": "T_x(+1.0)", "t2_xform": p1_t2,
		},
		{
			"title": "Pair 2: rotate Z+60° + scale 1.5×",
			"t1_label": "rotate Z+60°", "t1_short": "R_z(+60°)", "t1_xform": p2_t1,
			"t2_label": "scale 1.5×", "t2_short": "S(×1.5)", "t2_xform": p2_t2,
		},
		{
			"title": "Pair 3: translate +X 0.8 + scale 0.6×",
			"t1_label": "translate +X 0.8", "t1_short": "T_x(+0.8)", "t1_xform": p3_t1,
			"t2_label": "scale 0.6×", "t2_short": "S(×0.6)", "t2_xform": p3_t2,
		},
		{
			"title": "Pair 4: rotate X+30° + rotate Y+45°",
			"t1_label": "rotate X+30°", "t1_short": "R_x(+30°)", "t1_xform": p4_t1,
			"t2_label": "rotate Y+45°", "t2_short": "R_y(+45°)", "t2_xform": p4_t2,
		},
	]


# ── Slider stops ──────────────────────────────────────────────────────

func _normalized_to_pair_index(norm: float) -> int:
	var idx: int = int(round(norm * float(PAIR_COUNT - 1)))
	return clampi(idx, 0, PAIR_COUNT - 1)


func _pair_index_to_normalized(idx: int) -> float:
	return float(idx) / float(PAIR_COUNT - 1)


# ── Plate + slider ────────────────────────────────────────────────────

func _build_plate_and_slider() -> void:
	# Canonical desktop ControlConsole (workbench principal): pair slider + summary
	# readout. The 3D stage (ghost / left / right transforms) + detail card stay as
	# world-space viz. Replaces the hand-built plate + jumpy slider_horizontal.
	_plate_root = InterfacePresets.build("workbench", "Transform Composition", plate_height)
	_plate_root.position = Vector3(0.0, plate_height, plate_offset_z)
	add_child(_plate_root)
	_plate_readout = _plate_root.add_readout("")
	_slider = _plate_root.add_slider("pair", "pair")
	if _slider and _slider.has_method("set_normalized_value"):
		_slider.call("set_normalized_value", _pair_index_to_normalized(_pair_index))
	if _slider and _slider.has_signal("slider_moved"):
		_slider.connect("slider_moved", Callable(self, "_on_slider_changed"))


func _on_slider_changed(_value) -> void:
	if _slider == null or not _slider.has_method("get_normalized_value"):
		return
	var norm: Variant = _slider.call("get_normalized_value")
	var new_idx: int = _normalized_to_pair_index(float(norm))
	if new_idx == _pair_index:
		return
	_pair_index = new_idx
	_viz_dirty = true   # throttled rebuild (see _process) — keep the grab loop free


func _process(delta: float) -> void:
	if _viz_cooldown > 0.0:
		_viz_cooldown -= delta
	if _viz_dirty and _viz_cooldown <= 0.0:
		_viz_dirty = false
		_viz_cooldown = VIZ_REFRESH_INTERVAL
		_refresh_all()


# ── Stage (ghost + two transformed shapes + trajectories) ─────────────

func _build_stage() -> void:
	_stage_root = Node3D.new()
	_stage_root.name = "Stage"
	_stage_root.position = stage_offset
	add_child(_stage_root)

	# Backplate behind the trio — gives the shapes a dark stage to read against.
	var back := MeshInstance3D.new()
	back.name = "StageBackplate"
	var back_mesh := QuadMesh.new()
	back_mesh.size = Vector2(stage_spread * 2.0 + 0.25, 0.65)
	back.mesh = back_mesh
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.02, 0.02, 0.04)
	back_mat.roughness = 0.95
	back.material_override = back_mat
	back.position = Vector3(0.0, 0.15, -0.05)
	_stage_root.add_child(back)

	# A faint horizontal floor line through the stage so the shapes read as
	# sitting on a shared ground.
	var floor_mesh := ImmediateMesh.new()
	floor_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	floor_mesh.surface_add_vertex(Vector3(-stage_spread - 0.08, 0.0, 0.0))
	floor_mesh.surface_add_vertex(Vector3(stage_spread + 0.08, 0.0, 0.0))
	floor_mesh.surface_end()
	var floor_inst := MeshInstance3D.new()
	floor_inst.name = "StageFloor"
	floor_inst.mesh = floor_mesh
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.35, 0.40, 0.50)
	floor_mat.emission_enabled = true
	floor_mat.emission = Color(0.35, 0.40, 0.50)
	floor_mat.emission_energy_multiplier = 0.6
	floor_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	floor_inst.material_override = floor_mat
	_stage_root.add_child(floor_inst)

	# Three shape root nodes — ghost in center, left = T2∘T1, right = T1∘T2.
	# Each one is rebuilt every refresh because the math transform may change.
	_ghost_root = Node3D.new()
	_ghost_root.name = "Ghost"
	_stage_root.add_child(_ghost_root)

	_left_root = Node3D.new()
	_left_root.name = "Result_T2_after_T1"
	_stage_root.add_child(_left_root)

	_right_root = Node3D.new()
	_right_root.name = "Result_T1_after_T2"
	_stage_root.add_child(_right_root)

	# Trajectory arrows — gold lines from ghost-centroid to each result-centroid.
	# Built fresh on every refresh inside their root nodes (so reorienting is
	# simply "delete + rebuild" with the new endpoints).
	_left_traj_root = Node3D.new()
	_left_traj_root.name = "Trajectory_Left"
	_stage_root.add_child(_left_traj_root)

	_right_traj_root = Node3D.new()
	_right_traj_root.name = "Trajectory_Right"
	_stage_root.add_child(_right_traj_root)

	# WORKINGS holder — added LAST so the five nodes above keep their indices and
	# positions on the legacy path. Stays empty for "outcome".
	_workings_root = Node3D.new()
	_workings_root.name = "Workings"
	_stage_root.add_child(_workings_root)


func _refresh_stage() -> void:
	# Wipe previous geometry.
	for c in _ghost_root.get_children():
		c.queue_free()
	for c in _left_root.get_children():
		c.queue_free()
	for c in _right_root.get_children():
		c.queue_free()
	for c in _left_traj_root.get_children():
		c.queue_free()
	for c in _right_traj_root.get_children():
		c.queue_free()

	# Build the three shapes — ghost (transparent), left-result, right-result.
	var ghost := _build_tet_shape(color_ghost, true)
	# Ghost sits at the center column, scaled to display scale, no math transform.
	ghost.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * stage_display_scale), Vector3.ZERO)
	_ghost_root.add_child(ghost)

	var pair: Dictionary = _pairs[_pair_index]
	var t1: Transform3D = pair["t1_xform"]
	var t2: Transform3D = pair["t2_xform"]
	# T2 ∘ T1 — apply T1 first, then T2. In Godot's Transform3D · operator,
	# (t2 * t1) * v means "apply t1, then t2" — same as matrix math right-to-left.
	var left_xform: Transform3D = t2 * t1
	var right_xform: Transform3D = t1 * t2

	# Convert centroids from base-local space to stage space, applying both the
	# math transform AND the display scale, AND offsetting the result column
	# to its side of the stage.
	var base_centroid: Vector3 = _shape_centroid()

	var left_disp_center: Vector3 = Vector3(-stage_spread, 0.0, 0.0)
	var right_disp_center: Vector3 = Vector3(stage_spread, 0.0, 0.0)
	var ghost_disp_center: Vector3 = Vector3(0.0, 0.0, 0.0)

	# Apply the math transform to the base shape, then scale-and-offset into the
	# left/right stage column.
	var left_node := _build_tet_shape(color_left, false)
	left_node.transform = _stage_transform(left_xform, left_disp_center)
	_left_root.add_child(left_node)

	var right_node := _build_tet_shape(color_right, false)
	right_node.transform = _stage_transform(right_xform, right_disp_center)
	_right_root.add_child(right_node)

	# Trajectory arrows: from ghost centroid to each result centroid, in
	# DISPLAY space (the math centroid is what the eye should follow, so
	# both the math transform and the display scale apply, and the column
	# offset is added).
	var ghost_centroid_disp: Vector3 = ghost_disp_center + base_centroid * stage_display_scale
	var left_centroid_disp: Vector3 = left_disp_center + (left_xform * base_centroid) * stage_display_scale
	var right_centroid_disp: Vector3 = right_disp_center + (right_xform * base_centroid) * stage_display_scale

	var left_traj := _build_trajectory_arrow(ghost_centroid_disp, left_centroid_disp, color_left)
	if left_traj:
		_left_traj_root.add_child(left_traj)
	var right_traj := _build_trajectory_arrow(ghost_centroid_disp, right_centroid_disp, color_right)
	if right_traj:
		_right_traj_root.add_child(right_traj)

	# WORKINGS dressing, built LAST so nothing above it moves. "outcome" falls
	# through and adds nothing at all — the legacy lineage.
	if _workings_root != null:
		for c in _workings_root.get_children():
			c.queue_free()
		match workings:
			"trace":
				_workings_trace(pair, t1, t2, base_centroid, ghost_centroid_disp)
			"operands":
				_workings_operands(pair, t1, t2, base_centroid)
			"expression":
				_workings_expression(pair, t1, t2)
			_:
				pass                                   # "outcome" — the legacy lineage


# Build a Transform3D that:
#  1. Applies the math transform (rotation/translation/scale) to the base
#  2. Uniformly scales the result for display
#  3. Translates to the stage column (-spread, 0, +spread)
#
# Order matters here too — we want the math transform to act first on the
# base shape, THEN the display scale, THEN the column offset. So in matrix
# form (with vectors on the right): result = translate · scale · math · v.
func _stage_transform(math_xform: Transform3D, column_offset: Vector3) -> Transform3D:
	var scale_xform: Transform3D = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * stage_display_scale), Vector3.ZERO)
	var offset_xform: Transform3D = Transform3D(Basis.IDENTITY, column_offset)
	return offset_xform * scale_xform * math_xform


func _shape_centroid() -> Vector3:
	# Same centroid used in the gallery — average of the five vertices. Stable
	# across base and transformed copies; good enough for trajectory arrows.
	return (SHAPE_APEX + SHAPE_B + SHAPE_C + SHAPE_D + SHAPE_F) / 5.0


# ── Tetrahedron shape with fin (same geometry as the gallery) ─────────

func _build_tet_shape(color: Color, is_ghost: bool) -> Node3D:
	var holder := Node3D.new()
	holder.name = "TetShape"

	# Body — five triangular faces of the tetrahedron + two fin triangles.
	var im := ImmediateMesh.new()
	var mat := _make_body_material(color, is_ghost)
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLES, mat)
	_add_tri(im, SHAPE_APEX, SHAPE_C, SHAPE_D)   # front
	_add_tri(im, SHAPE_APEX, SHAPE_D, SHAPE_B)   # +Z side
	_add_tri(im, SHAPE_APEX, SHAPE_B, SHAPE_C)   # -Z side
	_add_tri(im, SHAPE_B, SHAPE_D, SHAPE_C)      # back base
	_add_tri(im, SHAPE_B, SHAPE_APEX, SHAPE_F)   # fin +Z
	_add_tri(im, SHAPE_APEX, SHAPE_B, SHAPE_F)   # fin -Z
	im.surface_end()

	# Wireframe outline so each shape stays legible against the dark stage.
	var wire_color: Color
	if is_ghost:
		wire_color = Color(0.85, 0.92, 1.0, 0.45)
	else:
		wire_color = Color(color.r * 1.4, color.g * 1.4, color.b * 1.4, 1.0)
	im.surface_begin(Mesh.PRIMITIVE_LINES, _make_wire_material(wire_color, is_ghost))
	var edges: Array = [
		[SHAPE_APEX, SHAPE_B], [SHAPE_APEX, SHAPE_C], [SHAPE_APEX, SHAPE_D],
		[SHAPE_B, SHAPE_C], [SHAPE_C, SHAPE_D], [SHAPE_D, SHAPE_B],
		[SHAPE_B, SHAPE_F], [SHAPE_APEX, SHAPE_F],
	]
	for e in edges:
		im.surface_add_vertex(e[0])
		im.surface_add_vertex(e[1])
	im.surface_end()

	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(mi)
	return holder


func _add_tri(im: ImmediateMesh, a: Vector3, b: Vector3, c: Vector3) -> void:
	var n: Vector3 = (b - a).cross(c - a).normalized()
	im.surface_set_normal(n)
	im.surface_add_vertex(a)
	im.surface_set_normal(n)
	im.surface_add_vertex(b)
	im.surface_set_normal(n)
	im.surface_add_vertex(c)


func _make_body_material(color: Color, transparent: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.roughness = 0.55
	mat.metallic = 0.0
	mat.metallic_specular = 0.2
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_PER_PIXEL
	else:
		mat.emission_enabled = true
		mat.emission = color
		mat.emission_energy_multiplier = 0.22
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


func _make_wire_material(color: Color, transparent: bool) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = color
	mat.emission_enabled = true
	mat.emission = Color(color.r, color.g, color.b, 1.0)
	mat.emission_energy_multiplier = 0.7
	if transparent:
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.disable_receive_shadows = true
	return mat


# ── Trajectory arrow (gold cylinder + cone arrowhead) ─────────────────

func _build_trajectory_arrow(start: Vector3, end: Vector3, tint: Color) -> Node3D:
	var v: Vector3 = end - start
	var dist: float = v.length()
	if dist < 0.01:
		return null

	var holder := Node3D.new()
	holder.name = "TrajectoryArrow"

	var head_len: float = min(0.06, dist * 0.25)
	var shaft_len: float = max(0.005, dist - head_len)

	# Shaft.
	var shaft_mi := MeshInstance3D.new()
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = 0.008
	shaft_mesh.bottom_radius = 0.008
	shaft_mesh.height = shaft_len
	shaft_mesh.radial_segments = 8
	shaft_mesh.rings = 1
	shaft_mi.mesh = shaft_mesh
	shaft_mi.transform = _aim_transform(start, end, shaft_len / 2.0)
	shaft_mi.material_override = _make_arrow_material(tint)
	shaft_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(shaft_mi)

	# Head — cone (top_radius = 0).
	var head_mi := MeshInstance3D.new()
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = 0.025
	head_mesh.height = head_len
	head_mesh.radial_segments = 12
	head_mesh.rings = 1
	head_mi.mesh = head_mesh
	head_mi.transform = _aim_transform(start, end, dist - head_len / 2.0)
	head_mi.material_override = _make_arrow_material(tint)
	head_mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	holder.add_child(head_mi)

	return holder


func _aim_transform(start: Vector3, end: Vector3, t: float) -> Transform3D:
	# Place a +Y-aligned mesh at the parametric point along the start→end line,
	# pointing in the direction. Picks a non-parallel reference up so the
	# orthonormal basis is well-defined.
	var v: Vector3 = end - start
	var dir: Vector3 = v.normalized()
	var pos: Vector3 = start + dir * t
	var up_ref: Vector3 = Vector3.UP
	if abs(dir.dot(up_ref)) > 0.99:
		up_ref = Vector3.RIGHT
	var y: Vector3 = dir
	var z: Vector3 = y.cross(up_ref).normalized()
	if z.length_squared() < 0.0001:
		z = y.cross(Vector3.FORWARD).normalized()
	var x: Vector3 = z.cross(y).normalized()
	var basis_y_to_dir: Basis = Basis(x, y, z)
	return Transform3D(basis_y_to_dir, pos)


func _make_arrow_material(tint: Color) -> StandardMaterial3D:
	# Mix gold with a touch of the result color so the eye groups the arrow
	# with its corresponding shape (left arrow = bluish-gold, right = reddish-gold).
	var c: Color = color_trajectory.lerp(tint, 0.35)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = c
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = c
	mat.emission_energy_multiplier = 0.95
	return mat


# ── Readout panel ─────────────────────────────────────────────────────

# ONE BODY: the whole composition readout (pair title + commute status + both
# centroids) is a single integrated panel — one opaque backing plate with a
# multi-line baked-text block painted onto it, instead of four floating Label3D
# nodes stacked on a bare card (which crowded and overlapped as the pair title
# ran long). The text block is rebuilt on every refresh; the plate is static.
const READOUT_W: float = 0.58
const READOUT_H: float = 0.42
const READOUT_LINE_H: float = 0.052
const READOUT_GAP: float = 0.018

func _build_readout_panel() -> void:
	_readout_root = Node3D.new()
	_readout_root.name = "Readout"
	_readout_root.position = Vector3(stage_spread + 0.30, plate_height + 0.55, plate_offset_z + 0.05)
	add_child(_readout_root)

	# Opaque backing plate — one textured quad, no floating labels behind it.
	var plate: MeshInstance3D = BakedText.make_panel_mesh(
		" ", Color(0.03, 0.05, 0.08), Color(0.03, 0.05, 0.08),
		Vector2(READOUT_W, READOUT_H))
	if plate:
		plate.name = "ReadoutPlate"
		plate.position = Vector3(0.0, 0.0, -0.006)
		_readout_root.add_child(plate)

	# Holder for the rebuilt multi-line text block (cleared + refilled per refresh).
	_readout_block_root = Node3D.new()
	_readout_block_root.name = "ReadoutBlock"
	_readout_block_root.position = Vector3(0.0, 0.0, 0.004)
	_readout_root.add_child(_readout_block_root)


func _refresh_readout() -> void:
	var pair: Dictionary = _pairs[_pair_index]

	if _plate_readout:
		_plate_readout.text = "pair %d / %d\n%s" % [_pair_index + 1, PAIR_COUNT, pair["title"]]

	var t1: Transform3D = pair["t1_xform"]
	var t2: Transform3D = pair["t2_xform"]
	var base_c: Vector3 = _shape_centroid()
	var left_c: Vector3 = (t2 * t1) * base_c   # T2∘T1
	var right_c: Vector3 = (t1 * t2) * base_c  # T1∘T2

	var d: float = left_c.distance_to(right_c)
	var commutes: bool = d <= commutes_tolerance
	var status_text: String
	if commutes:
		status_text = "T2∘T1 = T1∘T2  ✓  commutes (pair %d only)" % (_pair_index + 1)
	else:
		status_text = "T2∘T1 ≠ T1∘T2  non-commutative  Δ = %.3f" % d

	var left_text: String = "T2∘T1 centroid: (%+.2f, %+.2f, %+.2f)" % [left_c.x, left_c.y, left_c.z]
	var right_text: String = "T1∘T2 centroid: (%+.2f, %+.2f, %+.2f)" % [right_c.x, right_c.y, right_c.z]

	# One multi-line panel carries the whole readout — same four strings, now on a
	# single evenly-pitched surface so lines can never overlap.
	if _readout_block_root == null:
		return
	for c in _readout_block_root.get_children():
		c.queue_free()

	var text_w: float = READOUT_W * 0.90
	var body := BakedText.make_text_block(
		[pair["title"], status_text, left_text, right_text],
		Color(0.90, 0.94, 1.0), READOUT_LINE_H, text_w, READOUT_GAP, true)
	if body:
		body.name = "ReadoutTextBlock"
		_readout_block_root.add_child(body)


# ── Commutes badge ────────────────────────────────────────────────────

func _build_badge() -> void:
	# A small upright pill to the LEFT of the stage. Its color tells you at
	# a glance whether the two orderings coincide. Text inside echoes the
	# state — "commutes" / "non-comm."
	_badge_root = Node3D.new()
	_badge_root.name = "CommutesBadge"
	_badge_root.position = Vector3(-stage_spread - 0.35, plate_height + 0.55, plate_offset_z + 0.05)
	add_child(_badge_root)

	# Pill background.
	_badge_mesh_inst = MeshInstance3D.new()
	_badge_mesh_inst.name = "BadgePill"
	var pill_mesh := QuadMesh.new()
	pill_mesh.size = Vector2(0.30, 0.10)
	_badge_mesh_inst.mesh = pill_mesh
	_badge_material = StandardMaterial3D.new()
	_badge_material.albedo_color = badge_color_noncommutes
	_badge_material.emission_enabled = true
	_badge_material.emission = badge_color_noncommutes
	_badge_material.emission_energy_multiplier = 1.1
	_badge_material.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	_badge_mesh_inst.material_override = _badge_material
	_badge_mesh_inst.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_badge_root.add_child(_badge_mesh_inst)

	# Badge label — a baked-text board sized to sit inside the pill (never wider
	# than the pill face), rebuilt on state change. Holder so the tag can be
	# swapped without disturbing the pill.
	_badge_label_root = Node3D.new()
	_badge_label_root.name = "BadgeLabel"
	_badge_label_root.position = Vector3(0.0, 0.0, 0.004)
	_badge_root.add_child(_badge_label_root)


func _refresh_badge() -> void:
	var pair: Dictionary = _pairs[_pair_index]
	var t1: Transform3D = pair["t1_xform"]
	var t2: Transform3D = pair["t2_xform"]
	var base_c: Vector3 = _shape_centroid()
	var d: float = ((t2 * t1) * base_c).distance_to((t1 * t2) * base_c)
	var commutes: bool = d <= commutes_tolerance
	var c: Color = badge_color_commutes if commutes else badge_color_noncommutes
	_badge_material.albedo_color = c
	_badge_material.emission = c

	if _badge_label_root == null:
		return
	for ch in _badge_label_root.get_children():
		ch.queue_free()
	var text: String = "commutes ✓" if commutes else "non-comm."
	# Baked text painted on a transparent quad, width fit inside the 0.30 pill.
	var label: MeshInstance3D = BakedText.make_label_mesh(
		text, Color(0.06, 0.06, 0.08), Vector2(0.26, 0.07), 1400, true)
	if label:
		label.name = "BadgeText"
		_badge_label_root.add_child(label)


# ── Axis legend (faint world axes on the stage) ───────────────────────

func _build_axis_legend() -> void:
	# A small XYZ tripod at the bottom-center of the stage so the rotations
	# read against a fixed frame.
	var legend := Node3D.new()
	legend.name = "AxisLegend"
	legend.position = Vector3(0.0, -0.18, 0.0)
	_stage_root.add_child(legend)

	var im := ImmediateMesh.new()
	im.surface_begin(Mesh.PRIMITIVE_LINES, _make_wire_material(Color(0.55, 0.60, 0.70, 0.9), false))
	# X (red), Y (green), Z (blue) — but with one shared material here for
	# the lines themselves. Tick markers below carry the actual colors.
	var L: float = 0.08
	im.surface_add_vertex(Vector3.ZERO); im.surface_add_vertex(Vector3(L, 0, 0))
	im.surface_add_vertex(Vector3.ZERO); im.surface_add_vertex(Vector3(0, L, 0))
	im.surface_add_vertex(Vector3.ZERO); im.surface_add_vertex(Vector3(0, 0, L))
	im.surface_end()
	var mi := MeshInstance3D.new()
	mi.mesh = im
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	legend.add_child(mi)

	_add_axis_tip(legend, Vector3(L, 0, 0), Color(1.0, 0.40, 0.45), "X")
	_add_axis_tip(legend, Vector3(0, L, 0), Color(0.45, 1.0, 0.55), "Y")
	_add_axis_tip(legend, Vector3(0, 0, L), Color(0.45, 0.65, 1.0), "Z")


func _add_axis_tip(parent: Node3D, pos: Vector3, color: Color, label: String) -> void:
	var mi := MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = 0.01
	sphere.height = 0.02
	sphere.radial_segments = 10
	sphere.rings = 4
	mi.mesh = sphere
	mi.position = pos
	var mat := StandardMaterial3D.new()
	mat.albedo_color = color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = color
	mat.emission_energy_multiplier = 0.7
	mi.material_override = mat
	mi.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	parent.add_child(mi)

	# Axis letter as a small integrated tag board, pushed out past its tip sphere
	# so the three (X/Y/Z) never overlap each other or the tripod.
	var tag: Node3D = BakedText.make_tag(
		label, color, 0.05, Color(0.05, 0.06, 0.09), true, Color(0, 0, 0, 0))
	if tag:
		tag.name = "AxisTip_" + label
		tag.position = pos * 1.9
		parent.add_child(tag)


# ── Refresh ───────────────────────────────────────────────────────────

func _refresh_all() -> void:
	_refresh_stage()
	_refresh_readout()
	_refresh_badge()


# ── Grid system integration ───────────────────────────────────────────

func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("initial_pair"):
		var requested: int = clampi(int(config_data["initial_pair"]) - 1, 0, PAIR_COUNT - 1)
		_pair_index = requested
		if _slider and _slider.has_method("set_normalized_value"):
			_slider.call("set_normalized_value", _pair_index_to_normalized(_pair_index))
		_refresh_all()
	if config_data.has("plate_scale"):
		plate_scale = float(config_data["plate_scale"])
		if _plate_root:
			_plate_root.scale = Vector3.ONE * plate_scale
	if config_data.has("stage_spread"):
		stage_spread = float(config_data["stage_spread"])
		_refresh_all()
	if config_data.has("stage_display_scale"):
		stage_display_scale = float(config_data["stage_display_scale"])
		_refresh_all()
	if config_data.has("workings"):
		# Normalising read — an unknown word keeps the default rather than blanking
		# the stage, so a typo in a map token can never publish an empty bench.
		var _w: String = str(config_data["workings"]).strip_edges().to_lower()
		if WORKINGS.has(_w):
			workings = _w
			_refresh_all()


# ── WORKINGS ─────────────────────────────────────────────────────────────────
# One axis, four values, all appended after the legacy stage is complete. Each
# builder writes only into _workings_root (plus, for "trace", it drops the two
# direct arrows out of every render layer — layers = 0 on the MeshInstance3D, NOT
# visible = false, which would take the holder's whole subtree with it).


## TRACE — the halfway states. The left column shows T2∘T1, so its waypoint is the
## base after T1 ALONE; the right column shows T1∘T2, so its waypoint is the base
## after T2 alone. Each stands at half spread with its operator tag, and the gold
## arrow is rebuilt in two segments that bend through it. On pair 2 (rotation ×
## uniform scale) the endpoints coincide — and the waypoints do not.
func _workings_trace(pair: Dictionary, t1: Transform3D, t2: Transform3D,
		base_centroid: Vector3, ghost_centroid_disp: Vector3) -> void:
	# The direct ghost→result arrows are the claim "a composition is a displacement".
	# Trace disputes that, so it retires them.
	_hide_instances(_left_traj_root)
	_hide_instances(_right_traj_root)

	var half: float = stage_spread * 0.5
	var steps: Array = [
		{"xform": t1, "col": Vector3(-half, 0.0, 0.0), "tint": color_left,
			"tag": str(pair["t1_short"]), "end": Vector3(-stage_spread, 0.0, 0.0),
			"end_xform": t2 * t1},
		{"xform": t2, "col": Vector3(half, 0.0, 0.0), "tint": color_right,
			"tag": str(pair["t2_short"]), "end": Vector3(stage_spread, 0.0, 0.0),
			"end_xform": t1 * t2},
	]

	for s in steps:
		var mid_xform: Transform3D = s["xform"]
		var col: Vector3 = s["col"]
		var tint: Color = s["tint"]

		# The waypoint shape — the same tetrahedron, held mid-computation. Transparent
		# so it reads as a state passed through rather than a third answer.
		var way := _build_tet_shape(Color(tint.r, tint.g, tint.b, 0.34), true)
		way.transform = _stage_transform(mid_xform, col)
		_workings_root.add_child(way)

		# Two-segment arrow: ghost → waypoint → result. Same gold family as the
		# direct arrow it replaces, so the eye follows a ROUTE, not a jump.
		var mid_c: Vector3 = col + (mid_xform * base_centroid) * stage_display_scale
		var end_c: Vector3 = (s["end"] as Vector3) + ((s["end_xform"] as Transform3D) * base_centroid) * stage_display_scale
		var leg_a := _build_trajectory_arrow(ghost_centroid_disp, mid_c, tint)
		if leg_a:
			_workings_root.add_child(leg_a)
		var leg_b := _build_trajectory_arrow(mid_c, end_c, tint)
		if leg_b:
			_workings_root.add_child(leg_b)

		# Which single operation got you here.
		var tag: Node3D = BakedText.make_tag(
			str(s["tag"]), Color(0.92, 0.95, 1.0), 0.038,
			Color(0.05, 0.06, 0.09), true, tint)
		if tag:
			tag.position = col + Vector3(0.0, 0.30, 0.02)
			_workings_root.add_child(tag)


## OPERANDS — the two transformations pulled out of the composition and shown acting
## alone, on a shelf under the stage: ghost → gold link → result, twice, each under a
## stencilled operator tag. The stage above still shows what they make together, so
## the frame carries both the parts and the product.
func _workings_operands(pair: Dictionary, t1: Transform3D, t2: Transform3D,
		base_centroid: Vector3) -> void:
	var shelf_y: float = -0.34
	var s: float = stage_display_scale * 0.62
	var gap: float = 0.13

	# A thin shelf bar so the operands read as SET DOWN, not floating loose.
	var bar := MeshInstance3D.new()
	bar.name = "OperandShelf"
	var bar_mesh := BoxMesh.new()
	bar_mesh.size = Vector3(stage_spread * 2.0 + 0.22, 0.012, 0.05)
	bar.mesh = bar_mesh
	var bar_mat := StandardMaterial3D.new()
	bar_mat.albedo_color = Color(0.16, 0.18, 0.24)
	bar_mat.roughness = 0.8
	bar.material_override = bar_mat
	bar.position = Vector3(0.0, shelf_y - 0.09, -0.02)
	bar.cast_shadow = GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	_workings_root.add_child(bar)

	var slots: Array = [
		{"xform": t1, "cx": -stage_spread * 0.72, "tint": color_left, "tag": str(pair["t1_short"])},
		{"xform": t2, "cx": stage_spread * 0.72, "tint": color_right, "tag": str(pair["t2_short"])},
	]

	for slot in slots:
		var cx: float = slot["cx"]
		var xf: Transform3D = slot["xform"]
		var tint: Color = slot["tint"]

		# The base, untouched.
		var g := _build_tet_shape(color_ghost, true)
		g.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * s),
			Vector3(cx - gap, shelf_y, 0.0))
		_workings_root.add_child(g)

		# The base after this ONE operation.
		var r := _build_tet_shape(tint, false)
		var r_basis: Basis = xf.basis.scaled(Vector3.ONE * s)
		r.transform = Transform3D(r_basis, Vector3(cx + gap, shelf_y, 0.0) + xf.origin * s)
		_workings_root.add_child(r)

		# The single hop between them.
		var link := _build_trajectory_arrow(
			Vector3(cx - gap, shelf_y, 0.0) + base_centroid * s,
			Vector3(cx + gap, shelf_y, 0.0) + (xf * base_centroid) * s,
			tint)
		if link:
			_workings_root.add_child(link)

		var tag: Node3D = BakedText.make_tag(
			str(slot["tag"]), Color(0.92, 0.95, 1.0), 0.040,
			Color(0.05, 0.06, 0.09), true, tint)
		if tag:
			tag.position = Vector3(cx, shelf_y - 0.16, 0.02)
			_workings_root.add_child(tag)


## EXPRESSION — the algebra promoted over the geometry. A wide dark board across the
## top of the stage writes both orderings out with the operators substituted, plus a
## verdict line; a small tag over each column pins that column's expression to the
## shape it names. Composition stops being a picture and becomes notation you read
## right to left.
func _workings_expression(pair: Dictionary, t1: Transform3D, t2: Transform3D) -> void:
	var t1s: String = str(pair["t1_short"])
	var t2s: String = str(pair["t2_short"])

	var base_c: Vector3 = _shape_centroid()
	var d: float = ((t2 * t1) * base_c).distance_to((t1 * t2) * base_c)
	var commutes: bool = d <= commutes_tolerance
	var verdict: String = ("T2∘T1 = T1∘T2   this pair commutes" if commutes
		else "T2∘T1 ≠ T1∘T2   order is the operation")

	var bw: float = stage_spread * 2.0 + 0.30
	var bh: float = 0.30

	var plate: MeshInstance3D = BakedText.make_panel_mesh(
		" ", Color(0.03, 0.05, 0.08), Color(0.03, 0.05, 0.08), Vector2(bw, bh))
	if plate:
		plate.name = "ExpressionPlate"
		plate.position = Vector3(0.0, 0.66, -0.03)
		_workings_root.add_child(plate)

	var block: Node3D = BakedText.make_text_block(
		["left   T2∘T1  =  %s ∘ %s" % [t2s, t1s],
		 "right  T1∘T2  =  %s ∘ %s" % [t1s, t2s],
		 verdict],
		Color(0.90, 0.94, 1.0), 0.062, bw * 0.92, 0.016, true)
	if block:
		block.name = "ExpressionBlock"
		block.position = Vector3(0.0, 0.66, -0.02)
		_workings_root.add_child(block)

	# The expression pinned over the object it names.
	var left_tag: Node3D = BakedText.make_tag(
		"%s ∘ %s" % [t2s, t1s], Color(0.92, 0.95, 1.0), 0.040,
		Color(0.05, 0.06, 0.09), true, color_left)
	if left_tag:
		left_tag.position = Vector3(-stage_spread, 0.34, 0.02)
		_workings_root.add_child(left_tag)

	var right_tag: Node3D = BakedText.make_tag(
		"%s ∘ %s" % [t1s, t2s], Color(0.92, 0.95, 1.0), 0.040,
		Color(0.05, 0.06, 0.09), true, color_right)
	if right_tag:
		right_tag.position = Vector3(stage_spread, 0.34, 0.02)
		_workings_root.add_child(right_tag)


## Drop every VisualInstance3D under `root` out of all render layers. Per-instance,
## so the mesh, the material and the subtree all survive — unlike `visible = false`,
## which is hierarchical and would take the arrow holder's children with it.
func _hide_instances(root: Node) -> void:
	if root == null:
		return
	for n in root.get_children():
		if n is VisualInstance3D:
			(n as VisualInstance3D).layers = 0
		_hide_instances(n)
