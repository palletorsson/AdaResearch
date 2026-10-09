# modulor_cypress.gd — Walkable L-system plant with Modulor-fold leaf scaling.
# Composes TWO substrates at runtime: lsystem_grammar produces the branching
# skeleton, and at every leaf position we drop a scaled-down Modulor "cup"
# (a small cone) — Corbusier's golden-ratio descent applied to Lindenmayer's plant.
#
# This is the walkable twin of gg_ls02_plant_modulor_folded (the graph-grammar
# gallery's crown jewel). That image showed the fold from the outside; this
# artifact lets the player stand next to the dense cypress and see how every
# branch tip gets a further small volume hanging from it.
#
# @identity
# essence: L-system + Modulor fold — two grammars stacked so the tree has foliage that has scale
# desire: To show composition in VR — not "an L-system plant" but "an L-system plant that has been folded"
# critical_parameter: modulor_level — how deep Corbusier's descent goes. Higher = tinier leaf-cups, denser canopy.
# triggers: Change angle → palm to cypress to bush. Change modulor_level → sparse leaves to dense canopy to moss-like coating.
# emerges: A tree where the composition of two grammars is visible at every tip — big geometry from L-system, small geometry from Modulor.
# needs: VR scale. Label explaining the composition.
# relationships: Walkable twin of gg_ls02_plant_modulor_folded. Sibling of lindenmayer_tube_tree (same L-system skeleton, different finishing layer).
# truth: Two rules stacked, two volumes at every point.

extends Node3D

class_name ModulorCypress

const LSystemSimScript    = preload("res://commons/lsystem_grammar/lsystem_sim.gd")
const LSystemTurtleScript = preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

## L-system DNA
@export var axiom: String = "F"
@export var rule_F: String = "F[+F]F[-F]F"
@export var iterations: int = 4
@export var angle_deg: float = 25.7
@export var step_len: float = 0.24
@export var step_shrink: float = 0.72
@export var base_width: float = 0.028
@export var width_shrink: float = 0.72

## Modulor fold — golden-ratio scale descent at each leaf
## Modulor rung = base * φ^(-level). level 3 ≈ 24cm at 1m base.
const PHI: float = 1.61803398875
@export var modulor_level: int = 3
@export var modulor_base_m: float = 0.45        # base meter at rung 0
@export var leaf_shape: String = "cone"          # cone / sphere

## Colors
@export var color_trunk: Color = Color(0.38, 0.24, 0.12)
@export var color_tip: Color = Color(0.28, 0.55, 0.22)
@export var color_leaf: Color = Color(0.76, 0.43, 0.18)  # Modulor "cup" warm

## Label
@export var show_label: bool = true
@export var label_height: float = 0.45


func _ready() -> void:
	_build_cypress()
	if show_label:
		_build_label()


func _build_cypress() -> void:
	var s: String = LSystemSimScript.rewrite(axiom, {"F": rule_F}, iterations)
	var walk: Dictionary = LSystemTurtleScript.walk(s, {
		"angle_deg":    angle_deg,
		"step_len":     step_len,
		"step_shrink":  step_shrink,
		"base_width":   base_width,
		"width_shrink": width_shrink,
	})
	var segments: Array = walk["segments"]
	if segments.is_empty(): return

	# Identify leaf segments — those whose end point isn't another segment's start.
	# This catches the final segment before each ] pop.
	var start_keys := {}
	for seg in segments:
		var key: String = "%d_%d_%d" % [
			roundi(seg[0].x * 1e4), roundi(seg[0].y * 1e4), roundi(seg[0].z * 1e4)
		]
		start_keys[key] = true
	var leaf_positions: PackedVector3Array = PackedVector3Array()
	for seg in segments:
		var end: Vector3 = seg[1]
		var ek: String = "%d_%d_%d" % [
			roundi(end.x * 1e4), roundi(end.y * 1e4), roundi(end.z * 1e4)
		]
		if not start_keys.has(ek):
			leaf_positions.append(end)

	var max_depth := 1
	for seg in segments:
		max_depth = max(max_depth, int(seg[2]))

	# ─── Branch tubes (L-system skeleton) ─────────────────────
	var branch_mmi := MultiMeshInstance3D.new()
	branch_mmi.name = "Branches"
	var bmm := MultiMesh.new()
	bmm.transform_format = MultiMesh.TRANSFORM_3D
	bmm.use_colors = true
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0; cm.bottom_radius = 1.0; cm.height = 1.0
	cm.radial_segments = 6
	bmm.mesh = cm
	bmm.instance_count = segments.size()
	for i in segments.size():
		var seg = segments[i]
		var a: Vector3 = seg[0]; var b: Vector3 = seg[1]
		var d: int = int(seg[2]); var w: float = max(float(seg[3]), 0.004)
		var v: Vector3 = b - a
		var h: float = v.length()
		if h < 1e-6: continue
		var axis: Vector3 = v / h
		var y := Vector3.UP
		var basis := Basis()
		var dot := y.dot(axis)
		if dot > 0.9999: basis = Basis.IDENTITY
		elif dot < -0.9999: basis = Basis(Vector3.RIGHT, PI)
		else: basis = Basis(y.cross(axis).normalized(), acos(clampf(dot, -1.0, 1.0)))
		basis = basis.scaled(Vector3(w, h, w))
		bmm.set_instance_transform(i, Transform3D(basis, (a + b) * 0.5))
		var tt: float = clampf(float(d) / float(max_depth), 0.0, 1.0)
		bmm.set_instance_color(i, color_trunk.lerp(color_tip, tt))
	branch_mmi.multimesh = bmm
	var branch_mat := StandardMaterial3D.new()
	branch_mat.vertex_color_use_as_albedo = true
	branch_mat.roughness = 0.7
	branch_mmi.material_override = branch_mat
	add_child(branch_mmi)

	# ─── Modulor-fold cups at every leaf ──────────────────────
	# Rung size = modulor_base * φ^(-level). Small warm-colored cone hanging
	# from each leaf tip. This is the second grammar — Corbusier on top of Lindenmayer.
	var rung: float = modulor_base_m * pow(PHI, -float(modulor_level))
	var cup_mmi := MultiMeshInstance3D.new()
	cup_mmi.name = "ModulorCups"
	var cmm := MultiMesh.new()
	cmm.transform_format = MultiMesh.TRANSFORM_3D
	cmm.use_colors = false
	var cup_mesh: Mesh
	if leaf_shape == "sphere":
		var sp := SphereMesh.new()
		sp.radius = rung * 0.5; sp.height = rung
		sp.radial_segments = 8; sp.rings = 4
		cup_mesh = sp
	else:
		var cone := CylinderMesh.new()
		cone.top_radius = 0.0
		cone.bottom_radius = rung * 0.5
		cone.height = rung
		cone.radial_segments = 6
		cup_mesh = cone
	cmm.mesh = cup_mesh
	cmm.instance_count = leaf_positions.size()
	for i in leaf_positions.size():
		var t := Transform3D.IDENTITY
		t.origin = leaf_positions[i] + Vector3(0, rung * 0.25, 0)
		cmm.set_instance_transform(i, t)
	cup_mmi.multimesh = cmm
	var cup_mat := StandardMaterial3D.new()
	cup_mat.albedo_color = color_leaf
	cup_mat.roughness = 0.55
	cup_mmi.material_override = cup_mat
	add_child(cup_mmi)

	print("ModulorCypress: %d branches + %d Modulor cups at rung %d (%.3fm)" % [
		segments.size(), leaf_positions.size(), modulor_level, rung
	])


func _build_label() -> void:
	var lbl := Label3D.new()
	lbl.name = "Label"
	lbl.text = "Modulor Cypress\nL-system: %s → %s (×%d)\nModulor fold: rung %d" % [
		axiom, rule_F, iterations, modulor_level
	]
	lbl.pixel_size = 0.003
	lbl.font_size = 26
	lbl.modulate = Color(0.88, 0.85, 0.78)
	lbl.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	lbl.position = Vector3(0, label_height, 0)
	add_child(lbl)


## Grid-system integration
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("axiom"):        axiom = str(config_data["axiom"])
	if config_data.has("rule_F"):       rule_F = str(config_data["rule_F"])
	if config_data.has("iterations"):   iterations = clampi(int(config_data["iterations"]), 1, 6)
	if config_data.has("angle_deg"):    angle_deg = float(config_data["angle_deg"])
	if config_data.has("modulor_level"):modulor_level = clampi(int(config_data["modulor_level"]), 0, 6)
	if config_data.has("leaf_shape"):   leaf_shape = str(config_data["leaf_shape"])
	for child in get_children():
		child.queue_free()
	_build_cypress()
	if show_label: _build_label()
