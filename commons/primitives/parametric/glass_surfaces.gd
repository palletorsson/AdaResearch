# glass_surfaces.gd — Glass tube forms rebuilt as parametric surfaces
# Each shape is a continuous (u, v) parametric surface — no segments, no rings.
# u = position along the tube path [0, 2π or custom range]
# v = position around the tube cross-section [0, 2π]
#
# This proves that glass forms are just constrained parametric surfaces:
# a straight tube is a cylinder, a corner is a torus quarter,
# a flask is a sphere-cylinder blend, a spiral is a helical tube.

extends Node3D

@export_range(0, 9) var shape_type: int = 0
@export var u_steps: int = 64
@export var v_steps: int = 16
@export var tube_radius: float = 0.06
@export var major_radius: float = 0.5
@export var height: float = 1.0
@export var base_color: Color = Color(0.85, 0.92, 1.0)

const SHAPE_NAMES: Array[String] = [
	"Straight Tube", "90° Corner", "S-Bend", "U-Bend",
	"Spiral Coil", "Flask", "Beaker", "Y-Junction",
	"Torus Ring", "Twisted Ribbon",
]

var mesh_instance: MeshInstance3D


func _ready():
	_build_surface()


func _build_surface() -> void:
	if mesh_instance:
		if mesh_instance.get_parent() == self:
			remove_child(mesh_instance)
		mesh_instance.queue_free()

	var surface_tool := SurfaceTool.new()
	surface_tool.begin(Mesh.PRIMITIVE_TRIANGLES)

	# Build vertex grid from parametric equations
	var vertices: Array = []
	for i in range(u_steps + 1):
		var row: Array = []
		for j in range(v_steps + 1):
			var u: float = float(i) / float(u_steps)
			var v: float = float(j) / float(v_steps) * TAU

			var pos: Vector3 = _evaluate(u, v)
			row.append(pos)
		vertices.append(row)

	# Triangulate quads — same pattern as seashell, torus_knot
	for i in range(u_steps):
		for j in range(v_steps):
			var v0: Vector3 = vertices[i][j]
			var v1: Vector3 = vertices[i + 1][j]
			var v2: Vector3 = vertices[i + 1][j + 1]
			var v3: Vector3 = vertices[i][j + 1]

			var uv0 := Vector2(float(i) / u_steps, float(j) / v_steps)
			var uv1 := Vector2(float(i + 1) / u_steps, float(j) / v_steps)
			var uv2 := Vector2(float(i + 1) / u_steps, float(j + 1) / v_steps)
			var uv3 := Vector2(float(i) / u_steps, float(j + 1) / v_steps)

			# Triangle 1
			surface_tool.set_uv(uv0); surface_tool.add_vertex(v0)
			surface_tool.set_uv(uv1); surface_tool.add_vertex(v1)
			surface_tool.set_uv(uv2); surface_tool.add_vertex(v2)
			# Triangle 2
			surface_tool.set_uv(uv0); surface_tool.add_vertex(v0)
			surface_tool.set_uv(uv2); surface_tool.add_vertex(v2)
			surface_tool.set_uv(uv3); surface_tool.add_vertex(v3)

	surface_tool.generate_normals()
	var mesh: ArrayMesh = surface_tool.commit()

	mesh_instance = MeshInstance3D.new()
	mesh_instance.mesh = mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(base_color.r, base_color.g, base_color.b, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.roughness = 0.05
	mat.metallic = 0.1
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mesh_instance.material_override = mat
	add_child(mesh_instance)


## Parametric evaluation: returns a point on the surface for given (u, v).
## u ∈ [0, 1] = position along tube path
## v ∈ [0, 2π] = angle around cross-section
func _evaluate(u: float, v: float) -> Vector3:
	match shape_type:
		0: return _straight_tube(u, v)
		1: return _corner_90(u, v)
		2: return _s_bend(u, v)
		3: return _u_bend(u, v)
		4: return _spiral_coil(u, v)
		5: return _flask(u, v)
		6: return _beaker(u, v)
		7: return _y_junction(u, v)
		8: return _torus_ring(u, v)
		9: return _twisted_ribbon(u, v)
	return _straight_tube(u, v)


# ═══════════════════════════════════════════════════════════════
# PARAMETRIC EQUATIONS — each glass form as a continuous surface
# ═══════════════════════════════════════════════════════════════

## Straight tube: cylinder. The simplest — center line is vertical.
func _straight_tube(u: float, v: float) -> Vector3:
	var y: float = u * height
	return Vector3(cos(v) * tube_radius, y, sin(v) * tube_radius)


## 90° corner: quarter torus. Center follows a circular arc.
func _corner_90(u: float, v: float) -> Vector3:
	var angle: float = u * PI * 0.5  # Quarter turn
	# Center of tube traces a circle in the XY plane
	var cx: float = major_radius * cos(angle)
	var cy: float = major_radius * sin(angle)
	# Local frame: tangent along the arc, normal/binormal for cross-section
	var tx: float = -sin(angle)  # tangent x
	var ty: float = cos(angle)   # tangent y
	# Cross-section circle perpendicular to tangent
	# normal = radial direction, binormal = Z
	var nx: float = cos(angle)
	var ny: float = sin(angle)
	return Vector3(
		cx + nx * cos(v) * tube_radius,
		cy + ny * cos(v) * tube_radius,
		sin(v) * tube_radius)


## S-bend: sinusoidal path. Center snakes left-right while going up.
func _s_bend(u: float, v: float) -> Vector3:
	var y: float = u * height
	var x_offset: float = sin(u * PI) * major_radius * 0.4
	# Tangent direction
	var dx: float = cos(u * PI) * PI * major_radius * 0.4 / height
	var tangent := Vector3(dx, 1.0, 0.0).normalized()
	var right := tangent.cross(Vector3.FORWARD).normalized()
	var fwd := right.cross(tangent).normalized()
	return Vector3(x_offset, y, 0) + (right * cos(v) + fwd * sin(v)) * tube_radius


## U-bend: semicircle. Center follows a half-circle arc.
func _u_bend(u: float, v: float) -> Vector3:
	var angle: float = u * PI  # Half turn
	var cx: float = major_radius * cos(angle)
	var cy: float = major_radius * sin(angle)
	var nx: float = cos(angle)
	var ny: float = sin(angle)
	return Vector3(
		cx + nx * cos(v) * tube_radius,
		cy + ny * cos(v) * tube_radius,
		sin(v) * tube_radius)


## Spiral coil: helix. Center traces a helix with configurable turns.
func _spiral_coil(u: float, v: float) -> Vector3:
	var turns: float = 4.0
	var angle: float = u * TAU * turns
	var y: float = u * height
	var cx: float = cos(angle) * major_radius
	var cz: float = sin(angle) * major_radius
	# Tangent along helix
	var tx: float = -sin(angle) * major_radius * TAU * turns
	var ty: float = height
	var tz: float = cos(angle) * major_radius * TAU * turns
	var tangent := Vector3(tx, ty, tz).normalized()
	var up := Vector3.UP
	var right := tangent.cross(up).normalized()
	var fwd := right.cross(tangent).normalized()
	return Vector3(cx, y, cz) + (right * cos(v) + fwd * sin(v)) * tube_radius


## Flask: round bottom. Blends from a sphere into a cylinder neck.
func _flask(u: float, v: float) -> Vector3:
	# Bottom half: sphere. Top half: cylinder neck.
	var bulge_r: float = major_radius * 0.6
	if u < 0.5:
		# Sphere portion
		var phi: float = (1.0 - u * 2.0) * PI * 0.5  # π/2 to 0
		var r: float = bulge_r * cos(phi)
		var y: float = -bulge_r * sin(phi)
		return Vector3(cos(v) * r, y, sin(v) * r)
	else:
		# Neck portion (cylinder, narrower)
		var neck_r: float = tube_radius * 1.5
		var blend: float = (u - 0.5) * 2.0  # 0 to 1
		var r: float = lerpf(bulge_r, neck_r, clampf(blend * 2.0, 0.0, 1.0))
		var y: float = blend * height * 0.6
		return Vector3(cos(v) * r, y, sin(v) * r)


## Beaker: tapered cylinder. Wider at bottom, narrower at top.
func _beaker(u: float, v: float) -> Vector3:
	var bottom_r: float = major_radius * 0.5
	var top_r: float = major_radius * 0.4
	var r: float = lerpf(bottom_r, top_r, u)
	var y: float = u * height
	return Vector3(cos(v) * r, y, sin(v) * r)


## Y-junction: splits into two branches. Uses a blend function.
func _y_junction(u: float, v: float) -> Vector3:
	if u < 0.5:
		# Stem: straight tube
		var y: float = u * 2.0 * height * 0.5
		return Vector3(cos(v) * tube_radius, y, sin(v) * tube_radius)
	else:
		# Branch: offset based on v-hemisphere
		var t: float = (u - 0.5) * 2.0
		var branch_angle: float = 0.4  # radians spread
		var side: float = 1.0 if v < PI else -1.0
		var x_offset: float = sin(t * branch_angle) * major_radius * 0.3 * side
		var y: float = height * 0.5 + t * height * 0.4
		var r: float = tube_radius * (1.0 - t * 0.2)  # Slightly thinner
		return Vector3(x_offset + cos(v) * r, y, sin(v) * r)


## Torus ring: full ring. Same as a mathematical torus.
func _torus_ring(u: float, v: float) -> Vector3:
	var angle: float = u * TAU
	var cx: float = cos(angle) * major_radius
	var cz: float = sin(angle) * major_radius
	var nx: float = cos(angle)
	var nz: float = sin(angle)
	return Vector3(
		cx + nx * cos(v) * tube_radius,
		sin(v) * tube_radius,
		cz + nz * cos(v) * tube_radius)


## Twisted ribbon: flat cross-section with 360° twist. Möbius cousin.
func _twisted_ribbon(u: float, v: float) -> Vector3:
	var angle: float = u * TAU
	var cx: float = cos(angle) * major_radius
	var cz: float = sin(angle) * major_radius
	# Twist the cross-section
	var twist: float = u * TAU  # Full 360° twist
	var width: float = tube_radius * 3.0
	var thickness: float = tube_radius * 0.2
	var local_x: float = (v / TAU - 0.5) * width
	var local_y: float = cos(v) * thickness
	# Rotate by twist
	var rx: float = local_x * cos(twist) - local_y * sin(twist)
	var ry: float = local_x * sin(twist) + local_y * cos(twist)
	var nx: float = cos(angle)
	var nz: float = sin(angle)
	return Vector3(
		cx + nx * rx,
		ry,
		cz + nz * rx)
