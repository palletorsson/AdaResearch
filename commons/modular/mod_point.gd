class_name ModularPoint
extends RefCounted
## Module: the point — the first thing, a small ink sphere. It is a construction
## mark: a surface association never paints over it, so the points a line was
## made from stay visible inside the tape.


static func make(spec: Dictionary) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	mi.name = "point"
	var m := SphereMesh.new()
	var r: float = float(spec.get("radius", 0.03))
	m.radius = r
	m.height = r * 2.0
	m.radial_segments = 10
	m.rings = 6
	mi.mesh = m
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(str(spec.get("color", "2b1d14")))
	mat.roughness = 0.8
	mi.material_override = mat
	mi.set_meta("construction_mark", true)
	return mi
