@tool
extends Node3D

# @identity
# essence: X=red, Y=green, Z=blue axes at 3m length — the standard right-handed coordinate frame made visible, now built from the CoordinateLine primitive so every axis carries the same tick-mark ruler vocabulary
# desire: learner stands inside the coordinate system and feels orientation as embodied direction
# critical_parameter: axis_length = 3.0 — at half-scale (scale 0.5) these appear as 1.5m axes in world space
# triggers: runtime adds info panel and gyroscope gadget showing orientation relative to viewer
# emerges: the arbitrary nature of axis conventions — right-handed vs left-handed, Y-up vs Z-up are choices; AND tick marks make the chosen frame's scale legible
# needs: [has info panel [has], has gyroscope gadget [has], CoordinateLine primitive as shared axis vocabulary [present, 2026-05-19]]
# relationships: used in vectors sequence; embedded by xyz_slider_plate as the workspace coordinate frame; the gyroscope gadget adds interactive orientation feedback; consumes CoordinateLine primitive (three instances, one per axis, rotated to +X/+Y/+Z)
# truth: a coordinate system is a choice of three mutually perpendicular directions with an agreed origin — and the rulers along those directions tell you what the choice actually measures

# Coordinate System Visualization
# Illustrates X, Y, Z axes with 3m length.

const GyroscopeGadgetScript = preload("res://algorithms/vectors/shared/gadgets/gyroscope_gadget.gd")
const CoordinateLineScript = preload("res://commons/primitives/line/coordinate_line.gd")

@export var axis_length: float = 3.0
@export var axis_thickness: float = 0.02 # Thinner lines
## Spacing for tick marks along each axis, in axis-length units. Default 0.5
## gives ticks every 0.5 m along a 3 m axis — six ticks per axis, marking the
## scale clearly. Set to 0.0 to suppress ticks.
@export var tick_step: float = 0.5
## Uniform scale applied in _ready(). 0.5 = half-size exhibition default
## (was the hardcoded value). 1.5 = 3× exhibition size, useful inside
## taller rooms where the coordinate frame should fill the space.
## Driveable from map_data via `CoordinateSystem3M:0:0#display_scale:1.5`.
@export var display_scale: float = 1.5
## A FLOATING POINT inside the frame (Palle, 2026-08-19: "add a floating point to
## the coordinate system we can move"): interactive_point_origin — pickable,
## shows its coordinates IN THIS FRAME while held, draws its line to this origin.
## Map/plan: `CoordinateSystem3M:0:0#floating_point:1`; the book: config.
@export var floating_point: bool = false
## Where the floating point starts, in axis units (the frame's own metres).
@export var floating_point_at: Vector3 = Vector3(1.0, 1.0, 1.0)
const FloatingPointScene := "res://commons/primitives/point/interactive_point_origin.tscn"
## THE BARE FRAME (2026-08-24, Palle: "remove indicators along axels and text
## labels ... put the text of x,y,z on the wall work displays instead"):
## `#labels:0` drops the X/Y/Z letters, `#panel:0` drops the info panel — the
## words move to `coordinate_readout` wall works, fed live through the
## "ada_coordinate_readout" group while the grab point moves.
@export var show_labels: bool = true
@export var show_panel: bool = true
## THE NUMBERS ARE THE WORLD'S, NOT THE FRAME'S (2026-08-31, Palle: "do not think
## about CoordinateSystem3M as local but the global values from vector.zero").
##
## The readout used to report `to_local(point.global_position)` — the point's
## offset from THIS FRAME. So a frame standing at world (5, 0, 8) with the point
## one metre out along each axis said 1.00 / 1.00 / 1.00, and said exactly that in
## all 47 halls that place it, wherever they stood. The number described the
## gadget, not the room, and there is nothing to learn from a coordinate system
## whose origin follows it around.
##
## `world` measures from Vector3.ZERO, so the point reads its real position in the
## map — x:6, y:1, z:10 — and two frames in different halls disagree, which is the
## whole use of a coordinate. `local` keeps the old behaviour for a map that wants
## a self-contained demonstration frame: `#readout_space:local`.
@export_enum("world", "local") var readout_space: String = "world"
## The point is the thing you are meant to look at (2026-08-31, Palle: "make the
## point a bit bigger and more bright"), so it is sized and lit from here rather
## than left at the scene's shelf defaults.
@export var point_scale: float = 1.45
@export var point_energy: float = 3.4
## WHERE THE POINT STARTS, AND IN WHOSE UNITS (2026-08-31, Palle: "move point to
## x: 8 y: same z:10"). Asking for a world position and getting axis units is the
## same confusion the readout had, so `floating_point_at` can now be read in
## either space. `world` converts through this frame and CLAMPS into the axis box,
## and says so if the target was out of reach — a frame three units long standing
## at x=4 cannot put its point at x=40, and should not pretend it did.
@export_enum("local", "world") var floating_point_space: String = "local"

var gyroscope: Node3D
var _fp_ref: Node3D = null              # the grab point (survives re-parenting by a grab)
## Which components of floating_point_at were given in world units (1) and which
## were left as `same` (0). Only the named ones are converted through the frame.
var _axis_from_world: Vector3 = Vector3.ONE
var _axis_markers: Array = []           # projection markers riding the three axes
var _proj_lines: MeshInstance3D = null  # thin guide lines, point -> each marker
var _proj_mesh: ImmediateMesh = null

func _ready() -> void:
	# Uniform display scale — controlled by the display_scale @export
	# (default 1.5 = 3× the original exhibition half-size).
	scale = Vector3(display_scale, display_scale, display_scale)

	# Clear existing children to avoid duplication if running in tool mode updates
	for child in get_children():
		child.queue_free()

	create_axis(Vector3.RIGHT, Color.RED, "X")
	create_axis(Vector3.UP, Color.GREEN, "Y")
	create_axis(Vector3.BACK, Color.BLUE, "Z")

	# Info frame and gadget only at runtime (not in editor tool mode)
	if not Engine.is_editor_hint():
		if show_panel:
			_add_info_frame()
		_add_gyroscope()
		if floating_point:
			_add_floating_point()


func _add_floating_point() -> void:
	if get_node_or_null("FloatingPoint") != null or not ResourceLoader.exists(FloatingPointScene):
		return
	var ps: PackedScene = load(FloatingPointScene)
	var pt: Node3D = ps.instantiate() as Node3D
	pt.name = "FloatingPoint"
	_fp_ref = pt
	# the point is a body: it does not inherit this frame's display scale
	pt.top_level = false
	# BEFORE add_child: the point builds its material in _ready, and add_child runs
	# _ready immediately — setting the energy afterwards paints nothing.
	pt.set("glow_emission_energy", point_energy)
	add_child(pt)
	pt.position = _start_local()
	pt.scale = Vector3.ONE / maxf(0.01, display_scale) * maxf(0.05, point_scale)
	# its origin is THIS frame's origin, and it reads its coordinates in this frame
	pt.set("origin_point", global_position if is_inside_tree() else Vector3.ZERO)
	pt.set("frame_path", pt.get_path_to(self))

## floating_point_at resolved into this frame's own units, clamped to the axes.
func _start_local() -> Vector3:
	var want: Vector3 = floating_point_at
	if floating_point_space == "world" and is_inside_tree():
		var conv: Vector3 = to_local(floating_point_at)
		# an axis marked `same` keeps the local value it already had
		want = Vector3(
			conv.x if _axis_from_world.x > 0.5 else floating_point_at.x,
			conv.y if _axis_from_world.y > 0.5 else floating_point_at.y,
			conv.z if _axis_from_world.z > 0.5 else floating_point_at.z)
	var cl := Vector3(
		clampf(want.x, 0.0, axis_length),
		clampf(want.y, 0.0, axis_length),
		clampf(want.z, 0.0, axis_length))
	if not want.is_equal_approx(cl):
		push_warning("[CoordinateSystem3M] point start %s is outside the %.1f-unit frame at %s — clamped to %s"
			% [str(floating_point_at), axis_length, str(global_position), str(cl)])
	return cl


func _add_info_frame() -> void:
	var sc := 0.33  # Match SCENE_SCALE from VectorSceneBase
	var panel_pos := Vector3(0, 1.2, -0.5) * sc
	var panel_size := Vector2(1.4, 0.8) * sc
	var title_height := 0.12 * sc
	var gap := 0.025 * sc

	var panel := Node3D.new()
	panel.name = "InfoPanel"
	panel.position = panel_pos
	add_child(panel)

	# Title bar
	var title_panel := Node3D.new()
	title_panel.name = "TitlePanel"
	title_panel.position.y = panel_size.y / 2.0 + title_height / 2.0 + gap
	panel.add_child(title_panel)

	var title_backing := MeshInstance3D.new()
	var title_box := BoxMesh.new()
	title_box.size = Vector3(panel_size.x, title_height, 0.01 * sc)
	title_backing.mesh = title_box
	var title_mat := StandardMaterial3D.new()
	title_mat.albedo_color = Color(0.06, 0.07, 0.1, 0.95)
	title_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	title_mat.render_priority = -10
	title_backing.material_override = title_mat
	title_panel.add_child(title_backing)

	var title_label := Label3D.new()
	title_label.text = "COORDINATE SYSTEM"
	title_label.pixel_size = 0.0015
	title_label.font_size = 28
	title_label.modulate = Color.WHITE
	title_label.no_depth_test = false  # occlude behind walls/boards, don't bleed through
	title_label.render_priority = 0
	title_label.outline_size = 4
	title_label.outline_modulate = Color(0.0, 0.0, 0.0, 0.8)
	title_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	title_label.position.z = 0.08 * sc
	title_panel.add_child(title_label)

	# Main backing
	var backing := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = Vector3(panel_size.x, panel_size.y, 0.01 * sc)
	backing.mesh = box
	var back_mat := StandardMaterial3D.new()
	back_mat.albedo_color = Color(0.04, 0.05, 0.07, 0.95)
	back_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	back_mat.render_priority = -10
	backing.material_override = back_mat
	panel.add_child(backing)

	# Formula
	var content_top := panel_size.y / 2.0 - 0.03 * sc
	var formula_label := Label3D.new()
	formula_label.text = "P = (x, y, z)"
	formula_label.pixel_size = 0.0015
	formula_label.font_size = 22
	formula_label.modulate = Color(0.85, 0.95, 1.0)
	formula_label.no_depth_test = false  # occlude behind walls/boards
	formula_label.render_priority = 0
	formula_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	formula_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	formula_label.position = Vector3(0, content_top, 0.08 * sc)
	panel.add_child(formula_label)

	# Accent line
	var accent := MeshInstance3D.new()
	var accent_box := BoxMesh.new()
	accent_box.size = Vector3(panel_size.x * 0.6, 0.002 * sc, 0.005 * sc)
	accent.mesh = accent_box
	var accent_mat := StandardMaterial3D.new()
	accent_mat.albedo_color = Color(0.4, 0.7, 1.0)
	accent_mat.emission_enabled = true
	accent_mat.emission = Color(0.3, 0.5, 0.8)
	accent_mat.emission_energy_multiplier = 1.5
	accent.material_override = accent_mat
	accent.position = Vector3(0, content_top - 0.05 * sc, 0.003 * sc)
	panel.add_child(accent)

	# Description
	var desc_label := Label3D.new()
	desc_label.text = "Three perpendicular axes define 3D space"
	desc_label.pixel_size = 0.0015
	desc_label.font_size = 16
	desc_label.modulate = Color(0.55, 0.6, 0.65)
	desc_label.no_depth_test = false  # occlude behind walls/boards
	desc_label.render_priority = 0
	desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	desc_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	desc_label.position = Vector3(0, content_top - 0.12 * sc, 0.08 * sc)
	panel.add_child(desc_label)

func _add_gyroscope() -> void:
	gyroscope = GyroscopeGadgetScript.new()
	gyroscope.position = Vector3(-1.5, 0.5, 0)
	add_child(gyroscope)

func create_axis(direction: Vector3, color: Color, label_text: String) -> void:
	# Build a CoordinateLine instance for the shaft + arrow + ticks. Its internal
	# geometry is along +X; we rotate the whole node to point at `direction`.
	# This replaces the inline CylinderMesh+cone duplication that used to live
	# here. The migration ensures tick marks propagate to every consumer
	# (xyz_slider_plate, etc.) without changes there.
	var axis_node: Node3D = Node3D.new()
	axis_node.script = CoordinateLineScript
	axis_node.length = axis_length
	axis_node.thickness = axis_thickness
	axis_node.color = color
	axis_node.arrow_size = axis_thickness * 4.0       # match the old cone proportions
	axis_node.from_origin = true                       # axis starts at origin, extends +length
	axis_node.unshaded = true                          # match the old unshaded look
	axis_node.alpha = 0.5                              # match the old 50% transparent look
	axis_node.show_ticks = tick_step > 0.0
	axis_node.tick_step = tick_step
	axis_node.tick_size = axis_thickness * 2.5         # tick crosses are a bit wider than the shaft
	axis_node.tick_thickness = axis_thickness * 0.6    # tick bars thinner than the shaft

	# Rotate axis_node from local +X to the world direction. Three cases for the
	# standard right-handed frame; falls back to a general from-+X rotation for
	# any other unit vector.
	if direction == Vector3.RIGHT:
		pass                                            # identity — already points along +X
	elif direction == Vector3.UP:
		axis_node.rotate(Vector3.FORWARD, deg_to_rad(-90.0))   # +X → +Y
	elif direction == Vector3.BACK:
		axis_node.rotate(Vector3.UP, deg_to_rad(90.0))         # +X → +Z (Godot Vector3.BACK = +Z)
	else:
		var from := Vector3.RIGHT
		var d := direction.normalized()
		if from.cross(d).length_squared() > 1e-8:
			var rot_axis := from.cross(d).normalized()
			var angle := from.angle_to(d)
			axis_node.rotate(rot_axis, angle)
	add_child(axis_node)

	# Label (Label3D) — kept here so the label-positioning logic stays a
	# CoordinateSystem3M concern. CoordinateLine doesn't ship a label.
	# Gated: with show_labels off the letters live on the hall's
	# coordinate_readout wall works instead of floating at the axis tips.
	if not show_labels:
		return
	var label = Label3D.new()
	label.text = label_text
	label.modulate = color
	label.font_size = 64
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.position = direction * (axis_length + 0.2)
	add_child(label)

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## ── THE PROJECTION (2026-08-24, Palle: "add a grab point and indicate the
## position along axels") ────────────────────────────────────────────────────
## While the grab point exists, three axis-coloured markers ride the axes at
## its x, y and z, joined to the point by thin guide lines — the position is
## INDICATED on the frame; the WORDS go to the hall's coordinate_readout
## displays (group "ada_coordinate_readout"), not to floating labels.
func _find_point() -> Node3D:
	if _fp_ref != null and is_instance_valid(_fp_ref):
		return _fp_ref
	_fp_ref = get_node_or_null("FloatingPoint") as Node3D
	return _fp_ref


func _ensure_projection() -> void:
	if not _axis_markers.is_empty():
		return
	var cols: Array = [Color.RED, Color.GREEN, Color.BLUE]
	for i in range(3):
		var m := MeshInstance3D.new()
		var sm := SphereMesh.new()
		sm.radius = maxf(0.02, axis_thickness * 3.0)
		sm.height = sm.radius * 2.0
		m.mesh = sm
		var mat := StandardMaterial3D.new()
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.albedo_color = cols[i]
		mat.emission_enabled = true
		mat.emission = cols[i]
		m.material_override = mat
		m.name = "AxisMarker%d" % i
		add_child(m)
		_axis_markers.append(m)
	_proj_mesh = ImmediateMesh.new()
	_proj_lines = MeshInstance3D.new()
	_proj_lines.mesh = _proj_mesh
	var lm := StandardMaterial3D.new()
	lm.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	lm.albedo_color = Color(1, 1, 1, 0.35)
	lm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_proj_lines.material_override = lm
	_proj_lines.name = "AxisProjection"
	add_child(_proj_lines)


func _process(_delta: float) -> void:
	if Engine.is_editor_hint():
		return
	var pt := _find_point()
	if pt == null:
		if _proj_lines != null:
			_proj_lines.visible = false
			for mk in _axis_markers:
				(mk as Node3D).visible = false
		return
	_ensure_projection()
	# frame-local coordinates survive a grab's re-parenting: read the GLOBAL
	# position back through this frame (to_local includes the display scale)
	var lp: Vector3 = to_local(pt.global_position)
	var cl := Vector3(clampf(lp.x, 0.0, axis_length), clampf(lp.y, 0.0, axis_length), clampf(lp.z, 0.0, axis_length))
	# THE POINT STAYS INSIDE THE LINES (2026-08-31, Palle: "the point is not inside
	# the x,y,z lines"). Only the MARKERS were clamped; the point and its guide
	# lines were drawn at the raw position, so a drag past the end of an axis left
	# the point outside the frame with its markers pinned at the corners — three
	# lines running off to a dot in mid-air. Clamping the body itself makes the
	# axis ends what they look like: walls. A held point stops there and stays held.
	if not lp.is_equal_approx(cl):
		pt.global_position = to_global(cl)
		lp = cl
	(_axis_markers[0] as Node3D).position = Vector3(cl.x, 0, 0)
	(_axis_markers[1] as Node3D).position = Vector3(0, cl.y, 0)
	(_axis_markers[2] as Node3D).position = Vector3(0, 0, cl.z)
	for mk in _axis_markers:
		(mk as Node3D).visible = true
	_proj_lines.visible = true
	_proj_mesh.clear_surfaces()
	_proj_mesh.surface_begin(Mesh.PRIMITIVE_LINES)
	for tgt_v in [Vector3(cl.x, 0, 0), Vector3(0, cl.y, 0), Vector3(0, 0, cl.z)]:
		_proj_mesh.surface_add_vertex(lp)
		_proj_mesh.surface_add_vertex(tgt_v as Vector3)
	_proj_mesh.surface_end()
	# the x,y,z TEXT lives on the hall's wall works — in WORLD units by default,
	# measured from Vector3.ZERO rather than from this frame's own origin.
	if is_inside_tree():
		var reported: Vector3 = pt.global_position if readout_space == "world" else lp
		for rd in get_tree().get_nodes_in_group("ada_coordinate_readout"):
			if rd.has_method("show_coordinates"):
				rd.show_coordinates(reported)


func apply_grid_config(config: Dictionary) -> void:
	# map_data tokens: CoordinateSystem3M:0:0#display_scale:1.5#tick_step:0.0
	#                  #readout_space:local  #point_scale:1.8  #point_energy:5.0
	if config.has("readout_space"):
		var rs: String = str(config["readout_space"]).to_lower().strip_edges()
		if rs in ["world", "local"]:
			readout_space = rs
	if config.has("point_scale"):
		point_scale = maxf(0.05, float(config["point_scale"]))
	if config.has("point_energy"):
		point_energy = maxf(0.0, float(config["point_energy"]))
	if config.has("display_scale"):
		display_scale = float(config["display_scale"])
		scale = Vector3(display_scale, display_scale, display_scale)
	if config.has("floating_point_space"):
		var sp: String = str(config["floating_point_space"]).to_lower().strip_edges()
		if sp in ["local", "world"]:
			floating_point_space = sp
	if config.has("floating_point_at"):
		var v: Variant = config["floating_point_at"]
		if v is Array and (v as Array).size() >= 3:
			floating_point_at = Vector3(float(v[0]), float(v[1]), float(v[2]))
		elif v is String:
			# a map token cannot carry an Array: `#floating_point_at:8,1.7,10`.
			# `same` on any axis KEEPS the value already in force, so a token can
			# move the point across the floor without also deciding its height —
			# Palle asked for "x: 8 y: same z:10", and the frame's own y offset is
			# edited from elsewhere, so a hardcoded world y would go stale the next
			# time somebody nudges the plinth.
			var parts: PackedStringArray = str(v).split(",", false)
			if parts.size() >= 3:
				var cur: Vector3 = floating_point_at
				floating_point_at = Vector3(
					cur.x if parts[0].strip_edges().to_lower() == "same" else float(parts[0]),
					cur.y if parts[1].strip_edges().to_lower() == "same" else float(parts[1]),
					cur.z if parts[2].strip_edges().to_lower() == "same" else float(parts[2]))
				_axis_from_world = Vector3(
					0.0 if parts[0].strip_edges().to_lower() == "same" else 1.0,
					0.0 if parts[1].strip_edges().to_lower() == "same" else 1.0,
					0.0 if parts[2].strip_edges().to_lower() == "same" else 1.0)
	if config.has("floating_point"):
		var fv: String = str(config["floating_point"])
		floating_point = (float(fv) != 0.0) if fv.is_valid_float() else (fv.to_lower() in ["true", "yes", "on"])
		# apply_grid_config may arrive BEFORE _ready (the museum's handoff): then
		# _ready builds it; after _ready it is added here
		if floating_point and not Engine.is_editor_hint() and is_node_ready() and is_inside_tree():
			_add_floating_point()
		elif not floating_point and get_node_or_null("FloatingPoint") != null:
			get_node("FloatingPoint").queue_free()
	# axis_length / axis_thickness / tick_step only affect the AXES, which
	# were already built in _ready() — so changing the vars alone does
	# nothing (the old bug: tick_step:0.0 was ignored, ticks stayed). Track
	# whether any axis-shaping value changed and rebuild the axes if so.
	var rebuild_axes := false
	if config.has("axis_length"):
		axis_length = float(config["axis_length"]); rebuild_axes = true
	if config.has("axis_thickness"):
		axis_thickness = float(config["axis_thickness"]); rebuild_axes = true
	if config.has("tick_step"):
		tick_step = float(config["tick_step"]); rebuild_axes = true
	# the BARE FRAME keys (2026-08-24): #labels:0 drops the axis letters,
	# #panel:0 drops the info panel — the words move to the wall works
	if config.has("labels"):
		var lv2: String = str(config["labels"])
		show_labels = (float(lv2) != 0.0) if lv2.is_valid_float() else (lv2.to_lower() in ["true", "yes", "on"])
		rebuild_axes = true
	if config.has("panel"):
		var pv2: String = str(config["panel"])
		show_panel = (float(pv2) != 0.0) if pv2.is_valid_float() else (pv2.to_lower() in ["true", "yes", "on"])
		var ip := get_node_or_null("InfoPanel")
		if ip != null and not show_panel:
			ip.queue_free()
	if rebuild_axes:
		_rebuild_axes()


# Rebuild just the three axes + their labels (used when axis_length /
# tick_step / axis_thickness change after _ready). Leaves the info panel and
# gyroscope intact.
func _rebuild_axes() -> void:
	for child in get_children():
		# Axis nodes carry the CoordinateLine script; their labels are Label3D
		# with single-letter text. Remove both; keep panel + gyroscope.
		if child is Label3D and child.text in ["X", "Y", "Z"]:
			child.queue_free()
		elif child.get_script() != null and \
				str(child.get_script().resource_path).ends_with("coordinate_line.gd"):
			child.queue_free()
	create_axis(Vector3.RIGHT, Color.RED, "X")
	create_axis(Vector3.UP, Color.GREEN, "Y")
	create_axis(Vector3.BACK, Color.BLUE, "Z")
