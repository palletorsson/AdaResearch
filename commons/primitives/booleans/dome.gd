extends Node3D

# @identity
# essence: the boolean shelter's DNA head — a thin root over the authored CSG stack in dome.tscn (a 20 x 26 x 20 block with a sphere, two cylinders and a door box subtracted), restating the same subtraction at four moments of its own making
# desire: to let the reference enclosure admit HOW an enclosure is made by subtraction — the stock, the tools, the result and the autopsy are four photographs of one operation
# critical_parameter: facture — which moment of the boolean operation stands in the room; every dimension, every operand transform and the grid-wireframe material are the authored scene's and are never rewritten
# triggers: _ready() reads facture, returns immediately on the default, and otherwise detaches or re-stages the authored CSG operands; a capture fixture adds a layers = 0 anchor because CSG nodes are invisible to the MeshInstance3D-only capture AABB
# emerges: the recognition that a shelter made by subtraction is the shape of what was TAKEN — show the cores alone and the room you could walk into is revealed as four solids you never saw
# needs: the authored CSGBox3D and its four subtraction children [present, read live]; a MeshInstance3D capture anchor because CSG does not count toward the capture AABB [present, fixture-gated]; mesh stand-ins derived from each operand's own class and parameters [derived, never transcribed]
# relationships: adopts `facture` — the primitives tier's word for a state of making — from [[capsule]], [[folded_strip]] and [[platonic_grabbables]], with values adapted to a body whose making is an OPERATION rather than a surface; reference geometry for the proceduralgeneration sequence's enclosures
# truth: a boolean shelter is the interference pattern of solids that are no longer present. The room is real; everything that shaped it is gone — and facture is the right to see it again.

## AXIS — WHAT MOMENT OF THE MAKING THE BODY IS SHOWN AT. The operation never changes:
## the same stock, the same four cutting volumes at the same transforms, the same grid
## wireframe skin. What changes is which end of the subtraction you are standing at.
## The word is the primitives tier's `facture` (capsule, folded_strip,
## platonic_grabbables), adapted to a solid whose making is boolean: a capsule admits its
## tessellation, a dome admits its cuts.
##
##   cast     the finished subtraction — hollow, doored, walkable. The form as given.
##            THE SHIPPED LINEAGE, byte for byte: this branch touches nothing.
##   blank    the stock before the cuts: the four subtraction operands withdrawn and the
##            solid 20 x 26 x 20 block standing uncut. No door, no hollow — the claim
##            that before a shelter there was only material.
##   core     the cuts without the work: the block withdrawn and the four negative
##            volumes staged solid in its place, at their authored transforms, in the
##            authored skin. The sphere of air you stood in, the drum under the floor,
##            the plug and the doorway — the tools shown as things.
##   section  the operation opened: the front half of the result cut away on the z = 0
##            plane, straight through the hollow. The dollhouse read — wall thickness,
##            bowl and doorway in one view, the drawing convention made walkable.
@export_enum("cast", "blank", "core", "section") var facture: String = "cast"
const FACTURES: PackedStringArray = ["cast", "blank", "core", "section"]

## CAPTURE FIXTURE, not an axis, and OFF in every room. Every visible part of this
## artifact is CSG, and the capture AABB counts MeshInstance3D only — an unanchored sweep
## frames a 1 m fallback box and photographs a corner of a 26 m wall. True adds an
## invisible (layers = 0) box mesh matching the authored block's extent, identical at
## every facture value, so the frame is both correct and FIXED while the geometry
## changes. Untyped so a fixture string survives being assigned before _ready.
@export var capture_anchor = false

## The authored CSG root inside dome.tscn.
const CSG_NODE := "CSGBox3D"

var _csg: CSGBox3D = null
var _detached: Array[Node] = []
var _staged: Array[Node] = []


func _ready() -> void:
	_read_dna_meta()
	var f: String = str(facture).strip_edges().to_lower()
	facture = f if FACTURES.has(f) else "cast"

	_csg = get_node_or_null(CSG_NODE) as CSGBox3D

	# The anchor is built from the authored block's own size and position, so it stays
	# honest if the scene is ever re-dimensioned. Built for every value, before any
	# operand moves, because the frame must hold still while the geometry argues.
	if _is_true(capture_anchor) and _csg != null:
		_build_capture_anchor(_csg.size, _csg.position)

	# THE LEGACY PATH. "cast" is the scene exactly as authored — no operand is touched,
	# no node is staged. Nothing below runs.
	if facture == "cast":
		return

	_apply_facture()


## The grid stamps `config_*` metadata BEFORE add_child, so this runs ahead of the
## build. An unknown word keeps the default; no metadata, no change — which is all
## existing placements.
func _read_dna_meta() -> void:
	if has_meta("config_facture"):
		var f: String = str(get_meta("config_facture")).strip_edges().to_lower()
		facture = f if FACTURES.has(f) else facture
	if has_meta("config_capture_anchor"):
		capture_anchor = get_meta("config_capture_anchor")


## Late config honours only the facture key. Operands are DETACHED rather than freed, so
## a second word can restore the baseline and re-apply — switching claims twice does not
## lose the authored scene.
func apply_grid_config(config_data: Dictionary) -> void:
	if not config_data.has("facture"):
		return
	var f: String = str(config_data["facture"]).strip_edges().to_lower()
	if not FACTURES.has(f) or f == facture:
		return
	facture = f
	if is_node_ready():
		_apply_facture()


func _exit_tree() -> void:
	# Detached operands live outside the tree and would leak on scene teardown.
	for n in _detached:
		if is_instance_valid(n):
			n.queue_free()
	_detached.clear()


# ── FACTURE ──────────────────────────────────────────────────────────────────
# One axis, four moments of a subtraction. Appended LAST in the file and reached only
# off the default path: `cast` never arrives here. Baseline is restored before every
# apply, so the branches are idempotent.

func _apply_facture() -> void:
	_restore_baseline()
	if _csg == null:
		return
	match facture:
		"blank":
			# Withdraw the four cutting volumes; the uncut stock stands.
			for c in _cut_children():
				_csg.remove_child(c)
				_detached.append(c)
		"core":
			# Withdraw the work; stage each cutting volume as a solid mesh at its
			# authored transform, in the authored skin. Parameters are read from each
			# operand's own class — derived, never transcribed.
			var skin: Material = _csg.material_override
			var base: Transform3D = _csg.transform
			for c in _cut_children():
				var mi: MeshInstance3D = _stand_in_for(c)
				if mi == null:
					continue
				mi.transform = base * (c as Node3D).transform
				mi.material_override = skin
				add_child(mi)
				_staged.append(mi)
			remove_child(_csg)
			_detached.append(_csg)
		"section":
			# One more cut: everything forward of z = 0, straight through the hollow.
			# Margins overshoot outward only, so the cut plane lands exactly on the
			# sphere's own centre plane.
			var sz: Vector3 = _csg.size
			var cut := CSGBox3D.new()
			cut.name = "SectionCut"
			cut.operation = CSGShape3D.OPERATION_SUBTRACTION
			cut.size = Vector3(sz.x + 2.0, sz.y + 2.0, sz.z * 0.5 + 1.0)
			cut.position = Vector3(0.0, 0.0, (sz.z * 0.5 + 1.0) * 0.5)
			_csg.add_child(cut)
			_staged.append(cut)
		_:
			pass                                  # "cast": the baseline restore above IS the value


## Put the authored scene back exactly: re-attach whatever a previous value withdrew and
## free whatever it staged.
func _restore_baseline() -> void:
	for n in _staged:
		if is_instance_valid(n):
			var p: Node = n.get_parent()
			if p != null:
				p.remove_child(n)
			n.queue_free()
	_staged.clear()
	for n in _detached:
		if not is_instance_valid(n):
			continue
		if n == _csg:
			add_child(n)
		elif _csg != null:
			_csg.add_child(n)
	_detached.clear()


## The authored subtraction operands, read live.
func _cut_children() -> Array[Node]:
	var out: Array[Node] = []
	if _csg == null:
		return out
	for c in _csg.get_children():
		var shape: CSGShape3D = c as CSGShape3D
		if shape != null and shape.operation == CSGShape3D.OPERATION_SUBTRACTION:
			out.append(c)
	return out


## A solid MeshInstance3D shaped like one CSG operand, parameters read off the operand.
func _stand_in_for(c: Node) -> MeshInstance3D:
	var mesh: Mesh = null
	if c is CSGSphere3D:
		var s := SphereMesh.new()
		s.radius = (c as CSGSphere3D).radius
		s.height = s.radius * 2.0
		s.radial_segments = (c as CSGSphere3D).radial_segments
		s.rings = (c as CSGSphere3D).rings
		mesh = s
	elif c is CSGCylinder3D:
		var cy := CylinderMesh.new()
		cy.top_radius = (c as CSGCylinder3D).radius
		cy.bottom_radius = (c as CSGCylinder3D).radius
		cy.height = (c as CSGCylinder3D).height
		cy.radial_segments = (c as CSGCylinder3D).sides
		mesh = cy
	elif c is CSGBox3D:
		var b := BoxMesh.new()
		b.size = (c as CSGBox3D).size
		mesh = b
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = str(c.name) + "Core"
	mi.mesh = mesh
	return mi


## The frame-holder: an invisible box mesh at the authored block's extent. layers = 0
## renders nothing and propagates to no child, but the capture AABB walk still counts
## the mesh — the flashlight_demo pattern, needed here for the same reason (CSG does not
## count).
func _build_capture_anchor(size: Vector3, at: Vector3) -> void:
	var box := BoxMesh.new()
	box.size = size
	var mi := MeshInstance3D.new()
	mi.name = "CaptureAnchor"
	mi.mesh = box
	mi.position = at
	mi.layers = 0
	add_child(mi)


func _is_true(v) -> bool:
	return str(v).strip_edges().to_lower() in ["true", "1", "yes", "on"]
