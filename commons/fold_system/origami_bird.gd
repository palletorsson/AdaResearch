# @identity
# essence: fold_amount maps a continuous origami crane — egg(0.0) → standing(0.4) → walking(0.6) → flying(1.0)
# desire: a paper bird that hatches from a folded seed, stands on two legs, walks with a gait, then unfolds into soaring flight
# critical_parameter: fold_amount — 0.0 is tight origami egg, 0.4 is standing crane, 0.6 is walking, 1.0 is full wingspan flight
# triggers: FSM drives fold_amount through spring dynamics; proximity triggers hatch; energy gates flight
# emerges: walking gait from sinusoidal leg alternation during WALKING state; flight from wing flap cycle during DEPLOYED
# needs: FoldCritter base [has]; BoneFoldSolver [has]; procedural mesh [built here]
# relationships: first creature to use full fold progression (egg→stand→walk→fly); extends fold_demo_critter pattern
# truth: One fold_amount variable, twelve segments, four locomotion modes. Origami is compressed potential.

class_name OrigamiBird
extends FoldCritter
## Origami crane that progresses through four fold stages:
## EGG (0.0) → STANDING (0.4) → WALKING (0.6) → FLYING (1.0)
## Each stage is a different origami crease pattern of the same body.

# ── Custom States ───────────────────────────────────────────────────────
# We extend the base FSM with sub-states for locomotion modes.
# fold_amount ranges:
#   0.00 - 0.10  EGG: tight folded seed
#   0.10 - 0.35  HATCHING: shell cracks, body emerges
#   0.35 - 0.55  STANDING: upright crane pose, legs extended
#   0.55 - 0.75  WALKING: alternating leg gait, wings half-spread
#   0.75 - 1.00  FLYING: full wingspan, legs tucked, wing flap cycle

enum BirdMode { EGG_SEED, HATCHING, STANDING, WALKING, FLYING }
var bird_mode: BirdMode = BirdMode.EGG_SEED

# ── Locomotion ──────────────────────────────────────────────────────────
var _walk_phase: float = 0.0
var _flap_phase: float = 0.0
var _walk_speed: float = 1.2
var _flap_speed: float = 3.0
@export var move_speed: float = 1.5
@export var fly_height: float = 1.5

# ── Egg visual ──────────────────────────────────────────────────────────
var _egg_mesh: MeshInstance3D = null
var _egg_alpha: float = 1.0

# ── Materials ───────────────────────────────────────────────────────────
var _mat_body: StandardMaterial3D
var _mat_wing: StandardMaterial3D
var _mat_tail: StandardMaterial3D
var _mat_beak: StandardMaterial3D
var _mat_leg: StandardMaterial3D
var _mat_egg: StandardMaterial3D

# ── Body references ─────────────────────────────────────────────────────
var _body_root: Node3D = null


func _ready() -> void:
	_create_materials()
	_create_fold_rig()
	_build_fold_mesh()
	_create_collision()
	super._ready()

	# Start as egg
	fold_state = FoldState.EGG
	fold_amount = 0.0
	target_fold = 0.0
	bird_mode = BirdMode.EGG_SEED


# ═════════════════════════════════════════════════════════════════════════
# FOLD RIG — 12 segments for full origami crane
# ═════════════════════════════════════════════════════════════════════════

func _create_fold_rig() -> void:
	fold_rig = FoldRig.new()
	fold_rig.solver = BoneFoldSolver.new()
	fold_rig.base_stiffness = 14.0
	fold_rig.base_damping = 0.88
	fold_rig.max_fold_energy = 1.5
	fold_rig.is_hatchable = true
	fold_rig.supports_misfold = true
	fold_rig.supports_latch = true

	var segments: Array[FoldSegmentData] = []
	var constraints: Array[FoldConstraintData] = []

	# ── TRANSFORMER CASCADE ──
	# Each segment has an activation window [start, end] within fold_amount 0→1.
	# The bird unfolds in sequence: body → legs → neck → wings → tail → head → beak → wingtips
	# Like Bumblebee: hood first, arms second, legs third, head last.

	# Core body — always present, no rotation                   activation: 0.0 - 1.0
	segments.append(_seg(&"body", Vector3.RIGHT, 0.0, 0.0, &"", 0.0, &"bone", 3.0,
		Vector3(0.1, 0.08, 0.18), 0.08, Vector3.ZERO, 0.0, 1.0))

	# Legs deploy first (standing up)                           activation: 0.05 - 0.35
	segments.append(_seg(&"leg_left", Vector3.FORWARD, 90.0, -30.0, &"body", 0.0, &"bone", 0.5,
		Vector3(0.012, 0.12, 0.012), 0.012, Vector3(-0.03, -0.04, 0.02), 0.05, 0.35))
	segments.append(_seg(&"leg_right", Vector3.FORWARD, -90.0, 30.0, &"body", 0.0, &"bone", 0.5,
		Vector3(0.012, 0.12, 0.012), 0.012, Vector3(0.03, -0.04, 0.02), 0.05, 0.35))

	# Feet follow legs                                          activation: 0.15 - 0.40
	segments.append(_seg(&"foot_left", Vector3.RIGHT, 0.0, 60.0, &"leg_left", 0.0, &"bone", 0.2,
		Vector3(0.025, 0.005, 0.035), 0.005, Vector3(0.0, -0.12, 0.0), 0.15, 0.40))
	segments.append(_seg(&"foot_right", Vector3.RIGHT, 0.0, 60.0, &"leg_right", 0.0, &"bone", 0.2,
		Vector3(0.025, 0.005, 0.035), 0.005, Vector3(0.0, -0.12, 0.0), 0.15, 0.40))

	# Neck rises (head chain starts)                            activation: 0.15 - 0.50
	segments.append(_seg(&"neck", Vector3.RIGHT, -90.0, 30.0, &"body", 0.0, &"bone", 1.0,
		Vector3(0.03, 0.03, 0.12), 0.03, Vector3(0.0, 0.04, -0.09), 0.15, 0.50))

	# Tail fans out (early, decorative)                         activation: 0.10 - 0.45
	segments.append(_seg(&"tail", Vector3.RIGHT, -20.0, 40.0, &"body", 0.0, &"membrane", 0.6,
		Vector3(0.08, 0.005, 0.1), 0.005, Vector3(0.0, 0.0, 0.09), 0.10, 0.45))

	# Wings spread (the main event)                             activation: 0.30 - 0.70
	segments.append(_seg(&"wing_left", Vector3.FORWARD, 0.0, 150.0, &"body", 0.0, &"membrane", 1.0,
		Vector3(0.22, 0.005, 0.16), 0.005, Vector3(-0.05, 0.0, 0.0), 0.30, 0.70))
	segments.append(_seg(&"wing_right", Vector3.FORWARD, 0.0, -150.0, &"body", 0.0, &"membrane", 1.0,
		Vector3(0.22, 0.005, 0.16), 0.005, Vector3(0.05, 0.0, 0.0), 0.30, 0.70))

	# Head appears (after neck is mostly up)                    activation: 0.40 - 0.65
	segments.append(_seg(&"head", Vector3.RIGHT, -30.0, 15.0, &"neck", 0.0, &"bone", 0.5,
		Vector3(0.05, 0.04, 0.05), 0.025, Vector3(0.0, 0.0, -0.12), 0.40, 0.65))

	# Beak opens last (character reveal)                        activation: 0.55 - 0.75
	segments.append(_seg(&"beak", Vector3.RIGHT, 0.0, -20.0, &"head", 0.0, &"bone", 0.2,
		Vector3(0.015, 0.01, 0.04), 0.01, Vector3(0.0, 0.0, -0.025), 0.55, 0.75))

	# Wingtips extend last (full wingspan)                      activation: 0.60 - 0.85
	segments.append(_seg(&"wingtip_left", Vector3.FORWARD, 0.0, 30.0, &"wing_left", 0.0, &"membrane", 0.3,
		Vector3(0.1, 0.005, 0.06), 0.005, Vector3(-0.22, 0.0, 0.0), 0.60, 0.85))
	segments.append(_seg(&"wingtip_right", Vector3.FORWARD, 0.0, -30.0, &"wing_right", 0.0, &"membrane", 0.3,
		Vector3(0.1, 0.005, 0.06), 0.005, Vector3(0.22, 0.0, 0.0), 0.60, 0.85))

	fold_rig.segments = segments

	# ── Constraints ──
	constraints.append(_con(&"wing_left", 0.0, 150.0))
	constraints.append(_con(&"wing_right", -150.0, 0.0))
	constraints.append(_con(&"neck", -90.0, 30.0))
	constraints.append(_con(&"tail", -20.0, 40.0))
	constraints.append(_con(&"leg_left", -30.0, 90.0))
	constraints.append(_con(&"leg_right", -90.0, 30.0))

	fold_rig.constraints = constraints


# ═════════════════════════════════════════════════════════════════════════
# MATERIALS — paper-white with colored accents
# ═════════════════════════════════════════════════════════════════════════

func _create_materials() -> void:
	_mat_body = _paper_mat(Color(0.92, 0.90, 0.85), Color(0.15, 0.12, 0.10), 0.4)
	_mat_wing = _paper_mat(Color(0.95, 0.93, 0.88), Color(0.18, 0.15, 0.10), 0.5)
	_mat_tail = _paper_mat(Color(0.88, 0.85, 0.80), Color(0.12, 0.10, 0.08), 0.4)
	_mat_beak = _paper_mat(Color(0.95, 0.65, 0.15), Color(0.50, 0.30, 0.05), 0.8)
	_mat_leg = _paper_mat(Color(0.90, 0.60, 0.20), Color(0.45, 0.25, 0.05), 0.6)
	_mat_egg = _paper_mat(Color(0.85, 0.82, 0.78), Color(0.10, 0.08, 0.06), 0.3)


func _paper_mat(albedo: Color, emission: Color, emission_energy: float) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = albedo
	mat.roughness = 0.85  # Paper texture
	mat.metallic = 0.0
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED  # Paper is double-sided
	mat.emission_enabled = true
	mat.emission = emission
	mat.emission_energy_multiplier = emission_energy
	return mat


# ═════════════════════════════════════════════════════════════════════════
# MESH — procedural origami crane geometry
# ═════════════════════════════════════════════════════════════════════════

func _build_fold_mesh() -> void:
	_segment_nodes.clear()

	# Egg shell — folded diamond (NOT a sphere — origami eggs are angular)
	_egg_mesh = MeshInstance3D.new()
	_egg_mesh.name = "EggShell"
	_egg_mesh.mesh = _make_diamond_mesh(0.1, 0.14, _mat_egg)
	_egg_mesh.material_override = _mat_egg
	add_child(_egg_mesh)

	_body_root = Node3D.new()
	_body_root.name = "BodyRoot"
	add_child(_body_root)

	# ── ALL ORIGAMI PANELS IN NESTED BONE HIERARCHY ──
	# Every piece is a flat triangular/diamond panel. No spheres. No boxes.
	# Sharp creases. Paper-flat surfaces. This is folded geometry.

	# ═══════════════════════════════════════════════════════════════
	# PART 1: BODY DIAMOND — the central torso
	# Two pyramids meeting at a horizontal equator. Ridge on top.
	# This is the only piece until we get it perfect.
	# ═══════════════════════════════════════════════════════════════
	var body_node := _make_seg_node(&"body", Vector3.ZERO, _body_root)
	var body_mi := MeshInstance3D.new()
	body_mi.mesh = _make_diamond_mesh(0.12, 0.24, _mat_body)
	body_node.add_child(body_mi)

	# ═══════════════════════════════════════════════════════════════
	# PART 2: WINGS — hinged at body left/right edges
	# Crease ridge runs from root to tip. Tapered triangle panels.
	# Pivot point is at the body edge so wings fold flush against body.
	# ═══════════════════════════════════════════════════════════════
	var wl_node := _make_seg_node(&"wing_left", Vector3(-0.06, 0.005, 0.0), body_node)
	_add_wing_mesh(wl_node, -1.0, _mat_wing)

	var wr_node := _make_seg_node(&"wing_right", Vector3(0.06, 0.005, 0.0), body_node)
	_add_wing_mesh(wr_node, 1.0, _mat_wing)

	# ═══════════════════════════════════════════════════════════════
	# PART 3: NECK + HEAD + BEAK — forward chain
	# Neck is a thin folded strip emerging from body front tip.
	# Head is a small diamond at the end of the neck.
	# Beak is a pointed triangle at the head front.
	# All flush — no visible gaps between segments.
	# ═══════════════════════════════════════════════════════════════

	# body → neck — hinge at body front tip
	var neck_node := _make_seg_node(&"neck", Vector3(0.0, 0.02, -0.1), body_node)
	var neck_mi := MeshInstance3D.new()
	neck_mi.mesh = _make_strip_mesh(0.012, 0.09, _mat_body)
	neck_mi.position = Vector3(0.0, 0.0, -0.045)  # Center the strip along its length
	neck_node.add_child(neck_mi)

	# neck → head — small diamond flush at neck end
	var head_node := _make_seg_node(&"head", Vector3(0.0, 0.0, -0.085), neck_node)
	var head_mi := MeshInstance3D.new()
	head_mi.mesh = _make_diamond_mesh(0.018, 0.035, _mat_body)
	head_node.add_child(head_mi)

	# head → beak — pointed triangle flush at head front tip
	var beak_node := _make_seg_node(&"beak", Vector3(0.0, 0.0, -0.017), head_node)
	var beak_mi := MeshInstance3D.new()
	beak_mi.mesh = _make_pointed_mesh(0.007, 0.03, _mat_beak)
	beak_mi.position = Vector3(0.0, 0.0, -0.015)  # Point extends forward from head
	beak_node.add_child(beak_mi)
	# ═══════════════════════════════════════════════════════════════
	# PART 4: LEGS + FEET — two paper strips with triangle pads
	# Hinge at body underside, slightly behind center.
	# Short enough to tuck against body when folded.
	# ═══════════════════════════════════════════════════════════════

	# body → leg_left
	var ll_node := _make_seg_node(&"leg_left", Vector3(-0.02, -0.03, 0.015), body_node)
	var ll_mi := MeshInstance3D.new()
	ll_mi.mesh = _make_strip_mesh(0.005, 0.065, _mat_leg)
	ll_mi.position = Vector3(0.0, -0.032, 0.0)
	ll_mi.rotation_degrees.x = 90.0
	ll_node.add_child(ll_mi)

	# body → leg_right
	var lr_node := _make_seg_node(&"leg_right", Vector3(0.02, -0.03, 0.015), body_node)
	var lr_mi := MeshInstance3D.new()
	lr_mi.mesh = _make_strip_mesh(0.005, 0.065, _mat_leg)
	lr_mi.position = Vector3(0.0, -0.032, 0.0)
	lr_mi.rotation_degrees.x = 90.0
	lr_node.add_child(lr_mi)

	# leg_left → foot_left
	var fl_node := _make_seg_node(&"foot_left", Vector3(0.0, -0.065, 0.0), ll_node)
	var fl_mi := MeshInstance3D.new()
	fl_mi.mesh = _make_pointed_mesh(0.01, 0.022, _mat_leg)
	fl_mi.rotation_degrees.x = -90.0
	fl_node.add_child(fl_mi)

	# leg_right → foot_right
	var fr_node := _make_seg_node(&"foot_right", Vector3(0.0, -0.065, 0.0), lr_node)
	var fr_mi := MeshInstance3D.new()
	fr_mi.mesh = _make_pointed_mesh(0.01, 0.022, _mat_leg)
	fr_mi.rotation_degrees.x = -90.0
	fr_node.add_child(fr_mi)

	# ═══════════════════════════════════════════════════════════════
	# PART 5: TAIL FAN — radiating triangles at the back
	# ═══════════════════════════════════════════════════════════════
	var tail_node := _make_seg_node(&"tail", Vector3(0.0, 0.01, 0.1), body_node)
	var tail_mi := MeshInstance3D.new()
	tail_mi.mesh = _make_tail_fan_mesh(0.07, 0.13, _mat_tail)
	tail_mi.position = Vector3(0.0, 0.0, 0.015)
	tail_node.add_child(tail_mi)

	# ═══════════════════════════════════════════════════════════════
	# PART 6: WINGTIPS — pointed extensions at wing ends
	# ═══════════════════════════════════════════════════════════════
	var wtl_node := _make_seg_node(&"wingtip_left", Vector3(-0.20, 0.0, 0.0), wl_node)
	var wtl_mi := MeshInstance3D.new()
	wtl_mi.mesh = _make_pointed_mesh(0.02, 0.07, _mat_wing)
	wtl_mi.rotation_degrees.y = 90.0
	wtl_node.add_child(wtl_mi)

	var wtr_node := _make_seg_node(&"wingtip_right", Vector3(0.20, 0.0, 0.0), wr_node)
	var wtr_mi := MeshInstance3D.new()
	wtr_mi.mesh = _make_pointed_mesh(0.02, 0.07, _mat_wing)
	wtr_mi.rotation_degrees.y = -90.0
	wtr_node.add_child(wtr_mi)


func _add_wing_mesh(parent: Node3D, side: float, mat: StandardMaterial3D) -> void:
	## Origami wing — two triangular panels with a central crease ridge
	var mi := MeshInstance3D.new()
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var span: float = 0.22 * side
	var root_z: float = 0.09
	var tip_z: float = 0.025
	var ridge_height: float = 0.015  # Central crease lifts slightly

	# Root vertices (body edge)
	var r_top := Vector3(0.0, ridge_height, 0.0)
	var r_front := Vector3(0.0, 0.0, -root_z)
	var r_back := Vector3(0.0, 0.0, root_z)
	# Tip vertex (wing end)
	var tip := Vector3(span, 0.0, 0.0)
	# Tip front/back (slight width at tip for crease)
	var tip_front := Vector3(span, 0.0, -tip_z)
	var tip_back := Vector3(span, 0.0, tip_z)

	# Upper panel: ridge → front edge → tip front
	_add_tri(st, r_top, r_front, tip_front)
	_add_tri(st, r_top, tip_front, tip)
	# Lower panel: ridge → tip back → back edge
	_add_tri(st, r_top, tip, tip_back)
	_add_tri(st, r_top, tip_back, r_back)
	# Underside (reverse winding)
	_add_tri(st, r_top, tip_front, r_front)
	_add_tri(st, r_top, tip, tip_front)
	_add_tri(st, r_top, tip_back, tip)
	_add_tri(st, r_top, r_back, tip_back)

	st.generate_normals()
	mi.mesh = st.commit()
	mi.material_override = mat
	parent.add_child(mi)


func _add_tri(st: SurfaceTool, a: Vector3, b: Vector3, c: Vector3) -> void:
	var normal := (b - a).cross(c - a).normalized()
	if normal.length() < 0.001:
		normal = Vector3.UP
	st.set_normal(normal)
	st.add_vertex(a)
	st.set_normal(normal)
	st.add_vertex(b)
	st.set_normal(normal)
	st.add_vertex(c)


## Diamond mesh — two pyramids meeting at an equator. The origami body shape.
func _make_diamond_mesh(half_width: float, length: float, mat: StandardMaterial3D) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := half_width
	var hl := length * 0.5
	var ridge := half_width * 0.6  # Height of the ridge

	# 6 vertices: front tip, back tip, left, right, top ridge, bottom ridge
	var front := Vector3(0, 0, -hl)
	var back := Vector3(0, 0, hl)
	var left := Vector3(-hw, 0, 0)
	var right := Vector3(hw, 0, 0)
	var top := Vector3(0, ridge, 0)
	var bottom := Vector3(0, -ridge * 0.5, 0)

	# Upper 4 faces
	_add_tri(st, top, front, right)
	_add_tri(st, top, right, back)
	_add_tri(st, top, back, left)
	_add_tri(st, top, left, front)
	# Lower 4 faces
	_add_tri(st, bottom, right, front)
	_add_tri(st, bottom, back, right)
	_add_tri(st, bottom, left, back)
	_add_tri(st, bottom, front, left)

	st.generate_normals()
	return st.commit()


## Thin flat strip — folded paper edge for necks and legs
func _make_strip_mesh(half_width: float, length: float, mat: StandardMaterial3D) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := half_width
	var hl := length * 0.5
	var ridge := half_width * 0.8

	# 4 faces forming a thin diamond cross-section along Z
	var front := Vector3(0, 0, -hl)
	var back := Vector3(0, 0, hl)
	var top := Vector3(0, ridge, 0)
	var bottom := Vector3(0, -ridge * 0.3, 0)

	_add_tri(st, top, front, back)
	_add_tri(st, bottom, back, front)
	# Side faces for slight width
	var left := Vector3(-hw * 0.5, 0, 0)
	var right := Vector3(hw * 0.5, 0, 0)
	_add_tri(st, right, front, back)
	_add_tri(st, left, back, front)

	st.generate_normals()
	return st.commit()


## Pointed triangle — for beaks, feet, wingtips
func _make_pointed_mesh(half_base: float, length: float, mat: StandardMaterial3D) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hb := half_base
	var ridge := half_base * 0.5

	var tip := Vector3(0, 0, -length)
	var base_left := Vector3(-hb, 0, 0)
	var base_right := Vector3(hb, 0, 0)
	var base_top := Vector3(0, ridge, 0)

	# Upper face
	_add_tri(st, base_top, base_left, tip)
	_add_tri(st, base_top, tip, base_right)
	# Lower face
	_add_tri(st, base_top, tip, base_left)
	_add_tri(st, base_top, base_right, tip)

	st.generate_normals()
	return st.commit()


## Tail fan — three radiating triangular panels
func _make_tail_fan_mesh(half_width: float, length: float, mat: StandardMaterial3D) -> ArrayMesh:
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var hw := half_width
	var ridge := half_width * 0.3

	var base := Vector3.ZERO
	var base_top := Vector3(0, ridge, 0)
	# Three fan tips
	var tip_center := Vector3(0, 0, length)
	var tip_left := Vector3(-hw, ridge * 0.5, length * 0.85)
	var tip_right := Vector3(hw, ridge * 0.5, length * 0.85)

	# Center panel
	_add_tri(st, base_top, base, tip_center)
	# Left panel
	_add_tri(st, base_top, tip_left, base)
	_add_tri(st, base_top, tip_center, tip_left)
	# Right panel
	_add_tri(st, base_top, base, tip_right)
	_add_tri(st, base_top, tip_right, tip_center)
	# Underside
	_add_tri(st, base, base_top, tip_center)
	_add_tri(st, base, tip_left, base_top)
	_add_tri(st, tip_left, tip_center, base_top)
	_add_tri(st, base, base_top, tip_right)
	_add_tri(st, tip_center, tip_right, base_top)

	st.generate_normals()
	return st.commit()


# ═════════════════════════════════════════════════════════════════════════
# COLLISION
# ═════════════════════════════════════════════════════════════════════════

func _create_collision() -> void:
	var col := CollisionShape3D.new()
	var shape := SphereShape3D.new()
	shape.radius = 0.2
	col.shape = shape
	add_child(col)


# ═════════════════════════════════════════════════════════════════════════
# CUSTOM PHYSICS — bird-specific locomotion layered on fold system
# ═════════════════════════════════════════════════════════════════════════

func _physics_process(delta: float) -> void:
	super._physics_process(delta)
	_update_bird_mode()
	_update_egg_visual(delta)
	_update_locomotion(delta)


func _update_bird_mode() -> void:
	var old := bird_mode
	if fold_amount < 0.10:
		bird_mode = BirdMode.EGG_SEED
	elif fold_amount < 0.35:
		bird_mode = BirdMode.HATCHING
	elif fold_amount < 0.55:
		bird_mode = BirdMode.STANDING
	elif fold_amount < 0.75:
		bird_mode = BirdMode.WALKING
	else:
		bird_mode = BirdMode.FLYING


func _update_egg_visual(delta: float) -> void:
	if not _egg_mesh:
		return

	match bird_mode:
		BirdMode.EGG_SEED:
			# Egg fully visible, body hidden
			_egg_alpha = move_toward(_egg_alpha, 1.0, delta * 3.0)
			_egg_mesh.visible = true
			if _body_root:
				_body_root.visible = false
			# Gentle sway
			_egg_mesh.rotation.x = sin(Time.get_ticks_msec() * 0.002) * 0.03
			_egg_mesh.rotation.z = cos(Time.get_ticks_msec() * 0.0015) * 0.02

		BirdMode.HATCHING:
			# Egg cracks and fades, body emerges
			var hatch_t: float = (fold_amount - 0.10) / 0.25  # 0→1 over hatching range
			_egg_alpha = 1.0 - hatch_t
			_egg_mesh.visible = _egg_alpha > 0.01
			if _body_root:
				_body_root.visible = true

			# Egg trembles during hatch
			if hatch_t < 0.5:
				var tremble: float = sin(Time.get_ticks_msec() * 0.05) * 0.02 * (1.0 - hatch_t * 2.0)
				_egg_mesh.rotation.x = tremble
				_egg_mesh.rotation.z = tremble * 0.7

			# Scale egg down
			var egg_scale: float = lerp(1.0, 0.3, hatch_t)
			_egg_mesh.scale = Vector3.ONE * egg_scale

			# Update egg alpha
			_mat_egg.albedo_color.a = _egg_alpha
			if _egg_alpha < 1.0:
				_mat_egg.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA

		_:
			# Post-hatch: egg gone, body fully visible
			_egg_mesh.visible = false
			if _body_root:
				_body_root.visible = true
			_mat_egg.transparency = BaseMaterial3D.TRANSPARENCY_DISABLED


func _update_locomotion(delta: float) -> void:
	match bird_mode:
		BirdMode.STANDING:
			# Subtle head bob
			_apply_head_bob(delta, 0.005, 1.5)
			velocity = Vector3.ZERO

		BirdMode.WALKING:
			_walk_phase += delta * _walk_speed * TAU
			_apply_walk_gait(delta)
			_apply_head_bob(delta, 0.01, 3.0)
			# Move forward
			var forward_dir := -global_basis.z
			velocity = forward_dir * move_speed * 0.5

		BirdMode.FLYING:
			_flap_phase += delta * _flap_speed * TAU
			_apply_wing_flap(delta)
			# Lift off
			var target_y: float = global_position.y + fly_height
			velocity.y = (target_y - global_position.y) * 2.0
			var forward_dir := -global_basis.z
			velocity.x = forward_dir.x * move_speed
			velocity.z = forward_dir.z * move_speed

		_:
			velocity = Vector3.ZERO


func _apply_walk_gait(_delta: float) -> void:
	## Alternate leg rotation for walking — sinusoidal phase offset
	var leg_left_node: Node3D = _segment_nodes.get(&"leg_left")
	var leg_right_node: Node3D = _segment_nodes.get(&"leg_right")
	if not leg_left_node or not leg_right_node:
		return

	var swing_amplitude: float = 0.25  # Radians
	var left_swing: float = sin(_walk_phase) * swing_amplitude
	var right_swing: float = sin(_walk_phase + PI) * swing_amplitude  # 180° offset

	# Add walk motion on top of fold-solved pose
	leg_left_node.rotate(Vector3.RIGHT, left_swing * 0.1)
	leg_right_node.rotate(Vector3.RIGHT, right_swing * 0.1)


func _apply_wing_flap(_delta: float) -> void:
	## Sinusoidal wing flap cycle during flight
	var wl_node: Node3D = _segment_nodes.get(&"wing_left")
	var wr_node: Node3D = _segment_nodes.get(&"wing_right")
	if not wl_node or not wr_node:
		return

	var flap_amplitude: float = 0.3  # Radians
	var flap: float = sin(_flap_phase) * flap_amplitude

	# Flap adds rotation on top of deployed pose
	wl_node.rotate(Vector3.FORWARD, flap * 0.15)
	wr_node.rotate(Vector3.FORWARD, -flap * 0.15)

	# Wing tips follow with slight delay
	var wtl_node: Node3D = _segment_nodes.get(&"wingtip_left")
	var wtr_node: Node3D = _segment_nodes.get(&"wingtip_right")
	if wtl_node:
		wtl_node.rotate(Vector3.FORWARD, flap * 0.08)
	if wtr_node:
		wtr_node.rotate(Vector3.FORWARD, -flap * 0.08)


func _apply_head_bob(_delta: float, amplitude: float, speed: float) -> void:
	var head_node: Node3D = _segment_nodes.get(&"head")
	if head_node:
		head_node.rotate(Vector3.RIGHT, sin(Time.get_ticks_msec() * speed * 0.001) * amplitude * 0.1)


# ═════════════════════════════════════════════════════════════════════════
# HELPERS
# ═════════════════════════════════════════════════════════════════════════

func _make_seg_node(seg_name: StringName, offset: Vector3, parent: Node3D = null) -> Node3D:
	var node := Node3D.new()
	node.name = String(seg_name)
	node.position = offset
	if parent:
		parent.add_child(node)
	else:
		_body_root.add_child(node)
	_segment_nodes[seg_name] = node
	return node


func _add_box_mesh(parent: Node3D, size: Vector3, offset: Vector3, mat: StandardMaterial3D) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.material_override = mat
	mi.position = offset
	parent.add_child(mi)
	return mi


func _seg(sname: StringName, axis: Vector3, closed: float, opened: float,
		parent: StringName, parent_min: float, mat_type: StringName, mass_val: float,
		seg_size: Vector3 = Vector3(0.1, 0.1, 0.1), seg_thickness: float = 0.02,
		pivot: Vector3 = Vector3.ZERO,
		act_start: float = 0.0, act_end: float = 1.0) -> FoldSegmentData:
	var s := FoldSegmentData.new()
	s.segment_name = sname
	s.fold_axis = axis
	s.angle_closed = closed
	s.angle_open = opened
	s.parent_segment = parent
	s.parent_min_fold = parent_min
	s.material_type = mat_type
	s.mass = mass_val
	s.size = seg_size
	s.thickness = seg_thickness
	s.pivot_offset = pivot
	s.activation_start = act_start
	s.activation_end = act_end
	return s


func _con(sname: StringName, min_a: float, max_a: float) -> FoldConstraintData:
	var c := FoldConstraintData.new()
	c.segment_name = sname
	c.min_angle = min_a
	c.max_angle = max_a
	return c


# ── Grid Configuration ──────────────────────────────────────────────────

func configure(config: Dictionary) -> void:
	if config.has("affect"):
		affect = str(config["affect"])
	if config.has("fold_amount"):
		fold_amount = float(config["fold_amount"])
		target_fold = fold_amount
	if config.has("move_speed"):
		move_speed = float(config["move_speed"])
	if config.has("fly_height"):
		fly_height = float(config["fly_height"])


func apply_grid_config(config: Dictionary) -> void:
	configure(config)
