extends Node3D
class_name BioMech

# @identity
# essence: a single DNA-driven BIOMECH CYBORG — one floor-resting organism that,
#   depending on its `mode` DNA, grows into four flesh-and-machine specimens. Four
#   non-human creatures fused from soft wet tissue and lit steel: arachnid (an
#   eight-legged spider/crab whose meat abdomen is bolted under a steel carapace,
#   a toxic eye-cluster glowing in an armoured head-nub, cable tendons sinewing the
#   segmented metal legs), serpent (a rearing segmented centipede coiling up a
#   parametric curve — fleshy ribbed ovoids clamped by dark armour ribs, an exposed
#   mechanical spine of vertebrae and cables threading the back, a mandible maw and
#   amber eye-swarm at the reared head), avian (a winged bio-drone gripping a perch:
#   a fleshy body-pod in a split carapace, two strut-bone wings webbed with glowing
#   translucent membrane, a sensor head with a big central optic, a rudder tail), and
#   walker (a quadruped synth-beast — a bulbous flesh torso slung between four
#   pistoned mechanical strider legs, a glowing amber heart caged in a metal ribcage
#   in the belly gap, a low wedge sensor head). It is the body confessing it was
#   always partly manufactured — and the machine confessing it was always partly meat.
# desire: it wants the FLESH to read as soft living tissue (subsurface scatter,
#   backlight, faint vein glow — never plastic, never black) and the METAL to read as
#   lit steel (an emission floor so the dark chassis is form, not a silhouette) and
#   the CORES / EYES / VEINS to GLOW (saturated near-unshaded heat). It desires the
#   uncanny seam where the two meet — the bolt through muscle, the cable that is also
#   a tendon, the eye that is also an optic.
# critical_parameter: mode + seed + the colour triad (color_a / color_b / accent) —
#   mode picks the lineage and silhouette; seed varies the individual deterministically
#   (no global RNG, ever); color_a drives the FLESH (abdomen / segments / body-pod /
#   torso), color_b the METAL (carapace / armour / legs / struts / perch), accent the
#   GLOW (cores / eyes / veins / optic). One genome, four cyborgs, infinite individuals.
# triggers: _ready() reads DNA metadata overrides, seeds the RNG from `seed`, and
#   branches on `mode` to a _build_<mode>() helper; apply_grid_config rewrites config
#   metas, clears children (remove BEFORE free, guarded by `_built`), and rebuilds.
# emerges: dropped into a lab, a row of these reads as a BESTIARY OF FUSED THINGS —
#   four ways a body can be half-machine. Switch one mode and the room's idea of "what
#   a creature is" shifts; reseed and the specimen persists while its individual
#   varies. The piece is the boundary between organism and machine made walkable.
# needs: a seeded RNG for deterministic individuals [present]; four build branches
#   each with a strong creature silhouette [present]; a flesh material with subsurface
#   + backlight + vein floor [present]; a dark-metal material with an emission FLOOR so
#   nothing renders black under flat capture light [present]; a glow material for
#   cores/eyes/veins [present]; a colour triad that re-registers the same anatomy
#   [present]; bottom-centre floor origin reading from +Z [present]
# relationships: cousin to surreal_lab (both are mode-switchboards of one genome, but
#   the lab asks "what is an instrument?" while biomech asks "what is a body?"); kin to
#   the nature_system creatures (both blur living/manufactured, but the creatures grow
#   over time while biomech freezes one fused state); sibling to the catalyst foe
#   system (both stage the non-human as something met, not mastered).
# truth: flesh and machine were never a clean border. biomech holds four organisms in
#   one genome where meat is bolted to steel and steel is grown from meat, and lets a
#   single parameter choose which fusion the viewer is invited to read. The soft must
#   stay soft, the steel must stay lit, the core must burn — and the seam between them
#   is the whole point.

## A multi-mode generative biomech cyborg — flesh fused with machine.
##
## Built procedurally from DNA exports. Origin is at the BOTTOM CENTRE of the
## piece (floor-resting, Y up); it reads from +Z. The `mode` export selects one
## of FOUR creature vocabularies, each ported from a standalone trial:
## arachnid (eight-leg spider: flesh abdomen + steel carapace, glowing eye-cluster,
## cable tendons), serpent (rearing segmented centipede on a parametric curve:
## flesh segments under dark armour, exposed spine, mechanical maw, glowing cores),
## avian (winged bio-drone: strut-bone + translucent membrane wings, sensor head with
## optic, glowing chest core, on a perch), walker (quadruped synth-beast: bulbous
## flesh torso + 4 pistoned strider legs + amber core caged in a ribcage).
## A seeded RNG makes every individual deterministic from its `seed`. The colour
## triad (color_a FLESH / color_b METAL / accent GLOW) re-registers the same anatomy
## between palettes.
##
## Shared material + geometry helpers are consolidated under the `_bm_` prefix and
## reused by every mode. NO dependency on any other artifact script.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Form")
## arachnid | serpent | avian | walker
@export var mode: String = "arachnid"
## Deterministic seed — same seed always yields the same form.
@export var seed: int = 0
## Detail / element count (legs, tendrils, eyes, ribs scale with this).
@export var complexity: int = 5
## Overall height in meters (nominal full height of the creature).
@export var sculpt_height: float = 1.6
## Footprint width scale in meters (1.0 = native trial proportions).
@export var sculpt_width: float = 1.0

@export_group("Material")
## FLESH primary — organic body / abdomen / segments / torso.
@export var color_a: Color = Color(0.40, 0.15, 0.18)
## METAL primary — carapace / armour / legs / struts / perch.
@export var color_b: Color = Color(0.14, 0.155, 0.18)
## GLOW — cores / eyes / veins / optic.
@export var accent: Color = Color(1.0, 0.58, 0.16)
@export var metallic_amt: float = 0.88
@export var rough_amt: float = 0.40
## Boost emissive energies (glow reads hotter when true).
@export var emissive: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _rng := RandomNumberGenerator.new()

# Cool-steel emission-floor tint blended into the metal so it never reads black.
const _STEEL_TINT: Color = Color(0.16, 0.30, 0.34)


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k: Variant in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c: Node in get_children():
			remove_child(c)
			c.queue_free()
		_built = false
	_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_mode"):
		mode = str(get_meta("config_mode")).to_lower().strip_edges()
	if has_meta("config_seed"):
		seed = int(str(get_meta("config_seed")))
	if has_meta("config_complexity"):
		complexity = int(str(get_meta("config_complexity")))
	if has_meta("config_sculpt_height"):
		sculpt_height = float(str(get_meta("config_sculpt_height")))
	if has_meta("config_sculpt_width"):
		sculpt_width = float(str(get_meta("config_sculpt_width")))
	if has_meta("config_color_a"):
		color_a = _parse_color(str(get_meta("config_color_a")), color_a)
	if has_meta("config_color_b"):
		color_b = _parse_color(str(get_meta("config_color_b")), color_b)
	if has_meta("config_accent"):
		accent = _parse_color(str(get_meta("config_accent")), accent)
	if has_meta("config_metallic_amt"):
		metallic_amt = float(str(get_meta("config_metallic_amt")))
	if has_meta("config_rough_amt"):
		rough_amt = float(str(get_meta("config_rough_amt")))
	if has_meta("config_emissive"):
		emissive = str(get_meta("config_emissive")).to_lower() in ["true", "1", "yes", "on"]


## Accepts an "r,g,b" / "r,g,b,a" string OR a colour name ("red", "cyan", …).
func _parse_color(raw: String, fallback: Color) -> Color:
	var s := raw.strip_edges()
	var parts := s.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	# Try a named colour (Godot's Color(name) constructor handles HTML + names).
	var named := Color(s.to_lower())
	if named != Color(0, 0, 0, 1) or s.to_lower() in ["black", "#000000", "000000"]:
		return named
	return fallback


# ── Build dispatch ─────────────────────────────────────────────────────

func _build() -> void:
	_built = true
	_rng.seed = seed
	match mode:
		"arachnid":
			_build_arachnid()
		"serpent":
			_build_serpent()
		"avian":
			_build_avian()
		"walker":
			_build_walker()
		_:
			# Unknown mode falls back to the arachnid vocabulary.
			_build_arachnid()


# ── Shared `_bm_` material helpers ─────────────────────────────────────

## Energy multiplier for emissive elements, lifted when `emissive` is on.
func _bm_glow_energy(base: float) -> float:
	return base * (1.0 if emissive else 0.6)


## Soft organic FLESH (color_a family): subsurface scattering + a touch of
## backlight + a faint emissive vein floor, so the tissue reads as soft and wet
## and never collapses to flat black. `c` is the surface tint; `vein` is the
## inner-glow tint (defaults to `accent`).
func _bm_flesh_mat(c: Color, vein: Color = accent) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.roughness = 0.88
	m.metallic = 0.0
	m.subsurf_scatter_enabled = true
	m.subsurf_scatter_strength = 0.30
	# Inner-meat glow in the flesh's OWN deep tone, with only a whisper of the
	# vein accent blended in. Emitting the cool accent across the whole surface
	# (the previous behaviour) desaturated the tissue to pale pastel — the meat
	# must glow red from within, not cyan.
	m.emission_enabled = true
	m.emission = c.lerp(vein, 0.12) * 0.7
	m.emission_energy_multiplier = _bm_glow_energy(0.18) if emissive else 0.10
	# Backlight in the flesh's own warmth (not the cool accent), plus a soft rim.
	m.backlight_enabled = true
	m.backlight = c * 0.12
	m.rim_enabled = true
	m.rim = 0.24
	m.rim_tint = 0.5
	return m


## EMISSION-FLOOR METAL (color_b family): metallic ≈ metallic_amt, roughness ≈
## rough_amt, with an emission floor of its own tint so dark steel reads as lit
## steel rather than black under flat / unlit capture light. `sheen` shifts the
## floor toward a cool steel highlight.
func _bm_metal_mat(c: Color, sheen: Color = _STEEL_TINT, energy: float = 0.20,
		rough_bias: float = 0.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = c
	m.metallic = clampf(metallic_amt, 0.0, 1.0)
	m.roughness = clampf(rough_amt + rough_bias, 0.02, 1.0)
	m.emission_enabled = true
	m.emission = c.lerp(sheen, 0.6)
	m.emission_energy_multiplier = clampf(energy, 0.0, 1.0)
	m.rim_enabled = true
	m.rim = 0.4
	m.rim_tint = 0.5
	return m


## Bright GLOW (accent family): saturated near-unshaded emission for cores, eyes,
## veins, optics. `energy` ~2-6; alpha < 1.0 turns on alpha transparency (halos).
func _bm_glow_mat(c: Color, energy: float = 3.0, alpha: float = 1.0) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	if alpha < 1.0:
		m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.albedo_color = Color(c.r, c.g, c.b, alpha)
	m.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	m.emission_enabled = true
	m.emission = c
	m.emission_energy_multiplier = _bm_glow_energy(energy)
	return m


## Translucent glowing wing-membrane stretched across strut bones (avian).
func _bm_membrane_mat(tint: Color, glow: Color) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	m.albedo_color = Color(tint.r, tint.g, tint.b, 0.42)
	m.roughness = 0.55
	m.metallic = 0.0
	m.cull_mode = BaseMaterial3D.CULL_DISABLED
	m.emission_enabled = true
	m.emission = glow
	m.emission_energy_multiplier = _bm_glow_energy(0.85)
	return m


## Soft rubbery cable / tendon (dark, matte, faint floor).
func _bm_cable_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.06, 0.06, 0.07)
	m.roughness = 0.7
	m.metallic = 0.1
	m.emission_enabled = true
	m.emission = Color(0.10, 0.12, 0.14)
	m.emission_energy_multiplier = 0.07
	return m


# ── Shared `_bm_` mesh helpers ─────────────────────────────────────────

func _bm_sphere(parent: Node3D, radius: float, pos: Vector3, mat: Material,
		rings: int = 12, segs: int = 18) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = radius
	sph.height = radius * 2.0
	sph.radial_segments = segs
	sph.rings = rings
	mi.mesh = sph
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## An ellipsoid = unit sphere scaled into shape, placed via a Transform3D.
func _bm_ellipsoid(parent: Node3D, scale_v: Vector3, pos: Vector3,
		mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var sph := SphereMesh.new()
	sph.radius = 1.0
	sph.height = 2.0
	sph.radial_segments = 20
	sph.rings = 12
	mi.mesh = sph
	mi.material_override = mat
	mi.transform = Transform3D(Basis().scaled(scale_v), pos)
	parent.add_child(mi)
	return mi


func _bm_box(parent: Node3D, size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = size
	mi.mesh = bm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _bm_cylinder(parent: Node3D, top_r: float, bot_r: float, height: float,
		pos: Vector3, mat: Material, radial: int = 16) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = top_r
	cyl.bottom_radius = bot_r
	cyl.height = height
	cyl.radial_segments = radial
	cyl.rings = 1
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


func _bm_torus(parent: Node3D, inner_r: float, outer_r: float, pos: Vector3,
		mat: Material, rings: int = 24, ring_segs: int = 10) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var tm := TorusMesh.new()
	tm.inner_radius = maxf(inner_r, 0.001)
	tm.outer_radius = outer_r
	tm.rings = rings
	tm.ring_segments = ring_segs
	mi.mesh = tm
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## A cone (apex toward local +Y by default).
func _bm_cone(parent: Node3D, radius: float, height: float, pos: Vector3,
		mat: Material, sides: int = 8) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.0
	cyl.bottom_radius = radius
	cyl.height = height
	cyl.radial_segments = sides
	cyl.rings = 1
	mi.mesh = cyl
	mi.material_override = mat
	mi.position = pos
	parent.add_child(mi)
	return mi


## A Basis with +Y aligned to `up`, stable near-vertical and near-horizontal.
func _bm_basis_from_up(up: Vector3) -> Basis:
	var y := up.normalized()
	var ref := Vector3.RIGHT if absf(y.dot(Vector3.UP)) > 0.95 else Vector3.UP
	var x := ref.cross(y).normalized()
	var z := x.cross(y).normalized()
	return Basis(x, y, z)


## Oriented CYLINDER spanning a→b (uses a Basis — never out-of-tree look_at).
## Optional taper via `top_scale` (top radius = radius * top_scale).
func _bm_segment(parent: Node3D, a: Vector3, b: Vector3, radius: float,
		mat: Material, radial: int = 10, top_scale: float = 1.0) -> MeshInstance3D:
	var dir := b - a
	var length := dir.length()
	if length < 0.0001:
		return null
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	cyl.top_radius = radius * top_scale
	cyl.bottom_radius = radius
	cyl.height = length
	cyl.radial_segments = radial
	cyl.rings = 1
	mi.mesh = cyl
	mi.material_override = mat
	mi.transform = Transform3D(_bm_basis_from_up(dir / length), (a + b) * 0.5)
	parent.add_child(mi)
	return mi


## Oriented CAPSULE spanning a→b (rounded ends — for limb bones / struts).
func _bm_capsule_segment(parent: Node3D, a: Vector3, b: Vector3, radius: float,
		mat: Material) -> MeshInstance3D:
	var dir := b - a
	var length := dir.length()
	if length < 0.0001:
		return null
	var mi := MeshInstance3D.new()
	var cap := CapsuleMesh.new()
	cap.radius = radius
	cap.height = maxf(length, radius * 2.0 + 0.001)
	cap.radial_segments = 14
	cap.rings = 6
	mi.mesh = cap
	mi.material_override = mat
	mi.transform = Transform3D(_bm_basis_from_up(dir / length), (a + b) * 0.5)
	parent.add_child(mi)
	return mi


## Oriented tapered BOX BEAM spanning a→b (box local +Z runs the length).
func _bm_box_segment(parent: Node3D, a: Vector3, b: Vector3, w_start: float,
		w_end: float, mat: Material) -> MeshInstance3D:
	var length := a.distance_to(b)
	if length < 0.0001:
		return null
	var w := (w_start + w_end) * 0.5
	var mi := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(w, w, length)
	mi.mesh = bm
	mi.material_override = mat
	# Box local +Z spans the length; align +Z onto (b-a) via a Basis.
	var fwd := (b - a).normalized()
	var up := Vector3.UP
	if absf(fwd.dot(up)) > 0.98:
		up = Vector3.FORWARD
	var x := up.cross(fwd).normalized()
	var y := fwd.cross(x).normalized()
	mi.transform = Transform3D(Basis(x, y, fwd), a.lerp(b, 0.5))
	parent.add_child(mi)
	return mi


## A flat double-sided MEMBRANE panel spanning four corners (two triangles).
func _bm_membrane_panel(parent: Node3D, p0: Vector3, p1: Vector3, p2: Vector3,
		p3: Vector3, mat: Material) -> void:
	var verts := PackedVector3Array([p0, p1, p2, p0, p2, p3])
	var normals := PackedVector3Array()
	var nrm := (p1 - p0).cross(p3 - p0)
	if nrm.length() > 0.0001:
		nrm = nrm.normalized()
	else:
		nrm = Vector3.FORWARD
	for i: int in range(6):
		normals.append(nrm)
	var uvs := PackedVector2Array([
		Vector2(0, 0), Vector2(1, 0), Vector2(1, 1),
		Vector2(0, 0), Vector2(1, 1), Vector2(0, 1),
	])
	var arr: Array = []
	arr.resize(Mesh.ARRAY_MAX)
	arr[Mesh.ARRAY_VERTEX] = verts
	arr[Mesh.ARRAY_NORMAL] = normals
	arr[Mesh.ARRAY_TEX_UV] = uvs
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arr)
	var mi := MeshInstance3D.new()
	mi.mesh = am
	mi.material_override = mat
	parent.add_child(mi)


# =============================================================================
# MODE: arachnid — eight-leg spider/crab, flesh abdomen + steel carapace (v1)
# =============================================================================

func _build_arachnid() -> void:
	# Native trial proportions ≈ 1.7 m wide reach, body centre at 0.62 m. Scale
	# the whole creature so its full height lands near sculpt_height; width by w.
	var w := maxf(sculpt_width, 0.2)
	var native_body_h := 0.62
	var native_total := 0.90      # apex of leg arch ≈ peak height
	var vscale := maxf(sculpt_height, 0.4) / native_total
	var body_h := native_body_h * vscale
	var rig := Node3D.new()
	rig.name = "Arachnid"
	rig.scale = Vector3(w, vscale, w * 0.5 + 0.5 * w)
	add_child(rig)
	# Build in native space under a scaled rig so authored offsets stay readable.
	var centre := Vector3(0.0, native_body_h, 0.0)

	# Flesh = color_a; metal = color_b; glow = accent.
	_arachnid_abdomen(rig, centre)
	_arachnid_carapace(rig, centre)
	_arachnid_cephalo_head(rig, centre)
	_arachnid_eyes(rig, centre)
	_arachnid_core_vents(rig, centre)

	# Eight legs, splayed radially (spider/crab fan, more to the sides & front).
	var angles: Array[float] = [
		-28.0, -62.0, -108.0, -150.0,
		28.0, 62.0, 108.0, 150.0,
	]
	var idx := 0
	for a_deg: float in angles:
		var a := deg_to_rad(a_deg)
		var attach := centre + Vector3(sin(a) * 0.30, -0.06, cos(a) * 0.26)
		var reach := 0.92 + (0.06 if absf(a_deg) < 70.0 else 0.0)
		_arachnid_leg(rig, attach, a, reach, idx)
		idx += 1
	# Avoid an unused-local warning on body_h while keeping the derivation legible.
	rig.set_meta("body_h", body_h)


func _arachnid_abdomen(rig: Node3D, centre: Vector3) -> void:
	var flesh_mid := _bm_flesh_mat(color_a)
	var flesh_dark := _bm_flesh_mat(color_a.darkened(0.3))
	var lobes: Array = [
		[Vector3(0.0, 0.02, -0.16), Vector3(0.40, 0.34, 0.46), flesh_mid],
		[Vector3(0.0, 0.10, -0.30), Vector3(0.30, 0.27, 0.30), flesh_dark],
		[Vector3(0.13, -0.04, -0.10), Vector3(0.22, 0.20, 0.24), flesh_mid],
		[Vector3(-0.13, -0.04, -0.10), Vector3(0.22, 0.20, 0.24), flesh_mid],
		[Vector3(0.0, -0.10, -0.18), Vector3(0.26, 0.18, 0.30), flesh_dark],
	]
	for lobe: Array in lobes:
		var pos: Vector3 = centre + (lobe[0] as Vector3)
		var scl: Vector3 = lobe[1]
		var mat: Material = lobe[2]
		_bm_ellipsoid(rig, scl, pos, mat)

	# Glowing vein bands wrapping the abdomen.
	var vein_mat := _bm_glow_mat(accent, 2.4)
	for i: int in range(3):
		var ty := centre.y + 0.10 - float(i) * 0.14
		var ring := _bm_torus(rig, 0.34 - float(i) * 0.03 - 0.012,
			0.34 - float(i) * 0.03, Vector3(0.0, ty, centre.z - 0.18), vein_mat, 24, 6)
		ring.rotation_degrees = Vector3(82.0, 0.0, float(i) * 14.0)

	# Vein capillaries creeping forward over the flesh.
	for j: int in range(4):
		var t := float(j) / 3.0
		var x := lerpf(-0.18, 0.18, t)
		var cap := _bm_box(rig, Vector3(0.012, 0.012, 0.26),
			centre + Vector3(x, 0.16, -0.04), vein_mat)
		cap.rotation_degrees = Vector3(18.0, lerpf(-22.0, 22.0, t), 0.0)


func _arachnid_carapace(rig: Node3D, centre: Vector3) -> void:
	var plate_mat := _bm_metal_mat(color_b.lightened(0.12))
	var bolt_mat := _bm_metal_mat(color_b)
	var seam_mat := _bm_flesh_mat(color_a.lerp(Color(0.30, 0.26, 0.28), 0.5))

	# Main dorsal shell.
	var shell := _bm_box(rig, Vector3(0.46, 0.10, 0.48), centre + Vector3(0.0, 0.26, -0.14), plate_mat)
	shell.rotation_degrees = Vector3(-14.0, 0.0, 0.0)

	# Two side flank plates + a flesh fusion seam under each.
	for s: float in [-1.0, 1.0]:
		var flank := _bm_box(rig, Vector3(0.12, 0.30, 0.40), centre + Vector3(0.26 * s, 0.06, -0.12), plate_mat)
		flank.rotation_degrees = Vector3(0.0, 0.0, -18.0 * s)
		var seam := _bm_box(rig, Vector3(0.05, 0.22, 0.34), centre + Vector3(0.205 * s, 0.02, -0.12), seam_mat)
		seam.rotation_degrees = Vector3(0.0, 0.0, -18.0 * s)

	# Rivet studs along the dorsal ridge.
	for i: int in range(5):
		var t := float(i) / 4.0
		var bz := lerpf(0.06, -0.34, t)
		_bm_sphere(rig, 0.022, centre + Vector3(0.0, 0.31 - t * 0.02, bz), bolt_mat, 6, 8)

	# Mechanical spine crest of small angled fins.
	var fin_mat := _bm_metal_mat(color_b)
	for i: int in range(4):
		var t := float(i) / 3.0
		var fin := _bm_box(rig, Vector3(0.03, 0.10, 0.07),
			centre + Vector3(0.0, 0.34 + t * 0.02, lerpf(0.0, -0.30, t)), fin_mat)
		fin.rotation_degrees = Vector3(-30.0, 0.0, 0.0)

	# Exposed glowing core set into a gap in the dorsal plate.
	var core_mat := _bm_glow_mat(accent, 3.2)
	var port_ring := _bm_torus(rig, 0.048, 0.07, centre + Vector3(0.0, 0.31, 0.04), plate_mat, 16, 6)
	port_ring.rotation_degrees = Vector3(76.0, 0.0, 0.0)
	_bm_sphere(rig, 0.055, centre + Vector3(0.0, 0.30, 0.04), core_mat, 10, 12)
	# Amber pipe stubs feeding the core.
	for s: float in [-1.0, 1.0]:
		var pipe := _bm_box(rig, Vector3(0.018, 0.018, 0.10), centre + Vector3(0.06 * s, 0.29, -0.03), bolt_mat)
		pipe.rotation_degrees = Vector3(0.0, 35.0 * s, 0.0)


func _arachnid_cephalo_head(rig: Node3D, centre: Vector3) -> void:
	var flesh_grey := _bm_flesh_mat(color_a.lerp(Color(0.30, 0.26, 0.28), 0.45))
	var metal := _bm_metal_mat(color_b)
	var metal_hi := _bm_metal_mat(color_b.lightened(0.12))

	# Cephalothorax: a metal-ringed flesh neck.
	_bm_ellipsoid(rig, Vector3(0.40, 0.34, 0.34), centre + Vector3(0.0, -0.02, 0.22), flesh_grey)
	# Metal collar ring at the seam.
	var collar := _bm_torus(rig, 0.14, 0.17, centre + Vector3(0.0, -0.01, 0.30), metal_hi, 18, 6)
	collar.rotation_degrees = Vector3(90.0, 0.0, 0.0)
	# Head nub: a small armoured pod holding the eyes.
	_bm_ellipsoid(rig, Vector3(0.26, 0.22, 0.30), centre + Vector3(0.0, -0.04, 0.46), metal)

	# Two forward-reaching mechanical mandibles + fang tips.
	for s: float in [-1.0, 1.0]:
		var jaw := _bm_box(rig, Vector3(0.04, 0.05, 0.18), centre + Vector3(0.07 * s, -0.12, 0.54), metal_hi)
		jaw.rotation_degrees = Vector3(28.0, -10.0 * s, 0.0)
		var fang := _bm_cone(rig, 0.02, 0.07, centre + Vector3(0.085 * s, -0.18, 0.62), metal_hi)
		fang.rotation_degrees = Vector3(180.0, 0.0, 0.0)


func _arachnid_eyes(rig: Node3D, centre: Vector3) -> void:
	var eye_mat := _bm_glow_mat(accent.lerp(Color(0.35, 1.0, 0.85), 0.5), 5.2)
	# Dark recessed brow plate so the glowing eyes read proud of the metal head.
	var socket_mat := _bm_metal_mat(color_b.darkened(0.5), _STEEL_TINT, 0.08)
	# Sit the eyes on the FRONT SURFACE of the head nub (its front pole ≈ z+0.76),
	# protruding forward so the glow caps are not buried inside the metal.
	var head_front := centre + Vector3(0.0, 0.02, 0.66)
	# [offset, radius, is_primary] — two big forward principal eyes + a brow cluster.
	var eyes: Array = [
		[Vector3(-0.085, 0.05, 0.06), 0.072, true],
		[Vector3(0.085, 0.05, 0.06), 0.072, true],
		[Vector3(-0.13, -0.01, 0.0), 0.034, false],
		[Vector3(-0.05, -0.05, 0.04), 0.034, false],
		[Vector3(0.05, -0.05, 0.04), 0.034, false],
		[Vector3(0.13, -0.01, 0.0), 0.034, false],
	]
	for e: Array in eyes:
		var off: Vector3 = e[0]
		var r: float = e[1]
		if bool(e[2]):
			_bm_sphere(rig, r * 1.25, head_front + off - Vector3(0.0, 0.0, 0.05), socket_mat, 8, 10)
		_bm_sphere(rig, r, head_front + off, eye_mat, 8, 10)


func _arachnid_core_vents(rig: Node3D, centre: Vector3) -> void:
	var core_mat := _bm_glow_mat(accent, 3.0)
	var tube_mat := _bm_metal_mat(color_b)

	# Central glowing core under the abdomen.
	_bm_sphere(rig, 0.075, centre + Vector3(0.0, -0.16, -0.04), core_mat, 10, 12)

	# Exposed gut tubing loops on the belly.
	for i: int in range(3):
		var t := float(i) / 2.0
		var x := lerpf(-0.12, 0.12, t)
		var loop := _bm_torus(rig, 0.036, 0.05, centre + Vector3(x, -0.18, -0.10), tube_mat, 14, 6)
		loop.rotation_degrees = Vector3(20.0, float(i) * 30.0, 0.0)

	# Vent slits glowing along the flanks.
	for s: float in [-1.0, 1.0]:
		_bm_box(rig, Vector3(0.015, 0.06, 0.14), centre + Vector3(0.27 * s, 0.0, -0.10), core_mat)


func _arachnid_leg(rig: Node3D, attach: Vector3, ang: float, reach: float, leg_idx: int) -> void:
	var metal_a := _bm_metal_mat(color_b.darkened(0.05))
	var metal_b := _bm_metal_mat(color_b.lightened(0.10))
	var joint_mat := _bm_metal_mat(color_b.lightened(0.14))
	var cable_mat := _bm_flesh_mat(Color(0.10, 0.10, 0.12), accent.darkened(0.4))
	cable_mat.roughness = 0.85

	var dir := Vector3(sin(ang), 0.0, cos(ang)).normalized()

	# Arched stance: leg goes UP then back DOWN to the floor.
	var apex_h := 0.78
	var knee := attach + dir * (reach * 0.42) + Vector3(0.0, apex_h - attach.y, 0.0)
	var mid := attach + dir * (reach * 0.72) + Vector3(0.0, apex_h * 0.55 - attach.y, 0.0)
	var foot := attach + dir * reach + Vector3(0.0, -attach.y, 0.0)

	# Joint pivot spheres.
	_bm_sphere(rig, 0.055, attach, joint_mat, 8, 10)
	_bm_sphere(rig, 0.05, knee, joint_mat, 8, 10)
	_bm_sphere(rig, 0.042, mid, joint_mat, 8, 10)

	# Coxa/femur → tibia → tarsus (tapered box beams).
	_bm_box_segment(rig, attach, knee, 0.075, 0.058, metal_a)
	_bm_box_segment(rig, knee, mid, 0.056, 0.040, metal_b)
	_bm_box_segment(rig, mid, foot + Vector3(0.0, 0.04, 0.0), 0.038, 0.022, metal_a)

	# Sharp foot spike driving into the floor (cone apex points down).
	var spike := _bm_cone(rig, 0.03, 0.12, foot + Vector3(0.0, 0.05, 0.0), metal_b)
	spike.transform.basis = _bm_basis_from_up(Vector3.DOWN)

	# Cable tendon running attach → knee → mid, offset to the side as a sinew.
	var side := dir.cross(Vector3.UP).normalized() * 0.05
	_bm_box_segment(rig, attach + side, knee + side, 0.018, 0.016, cable_mat)
	_bm_box_segment(rig, knee + side, mid + side, 0.016, 0.014, cable_mat)

	# Flesh nodules at the fusion seams (meat gripping metal).
	_bm_ellipsoid(rig, Vector3(0.16, 0.13, 0.16), attach - dir * 0.03 + Vector3(0.0, 0.02, 0.0),
		_bm_flesh_mat(color_a))
	_bm_ellipsoid(rig, Vector3(0.11, 0.09, 0.11), knee - dir * 0.02,
		_bm_flesh_mat(color_a.darkened(0.3)))

	# Glowing vein streak along the front-most femurs.
	if leg_idx == 0 or leg_idx == 4:
		var vmid := attach.lerp(knee, 0.5) + side * 1.4
		_bm_segment(rig, vmid, knee + side * 1.4, 0.008, _bm_glow_mat(accent, 2.0), 6)


# =============================================================================
# MODE: serpent — rearing segmented centipede on a parametric curve (v2)
# =============================================================================

const _SERP_SEG_COUNT: int = 17
const _SERP_PATH_SAMPLES: int = 220


func _build_serpent() -> void:
	var w := maxf(sculpt_width, 0.2)
	var raw := _serpent_sample_path()

	# Bounds → scale so the creature stands ~sculpt_height and sits on y=0.
	var lo := raw[0]
	var hi := raw[0]
	for p: Vector3 in raw:
		lo = Vector3(minf(lo.x, p.x), minf(lo.y, p.y), minf(lo.z, p.z))
		hi = Vector3(maxf(hi.x, p.x), maxf(hi.y, p.y), maxf(hi.z, p.z))
	var span_y := maxf(hi.y - lo.y, 0.001)
	var scale_k := maxf(sculpt_height, 0.4) / span_y

	var path: Array[Vector3] = []
	for p: Vector3 in raw:
		path.append(Vector3((p.x - (lo.x + hi.x) * 0.5) * scale_k * w,
			(p.y - lo.y) * scale_k,
			(p.z - lo.z) * scale_k))

	var frames := _serpent_build_frames(path)

	# Flesh = color_a; metal = color_b; glow = accent.
	var flesh_a := _bm_flesh_mat(color_a)
	var flesh_b := _bm_flesh_mat(color_a.lightened(0.10))
	var metal := _bm_metal_mat(color_b, _STEEL_TINT, 0.16)
	var spine_metal := _bm_metal_mat(color_b.lightened(0.05), accent.darkened(0.2), 0.16)
	var cable := _bm_cable_mat()
	var eye_mat := _bm_glow_mat(accent, 4.2)
	var core_mat := _bm_glow_mat(accent.lerp(Color(0.30, 0.95, 0.55), 0.5), 2.4)

	var bodies := Node3D.new()
	bodies.name = "Body"
	add_child(bodies)

	for i: int in range(_SERP_SEG_COUNT):
		var t := float(i) / float(_SERP_SEG_COUNT - 1)
		var fi := int(round(t * float(frames.size() - 1)))
		var xf := frames[fi]
		var girth := _serpent_girth(t)

		# Fleshy ovoid squashed along the forward axis so segments read as rings.
		var flesh := MeshInstance3D.new()
		var ov := SphereMesh.new()
		ov.radius = girth
		ov.height = girth * 1.55
		ov.radial_segments = 18
		ov.rings = 12
		flesh.mesh = ov
		flesh.material_override = (flesh_a if i % 2 == 0 else flesh_b)
		var fxf := xf
		fxf.basis = fxf.basis.scaled(Vector3(1.0, 0.92, 0.62))
		flesh.transform = fxf
		bodies.add_child(flesh)

		_serpent_armour_rib(bodies, xf, girth, t, metal)

		# Glowing organic core peeking from a flank seam (a few segments).
		if i % 4 == 1 and t < 0.82:
			var core_pos := xf.origin + xf.basis.x * (girth * 0.92) + xf.basis.y * (girth * 0.25)
			_bm_sphere(bodies, girth * 0.30, core_pos, core_mat, 6, 10)

		# Leg-tendrils splaying from the lower third (both sides).
		if t < 0.55 and i % 2 == 0:
			_serpent_leg_tendril(bodies, xf, girth, 1.0, flesh_b, metal)
			_serpent_leg_tendril(bodies, xf, girth, -1.0, flesh_b, metal)

	# Exposed mechanical spine: vertebrae + cable.
	_serpent_spine(frames, spine_metal, cable, core_mat)
	# Head at the reared top: maw, eyes, antennae.
	_serpent_head(frames[frames.size() - 1], _serpent_girth(1.0), metal, flesh_a, eye_mat, core_mat, cable)


## Rearing serpent: a base coil that lifts, curls back, then sweeps forward + UP.
func _serpent_sample_path() -> Array[Vector3]:
	var pts: Array[Vector3] = []
	for s: int in range(_SERP_PATH_SAMPLES):
		var u := float(s) / float(_SERP_PATH_SAMPLES - 1)
		var y := 2.0 * pow(u, 1.18)
		var coil_turns := 1.35
		var ang := u * coil_turns * TAU
		var coil_r := lerpf(0.62, 0.05, smoothstep(0.0, 0.7, u))
		var cx := sin(ang) * coil_r
		var cz := cos(ang) * coil_r * 0.85
		var sweep := smoothstep(0.40, 1.0, u)
		var fz := sweep * sweep * 1.35
		var hood := -sin(clampf((u - 0.55) / 0.35, 0.0, 1.0) * PI) * 0.18
		var lunge := smoothstep(0.85, 1.0, u) * 0.35
		var x := cx + sin(u * PI) * 0.10
		var z := cz + fz + hood + lunge
		pts.append(Vector3(x, y, z))
	return pts


## Per-sample oriented frames (forward = tangent; up smoothed toward world-up).
func _serpent_build_frames(path: Array[Vector3]) -> Array[Transform3D]:
	var frames: Array[Transform3D] = []
	var n := path.size()
	var prev_up := Vector3.UP
	for i: int in range(n):
		var here := path[i]
		var ahead := path[mini(i + 1, n - 1)]
		var behind := path[maxi(i - 1, 0)]
		var fwd := (ahead - behind)
		if fwd.length() < 0.0001:
			fwd = Vector3(0, 0, 1)
		fwd = fwd.normalized()
		var up_guess := (Vector3.UP * 0.7 + prev_up * 0.3)
		var right := up_guess.cross(fwd)
		if right.length() < 0.001:
			right = Vector3.RIGHT
		right = right.normalized()
		var up := fwd.cross(right).normalized()
		prev_up = up
		frames.append(Transform3D(Basis(right, up, fwd), here))
	return frames


## Girth profile along the body (tail thin → mid fat → neck tapered).
func _serpent_girth(t: float) -> float:
	var bell := sin(clampf(t, 0.0, 1.0) * PI)
	var base := lerpf(0.10, 0.30, bell)
	base += 0.06 * smoothstep(0.5, 0.15, t)
	return maxf(base, 0.085)


func _serpent_armour_rib(parent: Node3D, xf: Transform3D, girth: float, t: float, mat: Material) -> void:
	var plate_w := girth * 0.40
	var plate_h := girth * 0.15
	var spread := girth * 0.78
	var rib := Node3D.new()
	rib.transform = xf
	parent.add_child(rib)

	var arc: Array[float] = [-0.5, 0.0, 0.5]
	for a: float in arc:
		var plate := MeshInstance3D.new()
		var bx := BoxMesh.new()
		bx.size = Vector3(plate_w, plate_h, girth * 0.95)
		plate.mesh = bx
		plate.material_override = mat
		var local := Transform3D()
		local = local.rotated(Vector3(0, 0, 1), a)
		local.origin = Vector3(sin(a) * spread, cos(a) * (spread * 0.7) + girth * 0.34, 0.0)
		plate.transform = local
		rib.add_child(plate)

	# Raised dorsal keel on the mid-body for silhouette.
	if t > 0.15 and t < 0.7:
		var keel := MeshInstance3D.new()
		var kb := BoxMesh.new()
		kb.size = Vector3(girth * 0.10, girth * 0.55, girth * 0.9)
		keel.mesh = kb
		keel.material_override = mat
		keel.transform = Transform3D(Basis(), Vector3(0, girth * 0.95, 0))
		rib.add_child(keel)


func _serpent_leg_tendril(parent: Node3D, xf: Transform3D, girth: float, side: float,
		flesh: Material, tip_mat: Material) -> void:
	var root := Node3D.new()
	root.transform = xf
	parent.add_child(root)

	var seg_len := girth * 0.9
	var origin := Vector3(side * girth * 0.7, -girth * 0.35, 0.0)
	# thigh angled down-out
	var thigh := MeshInstance3D.new()
	var tc := CylinderMesh.new()
	tc.top_radius = girth * 0.10
	tc.bottom_radius = girth * 0.14
	tc.height = seg_len
	tc.radial_segments = 8
	thigh.mesh = tc
	thigh.material_override = flesh
	var th_xf := Transform3D()
	th_xf = th_xf.rotated(Vector3(0, 0, 1), side * deg_to_rad(58.0))
	th_xf.origin = origin + Vector3(side * seg_len * 0.4, -seg_len * 0.35, 0.0)
	thigh.transform = th_xf
	root.add_child(thigh)

	# sharper metal tip
	var tip := MeshInstance3D.new()
	var tipc := CylinderMesh.new()
	tipc.top_radius = girth * 0.015
	tipc.bottom_radius = girth * 0.10
	tipc.height = seg_len * 0.85
	tipc.radial_segments = 6
	tip.mesh = tipc
	tip.material_override = tip_mat
	var tip_xf := Transform3D()
	tip_xf = tip_xf.rotated(Vector3(0, 0, 1), side * deg_to_rad(20.0))
	tip_xf.origin = origin + Vector3(side * seg_len * 0.78, -seg_len * 0.95, 0.0)
	tip.transform = tip_xf
	root.add_child(tip)


func _serpent_spine(frames: Array[Transform3D], vmat: Material, cable: Material, core_mat: Material) -> void:
	var spine := Node3D.new()
	spine.name = "Spine"
	add_child(spine)

	var verts := 22
	var ring_pts: Array[Vector3] = []
	for i: int in range(verts):
		var t := float(i) / float(verts - 1)
		var fi := int(round(t * float(frames.size() - 1)))
		var xf := frames[fi]
		var g := _serpent_girth(t)
		var pos := xf.origin + xf.basis.y * (g * 0.62)
		ring_pts.append(pos)

		# vertebra = small box rotated to the frame.
		var vb := MeshInstance3D.new()
		var bx := BoxMesh.new()
		var vs := lerpf(0.045, 0.085, sin(t * PI))
		bx.size = Vector3(vs * 1.6, vs * 1.1, vs * 1.3)
		vb.mesh = bx
		vb.material_override = vmat
		var vxf := xf
		vxf.origin = pos
		vxf.basis = vxf.basis.rotated(xf.basis.z, deg_to_rad(45.0))
		vb.transform = vxf
		spine.add_child(vb)

		# emissive nerve node between every few vertebrae.
		if i % 3 == 0:
			_bm_sphere(spine, vs * 0.5, pos, core_mat, 5, 8)

	# Two thin cables following the vertebra chain.
	for j: int in range(ring_pts.size() - 1):
		var a := ring_pts[j]
		var b := ring_pts[j + 1]
		_bm_segment(spine, a, b, 0.018, cable, 6)
		var off := Vector3(0.03, 0, 0)
		_bm_segment(spine, a + off, b + off, 0.012, cable, 6)


func _serpent_head(head_xf: Transform3D, neck_g: float, metal: Material, flesh: Material,
		eye_mat: Material, core_mat: Material, cable: Material) -> void:
	var head := Node3D.new()
	head.name = "Head"
	# Push the head forward of the last frame and pitch it DOWN about its own X
	# axis so the maw + eye cluster (local +Z) tip toward the viewer.
	var hxf := head_xf
	hxf.origin = head_xf.origin + head_xf.basis.z * (neck_g * 1.0) + head_xf.basis.y * (neck_g * 0.2)
	hxf.basis = hxf.basis.rotated(head_xf.basis.x, deg_to_rad(48.0))
	head.transform = hxf
	add_child(head)

	var hg := maxf(neck_g * 1.35, 0.14)

	# Skull core — fleshy elongated ovoid.
	var skull := MeshInstance3D.new()
	var sk := SphereMesh.new()
	sk.radius = hg
	sk.height = hg * 2.1
	sk.radial_segments = 18
	sk.rings = 12
	skull.mesh = sk
	skull.material_override = flesh
	skull.transform = Transform3D(Basis().scaled(Vector3(0.9, 0.85, 1.25)), Vector3.ZERO)
	head.add_child(skull)

	# Metal cranial crest.
	var crest := MeshInstance3D.new()
	var cb := BoxMesh.new()
	cb.size = Vector3(hg * 0.5, hg * 0.7, hg * 1.6)
	crest.mesh = cb
	crest.material_override = metal
	crest.transform = Transform3D(Basis(), Vector3(0, hg * 0.78, hg * 0.1))
	head.add_child(crest)

	# MAW — four mandible plates opening outward at the front (+Z).
	var maw_z := hg * 1.15
	_serpent_mandible(head, hg, maw_z, deg_to_rad(-26.0), Vector3(0, -1, 0), metal)
	_serpent_mandible(head, hg, maw_z, deg_to_rad(24.0), Vector3(0, 1, 0), metal)
	_serpent_mandible(head, hg, maw_z, deg_to_rad(30.0), Vector3(1, 0, 0), metal)
	_serpent_mandible(head, hg, maw_z, deg_to_rad(30.0), Vector3(-1, 0, 0), metal)

	# Inner mouth glow.
	var throat := _bm_glow_mat(accent.lerp(Color(1.0, 0.40, 0.14), 0.4), 3.0)
	_bm_ellipsoid(head, Vector3(hg * 0.42, hg * 0.42, hg * 0.35),
		Vector3(0, -hg * 0.02, maw_z * 0.55), throat)

	# EYES — a cluster of orbs across the upper face, each in a metal socket.
	var eye_pos: Array[Vector3] = [
		Vector3(0.0, hg * 0.42, hg * 0.78),
		Vector3(hg * 0.40, hg * 0.30, hg * 0.62),
		Vector3(-hg * 0.40, hg * 0.30, hg * 0.62),
		Vector3(hg * 0.62, hg * 0.10, hg * 0.40),
		Vector3(-hg * 0.62, hg * 0.10, hg * 0.40),
		Vector3(hg * 0.22, hg * 0.55, hg * 0.55),
		Vector3(-hg * 0.22, hg * 0.55, hg * 0.55),
	]
	var eye_r: Array[float] = [0.058, 0.040, 0.040, 0.028, 0.028, 0.030, 0.030]
	for k: int in range(eye_pos.size()):
		_bm_sphere(head, eye_r[k], eye_pos[k], eye_mat, 8, 12)
		var ring := _bm_torus(head, eye_r[k] * 1.05, eye_r[k] * 1.55,
			eye_pos[k] - Vector3(0, 0, eye_r[k] * 0.3), metal, 8, 8)
		ring.transform = Transform3D(Basis(Vector3(1, 0, 0), deg_to_rad(90.0)),
			eye_pos[k] - Vector3(0, 0, eye_r[k] * 0.3))

	# ANTENNAE / sensor probes.
	_serpent_antenna(head, hg, 1.0, metal, core_mat)
	_serpent_antenna(head, hg, -1.0, metal, core_mat)

	# Feeler cables drooping from the lower jaw.
	for s: float in [-1.0, 1.0]:
		var a := Vector3(s * hg * 0.35, -hg * 0.55, maw_z * 0.7)
		var b := a + Vector3(s * hg * 0.18, -hg * 0.7, hg * 0.1)
		_bm_segment(head, a, b, 0.012, cable, 6)


func _serpent_mandible(head: Node3D, hg: float, maw_z: float, open_ang: float,
		open_axis: Vector3, mat: Material) -> void:
	var jaw := MeshInstance3D.new()
	var jb := BoxMesh.new()
	jb.size = Vector3(hg * 0.34, hg * 0.20, hg * 0.95)
	jaw.mesh = jb
	jaw.material_override = mat
	var pivot := Vector3(0, 0, maw_z * 0.35)
	var rot := Basis(open_axis.normalized(), open_ang)
	var local := Transform3D(rot, pivot)
	local.origin += rot * Vector3(open_axis.x * hg * 0.3, open_axis.y * hg * 0.05, maw_z * 0.55)
	jaw.transform = local
	head.add_child(jaw)

	# A couple of teeth on the plate's inner edge.
	for tnum: int in range(2):
		var tooth := MeshInstance3D.new()
		var tc := CylinderMesh.new()
		tc.top_radius = 0.004
		tc.bottom_radius = hg * 0.05
		tc.height = hg * 0.22
		tc.radial_segments = 5
		tooth.mesh = tc
		tooth.material_override = mat
		var toff := Transform3D()
		toff = toff.rotated(Vector3(1, 0, 0), deg_to_rad(90.0))
		toff.origin = Vector3((float(tnum) - 0.5) * hg * 0.18, -hg * 0.08, maw_z * 0.7)
		tooth.transform = local * toff
		head.add_child(tooth)


func _serpent_antenna(head: Node3D, hg: float, side: float, metal: Material, tip_mat: Material) -> void:
	var n := 4
	var prev := Vector3(side * hg * 0.45, hg * 0.7, hg * 0.2)
	for i: int in range(1, n + 1):
		var t := float(i) / float(n)
		var p := Vector3(
			side * (hg * 0.45 + sin(t * 1.2) * hg * 0.5),
			hg * 0.7 + t * hg * 1.2,
			hg * 0.2 - t * t * hg * 0.6)
		_bm_segment(head, prev, p, lerpf(0.018, 0.006, t), metal, 6)
		prev = p
	# glowing sensor bead at the tip.
	_bm_sphere(head, hg * 0.055, prev, tip_mat, 6, 10)


# =============================================================================
# MODE: avian — winged bio-drone on a perch (v3)
# =============================================================================

func _build_avian() -> void:
	# Native trial height ≈ 1.6 m (incl. perch). Scale to sculpt_height, width w.
	var w := maxf(sculpt_width, 0.2)
	var native_total := 1.6
	var vscale := maxf(sculpt_height, 0.4) / native_total
	var rig := Node3D.new()
	rig.name = "Avian"
	rig.scale = Vector3(w, vscale, w)
	add_child(rig)

	# Flesh = color_a; metal = color_b; glow = accent.
	var flesh := _bm_flesh_mat(color_a)
	var flesh_pale := _bm_flesh_mat(color_a.lightened(0.12))
	var metal := _bm_metal_mat(color_b, _STEEL_TINT, 0.28)
	var metal_strut := _bm_metal_mat(color_b.lightened(0.04), _STEEL_TINT, 0.40, -0.08)
	var glow_core := _bm_glow_mat(accent.lerp(Color(0.35, 0.95, 1.0), 0.4), 6.0)
	var glow_eye := _bm_glow_mat(accent, 5.0)
	var vein := _bm_glow_mat(accent.lightened(0.1), 3.2)
	var membrane := _bm_membrane_mat(color_a.darkened(0.15), accent)

	_avian_perch(rig, metal, metal_strut, glow_core)

	var body_y := 0.92
	var body := Node3D.new()
	body.name = "BodyPod"
	body.position = Vector3(0, body_y, 0)
	body.rotation_degrees = Vector3(8, 0, 0)
	rig.add_child(body)

	_avian_body(body, flesh, flesh_pale, metal, vein, glow_core)
	_avian_wing(body, 1.0, metal_strut, membrane, vein)
	_avian_wing(body, -1.0, metal_strut, membrane, vein)
	_avian_head(body, flesh, metal, metal_strut, glow_eye, vein)
	_avian_legs(rig, metal, metal_strut, flesh, body_y)
	_avian_tail(body, metal_strut, membrane, vein)


func _avian_perch(rig: Node3D, metal: Material, strut: Material, glow: Material) -> void:
	_bm_cylinder(rig, 0.30, 0.34, 0.06, Vector3(0, 0.03, 0), metal, 16)
	_bm_cylinder(rig, 0.055, 0.075, 0.74, Vector3(0, 0.43, 0), metal, 14)
	var bar := _bm_cylinder(rig, 0.05, 0.05, 0.46, Vector3(0, 0.80, 0), strut, 12)
	bar.transform = Transform3D(Basis().rotated(Vector3.FORWARD, PI * 0.5), Vector3(0, 0.80, 0))
	_bm_ellipsoid(rig, Vector3(0.10, 0.07, 0.10), Vector3(0, 0.80, 0), glow)
	for i: int in range(3):
		var a := float(i) / 3.0 * TAU
		var fp := Vector3(cos(a) * 0.26, 0.02, sin(a) * 0.26)
		var foot := _bm_box(rig, Vector3(0.10, 0.04, 0.16), fp, metal)
		foot.transform = Transform3D(Basis().rotated(Vector3.UP, -a), fp)


func _avian_body(body: Node3D, flesh: Material, flesh_pale: Material, metal: Material,
		vein: Material, core: Material) -> void:
	_bm_ellipsoid(body, Vector3(0.30, 0.34, 0.40), Vector3(0, 0.0, 0.0), flesh)
	_bm_ellipsoid(body, Vector3(0.34, 0.22, 0.26), Vector3(0, 0.20, -0.04), flesh)
	_bm_ellipsoid(body, Vector3(0.22, 0.22, 0.30), Vector3(0, -0.20, -0.14), flesh_pale)
	_bm_ellipsoid(body, Vector3(0.22, 0.22, 0.18), Vector3(0, 0.02, 0.26), flesh_pale)

	# Carapace plates over the back / shoulders (split so a gap shows the core).
	var back_plate := _bm_box(body, Vector3(0.40, 0.06, 0.34), Vector3(0, 0.16, -0.18), metal)
	back_plate.transform = Transform3D(Basis().rotated(Vector3.RIGHT, -0.5), Vector3(0, 0.16, -0.18))
	for sgn: float in [1.0, -1.0]:
		var side := _bm_box(body, Vector3(0.10, 0.34, 0.30), Vector3(sgn * 0.26, 0.0, 0.04), metal)
		side.transform = Transform3D(
			Basis().rotated(Vector3.UP, sgn * 0.35).rotated(Vector3.FORWARD, sgn * 0.25),
			Vector3(sgn * 0.26, 0.0, 0.04))

	# Glowing organic core in the chest, framed by a dark chassis ring.
	_bm_ellipsoid(body, Vector3(0.11, 0.12, 0.11), Vector3(0, 0.02, 0.34), core)
	var ring := _bm_torus(body, 0.11, 0.17, Vector3(0, 0.02, 0.34), metal, 16, 20)
	ring.transform = Transform3D(Basis().rotated(Vector3.RIGHT, PI * 0.5), Vector3(0, 0.02, 0.34))

	# Emissive vein nodes on the flesh.
	var vein_pts: Array[Vector3] = [
		Vector3(0.16, 0.10, 0.18), Vector3(-0.15, 0.06, 0.20),
		Vector3(0.10, -0.14, 0.10), Vector3(-0.10, -0.10, 0.12),
		Vector3(0.0, 0.22, 0.10),
	]
	for i: int in range(vein_pts.size()):
		_bm_ellipsoid(body, Vector3(0.025, 0.025, 0.025), vein_pts[i], vein)

	# Cable tubes draping from the carapace toward the perch.
	for sgn: float in [1.0, -1.0]:
		_bm_segment(body, Vector3(sgn * 0.18, -0.18, 0.0), Vector3(sgn * 0.08, -0.40, 0.02), 0.022, metal, 10, 0.7)
		_bm_segment(body, Vector3(sgn * 0.12, -0.22, -0.10), Vector3(sgn * 0.06, -0.40, -0.10), 0.018, vein, 10, 0.7)


func _avian_wing(body: Node3D, side: float, strut: Material, membrane: Material, vein: Material) -> void:
	var wing := Node3D.new()
	wing.name = "Wing%s" % ("R" if side > 0 else "L")
	wing.position = Vector3(side * 0.26, 0.16, -0.02)
	wing.rotation_degrees = Vector3(-12, side * -22.0, side * 34.0)
	body.add_child(wing)

	_bm_ellipsoid(wing, Vector3(0.09, 0.09, 0.09), Vector3.ZERO, strut)

	var bone_count := 4
	var spreads: Array[float] = [4.0, 24.0, 46.0, 70.0]
	var lengths: Array[float] = [0.86, 0.95, 0.84, 0.62]
	var tips: Array[Vector3] = []
	var mids: Array[Vector3] = []
	var roots: Array[Vector3] = []

	for b: int in range(bone_count):
		var spread_rad := deg_to_rad(spreads[b])
		var dir := Vector3(side * cos(spread_rad), sin(spread_rad), 0.0).normalized()
		var total_len := lengths[b]
		var seg1 := total_len * 0.58
		var seg2 := total_len * 0.42
		var root := Vector3.ZERO
		var mid := dir * seg1
		var dir2 := dir.lerp(Vector3(side, 0.15, 0.0).normalized(), 0.35).normalized()
		var tip := mid + dir2 * seg2
		roots.append(root)
		mids.append(mid)
		tips.append(tip)

		_bm_segment(wing, root, mid, lerpf(0.040, 0.026, float(b) / float(bone_count)), strut, 10, 0.7)
		_bm_ellipsoid(wing, Vector3(0.030, 0.030, 0.030), mid, strut)
		_bm_segment(wing, mid, tip, 0.018, strut, 10, 0.7)
		_bm_ellipsoid(wing, Vector3(0.022, 0.022, 0.040), tip, vein)

	# Leading-edge spar tying the strut knuckles.
	for b: int in range(bone_count - 1):
		_bm_segment(wing, mids[b], mids[b + 1], 0.014, strut, 8, 0.7)

	# Membrane panels webbed between consecutive bones.
	for b: int in range(bone_count - 1):
		_bm_membrane_panel(wing, roots[b], tips[b], tips[b + 1], roots[b + 1], membrane)

	# Small trailing-flap membrane behind the last bone toward the body.
	_bm_membrane_panel(wing, roots[bone_count - 1], tips[bone_count - 1],
		tips[bone_count - 1] + Vector3(side * -0.10, -0.18, 0.0),
		Vector3(side * -0.06, -0.20, 0.0), membrane)


func _avian_head(body: Node3D, flesh: Material, metal: Material, strut: Material,
		eye: Material, vein: Material) -> void:
	var neck := Node3D.new()
	neck.name = "Neck"
	neck.position = Vector3(0, 0.24, 0.18)
	neck.rotation_degrees = Vector3(26, 0, 0)
	body.add_child(neck)

	var nseg := 3
	for i: int in range(nseg):
		var f := float(i) / float(nseg)
		var p := Vector3(0, lerpf(0.0, 0.30, f), lerpf(0.0, 0.10, f))
		_bm_ellipsoid(neck, Vector3(lerpf(0.075, 0.055, f), 0.06, lerpf(0.075, 0.055, f)), p, flesh)
	for i: int in range(nseg):
		var f2 := (float(i) + 0.5) / float(nseg)
		var p2 := Vector3(0, lerpf(0.04, 0.26, f2), lerpf(0.01, 0.09, f2))
		var vert := _bm_cylinder(neck, 0.07, 0.07, 0.02, p2, metal, 12)
		vert.transform = Transform3D(Basis().rotated(Vector3.RIGHT, deg_to_rad(-12)), p2)

	var head := Node3D.new()
	head.name = "Head"
	head.position = Vector3(0, 0.34, 0.12)
	head.rotation_degrees = Vector3(-18, 0, 0)
	neck.add_child(head)

	_bm_ellipsoid(head, Vector3(0.11, 0.10, 0.17), Vector3(0, 0, 0.04), flesh)
	var crown := _bm_box(head, Vector3(0.16, 0.05, 0.22), Vector3(0, 0.06, 0.02), metal)
	crown.transform = Transform3D(Basis().rotated(Vector3.RIGHT, deg_to_rad(-10)), Vector3(0, 0.06, 0.02))

	# BIG central optic lens at the front.
	_bm_ellipsoid(head, Vector3(0.075, 0.075, 0.045), Vector3(0, 0.0, 0.16), metal)
	_bm_ellipsoid(head, Vector3(0.052, 0.052, 0.040), Vector3(0, 0.0, 0.185), eye)
	_bm_ellipsoid(head, Vector3(0.020, 0.020, 0.020), Vector3(0, 0.0, 0.205),
		_bm_glow_mat(Color(1, 1, 0.85), 8.0))

	# Cluster of smaller eyes around the main optic.
	var eye_off: Array[Vector3] = [
		Vector3(0.075, 0.045, 0.12), Vector3(-0.075, 0.045, 0.12),
		Vector3(0.06, -0.04, 0.14), Vector3(-0.06, -0.04, 0.14),
	]
	for i: int in range(eye_off.size()):
		_bm_ellipsoid(head, Vector3(0.022, 0.022, 0.020), eye_off[i], eye)

	# Antennae sweeping back + glowing tips.
	for sgn: float in [1.0, -1.0]:
		var a_root := Vector3(sgn * 0.06, 0.07, -0.02)
		var a_tip := Vector3(sgn * 0.16, 0.20, -0.18)
		_bm_segment(head, a_root, a_tip, 0.010, strut, 8, 0.7)
		_bm_ellipsoid(head, Vector3(0.016, 0.016, 0.016), a_tip, vein)

	# Small mandibles / pincers at the jaw.
	for sgn: float in [1.0, -1.0]:
		var m_root := Vector3(sgn * 0.05, -0.05, 0.16)
		var m_tip := Vector3(sgn * 0.085, -0.10, 0.27)
		_bm_segment(head, m_root, m_tip, 0.012, strut, 8, 0.7)
		_bm_ellipsoid(head, Vector3(0.012, 0.012, 0.020), m_tip, strut)


func _avian_legs(rig: Node3D, metal: Material, strut: Material, flesh: Material, body_y: float) -> void:
	for sgn: float in [1.0, -1.0]:
		var leg := Node3D.new()
		leg.name = "Leg%s" % ("R" if sgn > 0 else "L")
		rig.add_child(leg)

		var hip := Vector3(sgn * 0.14, body_y - 0.18, 0.06)
		var knee := Vector3(sgn * 0.20, body_y - 0.46, 0.12)
		var ankle := Vector3(sgn * 0.16, 0.86, 0.10)

		_bm_segment(leg, hip, knee, 0.05, strut, 10, 0.7)
		_bm_ellipsoid(leg, Vector3(0.055, 0.07, 0.055), (hip + knee) * 0.5, flesh)
		_bm_segment(leg, knee, ankle, 0.035, strut, 10, 0.7)
		_bm_ellipsoid(leg, Vector3(0.045, 0.045, 0.045), knee, strut)

		for c: int in range(3):
			var ca := lerpf(-0.5, 0.5, float(c) / 2.0)
			var claw_mid := ankle + Vector3(sgn * 0.02, -0.05, 0.06 + ca * 0.04)
			var claw_tip := ankle + Vector3(sgn * 0.01, -0.10, 0.02 + ca * 0.10)
			_bm_segment(leg, ankle, claw_mid, 0.018, strut, 8, 0.7)
			_bm_segment(leg, claw_mid, claw_tip, 0.012, metal, 8, 0.7)
		var rear_tip := ankle + Vector3(sgn * 0.02, -0.08, -0.10)
		_bm_segment(leg, ankle, rear_tip, 0.014, metal, 8, 0.7)


func _avian_tail(body: Node3D, strut: Material, membrane: Material, vein: Material) -> void:
	var tail := Node3D.new()
	tail.name = "Tail"
	tail.position = Vector3(0, -0.16, -0.30)
	tail.rotation_degrees = Vector3(18, 0, 0)
	body.add_child(tail)

	var seg := 3
	var prev := Vector3.ZERO
	for i: int in range(seg):
		var f := float(i + 1) / float(seg)
		var p := Vector3(0, lerpf(0.0, -0.10, f), lerpf(0.0, -0.34, f))
		_bm_segment(tail, prev, p, lerpf(0.04, 0.018, f), strut, 10, 0.7)
		_bm_ellipsoid(tail, Vector3(0.030, 0.030, 0.030), p, vein)
		prev = p

	# Vertical rudder membrane fin.
	var fin := MeshInstance3D.new()
	var q := QuadMesh.new()
	q.size = Vector2(0.30, 0.22)
	fin.mesh = q
	fin.material_override = membrane
	fin.transform = Transform3D(Basis().rotated(Vector3.UP, PI * 0.5), Vector3(0, -0.06, -0.30))
	tail.add_child(fin)
	_bm_segment(tail, Vector3(0, 0.06, -0.20), Vector3(0, -0.06, -0.42), 0.012, strut, 8, 0.7)


# =============================================================================
# MODE: walker — quadruped synth-beast, flesh torso + pistoned legs (v4)
# =============================================================================

func _build_walker() -> void:
	# Native trial height ≈ 1.6 m. Scale to sculpt_height, footprint by w.
	var w := maxf(sculpt_width, 0.2)
	var native_total := 1.6
	var vscale := maxf(sculpt_height, 0.4) / native_total
	var rig := Node3D.new()
	rig.name = "Walker"
	rig.scale = Vector3(w, vscale, w)
	add_child(rig)

	var torso_y := 1.02
	var torso := Node3D.new()
	torso.name = "Torso"
	torso.position = Vector3(0.0, torso_y, 0.10)
	rig.add_child(torso)
	_walker_torso(torso)
	_walker_core(torso)
	_walker_head(torso)
	_walker_tail_vent(torso)

	# Four legs (strider stance: front pair forward, rear pair back).
	var hip_h := 0.92
	_walker_leg(rig, Vector3(-0.42, hip_h, 0.52), Vector3(-0.78, 0.0, 0.86), true, true)
	_walker_leg(rig, Vector3(0.42, hip_h, 0.52), Vector3(0.78, 0.0, 0.86), false, true)
	_walker_leg(rig, Vector3(-0.46, hip_h, -0.34), Vector3(-0.86, 0.0, -0.72), true, false)
	_walker_leg(rig, Vector3(0.46, hip_h, -0.34), Vector3(0.86, 0.0, -0.72), false, false)


func _walker_torso(torso: Node3D) -> void:
	var flesh := _bm_flesh_mat(color_a)
	var flesh_deep := _bm_flesh_mat(color_a.darkened(0.3))

	# Main body mass — elongated along Z, biased rearward.
	_bm_ellipsoid(torso, Vector3(0.66, 0.52, 0.86), Vector3(0.0, 0.0, -0.08), flesh)
	# Forward chest swell, split to either side (hollow for the core).
	for sx: float in [-1.0, 1.0]:
		_bm_ellipsoid(torso, Vector3(0.40, 0.44, 0.42), Vector3(0.30 * sx, 0.16, 0.56), flesh)
	_bm_ellipsoid(torso, Vector3(0.60, 0.54, 0.50), Vector3(0.0, 0.05, -0.58), flesh_deep)
	# Sagging underbelly.
	_bm_ellipsoid(torso, Vector3(0.50, 0.34, 0.78), Vector3(0.0, -0.34, 0.04), flesh_deep)

	# Emissive veins crawling over the flesh.
	_walker_vein_lines(torso)

	# Dark armoured plates sheathing the spine.
	var spine_mat := _bm_metal_mat(color_b, _STEEL_TINT, 0.12)
	var plate_zs: Array[float] = [0.52, 0.18, -0.20, -0.56]
	var plate_tilts: Array[float] = [-0.30, -0.10, 0.10, 0.34]
	for i: int in range(plate_zs.size()):
		var plate := _bm_box(torso, Vector3(0.66, 0.12, 0.30),
			Vector3(0.0, 0.40 - absf(plate_zs[i]) * 0.10, plate_zs[i]), spine_mat)
		plate.rotation = Vector3(plate_tilts[i], 0.0, 0.0)
		var nub := _bm_box(torso, Vector3(0.12, 0.16, 0.16),
			Vector3(0.0, 0.50 - absf(plate_zs[i]) * 0.10, plate_zs[i]), spine_mat)
		nub.rotation = Vector3(plate_tilts[i], 0.0, 0.0)

	# Flank pauldrons (side armour over the hips).
	for sx: float in [-1.0, 1.0]:
		var pauldron := _bm_box(torso, Vector3(0.20, 0.34, 0.46),
			Vector3(0.56 * sx, 0.12, 0.40), _bm_metal_mat(color_b, _STEEL_TINT, 0.12))
		pauldron.rotation = Vector3(0.0, 0.0, -0.35 * sx)
		var rear_plate := _bm_box(torso, Vector3(0.18, 0.30, 0.40),
			Vector3(0.55 * sx, 0.10, -0.46), _bm_metal_mat(color_b, _STEEL_TINT, 0.12))
		rear_plate.rotation = Vector3(0.0, 0.0, -0.30 * sx)


func _walker_vein_lines(torso: Node3D) -> void:
	var vmat := _bm_glow_mat(accent.lightened(0.05), 1.7)
	var paths: Array[PackedVector3Array] = [
		PackedVector3Array([Vector3(0.0, -0.30, 0.55), Vector3(0.22, 0.05, 0.70), Vector3(0.30, 0.32, 0.55)]),
		PackedVector3Array([Vector3(0.0, -0.30, 0.55), Vector3(-0.24, 0.02, 0.66), Vector3(-0.34, 0.30, 0.42)]),
		PackedVector3Array([Vector3(0.0, -0.28, 0.40), Vector3(0.10, -0.10, -0.10), Vector3(0.18, 0.20, -0.50)]),
		PackedVector3Array([Vector3(0.0, -0.28, 0.40), Vector3(-0.12, -0.08, -0.12), Vector3(-0.20, 0.18, -0.52)]),
	]
	for path: PackedVector3Array in paths:
		for i: int in range(path.size() - 1):
			_bm_segment(torso, path[i], path[i + 1], 0.018, vmat, 8)
		for p: Vector3 in path:
			_bm_sphere(torso, 0.03, p, vmat, 8, 12)


func _walker_core(torso: Node3D) -> void:
	var core_anchor := Vector3(0.0, 0.10, 0.92)

	# Outer translucent halo shell.
	_bm_sphere(torso, 0.235, core_anchor, _bm_glow_mat(accent.lightened(0.2), 1.4, 0.22))
	# Bright heart.
	_bm_sphere(torso, 0.175, core_anchor, _bm_glow_mat(accent, 3.6))
	# Inner hot nucleus.
	_bm_sphere(torso, 0.088, core_anchor, _bm_glow_mat(accent.lightened(0.25), 5.2))

	# RIBCAGE — curved metal struts arcing over the heart, bowed toward +Z.
	var rib_mat := _bm_metal_mat(color_b.lightened(0.04), accent.darkened(0.2), 0.16)
	var n_ribs := 6
	for i: int in range(n_ribs):
		var t := float(i) / float(n_ribs - 1)
		var x := lerpf(-0.26, 0.26, t)
		var top := core_anchor + Vector3(x * 0.55, 0.32, -0.04)
		var bot := core_anchor + Vector3(x * 0.85, -0.32, 0.02)
		var mid := core_anchor + Vector3(x, 0.0, 0.205)
		_bm_capsule_segment(torso, top, mid, 0.028, rib_mat)
		_bm_capsule_segment(torso, mid, bot, 0.028, rib_mat)

	# Central vertical sternum strut.
	_bm_capsule_segment(torso, core_anchor + Vector3(0.0, 0.32, 0.02),
		core_anchor + Vector3(0.0, -0.32, 0.06), 0.034, rib_mat)

	# Two short cable tendons feeding the heart.
	var cmat := _bm_metal_mat(Color(0.08, 0.085, 0.10), _STEEL_TINT, 0.04, 0.2)
	_bm_capsule_segment(torso, core_anchor + Vector3(0.10, 0.10, -0.10), Vector3(0.18, 0.30, -0.10), 0.03, cmat)
	_bm_capsule_segment(torso, core_anchor + Vector3(-0.10, 0.10, -0.10), Vector3(-0.18, 0.30, -0.10), 0.03, cmat)


func _walker_head(torso: Node3D) -> void:
	var neck_base := Vector3(0.0, 0.10, 0.98)
	var head_anchor := Vector3(0.0, -0.14, 1.42)

	# Short armoured neck collar.
	var collar_mat := _bm_metal_mat(color_b, _STEEL_TINT, 0.13)
	_bm_capsule_segment(torso, neck_base, head_anchor, 0.13, collar_mat)
	var collar_ring := _bm_cylinder(torso, 0.17, 0.20, 0.12,
		neck_base + (head_anchor - neck_base) * 0.35, collar_mat, 16)
	collar_ring.rotation = Vector3(deg_to_rad(72.0), 0.0, 0.0)

	var head := Node3D.new()
	head.name = "Head"
	head.position = head_anchor
	head.rotation = Vector3(deg_to_rad(-14.0), 0.0, 0.0)
	torso.add_child(head)

	# Main skull wedge + snout cap.
	_bm_box(head, Vector3(0.30, 0.24, 0.40), Vector3(0.0, 0.0, 0.06), _bm_metal_mat(color_b, _STEEL_TINT, 0.14))
	_bm_box(head, Vector3(0.18, 0.15, 0.18), Vector3(0.0, -0.02, 0.30), _bm_metal_mat(color_b.lightened(0.04), _STEEL_TINT, 0.14))

	# Cheek armour plates.
	for sx: float in [-1.0, 1.0]:
		var cheek := _bm_box(head, Vector3(0.06, 0.18, 0.30), Vector3(0.17 * sx, 0.0, 0.06), _bm_metal_mat(color_b, _STEEL_TINT, 0.13))
		cheek.rotation = Vector3(0.0, 0.0, -0.18 * sx)

	# Glowing eye band + twin eye pods.
	_bm_box(head, Vector3(0.22, 0.05, 0.04), Vector3(0.0, 0.02, 0.39), _bm_glow_mat(accent.lightened(0.2), 4.2))
	for sx: float in [-1.0, 1.0]:
		_bm_sphere(head, 0.045, Vector3(0.085 * sx, 0.03, 0.40), _bm_glow_mat(accent, 4.6), 10, 14)

	# Sensor stalks rising from the back of the skull.
	var stalk_mat := _bm_metal_mat(color_b.lightened(0.04), _STEEL_TINT, 0.14, -0.12)
	var tip_mat := _bm_glow_mat(accent.lightened(0.05), 2.6)
	var stalks: Array[Vector3] = [
		Vector3(0.10, 0.20, -0.16),
		Vector3(-0.08, 0.24, -0.18),
		Vector3(0.02, 0.30, -0.10),
	]
	for tip: Vector3 in stalks:
		_bm_capsule_segment(head, Vector3(0.0, 0.10, -0.10), tip, 0.016, stalk_mat)
		_bm_sphere(head, 0.028, tip, tip_mat, 8, 12)


func _walker_tail_vent(torso: Node3D) -> void:
	var seg_mat := _bm_metal_mat(color_b.lightened(0.04), _STEEL_TINT, 0.14)
	var p0 := Vector3(0.0, 0.05, -0.86)
	var p1 := Vector3(0.0, -0.08, -1.12)
	var p2 := Vector3(0.0, -0.26, -1.30)
	_bm_capsule_segment(torso, p0, p1, 0.10, seg_mat)
	_bm_capsule_segment(torso, p1, p2, 0.07, seg_mat)
	var c0 := _bm_cylinder(torso, 0.12, 0.13, 0.06, p0, seg_mat, 16)
	c0.rotation = Vector3(deg_to_rad(64.0), 0.0, 0.0)
	# Glowing rear vent.
	var vent := _bm_cylinder(torso, 0.08, 0.05, 0.07, p2, _bm_glow_mat(accent, 3.0), 16)
	vent.rotation = Vector3(deg_to_rad(58.0), 0.0, 0.0)


func _walker_leg(rig: Node3D, hip_world: Vector3, foot_world: Vector3, left: bool, front: bool) -> void:
	var leg := Node3D.new()
	leg.name = ("Leg_%s_%s" % ["L" if left else "R", "F" if front else "B"])
	rig.add_child(leg)

	var leg_mat := _bm_metal_mat(color_b.lightened(0.04), _STEEL_TINT, 0.13)
	var joint_mat := _bm_metal_mat(color_b, _STEEL_TINT, 0.16, -0.1)

	# Hip ball socket + armour cowl.
	_bm_sphere(leg, 0.135, hip_world, joint_mat, 12, 18)
	_bm_box(leg, Vector3(0.22, 0.20, 0.24), hip_world + Vector3(0.0, 0.02, 0.0), leg_mat)

	# KNEE: bowed outward and up (strider "/\").
	var side := (1.0 if not left else -1.0)
	var knee := hip_world.lerp(foot_world, 0.46)
	knee.x += side * 0.30
	knee.y += 0.16

	# THIGH + outer armour plate.
	_bm_capsule_segment(leg, hip_world, knee, 0.085, leg_mat)
	var thigh_mid := hip_world.lerp(knee, 0.5)
	var thigh_plate := _bm_box(leg, Vector3(0.14, 0.30, 0.10), thigh_mid + Vector3(side * 0.07, 0.0, 0.02), leg_mat)
	# Orient the plate to face along the bone via a Basis (no out-of-tree look_at).
	thigh_plate.transform = Transform3D(_bm_basis_from_up((knee - thigh_plate.position).normalized()),
		thigh_plate.position)

	# KNEE joint pivot (visible machine elbow).
	_bm_sphere(leg, 0.10, knee, joint_mat, 12, 18)
	var knee_cap := _bm_cylinder(leg, 0.085, 0.085, 0.20, knee, joint_mat, 14)
	knee_cap.rotation = Vector3(0.0, 0.0, deg_to_rad(90.0))

	# SHIN.
	_bm_capsule_segment(leg, knee, foot_world, 0.06, leg_mat)

	# ANKLE + FOOT.
	_bm_sphere(leg, 0.07, foot_world + Vector3(0.0, 0.05, 0.0), joint_mat, 12, 18)
	_walker_foot(leg, foot_world, front)

	# HYDRAULIC PISTON alongside the thigh (dark barrel + bright rod).
	var piston_top := hip_world + Vector3(side * 0.10, 0.30, -0.06)
	var piston_mid := piston_top.lerp(knee, 0.55)
	_bm_capsule_segment(leg, piston_top, piston_mid, 0.045, joint_mat)
	_bm_capsule_segment(leg, piston_mid, knee, 0.028, _walker_piston_mat())

	# Cable tendon running the back of the leg (slack-bowed).
	var cmat := _bm_metal_mat(Color(0.08, 0.085, 0.10), _STEEL_TINT, 0.03, 0.23)
	var cable_bow := hip_world.lerp(foot_world, 0.5) + Vector3(side * -0.12, -0.04, -0.10)
	_bm_capsule_segment(leg, hip_world + Vector3(0.0, -0.05, -0.08), cable_bow, 0.022, cmat)
	_bm_capsule_segment(leg, cable_bow, foot_world + Vector3(0.0, 0.10, -0.04), 0.022, cmat)


## Bright machined rod (pistons) — a highlight against the dark legs.
func _walker_piston_mat() -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color = Color(0.55, 0.57, 0.60)
	m.roughness = 0.22
	m.metallic = 1.0
	m.emission_enabled = true
	m.emission = Color(0.55, 0.57, 0.60)
	m.emission_energy_multiplier = 0.06
	return m


func _walker_foot(leg: Node3D, foot_world: Vector3, front: bool) -> void:
	var foot_mat := _bm_metal_mat(color_b, _STEEL_TINT, 0.13)
	var claw_mat := _bm_metal_mat(color_b.lightened(0.04), _STEEL_TINT, 0.15)

	# Central foot pad.
	_bm_box(leg, Vector3(0.26, 0.10, 0.34), foot_world + Vector3(0.0, 0.05, 0.02), foot_mat)

	# Splayed toe claws.
	var fz := (1.0 if front else -1.0)
	var toe_dirs: Array[Vector3] = [
		Vector3(-0.16, 0.0, 0.20 * fz),
		Vector3(0.0, 0.0, 0.26 * fz),
		Vector3(0.16, 0.0, 0.20 * fz),
	]
	for d: Vector3 in toe_dirs:
		var base := foot_world + Vector3(0.0, 0.05, 0.0)
		var tip := base + d + Vector3(0.0, -0.03, 0.0)
		_bm_capsule_segment(leg, base, tip, 0.035, claw_mat)
		# sharp claw point (cone apex pointing along the toe direction).
		var claw := _bm_cone(leg, 0.045, 0.10, tip, claw_mat)
		claw.transform = Transform3D(_bm_basis_from_up(d.normalized()), tip)
