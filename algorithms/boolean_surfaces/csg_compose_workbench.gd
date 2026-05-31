# CSG Compose Workbench — the `csg-compose` catalyst affordance
#
# A working surface holding three preset CSG compositions visible from a player's stance.
# Each preset shows the same two primitives (box + sphere) with one of the three
# operators applied: union, intersection, difference. A central glowing pillar above
# the workbench labels the active demonstration with the operator symbol.
#
# The workbench is the *introduction* artifact for the player's csg-compose affordance:
# stand at the bench, see all three operators side by side, pick one with the bracelet,
# replicate the operation by hand.
#
# @identity
# essence: A workbench holding all three CSG operators side by side — union, intersection, difference — applied to the same box+sphere pair, each labeled by symbol.
# desire: To let the player meet the whole composition algebra at once and pick an operator by hand with the catalyst bracelet.
# critical_parameter: preset_spacing — how far apart the three demonstrations sit. Too close and the operators blur together; too far and the comparison between them is lost.
# triggers: Stand at the bench; the csg-compose affordance lets the bracelet select an operator and replicate it. Presets rotate to stay legible.
# emerges: The realization that union, intersection, and difference are one family — three lawful ways to compose two solids.
# needs: Procedural presets [has], catalyst affordance [has]. Missing: a live player-built composition surface beside the three fixed presets.
# relationships: The introduction hub for csg_union_demo, csg_intersection_demo, and csg_difference_demo. Hands the player the operators that csg_architecture_cavity then puts to work.
# truth: Three operators, one algebra. Composition is a choice — keep all, keep the shared, or take away.
# @qfep_term: F — composition algebra.

extends Node3D
class_name CSGComposeWorkbench

@export_category("Workbench Settings")
@export var bench_color: Color = Color(0.32, 0.36, 0.42, 1.0)
@export var preset_spacing: float = 1.1
@export var rotation_speed: float = 0.25

var _preset_roots: Array = []
var _t: float = 0.0


func _ready() -> void:
	_build_bench()
	_build_presets()
	_build_overall_label()


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("preset_spacing"):
		preset_spacing = float(config_data["preset_spacing"])


func _process(delta: float) -> void:
	_t += delta * rotation_speed
	for r in _preset_roots:
		if is_instance_valid(r):
			r.rotation.y = _t


func _build_bench() -> void:
	var bench := MeshInstance3D.new()
	bench.name = "Bench"
	var box := BoxMesh.new()
	box.size = Vector3(preset_spacing * 3.2, 0.12, 1.2)
	bench.mesh = box
	var mat := StandardMaterial3D.new()
	mat.albedo_color = bench_color
	mat.roughness = 0.7
	bench.material_override = mat
	bench.position.y = 0.5
	add_child(bench)


func _build_presets() -> void:
	var presets = [
		{"op": CSGShape3D.OPERATION_UNION, "color": Color(0.55, 0.85, 1.0, 1.0), "label": "A ∪ B"},
		{"op": CSGShape3D.OPERATION_INTERSECTION, "color": Color(1.0, 0.55, 0.4, 1.0), "label": "A ∩ B"},
		{"op": CSGShape3D.OPERATION_SUBTRACTION, "color": Color(0.7, 0.6, 0.95, 1.0), "label": "A − B"},
	]
	for i in presets.size():
		var preset: Dictionary = presets[i]
		var root := CSGCombiner3D.new()
		var x_off: float = (float(i) - 1.0) * preset_spacing
		root.position = Vector3(x_off, 1.1, 0.0)
		# Box first.
		var csg_box := CSGBox3D.new()
		csg_box.size = Vector3(0.45, 0.45, 0.45)
		csg_box.operation = CSGShape3D.OPERATION_UNION
		root.add_child(csg_box)
		# Sphere with the operator under test.
		var csg_sphere := CSGSphere3D.new()
		csg_sphere.radius = 0.3
		csg_sphere.position = Vector3(0.2, 0.1, 0.1)
		csg_sphere.operation = preset["op"]
		root.add_child(csg_sphere)
		var mat := StandardMaterial3D.new()
		mat.albedo_color = preset["color"]
		mat.metallic = 0.3
		mat.roughness = 0.4
		mat.emission_enabled = true
		mat.emission = preset["color"]
		mat.emission_energy_multiplier = 0.3
		root.material_override = mat
		add_child(root)
		_preset_roots.append(root)
		# Per-preset label.
		var label := Label3D.new()
		label.text = preset["label"]
		label.font_size = 30
		label.outline_size = 6
		label.modulate = preset["color"]
		label.position = Vector3(x_off, 0.45, 0.65)
		label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		add_child(label)


func _build_overall_label() -> void:
	var label := Label3D.new()
	label.text = "Compose"
	label.font_size = 42
	label.outline_size = 8
	label.modulate = Color(0.95, 0.85, 0.45, 1.0)
	label.position = Vector3(0.0, 1.95, 0.0)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	add_child(label)
