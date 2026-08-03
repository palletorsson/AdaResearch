# force_field_visualizer.gd
# Vector field visualization for forces
# Shows gravity, electric field, or custom fields as arrow grids
#
# QFEP: Fields as invisible structure — order you can't see until you probe it
#
# @identity
# essence: F(x) = vector at every point. The field precedes the particle. Space is not empty.
# desire: To show the invisible. To make the learner see that empty space carries instructions.
# critical_parameter: Field type (gravity/coulomb/dipole/vortex). Each is a different spatial grammar.
# triggers: Type button → topology changes (radial vs rotational vs superposed), strength slider → arrows grow/shrink
# emerges: Superposition from dipole (two sources cancel/reinforce). Curl from vortex. Convergence from gravity.
# needs: VR type buttons [has], strength slider [has], equation labels [has]. Could use: particle tracer following field lines.
# relationships: Feeds into ForcesSystems (particles in fields). Contrasts with vector_fields (same concept, different rendering).
#   Kin to [[wave_interference_tank]] and [[sine_wave_controller]] on the `evidence` axis — three
#   instruments, one ladder, the same question about how much working an instrument shows.
# truth: Motion is reading, not deciding. The field tells the particle where to go.
#
# DNA AXIS — evidence: how much of the field's arithmetic the grid puts on the table. The word and
#   its four rungs are taken character for character from [[wave_interference_tank]], which asks the
#   same question of a different phenomenon; a private synonym here would have split one family in
#   two. The ladder is monotone in disclosure — result (the sampled arrows alone, the legacy
#   default) < trace (the same arrows joined up into the paths a particle would take) < sources
#   (the equipotential family the source emits, so you can see WHERE the arrows come from) <
#   longhand (the two operands, |F| and F-hat, printed as separate plates above the grid, the
#   product below them).
# emerges: at `result` the field is a texture you accept; at `longhand` it is a multiplication you
#   can check, because both factors are visible side by side and the arrow below is their product.
#
# DNA AXIS — law: which of the four force laws the grid is a picture of. The @identity above has
#   named field_type critical since the file was written and the enum has always been live; what
#   was missing was any way for a map to say it, because apply_grid_config threw the key away.
#   gravity is uniform (position tells you nothing), point_charge is 1/r² from one well, dipole
#   is a SUM of two, vortex is curl with nothing entering or leaving. Deliberately not the word
#   `field` — see the block above the export for why the neighbouring VectorFieldFlow axis is a
#   different question wearing a similar name.
# emerges: the two axes are orthogonal on purpose — `law` changes what is true of the space and
#   `evidence` changes how much of the working is admitted, so the 4x4 grid asks whether a law
#   is easier to read when the instrument shows more of itself.

extends Node3D

class_name ForceFieldVisualizer

## Visualizes vector force fields as directional arrow grids.
## Computes field vectors (gravity, Coulomb, dipole, vortex) at each grid point
## and renders scaled, colored arrows via MultiMesh showing magnitude and direction.
## Key parameters: field_type selects the equation, field_strength scales magnitude,
## source_position sets the charge/vortex center.

# Arrow geometry constants
const SHAFT_RADIUS := 0.004
const SHAFT_HEIGHT := 0.05
const SHAFT_OFFSET := 0.025
const HEAD_BOTTOM_RADIUS := 0.012
const HEAD_HEIGHT := 0.02
const HEAD_OFFSET := 0.06
const EMISSION_ENERGY := 0.3
const SOURCE_RADIUS := 0.03
const SOURCE_EMISSION_ENERGY := 0.5
const LABEL_PIXEL_SIZE := 0.002
const BUTTON_LABEL_PIXEL_SIZE := 0.0008

## Size of the field grid in world units
@export_range(0.1, 5.0, 0.1) var field_size: float = 0.8
## Number of arrows per axis (total arrows = grid_resolution²)
@export_range(2, 32) var grid_resolution: int = 8

## Field type
enum FieldType { GRAVITY, POINT_CHARGE, DIPOLE, VORTEX, CUSTOM }

# Declared ahead of field_type because that property's setter reads _evidence_built, and an
# exported property can be assigned by the .tscn before this line would otherwise have run.
# A typed bool is false from construction, so the legacy path is safe either way — this is
# belt and braces, not a fix for a live bug.
var _evidence_root: Node3D
var _evidence_built: bool = false

## Which force field equation to visualize
@export var field_type: FieldType = FieldType.POINT_CHARGE:
	set(value):
		field_type = value
		_update_field()
		# A new equation is a new set of streamlines and a new equipotential family, so any
		# rung above `result` has to be rebuilt. Guarded on _evidence_built, which is false
		# until _ready has finished — and permanently false on the default rung, so the
		# legacy path never enters this branch at all.
		if _evidence_built:
			_rebuild_evidence()

## AXIS — WHICH LAW the space obeys. field_type has always been the @identity's declared
## critical_parameter ("each is a different spatial grammar") and has always been a live
## @export with a working setter — it was simply unreachable from a map token, because
## apply_grid_config discarded every key it was handed. This is the word-shaped face of that
## enum, so a token can name a law the way it names anything else.
##
##   gravity        F = (0, -g, 0). Constant everywhere: no source, no falloff, no centre.
##                  Every arrow the same length pointing the same way — the only rung where
##                  position carries no information at all
##   point_charge   F = k·r̂/r². One source, radial, inverse-square. The legacy default
##   dipole         F₊ + F₋. Two sources 0.2 m apart with opposite sign, so the picture is
##                  a SUM and the cancelling mid-line is drawn by arithmetic, not by a rule
##   vortex         tangent(r) · profile(|r|). Curl: nothing flows in or out, the arrows
##                  close on themselves and the source is an axis rather than a well
##
## NOT the word `field`, though [[VectorFieldFlow]] carries an axis by that name. Its four
## values (spiral · orbit · sink · source) are shapes ONE synthetic flow can be bent into;
## these four are named physical laws that fall off differently — and only two of them even
## have a counterpart over there, since a uniform field and a superposition have no shape-word
## in that list. Sharing the word while diverging on every value is the half-measure that
## makes a family look comparable when it is not.
@export_enum("gravity", "point_charge", "dipole", "vortex") var law: String = "point_charge":
	set(value):
		law = value
		# `as FieldType` mirrors the VR button handler below, which is the one place this
		# file already narrows an int to the enum.
		var picked: int = int(FIELD_LAWS.get(value, FieldType.POINT_CHARGE))
		field_type = picked as FieldType

## Allow-list, same contract as EVIDENCES: a typo falls back to the shipped law.
const LAWS: PackedStringArray = ["gravity", "point_charge", "dipole", "vortex"]

## The word → enum table. CUSTOM is deliberately absent: _calculate_field's `_:` branch
## returns Vector3.ZERO for it, which hides every arrow, so declaring it would put a blank
## rung in the sweep and call it a law.
const FIELD_LAWS := {
	"gravity": FieldType.GRAVITY,
	"point_charge": FieldType.POINT_CHARGE,
	"dipole": FieldType.DIPOLE,
	"vortex": FieldType.VORTEX,
}

## AXIS — HOW MUCH OF THE ARITHMETIC the grid puts on the table. Adopted word for word from
## [[wave_interference_tank]], which carries the same four rungs for superposition; the pair
## (and [[sine_wave_controller]], on the shorter three-rung version) ask one question in three
## bodies, so the words must not drift.
##
##   result    the 8x8 grid of scaled arrows alone — the shipped look, 6 rooms, byte for byte
##   trace     25 streamlines seeded on a 5x5 lattice and integrated 45 steps each way, drawn
##             as 6 mm emissive ribbons lying 8 mm over the base plate: the arrows joined up
##             into the paths a particle would actually take, so the local samples become one
##             continuous flow you can follow with a finger
##   sources   the equipotential family, six closed rings widening outward around every live
##             source (both of them under DIPOLE) — or, under GRAVITY where the source is a
##             plane and not a point, six straight parallel rules. The arrows stop being a
##             free-floating texture and acquire an origin
##   longhand  the two operands printed flat above the grid as a pair of 0.8 m texture plates
##             at y = 0.30 — MAGNITUDE on the left (log-scaled |F| through a black-orange-white
##             ramp) and DIRECTION on the right (the same field's angle as hue) — with the
##             product, the arrow grid itself, lying below them
##
## Rungs are APPEND-ONLY: everything hangs off one Evidence node added after the last legacy
## child, so no index or position above it moves. `result` builds nothing, not even the root.
@export_enum("result", "trace", "sources", "longhand") var evidence: String = "result"

## Allow-list. A typo in a map token falls back to the shipped look rather than stranding a
## placement with half an apparatus.
const EVIDENCES: PackedStringArray = ["result", "trace", "sources", "longhand"]

# --- Evidence apparatus (all null on the legacy default) ---
const EV_STREAM_SEEDS := 5          # 5x5 lattice of streamline seeds
const EV_STREAM_STEPS := 45         # integration steps each way from a seed
const EV_STREAM_DT := 0.012         # metres advanced per step (direction is normalised)
const EV_RIBBON_W := 0.003          # half-width of a streamline ribbon
const EV_RING_RADII := [0.05, 0.10, 0.16, 0.23, 0.31, 0.40]
const EV_RING_SEGMENTS := 72
const EV_PLATE_RES := 64            # texture resolution of a longhand operand plate
const EV_PLATE_Y := 0.30            # height the operand plates hang at

## Multiplier for field magnitude (0.1–5.0)
@export_range(0.1, 5.0, 0.1) var field_strength: float = 1.0:
	set(value):
		field_strength = clampf(value, 0.1, 5.0)
		_update_field()

## Source/charge position for point-based fields
@export var source_position: Vector3 = Vector3.ZERO:
	set(value):
		source_position = value
		if _source_marker:
			_source_marker.position = source_position
		_update_field()

## Color for outward/positive field directions
@export var color_positive: Color = Color(1.0, 0.3, 0.3)
## Color for inward/negative field directions
@export var color_negative: Color = Color(0.3, 0.5, 1.0)
## Color for field source markers
@export var color_source: Color = Color(1.0, 0.8, 0.3)

# MultiMesh arrow rendering
var _arrow_positions: Array[Vector3] = []
var _shaft_mm: MultiMesh
var _head_mm: MultiMesh
var _arrow_count: int = 0

# Scene nodes
var _source_marker: MeshInstance3D
var _source_2_marker: MeshInstance3D
var _info_label: Label3D
var _control_panel: Node3D
var _created_nodes: Array[Node] = []


func _ready() -> void:
	_create_base()
	_create_arrows()
	_create_source_markers()
	_create_labels()
	_create_vr_controls()
	_update_field()
	# Appended LAST, after every legacy child exists and after the arrows have been oriented,
	# so the default rung leaves the shipped tree untouched down to child order.
	_build_evidence()

func _exit_tree() -> void:
	for node in _created_nodes:
		if is_instance_valid(node):
			node.queue_free()
	_created_nodes.clear()

func _create_base() -> void:
	var base = MeshInstance3D.new()
	base.name = "Base"
	var plane = PlaneMesh.new()
	plane.size = Vector2(field_size, field_size)
	base.mesh = plane

	var mat = StandardMaterial3D.new()
	mat.albedo_color = Color(0.1, 0.1, 0.12, 0.3)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	base.material_override = mat
	base.position = Vector3(0, -0.01, 0)
	add_child(base)
	_created_nodes.append(base)

func _create_arrows() -> void:
	var cell_size = field_size / maxf(float(grid_resolution), 1.0)
	var half_size = field_size / 2.0
	_arrow_count = grid_resolution * grid_resolution

	# Pre-size position array
	_arrow_positions.resize(_arrow_count)
	var idx := 0
	for j in range(grid_resolution):
		for i in range(grid_resolution):
			var x = -half_size + (i + 0.5) * cell_size
			var z = -half_size + (j + 0.5) * cell_size
			_arrow_positions[idx] = Vector3(x, 0, z)
			idx += 1

	# Shared material for all arrow instances
	var arrow_mat := StandardMaterial3D.new()
	arrow_mat.vertex_color_use_as_albedo = true

	# Shaft MultiMesh (cylinder bodies)
	var shaft_mesh := CylinderMesh.new()
	shaft_mesh.top_radius = SHAFT_RADIUS
	shaft_mesh.bottom_radius = SHAFT_RADIUS
	shaft_mesh.height = SHAFT_HEIGHT

	_shaft_mm = MultiMesh.new()
	_shaft_mm.transform_format = MultiMesh.TRANSFORM_3D
	_shaft_mm.use_colors = true
	_shaft_mm.mesh = shaft_mesh
	_shaft_mm.instance_count = _arrow_count

	var shaft_mmi := MultiMeshInstance3D.new()
	shaft_mmi.name = "ShaftMultiMesh"
	shaft_mmi.multimesh = _shaft_mm
	shaft_mmi.material_override = arrow_mat
	add_child(shaft_mmi)
	_created_nodes.append(shaft_mmi)

	# Head MultiMesh (cone tips)
	var head_mesh := CylinderMesh.new()
	head_mesh.top_radius = 0.0
	head_mesh.bottom_radius = HEAD_BOTTOM_RADIUS
	head_mesh.height = HEAD_HEIGHT

	_head_mm = MultiMesh.new()
	_head_mm.transform_format = MultiMesh.TRANSFORM_3D
	_head_mm.use_colors = true
	_head_mm.mesh = head_mesh
	_head_mm.instance_count = _arrow_count

	var head_mmi := MultiMeshInstance3D.new()
	head_mmi.name = "HeadMultiMesh"
	head_mmi.multimesh = _head_mm
	head_mmi.material_override = arrow_mat
	add_child(head_mmi)
	_created_nodes.append(head_mmi)

func _create_source_markers() -> void:
	_source_marker = MeshInstance3D.new()
	_source_marker.name = "SourceMarker"
	var sphere = SphereMesh.new()
	sphere.radius = SOURCE_RADIUS
	sphere.height = SOURCE_RADIUS * 2.0
	_source_marker.mesh = sphere

	var mat = StandardMaterial3D.new()
	mat.albedo_color = color_source
	mat.emission_enabled = true
	mat.emission = color_source
	mat.emission_energy_multiplier = SOURCE_EMISSION_ENERGY
	_source_marker.material_override = mat
	_source_marker.position = source_position
	add_child(_source_marker)
	_created_nodes.append(_source_marker)

	# Second source for dipole
	_source_2_marker = MeshInstance3D.new()
	_source_2_marker.name = "Source2Marker"
	_source_2_marker.mesh = sphere.duplicate()
	var mat2 = StandardMaterial3D.new()
	mat2.albedo_color = color_negative
	mat2.emission_enabled = true
	mat2.emission = color_negative
	mat2.emission_energy_multiplier = SOURCE_EMISSION_ENERGY
	_source_2_marker.material_override = mat2
	_source_2_marker.visible = false
	add_child(_source_2_marker)
	_created_nodes.append(_source_2_marker)

func _create_labels() -> void:
	_info_label = Label3D.new()
	_info_label.name = "InfoLabel"
	_info_label.pixel_size = LABEL_PIXEL_SIZE
	_info_label.font_size = 16
	_info_label.position = Vector3(0, 0.2, 0)
	_info_label.text = "FORCE FIELD"
	add_child(_info_label)
	_created_nodes.append(_info_label)

func _create_vr_controls() -> void:
	var RackTpl: GDScript = load("res://commons/audio/rack_templates/RackTemplates.gd")
	_control_panel = RackTpl.create_panel("FORCE FIELD", [
		[
			{"type": "slider_h", "label": "STRENGTH", "default": (field_strength - 0.1) / 4.9},
		],
		[
			{"type": "button", "label": "GRAVITY"},
			{"type": "button", "label": "CHARGE"},
			{"type": "button", "label": "DIPOLE"},
			{"type": "button", "label": "VORTEX"},
		],
	])
	_control_panel.position = Vector3(0, 0.02, field_size / 2.0 + 0.15)
	_control_panel.rotation_degrees = Vector3(-30, 0, 0)
	add_child(_control_panel)
	_created_nodes.append(_control_panel)

	# Strength slider
	var strength_slider = _control_panel.find_child("Param_0", true, false)
	if strength_slider and strength_slider.has_signal("slider_moved"):
		strength_slider.slider_moved.connect(func(_pos):
			if strength_slider.has_method("get_normalized_value"):
				field_strength = 0.1 + strength_slider.get_normalized_value() * 4.9
		)

	# Field type buttons
	var type_names = ["GRAVITY", "CHARGE", "DIPOLE", "VORTEX"]
	for i in range(type_names.size()):
		var btn: Node = _control_panel.find_child("Btn_%d" % i, true, false)
		if btn:
			var type_idx = i
			var area = btn.get_node_or_null("InteractableAreaButton")
			if area:
				area.button_pressed.connect(func(_b): field_type = type_idx as FieldType)

func _update_field() -> void:
	if not _shaft_mm:
		return
	for i in _arrow_count:
		var pos = _arrow_positions[i]
		var field = _calculate_field(pos)
		_orient_arrow(i, pos, field)

	# Update source visibility
	if _source_marker:
		_source_marker.visible = field_type in [FieldType.POINT_CHARGE, FieldType.DIPOLE, FieldType.VORTEX]
	if _source_2_marker:
		_source_2_marker.visible = field_type == FieldType.DIPOLE
		if field_type == FieldType.DIPOLE:
			_source_2_marker.position = source_position + Vector3(0.2, 0, 0)

	_update_info()

func _calculate_field(pos: Vector3) -> Vector3:
	match field_type:
		FieldType.GRAVITY:
			return Vector3(0, -field_strength, 0)

		FieldType.POINT_CHARGE:
			var r = pos - source_position
			var dist = r.length()
			if dist < 0.01:
				return Vector3.ZERO
			# Inverse square: F = k/r²
			return r.normalized() * field_strength / (dist * dist + 0.01)

		FieldType.DIPOLE:
			var pos1 = source_position
			var pos2 = source_position + Vector3(0.2, 0, 0)

			var r1 = pos - pos1
			var r2 = pos - pos2
			var d1 = r1.length()
			var d2 = r2.length()

			var field1 = r1.normalized() * field_strength / (d1 * d1 + 0.01) if d1 > 0.01 else Vector3.ZERO
			var field2 = -r2.normalized() * field_strength / (d2 * d2 + 0.01) if d2 > 0.01 else Vector3.ZERO

			return field1 + field2

		FieldType.VORTEX:
			var r = pos - source_position
			var dist = r.length()
			if dist < 0.01:
				return Vector3.ZERO
			# Tangent field: cross(up, r) gives perpendicular direction (counterclockwise)
			var tangent = Vector3(-r.z, 0, r.x).normalized()
			# Strength peaks at mid-range, fades at center and edges (vortex profile)
			var profile = dist / (dist * dist + 0.02)
			return tangent * field_strength * profile

		_:
			return Vector3.ZERO

func _orient_arrow(idx: int, pos: Vector3, field: Vector3) -> void:
	var magnitude = field.length()

	if magnitude < 0.001:
		# Hide instance by scaling to near-zero and moving off-screen
		var hidden_xf := Transform3D(Basis.IDENTITY.scaled(Vector3.ONE * 0.001), Vector3(0, -100, 0))
		_shaft_mm.set_instance_transform(idx, hidden_xf)
		_head_mm.set_instance_transform(idx, hidden_xf)
		return

	# Scale arrow by field magnitude (clamped)
	var scale_factor = clampf(magnitude * 0.5, 0.3, 2.0)

	# Color by direction (outward=red, inward=blue)
	var direction = field.normalized()
	var from_source = (pos - source_position).normalized()
	var alignment = direction.dot(from_source)  # 1=outward, -1=inward

	var color: Color
	if field_type == FieldType.GRAVITY:
		color = color_negative  # Always down
	elif field_type == FieldType.VORTEX:
		# Vortex uses angular hue: green→cyan→blue around the circle
		var r = pos - source_position
		var angle = atan2(r.x, r.z)
		var hue = fmod((angle + PI) / TAU + 0.3, 1.0)
		color = Color.from_hsv(hue, 0.7, 1.0)
	else:
		color = color_negative.lerp(color_positive, (alignment + 1.0) / 2.0)

	_shaft_mm.set_instance_color(idx, color)
	_head_mm.set_instance_color(idx, color)

	# Compute arrow orientation
	var up := Vector3.UP
	if abs(direction.dot(up)) > 0.99:
		up = Vector3.FORWARD

	var arrow_xf := Transform3D()
	arrow_xf.origin = pos
	arrow_xf = arrow_xf.looking_at(pos + field, up)
	arrow_xf.basis = arrow_xf.basis * Basis(Vector3.RIGHT, -PI / 2.0)
	arrow_xf.basis = arrow_xf.basis.scaled(Vector3(scale_factor, scale_factor, scale_factor))

	# Shaft at local offset
	var shaft_origin = arrow_xf.origin + arrow_xf.basis * Vector3(0, SHAFT_OFFSET, 0)
	_shaft_mm.set_instance_transform(idx, Transform3D(arrow_xf.basis, shaft_origin))

	# Head at local offset
	var head_origin = arrow_xf.origin + arrow_xf.basis * Vector3(0, HEAD_OFFSET, 0)
	_head_mm.set_instance_transform(idx, Transform3D(arrow_xf.basis, head_origin))

func _update_info() -> void:
	var type_names = ["GRAVITY", "POINT CHARGE", "DIPOLE", "VORTEX", "CUSTOM"]
	var desc := ""
	match field_type:
		FieldType.GRAVITY:
			desc = "F = (0, -g, 0)  uniform downward"
		FieldType.POINT_CHARGE:
			desc = "F = k * r / |r|³  inverse-square"
		FieldType.DIPOLE:
			desc = "F = F₊ + F₋  two opposing charges"
		FieldType.VORTEX:
			desc = "F = tangent(r) × profile(|r|)  curl field"
		_:
			desc = ""
	_info_label.text = "%s FIELD\nStrength: %.1f\n%s" % [type_names[field_type], field_strength, desc]

func _input(event) -> void:
	if event is InputEventKey and event.pressed:
		match event.keycode:
			KEY_1: field_type = FieldType.GRAVITY
			KEY_2: field_type = FieldType.POINT_CHARGE
			KEY_3: field_type = FieldType.DIPOLE
			KEY_4: field_type = FieldType.VORTEX
			KEY_UP: field_strength = minf(field_strength + 0.2, 5.0)
			KEY_DOWN: field_strength = maxf(field_strength - 0.2, 0.1)

func set_field_type(type: FieldType) -> void:
	field_type = type

func set_strength(s: float) -> void:
	field_strength = s

func move_source(pos: Vector3) -> void:
	source_position = pos

## LATENT BUG, now closed for the two keys that are axes (was force_field_visualizer.gd:399,
## the whole body was `pass`). The artifact advertised a configuration hook and silently
## discarded every key a map handed it, so field_type / field_strength / source_position — the
## three things the @identity calls critical — were unreachable from a map token even though all
## three are live @exports with working setters.
##
## The 2026-08-02 pass read `evidence` and left field_type unread on the grounds that changing
## which law a room teaches is a curriculum decision. That was half right and is revised here: it
## IS a curriculum decision, which is exactly why it belongs to whoever writes the map token
## rather than to nobody. Nothing changes for a room that does not name it — `law` defaults to
## point_charge, the shipped enum default, and none of the 6 existing placements passes the key.
##
## field_strength and source_position stay unread. They are dials on the same law rather than a
## choice between laws, they already have VR controls a visitor can move, and a still cannot tell
## a stronger field from a nearer one. Reported, not silently widened.
func apply_grid_config(config_data: Dictionary) -> void:
	# LAW FIRST. Setting it rebuilds the apparatus only when one is already standing, and at
	# this point the default rung has built none — so the streamlines and rings below get
	# integrated against the final law instead of the old one and then thrown away.
	if config_data.has("law"):
		var picked: String = str(config_data["law"]).strip_edges().to_lower()
		if LAWS.has(picked) and picked != law:
			law = picked
	if config_data.has("evidence"):
		var word: String = str(config_data["evidence"]).strip_edges().to_lower()
		evidence = word if EVIDENCES.has(word) else evidence
		_rebuild_evidence()


# ── Evidence axis ─────────────────────────────────────────────────────
# Every rung's geometry hangs off one Evidence node and only there, so a changed token can drop
# the whole apparatus and build a different one without touching an arrow.

func _rebuild_evidence() -> void:
	_teardown_evidence()
	_build_evidence()


func _teardown_evidence() -> void:
	if is_instance_valid(_evidence_root):
		_created_nodes.erase(_evidence_root)
		remove_child(_evidence_root)
		_evidence_root.queue_free()
	_evidence_root = null
	_evidence_built = false


func _build_evidence() -> void:
	match evidence:
		"trace":
			_ev_root()
			_ev_streamlines()
		"sources":
			_ev_root()
			_ev_equipotentials()
		"longhand":
			_ev_root()
			_ev_operand_plates()
		_:
			return                                # "result" — the legacy lineage, nothing added
	_evidence_built = true


func _ev_root() -> void:
	_evidence_root = Node3D.new()
	_evidence_root.name = "Evidence"
	add_child(_evidence_root)
	_created_nodes.append(_evidence_root)


## Unshaded emissive material for the drawn apparatus — the arrows are lit geometry, the working
## is drawn ON TOP of the world rather than in it, which is the whole point of showing it.
func _ev_line_material(tint: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.albedo_color = tint
	mat.emission_enabled = true
	mat.emission = tint
	mat.emission_energy_multiplier = 1.6
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## TRACE — the arrows joined up. Seeds on a 5x5 lattice, integrated both ways along the
## normalised field so step length is uniform and a strong region does not eat the budget.
func _ev_streamlines() -> void:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.name = "Streamlines"
	mi.mesh = im
	mi.material_override = _ev_line_material(Color(0.55, 0.95, 1.0))
	_evidence_root.add_child(mi)

	var half: float = field_size * 0.5
	var step: float = field_size / float(EV_STREAM_SEEDS + 1)
	for j in range(EV_STREAM_SEEDS):
		for i in range(EV_STREAM_SEEDS):
			var seed_pos := Vector3(-half + step * float(i + 1), 0.0, -half + step * float(j + 1))
			var back: Array[Vector3] = _ev_integrate(seed_pos, -1.0)
			var fwd: Array[Vector3] = _ev_integrate(seed_pos, 1.0)
			var path: Array[Vector3] = []
			for k in range(back.size()):
				path.append(back[back.size() - 1 - k])
			path.append(seed_pos)
			path.append_array(fwd)
			_ev_ribbon(im, path, EV_RIBBON_W, 0.008)


## March the normalised field from `start`; sign_dir = +1 downstream, -1 upstream. Stops at the
## plate edge or wherever the field dies (the centre of a vortex, the surface of a charge).
func _ev_integrate(start: Vector3, sign_dir: float) -> Array[Vector3]:
	var out: Array[Vector3] = []
	var p: Vector3 = start
	var half: float = field_size * 0.5
	for _s in range(EV_STREAM_STEPS):
		var f: Vector3 = _calculate_field(p)
		if f.length() < 0.0001:
			break
		p = p + f.normalized() * (EV_STREAM_DT * sign_dir)
		# The y bound matters only under GRAVITY, whose streamlines are the one family that
		# leaves the plate: they fall straight out of it, which is exactly what a uniform
		# downward field does and is worth seeing rather than suppressing.
		if absf(p.x) > half or absf(p.z) > half or absf(p.y) > half:
			break
		out.append(p)
	return out


## A flat ribbon along a polyline, lying `lift` above the base plate. Line primitives render one
## pixel wide and would be measured as noise; a ribbon is geometry.
func _ev_ribbon(im: ImmediateMesh, path: Array[Vector3], half_w: float, lift: float) -> void:
	if path.size() < 2:
		return
	im.surface_begin(Mesh.PRIMITIVE_TRIANGLE_STRIP)
	for i in range(path.size()):
		var a: Vector3 = path[i]
		var b: Vector3 = path[mini(i + 1, path.size() - 1)]
		if i == path.size() - 1:
			b = a + (a - path[i - 1])
		var dir: Vector3 = b - a
		dir.y = 0.0                               # a purely vertical run (GRAVITY) falls through
		if dir.length() < 0.00001:                # to RIGHT, so its ribbon widens across Z
			dir = Vector3.RIGHT
		var perp: Vector3 = Vector3(-dir.z, 0.0, dir.x).normalized() * half_w
		var base := Vector3(a.x, a.y + lift, a.z)
		im.surface_add_vertex(base + perp)
		im.surface_add_vertex(base - perp)
	im.surface_end()


## SOURCES — where the arrows come from. A point source emits a family of nested equipotential
## rings; a uniform field's source is a plane, and in plan view a plane reads as parallel rules.
func _ev_equipotentials() -> void:
	var im := ImmediateMesh.new()
	var mi := MeshInstance3D.new()
	mi.name = "Equipotentials"
	mi.mesh = im
	mi.material_override = _ev_line_material(Color(1.0, 0.82, 0.42))
	_evidence_root.add_child(mi)

	var half: float = field_size * 0.5
	if field_type == FieldType.GRAVITY or field_type == FieldType.CUSTOM:
		for i in range(EV_RING_RADII.size()):
			var z: float = -half + field_size * (float(i) + 0.5) / float(EV_RING_RADII.size())
			var rule: Array[Vector3] = [Vector3(-half, 0.0, z), Vector3(half, 0.0, z)]
			_ev_ribbon(im, rule, EV_RIBBON_W * 1.4, 0.006)
		return

	var centres: Array[Vector3] = [source_position]
	if field_type == FieldType.DIPOLE:
		centres.append(source_position + Vector3(0.2, 0, 0))
	for c in centres:
		for r in EV_RING_RADII:
			var ring: Array[Vector3] = []
			for s in range(EV_RING_SEGMENTS + 1):
				var a: float = TAU * float(s) / float(EV_RING_SEGMENTS)
				ring.append(c + Vector3(cos(a) * float(r), 0.0, sin(a) * float(r)))
			_ev_ribbon(im, ring, EV_RIBBON_W * 1.4, 0.006)


## LONGHAND — the multiplication written out. An arrow is |F| times F-hat, and the shipped grid
## shows only the product; these two plates show the factors, printed flat above the field so the
## product lies underneath them and can be read against both.
func _ev_operand_plates() -> void:
	var mag_img := Image.create(EV_PLATE_RES, EV_PLATE_RES, false, Image.FORMAT_RGB8)
	var dir_img := Image.create(EV_PLATE_RES, EV_PLATE_RES, false, Image.FORMAT_RGB8)
	var half: float = field_size * 0.5
	var mags := PackedFloat32Array()
	mags.resize(EV_PLATE_RES * EV_PLATE_RES)
	var peak: float = 0.0
	var idx: int = 0
	for j in range(EV_PLATE_RES):
		for i in range(EV_PLATE_RES):
			var x: float = -half + field_size * (float(i) + 0.5) / float(EV_PLATE_RES)
			var z: float = -half + field_size * (float(j) + 0.5) / float(EV_PLATE_RES)
			var f: Vector3 = _calculate_field(Vector3(x, 0.0, z))
			var m: float = f.length()
			mags[idx] = m
			idx += 1
			peak = maxf(peak, m)
			var ang: float = atan2(f.z, f.x)
			var hue: float = fmod((ang + PI) / TAU, 1.0)
			var sat: float = 0.85 if m > 0.00001 else 0.0
			dir_img.set_pixel(i, j, Color.from_hsv(hue, sat, 1.0))
	# Log scaling: an inverse-square field spans four decades, and a linear ramp would print one
	# white dot on a black square. The ramp is black -> orange -> white, the same warm family the
	# source marker already uses.
	var denom: float = log(1.0 + peak)
	idx = 0
	for j in range(EV_PLATE_RES):
		for i in range(EV_PLATE_RES):
			var v: float = 0.0
			if denom > 0.00001:
				v = clampf(log(1.0 + mags[idx]) / denom, 0.0, 1.0)
			idx += 1
			var col: Color = Color(0.04, 0.02, 0.02).lerp(Color(1.0, 0.55, 0.12), minf(v * 2.0, 1.0))
			if v > 0.5:
				col = col.lerp(Color(1.0, 1.0, 0.95), (v - 0.5) * 2.0)
			mag_img.set_pixel(i, j, col)

	var dx: float = field_size * 0.62
	_ev_plate(mag_img, Vector3(-dx, EV_PLATE_Y, 0.0), "|F|")
	_ev_plate(dir_img, Vector3(dx, EV_PLATE_Y, 0.0), "F-hat")

	var rule := Label3D.new()
	rule.name = "LonghandRule"
	rule.text = "F  =  |F|  x  F-hat"
	rule.pixel_size = LABEL_PIXEL_SIZE
	rule.font_size = 20
	rule.position = Vector3(0, EV_PLATE_Y + 0.02, 0)
	rule.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_evidence_root.add_child(rule)


func _ev_plate(img: Image, at: Vector3, caption: String) -> void:
	var tex := ImageTexture.create_from_image(img)
	var quad := QuadMesh.new()
	quad.size = Vector2(field_size, field_size)
	var mi := MeshInstance3D.new()
	mi.name = "Operand_%s" % caption
	mi.mesh = quad
	mi.rotation_degrees = Vector3(-90, 0, 0)      # lie flat, same plane as the field below
	mi.position = at
	var mat := StandardMaterial3D.new()
	mat.albedo_texture = tex
	mat.emission_enabled = true
	mat.emission_texture = tex
	mat.emission_energy_multiplier = 0.9
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.texture_filter = BaseMaterial3D.TEXTURE_FILTER_NEAREST
	mi.material_override = mat
	_evidence_root.add_child(mi)

	var cap := Label3D.new()
	cap.text = caption
	cap.pixel_size = LABEL_PIXEL_SIZE
	cap.font_size = 16
	cap.position = at + Vector3(0, 0.02, field_size * 0.5 + 0.04)
	cap.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_evidence_root.add_child(cap)
