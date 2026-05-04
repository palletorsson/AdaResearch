# trajectory_artifact.gd
# Placeable wrapper around TrajSim. Integrates a force-trajectory config
# and renders all trails as a single MultiMesh of cylinder segments,
# colored start→end. Mirrors dna_workstation._build_trajectory.

extends Node3D
class_name TrajectoryArtifact

const TrajSim = preload("res://commons/trajectory_grammar/trajectory_sim.gd")

@export var config_path: String = ""
@export var tube_radius_override: float = -1.0   # -1 = use config value

var _current: MultiMeshInstance3D = null


func _ready() -> void:
	if config_path.strip_edges().is_empty(): return
	_build()


func apply_grid_config(cfg: Dictionary) -> void:
	if cfg.has("config_path"):  config_path = String(cfg["config_path"])
	if cfg.has("tube_radius"):  tube_radius_override = float(cfg["tube_radius"])
	_clear()
	_build()


func _clear() -> void:
	if _current:
		_current.queue_free()
		_current = null
	for c in get_children():
		c.queue_free()


func _build() -> void:
	if config_path.is_empty(): return
	var txt := FileAccess.get_file_as_string(config_path)
	if txt.is_empty(): return
	var j := JSON.new()
	if j.parse(txt) != OK or not (j.data is Dictionary): return
	var cfg: Dictionary = j.data

	var result: Dictionary = TrajSim.simulate(cfg)
	var trails: Array = result.get("trajectories", [])
	var cs := _color_or(cfg.get("color_start", null), Color(0.2, 0.3, 0.5))
	var ce := _color_or(cfg.get("color_end", null), Color(0.9, 0.55, 0.2))
	var radius: float = (tube_radius_override
		if tube_radius_override > 0.0
		else float(cfg.get("tube_radius", 0.025)))

	var total_seg := 0
	for t in trails:
		var pts: PackedVector3Array = t
		if pts.size() >= 2: total_seg += pts.size() - 1
	if total_seg == 0: return

	var mmi := MultiMeshInstance3D.new()
	var mm := MultiMesh.new()
	mm.transform_format = MultiMesh.TRANSFORM_3D
	mm.use_colors = true
	var cyl := CylinderMesh.new()
	cyl.top_radius = 1.0; cyl.bottom_radius = 1.0; cyl.height = 1.0
	cyl.radial_segments = 6; cyl.rings = 1
	mm.mesh = cyl
	mm.instance_count = total_seg
	var idx := 0
	for t in trails:
		var pts: PackedVector3Array = t
		if pts.size() < 2: continue
		for i in range(pts.size() - 1):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var v: Vector3 = b - a
			var h: float = v.length()
			if h < 1e-6: idx += 1; continue
			var axis := v / h
			var basis := Basis()
			var dot := Vector3.UP.dot(axis)
			if dot > 0.9999: basis = Basis.IDENTITY
			elif dot < -0.9999: basis = Basis(Vector3.RIGHT, PI)
			else: basis = Basis(Vector3.UP.cross(axis).normalized(), acos(clampf(dot, -1.0, 1.0)))
			basis = basis.scaled(Vector3(radius, h, radius))
			mm.set_instance_transform(idx, Transform3D(basis, (a + b) * 0.5))
			mm.set_instance_color(idx, cs.lerp(ce, float(i) / float(pts.size() - 1)))
			idx += 1
	mmi.multimesh = mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.55
	mmi.material_override = mat
	add_child(mmi)
	_current = mmi


func _color_or(v, fallback: Color) -> Color:
	if v is Array and (v as Array).size() >= 3:
		var a: Array = v
		return Color(float(a[0]), float(a[1]), float(a[2]),
		             float(a[3]) if a.size() >= 4 else 1.0)
	return fallback
