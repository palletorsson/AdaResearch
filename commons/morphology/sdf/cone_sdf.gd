# cone_sdf.gd
# Cone from apex_pos to base_pos with radius r at base. Covers tree crowns,
# witch hats, rocket noses, spires, roofs, carrot tips.
#
# SDF formulation: distance to a cone aligned with +Y, then transform p.

extends "res://commons/morphology/sdf/form_sdf.gd"

@export var apex: Vector3 = Vector3(0, 1, 0)
@export var base_center: Vector3 = Vector3.ZERO
@export var base_radius: float = 0.5


static func make(apex_pos: Vector3, base_pos: Vector3, r: float) -> Resource:
	var script: GDScript = load("res://commons/morphology/sdf/cone_sdf.gd")
	var c: Resource = script.new()
	c.apex = apex_pos
	c.base_center = base_pos
	c.base_radius = r
	return c


func signed_distance(p: Vector3) -> float:
	# Transform into cone-local frame: origin at base, +Y toward apex
	var axis: Vector3 = apex - base_center
	var h: float = axis.length()
	if h < 0.001:
		return (p - base_center).length() - base_radius
	var axis_n: Vector3 = axis / h
	var local: Vector3 = p - base_center
	var along: float = local.dot(axis_n)
	var perp: Vector3 = local - axis_n * along
	var r_at: float = perp.length()
	# 2D distance in (r, y) plane. Slant line goes from (base_radius, 0) at
	# base edge to (0, h) at apex. Outward normal is perpendicular-right of
	# that direction, i.e. points away from the axis.
	var q := Vector2(r_at, along)
	var slope: Vector2 = Vector2(-base_radius, h).normalized()  # base edge → apex
	var outward_normal: Vector2 = Vector2(slope.y, -slope.x)    # rotate 90° CW
	# Distance to slant line passing through (base_radius, 0) — offset matters.
	var slant_d: float = (q - Vector2(base_radius, 0.0)).dot(outward_normal)
	# Distance to the base cap: negative if above, positive if below base.
	var cap_d: float = -q.y  # q.y < 0 means below base → cap_d > 0 (outside)
	# Cone interior = inside slant AND above base → both signed negative.
	return maxf(slant_d, cap_d)


func get_aabb() -> AABB:
	var minp := Vector3(
		minf(apex.x, base_center.x - base_radius),
		minf(apex.y, base_center.y - base_radius * 0.2),
		minf(apex.z, base_center.z - base_radius),
	)
	var maxp := Vector3(
		maxf(apex.x, base_center.x + base_radius),
		maxf(apex.y, base_center.y + base_radius * 0.2),
		maxf(apex.z, base_center.z + base_radius),
	)
	return AABB(minp - Vector3(0.1, 0.1, 0.1), (maxp - minp) + Vector3(0.2, 0.2, 0.2))


func build_mesh_parts() -> Array:
	var axis: Vector3 = apex - base_center
	var height: float = axis.length()
	if height < 0.001:
		return []
	var mesh := CylinderMesh.new()
	mesh.top_radius = 0.0
	mesh.bottom_radius = base_radius
	mesh.height = height
	mesh.radial_segments = 12
	mesh.rings = 1

	# Godot CylinderMesh is aligned +Y, height centered on origin.
	# Move to midpoint of base→apex, orient so +Y = axis direction.
	var mid: Vector3 = (base_center + apex) * 0.5
	var dir_n: Vector3 = axis / height
	var basis := Basis.IDENTITY
	if not dir_n.is_equal_approx(Vector3.UP) and not dir_n.is_equal_approx(-Vector3.UP):
		var rot_axis: Vector3 = Vector3.UP.cross(dir_n).normalized()
		basis = Basis(rot_axis, Vector3.UP.angle_to(dir_n))
	elif dir_n.is_equal_approx(-Vector3.UP):
		basis = Basis(Vector3.FORWARD, PI)
	return [{"mesh": mesh, "transform": Transform3D(basis, mid), "slot": "self"}]
