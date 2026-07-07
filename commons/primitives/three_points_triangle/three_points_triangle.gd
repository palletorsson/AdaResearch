extends Node3D
class_name ThreePointsTriangle

# @identity
# essence: three points, three edges, and the moment they close into a surface. Two points make a line; the third point, joined back, encloses the first plane — and a plane is the first thing in the world that has an inside. This is also the GPU's atom: every model you will ever walk through in this project is triangles, because the triangle is the only polygon the hardware truly draws. Three corner points glow, the three edges connect them, and the face fills the boundary they close — the render primitive, shown being born.
# desire: it wants the player to watch a surface come into existence from three positions and nothing else. It wants the enclosure to feel like an event: that "inside" is not given but produced, the instant the third edge lands. And it wants to expose the secret that the entire smooth-looking 3D world is faceted all the way down — that every curve is a lie told well by enough triangles.
# critical_parameter: the three corner positions, and whether the face is closed. Collapse is three collinear points — no enclosure, no plane, just a degenerate line (the triangle that failed to become a surface). The φ-move is three points held genuinely apart so the boundary closes and an inside appears. The face normal marks which side is "front" — winding order, the GPU's quiet way of deciding what faces you.
# triggers: _ready builds the three corner points, the three edges, the filled face (a real triangle mesh) and the normal arrow; _process gives the fill a soft pulse so the surface reads as alive; apply_grid_config rebuilds on DNA change.
# emerges: a single triangle reads as "the first plane"; but its real lesson is recursive — once the player knows the world is triangles, every mesh becomes legible as a closed boundary of points. Point -> line -> triangle is the curriculum's first complete sentence: a position, a relation, and an enclosed inside. After this, everything is surface.
# needs: three corner points [present]; three edges that relate them [present]; a face that closes the boundary [triangle mesh, present]; a normal so the surface has a front [arrow, present]
# relationships: child of `two_points_line` (it adds the third point that closes the line into a plane) and grandchild of the point trilogy; ancestor of EVERY mesh in the project — it is the literal unit they are all built from; the Primitives map Point_Triangle ('three points close a boundary') is this artifact made architecture; cousin to `pink_triangle` and `tensegrity_triangle` (the same three points read as symbol and as structure).
# truth: a point is position; a line is relation; a triangle is the first enclosure — the minimum needed to make an inside, and the maximum the GPU needs to make a world. Everything smooth is secretly faceted; every surface is a debt of triangles paid in enough small flat lies. To close three points into a face is to perform the founding act of all computer graphics, slowly enough to see it happen.

## Three points close a boundary — the triangle as first surface + GPU atom.
##
## Built procedurally. Origin at the centroid; the triangle lies in the
## local XY plane (front faces +Z — hang it like a picture). Corner
## points, edges, a real filled face, and the face normal.

# ── DNA ───────────────────────────────────────────────────────────────

@export_group("Geometry")
@export var tri_width: float = 1.2
@export var tri_height: float = 1.1
@export var corner_radius: float = 0.05
@export var edge_radius: float = 0.014

@export_group("Material")
@export var corner_color: Color = Color(1.0, 0.85, 0.30)
@export var edge_color: Color = Color(0.9, 0.9, 0.95)
@export var face_color: Color = Color(0.35, 0.75, 1.0)
@export var show_normal: bool = true

# ── State ─────────────────────────────────────────────────────────────

var _built: bool = false
var _face_mat: StandardMaterial3D = null
var _phase: float = 0.0


func _ready() -> void:
	_read_metadata_overrides()
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	for k in config_data.keys():
		set_meta("config_%s" % str(k), config_data[k])
	_read_metadata_overrides()
	if _built:
		for c in get_children():
			c.queue_free()
		_built = false
		_face_mat = null
		_build()


func _read_metadata_overrides() -> void:
	if has_meta("config_tri_width"):
		tri_width = float(str(get_meta("config_tri_width")))
	if has_meta("config_tri_height"):
		tri_height = float(str(get_meta("config_tri_height")))
	if has_meta("config_face_color"):
		face_color = _parse_color(str(get_meta("config_face_color")), face_color)
	if has_meta("config_corner_color"):
		corner_color = _parse_color(str(get_meta("config_corner_color")), corner_color)
	if has_meta("config_show_normal"):
		var s: String = str(get_meta("config_show_normal")).to_lower()
		show_normal = s == "true" or s == "1" or s == "yes"


func _parse_color(raw: String, fallback: Color) -> Color:
	var parts := raw.split(",")
	if parts.size() >= 3:
		return Color(float(parts[0]), float(parts[1]), float(parts[2]),
			float(parts[3]) if parts.size() > 3 else 1.0)
	return fallback


# ── Build ─────────────────────────────────────────────────────────────

func _build() -> void:
	_built = true

	var v_top := Vector3(0.0, tri_height * 0.6, 0.0)
	var v_bl := Vector3(-tri_width * 0.5, -tri_height * 0.4, 0.0)
	var v_br := Vector3(tri_width * 0.5, -tri_height * 0.4, 0.0)

	# Filled face — a real triangle mesh, double-sided + emissive.
	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)
	var nrm := Vector3(0, 0, 1)
	st.set_normal(nrm); st.add_vertex(v_top)
	st.set_normal(nrm); st.add_vertex(v_bl)
	st.set_normal(nrm); st.add_vertex(v_br)
	var face := MeshInstance3D.new()
	face.name = "Face"
	face.mesh = st.commit()
	_face_mat = StandardMaterial3D.new()
	_face_mat.albedo_color = Color(face_color.r, face_color.g, face_color.b, 0.45)
	_face_mat.emission_enabled = true
	_face_mat.emission = face_color
	_face_mat.emission_energy_multiplier = 0.8
	_face_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	_face_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	face.material_override = _face_mat
	add_child(face)

	# Three edges.
	_add_edge(v_top, v_bl)
	_add_edge(v_bl, v_br)
	_add_edge(v_br, v_top)

	# Three corner points.
	_add_corner(v_top)
	_add_corner(v_bl)
	_add_corner(v_br)

	# Face normal — a short arrow from the centroid along +Z.
	if show_normal:
		var centroid := (v_top + v_bl + v_br) / 3.0
		var arrow := MeshInstance3D.new()
		arrow.name = "Normal"
		var am := CylinderMesh.new()
		am.top_radius = 0.0
		am.bottom_radius = 0.03
		am.height = 0.22
		arrow.mesh = am
		var amat := StandardMaterial3D.new()
		amat.albedo_color = Color(0.6, 1.0, 0.7)
		amat.emission_enabled = true
		amat.emission = Color(0.6, 1.0, 0.7)
		amat.emission_energy_multiplier = 1.4
		arrow.material_override = amat
		arrow.rotation = Vector3(PI * 0.5, 0, 0)   # point along +Z
		arrow.position = centroid + Vector3(0, 0, 0.13)
		add_child(arrow)

	_phase = 0.0
	set_process(true)


func _add_corner(pos: Vector3) -> void:
	var p := MeshInstance3D.new()
	var sm := SphereMesh.new()
	sm.radius = corner_radius
	sm.height = corner_radius * 2.0
	p.mesh = sm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = corner_color
	mat.emission_enabled = true
	mat.emission = corner_color
	mat.emission_energy_multiplier = 2.0
	mat.roughness = 0.25
	p.material_override = mat
	p.position = pos
	add_child(p)


func _add_edge(a: Vector3, b: Vector3) -> void:
	var dir := (b - a)
	var length := dir.length()
	if length < 0.001:
		return
	dir = dir / length
	var e := MeshInstance3D.new()
	var cm := CylinderMesh.new()
	cm.top_radius = edge_radius
	cm.bottom_radius = edge_radius
	cm.height = length
	e.mesh = cm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = edge_color
	mat.emission_enabled = true
	mat.emission = edge_color
	mat.emission_energy_multiplier = 0.8
	e.material_override = mat
	# Orient the cylinder's local +Y along the edge direction.
	var x_axis := dir.cross(Vector3(0, 0, 1))
	if x_axis.length() < 0.001:
		x_axis = dir.cross(Vector3(1, 0, 0))
	x_axis = x_axis.normalized()
	var z_axis := x_axis.cross(dir).normalized()
	var t := Transform3D(Basis(x_axis, dir, z_axis), (a + b) * 0.5)
	e.transform = t
	add_child(e)


func _process(delta: float) -> void:
	if _face_mat == null:
		return
	_phase += delta * 1.3
	var pulse: float = 0.5 + 0.5 * sin(_phase)
	_face_mat.emission_energy_multiplier = 0.5 + pulse * 0.8
	_face_mat.albedo_color.a = 0.35 + pulse * 0.25
