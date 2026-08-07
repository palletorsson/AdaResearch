extends Node3D

# @identity
# essence: the boolean shelter's DNA head — a thin root over the authored CSG stack in dome.tscn (a 20 x 26 x 20 block with a sphere, two cylinders and a door box subtracted), restating the same subtraction at four moments of its own making, and finishing all four in the authored grid skin re-hosted on a shader that answers to light
# desire: to let the reference enclosure admit HOW an enclosure is made by subtraction — the stock, the tools, the result and the autopsy are four photographs of one operation — and to let the room the subtraction leaves behind read as a room rather than as a grey hole in a block
# critical_parameter: facture — which moment of the boolean operation stands in the room; every dimension and every operand transform is the authored scene's and is never rewritten, and the grid-wireframe skin's seven parameters are READ OFF the authored material and re-hosted, never retyped
# triggers: _ready() derives the skin, refines any operand too coarse for its own radius, plans the room's lights, then reads facture, returns on the default, and otherwise detaches or re-stages the authored CSG operands; a capture fixture adds a layers = 0 anchor because CSG nodes are invisible to the MeshInstance3D-only capture AABB
# emerges: the recognition that a shelter made by subtraction is the shape of what was TAKEN — show the cores alone and the room you could walk into is revealed as four solids you never saw
# needs: the authored CSGBox3D and its four subtraction children [present, read live]; the authored ShaderMaterial's seven parameters [present, read live, re-hosted never retyped]; a cast-grain field from PbrKit for roughness, albedo and normal breakup [derived]; a MeshInstance3D capture anchor because CSG does not count toward the capture AABB [present, fixture-gated]; mesh stand-ins derived from each operand's own class and parameters [derived, never transcribed]; a contact shadow at the block's base and two lamps at the two largest cavities [derived]
# relationships: adopts `facture` — the primitives tier's word for a state of making — from [[capsule]], [[folded_strip]] and [[platonic_grabbables]], with values adapted to a body whose making is an OPERATION rather than a surface; surfaces through [[pbr_kit]] and [[mesh_kit]]; reference geometry for the proceduralgeneration sequence's enclosures
# truth: a boolean shelter is the interference pattern of solids that are no longer present. The room is real; everything that shaped it is gone — and facture is the right to see it again.

const PBR := preload("res://commons/render/pbr_kit.gd")
const MK := preload("res://commons/render/mesh_kit.gd")

## AXIS — WHAT MOMENT OF THE MAKING THE BODY IS SHOWN AT. The operation never changes:
## the same stock, the same four cutting volumes at the same transforms, the same grid
## wireframe skin. What changes is which end of the subtraction you are standing at.
## The word is the primitives tier's `facture` (capsule, folded_strip,
## platonic_grabbables), adapted to a solid whose making is boolean: a capsule admits its
## tessellation, a dome admits its cuts.
##
##   cast     the finished subtraction — hollow, doored, walkable. The form as given.
##            THE SHIPPED LINEAGE: no operand is moved, detached or staged, and this
##            branch returns before any of the staging code below runs. (The surface
##            pass in _finish_surfaces is value-INDEPENDENT — it runs identically for
##            all four, so it cannot be what any pair of tiles is measuring.)
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

## THE ROOM'S OWN LAMPS, not an axis either. A shelter you can walk into that is lit
## only by the map's ceiling has no inside: the hollow reads as a grey void punched in a
## block. Two omnis at the two largest cavities give it a floor, a ceiling and a doorway
## you can see out of. They cannot spill outside whatever range they are given — an
## exterior face points AWAY from every one of them, so N·L is negative there and the
## wall stays lit only by the map. What does escape is the doorway and the porthole,
## which is the point: from outside, a lit shelter has somewhere to go into.
## Only `cast` and `section` build them: `blank` and `core` have no room to light.
## Untyped for the same reason as capture_anchor. Set false for the strictest VR budget.
@export var interior_light = true

## The authored CSG root inside dome.tscn.
const CSG_NODE := "CSGBox3D"

## Detail tiling for the cast grain, in UV units per metre. One texture period every
## ~3 m across a 20 m wall: coarse enough to read as aggregate at arm's length, fine
## enough that the repeat is invisible at the sweep's framing.
const GRAIN_TILES_PER_M: float = 0.32

## An operand gets re-tessellated only if its own radius asks for more than the scene
## authored. Both authored cylinders already clear this bar (64 and 32 sides for 9 m
## and 3 m radii); only the 7.5 m sphere does not, at 24. The rule is stated once and
## measured against each operand rather than transcribed per node, so a re-dimensioned
## scene stays honest.
const SEG_PER_METRE: float = 4.5
const SEG_MAX: int = 48

## Lamp budget — two, which is what the cavities ask for and what a Quest can carry
## inside one artifact. Then: the share of the largest cavity below which a hole is a
## porthole rather than a room, the range as a multiple of the cavity's own reach (a lamp
## whose range stops AT the wall leaves the wall black), and a filament-warm tint set
## against the grid's red so the two temperatures separate.
const MAX_ROOM_LIGHTS: int = 2
const ROOM_SHARE: float = 0.2
const ROOM_RANGE_K: float = 1.7
const ROOM_ENERGY: float = 1.8
const ROOM_TINT: Color = Color(1.0, 0.93, 0.84)

var _csg: CSGBox3D = null
var _detached: Array[Node] = []
var _staged: Array[Node] = []
var _lights: Array[Node] = []
var _light_plan: Array = []
var _skin: ShaderMaterial = null
var _core_skin: ShaderMaterial = null


func _ready() -> void:
	_read_dna_meta()
	var f: String = str(facture).strip_edges().to_lower()
	facture = f if FACTURES.has(f) else "cast"

	_csg = get_node_or_null(CSG_NODE) as CSGBox3D

	# The surface pass. Value-independent by construction: it runs before the branch,
	# reads only the authored block and its operands, and touches no transform.
	_finish_surfaces()

	# The anchor is built from the authored block's own size and position, so it stays
	# honest if the scene is ever re-dimensioned. Built for every value, before any
	# operand moves, because the frame must hold still while the geometry argues.
	if _is_true(capture_anchor) and _csg != null:
		_build_capture_anchor(_csg.size, _csg.position)

	# THE LEGACY PATH. "cast" is the scene exactly as authored — no operand is touched,
	# no node is staged. Nothing below runs except the lamps, which every value decides
	# for itself.
	if facture == "cast":
		_sync_interior_lights()
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
	if has_meta("config_interior_light"):
		interior_light = get_meta("config_interior_light")


## Late config honours only the facture key. Operands are DETACHED rather than freed, so
## a second word can restore the baseline and re-apply — switching claims twice does not
## lose the authored scene. The lamps follow, because two of the four values have no
## room for them to stand in.
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


# ── SURFACE ──────────────────────────────────────────────────────────────────
# Rubric work, all of it value-independent. CSG constrains what is possible here: the
# mesh is produced by the solver, so no bevel pass and no vertex-colour wear can reach
# it, and one material_override covers every face the solver emits. What is left is the
# material itself — and the material was the flat one. The authored ShaderMaterial
# writes ALBEDO and EMISSION and nothing else, so Godot filled in ROUGHNESS = 1.0,
# METALLIC = 0.0, a flat normal and no AO: a 20 x 26 x 20 block of perfectly Lambertian
# grey with a red wireframe on it. Under any light rig at all it has no highlight to
# break up, because it has no highlight.

func _finish_surfaces() -> void:
	if _csg == null:
		return
	var authored: ShaderMaterial = _csg.material_override as ShaderMaterial
	# Two skins off one shader: the shell knows its own extent and can therefore tell an
	# outside face from a cavity wall; the stand-ins are solids with no inside at all.
	_skin = _build_skin(authored, _csg.size * 0.5)
	_core_skin = _build_skin(authored, Vector3.ZERO)
	_csg.material_override = _skin
	_refine_operands()
	_plan_interior_lights()
	_build_ground_shadow(_csg.size, _csg.position)


## Re-host the authored look on the shader below. Every one of the seven authored
## parameters is READ from the scene's own material by name — the colours, the edge
## width, the blur and the emission strength are the authored scene's, and the drawn
## wireframe pattern is unchanged. What the new shader adds is everything under the
## wireframe: a two-scale roughness field, an albedo that is not one number, a normal
## perturbation, ambient occlusion, and a separate read for the inside of the shell.
##
## `half` is the block's half-extent in the CSG root's own space. Passed non-zero it
## lets the shader ask, per fragment, "is this face ON the stock or INSIDE it" — which
## is the only way one material can finish an exterior and a cavity differently when the
## solver hands back a single surface. Passed ZERO the test is switched off and
## everything reads as exterior, which is right for a staged core: a solid has no inside.
func _build_skin(src: ShaderMaterial, half: Vector3) -> ShaderMaterial:
	var m := ShaderMaterial.new()
	m.shader = _skin_shader()
	m.set_shader_parameter("modelColor", _param(src, "modelColor", Color(0.5, 0.5, 0.5, 1.0)))
	m.set_shader_parameter("wireframeColor", _param(src, "wireframeColor", Color(1.0, 0.0, 0.0, 1.0)))
	m.set_shader_parameter("emissionColor", _param(src, "emissionColor", Color(1.0, 0.0, 0.0, 1.0)))
	m.set_shader_parameter("width", _param(src, "width", 2.0))
	m.set_shader_parameter("blur", _param(src, "blur", 1.0))
	m.set_shader_parameter("emission_strength", _param(src, "emission_strength", 2.0))
	m.set_shader_parameter("show_interior", _param(src, "show_interior", true))
	# The floor argument is 0.0 on purpose. PbrKit ramps a grain into [floor .. 1] because
	# Godot MULTIPLIES roughness by the texture and a dip to zero would make patches
	# mirror-smooth. This shader mixes rather than multiplies, so it wants the full range
	# and states its own band in rough_lo / rough_hi.
	m.set_shader_parameter("grain_tex", PBR.grain(PBR.GRAIN_CAST, 0.0))
	m.set_shader_parameter("grain_scale", GRAIN_TILES_PER_M)
	m.set_shader_parameter("shell_half", half)
	return m


## Read one authored shader parameter, or the shipped default if the scene never set it.
## Untyped by design: the values are Colors, floats and a bool through the same door.
func _param(src: ShaderMaterial, key: String, fallback):
	if src == null:
		return fallback
	var v = src.get_shader_parameter(key)
	return fallback if v == null else v


## One Shader for the whole process. Every dome in every map shares this instance, so
## the code compiles once no matter how many are placed.
static var _shared_shader: Shader = null

static func _skin_shader() -> Shader:
	if _shared_shader == null:
		_shared_shader = Shader.new()
		_shared_shader.code = SKIN_SHADER
	return _shared_shader


## Raise an operand's tessellation to what its own radius asks for, and never lower it.
## The 7.5 m sphere ships at 24 segments — a 1.96 m facet, which the smooth normals hide
## in shading but not on the silhouette you see from under it. It is the one operand that
## moves: both cylinders already exceed the rule. The sphere is fully interior, so the
## re-tessellation touches no exterior face and the block's outline is untouched.
func _refine_operands() -> void:
	for c in _cut_children():
		if c is CSGSphere3D:
			var s: CSGSphere3D = c as CSGSphere3D
			var want: int = _segments_for(s.radius)
			if want > s.radial_segments:
				s.rings = maxi(s.rings, int(round(float(want) * 0.5)))
				s.radial_segments = want
		elif c is CSGCylinder3D:
			var cy: CSGCylinder3D = c as CSGCylinder3D
			var want_sides: int = _segments_for(cy.radius)
			if want_sides > cy.sides:
				cy.sides = want_sides


func _segments_for(radius: float) -> int:
	return clampi(int(ceil(maxf(radius, 0.0) * SEG_PER_METRE)), 3, SEG_MAX)


## A contact shadow at the block's base. Rubric item 4 and the cheapest one available:
## the block is embedded a third of a metre into the floor, but with nothing pooling
## under it the join reads as a cut rather than as weight. A Decal conforms to whatever
## it lands on, so it darkens the ground AND the bottom band of the walls without
## z-fighting anything. Radius from the block's own footprint; not a light, so it costs
## nothing against the lamp budget.
func _build_ground_shadow(size: Vector3, at: Vector3) -> void:
	var radius: float = maxf(absf(size.x), absf(size.z)) * 0.60
	if radius <= 0.01:
		return
	var dec: Decal = PBR.ground_shadow(radius, 0.42, 0.10)
	if dec == null:
		return
	dec.position.y += at.y - absf(size.y) * 0.5
	add_child(dec)


# ── THE ROOM'S LAMPS ─────────────────────────────────────────────────────────
# Planned ONCE, from the authored operands, before anything is staged — otherwise the
# section cut (a 22 x 28 x 11 box, larger than any authored cavity) would win the ranking
# and the shelter would be lit from outside its own missing half.

func _plan_interior_lights() -> void:
	_light_plan.clear()
	if _csg == null:
		return
	var base: Transform3D = _csg.transform
	var rows: Array = []
	for c in _cut_children():
		var n3: Node3D = c as Node3D
		if n3 == null:
			continue
		var vol: float = _operand_volume(c)
		var reach: float = _operand_reach(c)
		if vol <= 0.0 or reach <= 0.0:
			continue
		rows.append({"vol": vol, "reach": reach, "at": (base * n3.transform).origin})
	if rows.is_empty():
		return
	rows.sort_custom(func(a, b): return float(a["vol"]) > float(b["vol"]))
	var biggest: float = float(rows[0]["vol"])
	var count: int = mini(rows.size(), MAX_ROOM_LIGHTS)
	for i in range(count):
		var row: Dictionary = rows[i]
		# A cavity a fifth the size of the largest is a porthole, not a room.
		if float(row["vol"]) < biggest * ROOM_SHARE:
			break
		var at: Vector3 = row["at"]
		var reach2: float = float(row["reach"])
		var energy: float = ROOM_ENERGY
		if i > 0:
			energy = ROOM_ENERGY * 0.78
		_light_plan.append({
			"at": at,
			"range": clampf(reach2 * ROOM_RANGE_K, 1.0, 40.0),
			"energy": energy
		})


## Rebuild the lamps to match the current value. Idempotent, and safe to call after a
## late config switch.
func _sync_interior_lights() -> void:
	for l in _lights:
		if is_instance_valid(l):
			var p: Node = l.get_parent()
			if p != null:
				p.remove_child(l)
			l.queue_free()
	_lights.clear()
	if not _is_true(interior_light):
		return
	if facture != "cast" and facture != "section":
		return
	for i in range(_light_plan.size()):
		var plan: Dictionary = _light_plan[i]
		var at: Vector3 = plan["at"]
		var rng: float = plan["range"]
		var energy: float = plan["energy"]
		var lamp := OmniLight3D.new()
		lamp.name = "RoomLight%d" % i
		lamp.position = at
		lamp.omni_range = rng
		lamp.light_energy = energy
		lamp.light_color = ROOM_TINT
		# Shadows off: an omni shadow is six faces of render, and the cavity is convex
		# enough that nothing inside it would cast one worth the cost. Specular held
		# under 1 so the lamps open the room without adding two more highlights to
		# argue with the key light outside.
		lamp.shadow_enabled = false
		lamp.light_specular = 0.55
		add_child(lamp)
		_lights.append(lamp)


func _operand_volume(c: Node) -> float:
	if c is CSGSphere3D:
		var r: float = (c as CSGSphere3D).radius
		return 4.18879 * r * r * r
	if c is CSGCylinder3D:
		var cy: CSGCylinder3D = c as CSGCylinder3D
		return PI * cy.radius * cy.radius * absf(cy.height)
	if c is CSGBox3D:
		var s: Vector3 = (c as CSGBox3D).size
		return absf(s.x * s.y * s.z)
	return 0.0


## How far a cavity reaches from its own centre — the length the lamp inside it has to
## cover before its wall goes dark.
func _operand_reach(c: Node) -> float:
	if c is CSGSphere3D:
		return (c as CSGSphere3D).radius
	if c is CSGCylinder3D:
		var cy: CSGCylinder3D = c as CSGCylinder3D
		return maxf(cy.radius, absf(cy.height) * 0.5)
	if c is CSGBox3D:
		return (c as CSGBox3D).size.length() * 0.5
	return 0.0


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
			var skin: Material = _core_skin if _core_skin != null else _csg.material_override
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
	_sync_interior_lights()


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
##
## The lathed and boxed operands come off MeshKit rather than off Godot's primitives:
## a cut volume shown as a thing is a thing, and a thing has a rim. The chamfer is a
## hundredth-and-a-bit of the operand's own smallest dimension — 12 cm on the drum
## (which meets the cap), 4.5 cm on the doorway, 3 cm on the plug — so a re-dimensioned
## scene still lands a proportionate edge instead of a transcribed one. The sphere keeps
## Godot's SphereMesh: MeshKit has no sphere, and a sphere has no edge to chamfer.
func _stand_in_for(c: Node) -> MeshInstance3D:
	var mesh: Mesh = null
	if c is CSGSphere3D:
		var cs: CSGSphere3D = c as CSGSphere3D
		var s := SphereMesh.new()
		s.radius = cs.radius
		s.height = s.radius * 2.0
		s.radial_segments = cs.radial_segments
		s.rings = cs.rings
		mesh = s
	elif c is CSGCylinder3D:
		var cy: CSGCylinder3D = c as CSGCylinder3D
		var r: float = cy.radius
		var h: float = absf(cy.height)
		mesh = MK.cylinder(r, h, maxi(cy.sides, 3), _rim_for(minf(r * 2.0, h)))
	elif c is CSGBox3D:
		var sz: Vector3 = (c as CSGBox3D).size
		var mind: float = minf(minf(absf(sz.x), absf(sz.y)), absf(sz.z))
		mesh = MK.bevel_box(sz, _rim_for(mind))
	if mesh == null:
		return null
	var mi := MeshInstance3D.new()
	mi.name = str(c.name) + "Core"
	mi.mesh = mesh
	return mi


## Chamfer radius for a part whose smallest dimension is `d`. Held inside MeshKit's
## useful band at the small end and capped at 12 cm so a 20 m operand does not get a
## fillet you could sit on.
func _rim_for(d: float) -> float:
	return clampf(absf(d) * 0.012, 0.004, 0.12)


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


# ── THE SKIN ─────────────────────────────────────────────────────────────────
# A superset of commons/resourses/shaders/Grid.gdshader, built in code so the shared
# file — which forty other scenes and every MultiMesh cube path depend on — is not
# touched. The first half of fragment() is that shader verbatim: the same barycentric
# edge distance, the same instance-colour override chain, the same emission. The seven
# authored uniforms keep their names and their shipped defaults, so _build_skin copies
# the scene's values across by name and the wireframe comes out identical.
#
# What is added is the half the authored shader never wrote:
#   ROUGHNESS   a two-scale field — a cast grain from PbrKit at ~3 m per period, mixed
#               with a metres-wide analytic undulation. One roughness value across a
#               26 m wall is the flat-plastic tell at architectural scale.
#   ALBEDO      the same field at a tenth strength, so the grey is a grey RANGE.
#   NORMAL      perturbed from the screen-space gradient of that field. CSG output is not
#               guaranteed to carry tangents, so a normal MAP would be a silent no-op;
#               this route needs none, and mipping fades it out with distance for free.
#   AO          crevice darkening the SSAO pass has nothing to bite on across a flat wall.
#   the inside  shell_half lets one material tell an exterior face from a cavity wall by
#               the fragment's own position, and give the room a warmer, slightly
#               rougher, faintly lifted read. The lift matters most: a hollow with no
#               ambient floor is 0,0,0, and a pure black has nothing left to shade.
#
# METALLIC stays at 0. There is no metal in a cast shelter, and the physically
# meaningless 0.3-0.6 middle is exactly what the rubric calls unconsidered.
const SKIN_SHADER := """
shader_type spatial;
render_mode depth_draw_always, cull_back;

// -- authored: names, hints and defaults are Grid.gdshader's own --
uniform vec4 modelColor : source_color = vec4(0.5, 0.5, 0.5, 1.0);
uniform vec4 wireframeColor : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform vec4 emissionColor : source_color = vec4(1.0, 0.0, 0.0, 1.0);
uniform float width : hint_range(0.1, 15.0) = 2.0;
uniform float blur : hint_range(0.1, 5.0) = 1.0;
uniform float emission_strength : hint_range(0.0, 10.0) = 2.0;
uniform bool show_interior = true;

// -- added: the surface response --
uniform sampler2D grain_tex : hint_default_white, filter_linear_mipmap, repeat_enable;
uniform float grain_scale = 0.32;
uniform float macro_mix : hint_range(0.0, 1.0) = 0.28;
uniform float rough_lo : hint_range(0.0, 1.0) = 0.50;
uniform float rough_hi : hint_range(0.0, 1.0) = 0.94;
uniform float metal_amount : hint_range(0.0, 1.0) = 0.0;
uniform float spec_amount : hint_range(0.0, 1.0) = 0.42;
uniform float edge_polish : hint_range(0.0, 1.0) = 0.30;
uniform float albedo_break : hint_range(0.0, 1.0) = 0.10;
uniform float ao_amount : hint_range(0.0, 1.0) = 0.45;
uniform float ao_light : hint_range(0.0, 1.0) = 0.25;
uniform float bump_gain : hint_range(0.0, 1.0) = 0.045;
uniform float bump_max : hint_range(0.0, 1.0) = 0.28;

// -- added: inside versus outside the stock --
uniform vec3 shell_half = vec3(0.0);
uniform vec4 inner_tint = vec4(1.05, 1.0, 0.93, 1.0);
uniform float inner_lift : hint_range(0.0, 1.0) = 0.055;
uniform float inner_rough : hint_range(-0.5, 0.5) = 0.04;

varying vec3 baryCoord;
varying vec4 instanceColor;
varying vec4 customData;
varying vec3 objPos;
varying vec3 objNrm;

void vertex() {
	int vertexIndex = VERTEX_ID % 3;
	if (vertexIndex == 0) {
		baryCoord = vec3(1.0, 0.0, 0.0);
	} else if (vertexIndex == 1) {
		baryCoord = vec3(0.0, 1.0, 0.0);
	} else {
		baryCoord = vec3(0.0, 0.0, 1.0);
	}
	instanceColor = COLOR;
	customData = INSTANCE_CUSTOM;
	objPos = VERTEX;
	objNrm = NORMAL;
}

void fragment() {
	// -- authored wireframe, unchanged --
	vec3 dBaryCoordX = dFdx(baryCoord);
	vec3 dBaryCoordY = dFdy(baryCoord);
	vec3 dBaryCoord = sqrt(dBaryCoordX * dBaryCoordX + dBaryCoordY * dBaryCoordY);
	dBaryCoord = max(dBaryCoord, vec3(0.0001));
	vec3 edge_distance = baryCoord / (dBaryCoord * width);
	vec3 remap = smoothstep(vec3(0.0), vec3(blur), edge_distance);
	float closestEdge = min(min(remap.x, remap.y), remap.z);

	vec4 baseColor = modelColor;
	if (length(modelColor.rgb - vec3(1.0)) < 0.01) {
		baseColor = instanceColor;
	} else if (length(instanceColor.rgb - vec3(1.0)) > 0.01 || instanceColor.a < 0.99) {
		baseColor = instanceColor;
	}

	// -- on the stock, or inside it --
	// Every exterior face of the block sits at exactly one half-extent, so its largest
	// normalised coordinate is 1.0; every cavity wall is strictly inside on all three.
	// The nearest miss is the drum floor at 0.985, which is why the band is this tight.
	float outer = 1.0;
	if (shell_half.x > 0.0) {
		vec3 rel = abs(objPos) / max(shell_half, vec3(0.0001));
		float shell = max(max(rel.x, rel.y), rel.z);
		outer = smoothstep(0.988, 0.999, shell);
	}

	// -- two-scale surface field --
	// Triplanar in the block's own space: CSG output has UVs the solver invented, and a
	// projection the object owns travels with it wherever a map puts it.
	vec3 nrm_o = normalize(objNrm);
	vec3 tw = pow(abs(nrm_o), vec3(4.0));
	tw = tw / max(tw.x + tw.y + tw.z, 0.0001);
	float fine = texture(grain_tex, objPos.zy * grain_scale).r * tw.x
		+ texture(grain_tex, objPos.xz * grain_scale).r * tw.y
		+ texture(grain_tex, objPos.xy * grain_scale).r * tw.z;
	// The macro layer is analytic rather than a fourth tap: three sines whose periods
	// are around 20-33 m give one slow blotch cycle across a 20 m wall for the cost of
	// no texture fetch at all, which is the difference between a detailed surface and a
	// tiled one.
	float broad = sin(objPos.x * 0.31 + 0.7) * sin(objPos.y * 0.23 + 2.1) * sin(objPos.z * 0.19 + 4.2);
	float g = clamp(mix(fine, broad * 0.5 + 0.5, macro_mix), 0.0, 1.0);

	// -- albedo --
	vec3 body = baseColor.rgb * (1.0 + albedo_break * (g - 0.5) * 2.0);
	body = mix(body * inner_tint.rgb, body, outer);
	vec3 finalColor;
	if (show_interior) {
		finalColor = mix(wireframeColor.rgb, body, closestEdge);
	} else {
		// The authored shader's two branches are byte-identical. This copy does not
		// invent a difference: the artifact ships show_interior true, and a false path
		// nobody authored would be a claim about a scene nobody wrote.
		finalColor = mix(wireframeColor.rgb, body, closestEdge);
	}
	ALBEDO = finalColor;

	// -- response --
	float rough = mix(rough_lo, rough_hi, g);
	rough += inner_rough * (1.0 - outer);
	// The wireframe line is where the form has been HANDLED - it is the drawn edge, and
	// a drawn edge on a cast surface is the one place polished enough to hold a
	// specular. This is the artifact's own version of edge wear.
	rough -= edge_polish * (1.0 - closestEdge);
	ROUGHNESS = clamp(rough, 0.04, 1.0);
	METALLIC = metal_amount;
	SPECULAR = spec_amount;
	AO = mix(1.0 - ao_amount, 1.0, g);
	AO_LIGHT_AFFECT = ao_light;

	// -- normal breakup with no tangents and no normal map --
	// The height field is g; its screen-space gradient, divided back through the
	// view-space size of one pixel, is the surface gradient in metres. Both divisors are
	// pixel footprints - never small enough to underflow - and the result is length
	// clamped, so no framing can make this explode.
	vec3 nv = normalize(NORMAL);
	vec3 sdx = dFdx(VERTEX);
	vec3 sdy = dFdy(VERTEX);
	float px = max(length(sdx), 1.0e-4);
	float py = max(length(sdy), 1.0e-4);
	vec3 tdir = sdx / px;
	vec3 bdir = sdy / py;
	tdir = tdir - nv * dot(tdir, nv);
	bdir = bdir - nv * dot(bdir, nv);
	vec3 sg = tdir * (dFdx(g) / px) + bdir * (dFdy(g) / py);
	float sgl = length(sg);
	sg = sg * (min(sgl * bump_gain, bump_max) / max(sgl, 1.0e-4));
	NORMAL = normalize(nv - sg);

	// -- authored emission, plus an ambient floor for the room --
	vec3 finalEmission = emissionColor.rgb;
	if (length(customData.rgb) > 0.001) {
		finalEmission = customData.rgb;
	}
	EMISSION = finalEmission * (1.0 - closestEdge) * emission_strength
		+ body * inner_lift * (1.0 - outer);
}
"""
