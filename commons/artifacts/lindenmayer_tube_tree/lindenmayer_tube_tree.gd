# lindenmayer_tube_tree.gd — Walkable L-system plant as tube-mesh.
# Uses the commons/lsystem_grammar/ substrate directly (rewriter + turtle)
# and renders every turtle segment as a proportioned cylinder via MultiMesh.
# Distinct from the older lsystem_tree artifact (which renders as lines) —
# this one shows the substrate reaching VR with volumetric branches the
# player can walk around.
#
# @identity
# essence: Lindenmayer 1968 plant rendered at VR scale — F→F[+F]F[-F]F as volume, not line
# desire: To stand next to a tree that is entirely rule-generated and see every branch as an oriented tube
# critical_parameter: angle_deg — the classical 25.7° is one of Lindenmayer's own values; vary it and the plant becomes a different species
# triggers: Change rules → different plant. Change iterations → sapling to full tree. Change angle → palm to pine to bush.
# emerges: A tree you can circle. Branch tapering from turtle width_shrink visible as you approach.
# needs: Label3D for pedagogy. Enough space to walk around.
# relationships: Sibling of lsystem_tree (line render) and ls03_classic_tree (gallery artifact). Uses the same DNA that seeds gg_ls01_plant_chandelier, sb_ls02_plant_wind_collapse, ps_ls01_bauhaus_tree.
# truth: No hand-placed branches. The string decided where every tube goes.

extends Node3D

class_name LindenmayerTubeTree

const LSystemSimScript    = preload("res://commons/lsystem_grammar/lsystem_sim.gd")
const LSystemTurtleScript = preload("res://commons/lsystem_grammar/lsystem_turtle.gd")

## L-system DNA
@export var axiom: String = "F"
@export_multiline var rule_F: String = "F[+F]F[-F]F"
@export var iterations: int = 4
@export var angle_deg: float = 25.7

## Turtle parameters
@export var step_len: float = 0.28
@export var step_shrink: float = 0.72
@export var base_width: float = 0.04
@export var width_shrink: float = 0.72

## Material
@export var color_trunk: Color = Color(0.45, 0.28, 0.12)
@export var color_tip: Color = Color(0.22, 0.65, 0.22)
@export var tube_sides: int = 8

## Label
@export var show_label: bool = true
@export var label_height: float = 0.35

var _mmi: MultiMeshInstance3D
var _label: Label3D


func _ready() -> void:
	_build_tree()
	if show_label:
		_build_label()


func _build_tree() -> void:
	var s: String = LSystemSimScript.rewrite(axiom, {"F": rule_F}, iterations)
	var walk: Dictionary = LSystemTurtleScript.walk(s, {
		"angle_deg":    angle_deg,
		"step_len":     step_len,
		"step_shrink":  step_shrink,
		"base_width":   base_width,
		"width_shrink": width_shrink,
	})
	var segments: Array = walk["segments"]
	if segments.is_empty():
		return

	var max_depth := 1
	for seg in segments:
		max_depth = max(max_depth, int(seg[2]))

	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Branches"
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cm := CylinderMesh.new()
	cm.top_radius = 1.0
	cm.bottom_radius = 1.0
	cm.height = 1.0
	cm.radial_segments = tube_sides
	cm.rings = 1
	mm.mesh = cm
	mm.instance_count = segments.size()

	for i in segments.size():
		var seg = segments[i]
		var a: Vector3 = seg[0]
		var b: Vector3 = seg[1]
		var d: int = int(seg[2])
		var w: float = max(float(seg[3]), 0.004)
		var mid: Vector3 = (a + b) * 0.5
		var v: Vector3 = b - a
		var h: float = v.length()
		if h < 1e-6: continue
		var axis: Vector3 = v / h
		var y := Vector3.UP
		var basis := Basis()
		var dot := y.dot(axis)
		if dot > 0.9999:
			basis = Basis.IDENTITY
		elif dot < -0.9999:
			basis = Basis(Vector3.RIGHT, PI)
		else:
			basis = Basis(y.cross(axis).normalized(), acos(clampf(dot, -1.0, 1.0)))
		basis = basis.scaled(Vector3(w, h, w))
		mm.set_instance_transform(i, Transform3D(basis, mid))
		var t: float = clampf(float(d) / float(max_depth), 0.0, 1.0)
		mm.set_instance_color(i, color_trunk.lerp(color_tip, t))

	_mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.65
	mat.metallic = 0.0
	_mmi.material_override = mat
	add_child(_mmi)

	print("LindenmayerTubeTree: %d segments from '%s' → '%s' ×%d @ %.1f°" % [
		segments.size(), axiom, rule_F, iterations, angle_deg])


func _build_label() -> void:
	_label = Label3D.new()
	_label.name = "Label"
	var rule_display: String = "%s → %s" % [axiom, rule_F]
	_label.text = "L-system plant\n%s\n%d iter · %.1f°" % [rule_display, iterations, angle_deg]
	_label.pixel_size = 0.003
	_label.font_size = 28
	_label.modulate = Color(0.85, 0.83, 0.78)
	_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_label.position = Vector3(0, label_height, 0)
	add_child(_label)


## Grid-system integration — map_data.json can override DNA at runtime
func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("axiom"):     axiom = str(config_data["axiom"])
	if config_data.has("rule_F"):    rule_F = str(config_data["rule_F"])
	if config_data.has("iterations"):iterations = clampi(int(config_data["iterations"]), 1, 6)
	if config_data.has("angle_deg"): angle_deg = float(config_data["angle_deg"])
	if config_data.has("step_len"):  step_len = float(config_data["step_len"])
	if config_data.has("base_width"):base_width = float(config_data["base_width"])
	# Rebuild
	if _mmi and _mmi.get_parent() == self:
		_mmi.queue_free(); _mmi = null
	if _label and _label.get_parent() == self:
		_label.queue_free(); _label = null
	_build_tree()
	if show_label: _build_label()
