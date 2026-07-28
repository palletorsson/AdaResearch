# elliptic_surface.gd
# Dome/sphere-like surface demonstrating positive curvature

extends Node3D

class_name EllipticSurface

# @identity
# essence: K > 0 — positive Gaussian curvature; parallel lines converge, triangles have angle sum > 180°
# desire: touch a dome and feel space curve inward — lines that start parallel must eventually meet
# critical_parameter: radius — controls how tightly space curves
# triggers: static geometry; presence alone teaches that parallel lines can converge
# emerges: the realization that on a positively curved surface there are NO parallel lines at all
# needs: VR controls [missing] — could add curvature_slider connection
# relationships: contrasts hyperbolic_surface (K<0, lines diverge); depends on curvature_slider; paired with angle_sum_triangle
# truth: on a positively curved surface, there is no room for parallel lines — all paths eventually meet

@export var radius: float = 0.4
@export var resolution: int = 24

## Stage-2 DNA axis — what the dome is MADE TO SHOW about the fifth postulate.
##
## The shipped object asserted "there are no parallel lines here" in 12 pt type on a
## label and demonstrated it with nothing on the mesh. This axis moves the claim onto
## the surface. Same word, same values, same order as hyperbolic_surface — the two are
## one comparison and the vocabulary should make that visible before anyone reads a
## caption. The values do opposite geometric work on each surface, which is the point:
## `parallels` splays on the saddle and CONVERGES here, `triangle` pinches there and
## BULGES here, `net` grows cells there and COLLAPSES them here. `euclid` is the shared
## flat control that makes the pair a triple.
##
##   bare       the shipped dome alone — no marks, the pre-promotion look, exactly
##   parallels  two meridian ribbons, 0.10 m apart at the equator, meeting at the pole
##   triangle   a great-circle triangle whose sides bow out past their own chords
##   net        8 meridians x 8 parallels; the cells collapse toward the pole on their own
##   euclid     no sphere at all — a flat disc carrying ribbons that never meet
@export_enum("bare", "parallels", "triangle", "net", "euclid") var postulate: String = "bare"

## Allow-list for `postulate`. Anything unrecognised falls back to the value already
## held, which for a fresh instance is the shipped look — a typo in a map token must
## never strand a placement with an empty cell.
const POSTULATES: PackedStringArray = ["bare", "parallels", "triangle", "net", "euclid"]

# ── Marking geometry ────────────────────────────────────────────────────────────
# Tube figures are quoted as RADII. On a 0.80 m dome a 0.014 m radius reads as a
# 28 mm bar — about 3.5% of the object's width, which survives the auto-framed
# capture. A 14 mm bar would not.
const TUBE_MAIN: float = 0.014      ## parallels / triangle ribbons
const TUBE_NET: float = 0.010       ## net meridians and parallels
const TUBE_FILLET: float = 0.010    ## corner-angle fillets on the triangle
const TUBE_SIDES: int = 8           ## cross-section segments of every tube

const JUNCTION_R: float = 0.03      ## sphere at the pole where the two meridians meet
const PARALLEL_GAP: float = 0.10    ## metres between the ribbons AT THE EQUATOR
const FILLET_ARC: float = 0.05      ## geodesic radius of the corner-angle marks

const TRI_LAT_DEG: float = 30.0     ## latitude of the three triangle vertices
const NET_MERIDIANS: int = 8
const NET_PARALLELS: int = 8
const NET_TOP_LAT_DEG: float = 84.5 ## topmost ring — where the cells reach ~0.03 m

const PLATE_H: float = 0.06
const PLATE_D: float = 0.006
const PLATE_Y: float = 0.42         ## clear of the dome's pole at +0.28
const PLATE_Y_FLAT: float = 0.12    ## euclid has no dome to clear

const LINE_COLOR: Color = Color(0.96, 0.94, 0.86)
const PLATE_COLOR: Color = Color(0.11, 0.12, 0.15)

var _mesh_instance: MeshInstance3D
var _label: Label3D

## Every node THIS script added. _rebuild_now frees only these — grid-added label
## plates, packaging and tag markers are somebody else's children.
var _own: Array[Node] = []
var _built: bool = false

## The value actually built, after the allow-list. Never read `postulate` directly
## in a builder — a sweep or a hand-edited scene can hold anything.
var _mode: String = "bare"

func _ready() -> void:
	_build_all()
	_built = true


# ═══════════════════════════════════════════════════════════════════
# BUILD
# ═══════════════════════════════════════════════════════════════════

## Synchronous, and reads the @export values only — no meta, no config, nothing
## deferred. The sweep harness sets `postulate` and adds the scene to the tree; if
## the marks were built in apply_grid_config it would photograph five empty domes.
func _build_all() -> void:
	_mode = _pick_axis(postulate, POSTULATES, "bare")

	match _mode:
		"euclid":
			_create_plane()
			_build_flat_figures()
		"parallels":
			_create_surface()
			_build_parallels()
		"triangle":
			_create_surface()
			_build_triangle()
		"net":
			_create_surface()
			_build_net()
		_:
			_create_surface()

	_create_label()


## The shipped dome, untouched: a 24-segment, 12-ring SphereMesh of radius 0.40 m
## sunk 0.12 m so only the upper hemisphere reads, flat orange.
func _create_surface() -> void:
	_mesh_instance = MeshInstance3D.new()
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2
	sphere.radial_segments = resolution
	sphere.rings = resolution / 2
	_mesh_instance.mesh = sphere

	# Only show upper hemisphere
	_mesh_instance.position.y = -radius * 0.3

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.5, 0.3)
	mat.metallic = 0.2
	mat.roughness = 0.6
	_mesh_instance.material_override = mat
	_own_add(_mesh_instance)


## `euclid`: the sphere is NOT built. A flat disc of the same radius sits at the same
## sunk height, so the control occupies the footprint of the dome it replaces.
func _create_plane() -> void:
	_mesh_instance = MeshInstance3D.new()
	var disc := CylinderMesh.new()
	disc.top_radius = radius
	disc.bottom_radius = radius
	disc.height = 0.004
	disc.radial_segments = resolution
	disc.rings = 1
	_mesh_instance.mesh = disc
	_mesh_instance.position.y = -radius * 0.3

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.8, 0.5, 0.3)
	mat.metallic = 0.2
	mat.roughness = 0.6
	_mesh_instance.material_override = mat
	_own_add(_mesh_instance)


func _create_label() -> void:
	_label = Label3D.new()
	_label.pixel_size = 0.001
	_label.font_size = 12
	if _mode == "euclid":
		# The flat control must not keep claiming to be a curved surface.
		_label.text = "EUCLIDEAN CONTROL\nZero curvature\nK = 0"
	else:
		_label.text = "ELLIPTIC SURFACE\nPositive curvature\nK > 0"
	_label.position = Vector3(0, -radius - 0.15, 0)
	_own_add(_label)


# ── postulate: parallels ────────────────────────────────────────────────────────

## Two great-circle ribbons crossing the equator at right angles and PARALLEL_GAP
## apart there, converging to one junction sphere at the pole. Meridians meet the
## equator perpendicular by construction, so the pair genuinely starts parallel and
## still ends in the same point — which is the whole claim, put on the mesh.
func _build_parallels() -> void:
	var half_lon: float = (PARALLEL_GAP / maxf(radius, 0.001)) * 0.5
	for s in [-1.0, 1.0]:
		var lon: float = half_lon * float(s)
		# Start below the equator so the ribbons visibly CROSS it, not stop at it.
		_add_tube(_meridian_points(lon, -8.0, 90.0, 30), TUBE_MAIN, LINE_COLOR)

	var junction := MeshInstance3D.new()
	var ball := SphereMesh.new()
	ball.radius = JUNCTION_R
	ball.height = JUNCTION_R * 2.0
	ball.radial_segments = 16
	ball.rings = 8
	junction.mesh = ball
	junction.position = _sphere_center() + Vector3(0, radius + TUBE_MAIN * 0.6, 0)
	junction.material_override = _line_material(LINE_COLOR)
	_own_add(junction)

	_add_plate("NO PARALLELS", 0.20, PLATE_Y)


# ── postulate: triangle ─────────────────────────────────────────────────────────

## A closed three-arc great-circle triangle. Each side is the shortest path on the
## sphere, and each one bows out past the straight chord a Euclidean eye supplies —
## so the figure reads fat. Three fillets mark the corner angles; they are visibly
## wider than the 60° a flat equilateral triangle would allow.
func _build_triangle() -> void:
	var lat: float = deg_to_rad(TRI_LAT_DEG)
	var verts: Array[Vector3] = []
	for i in range(3):
		verts.append(_dir(lat, deg_to_rad(120.0 * float(i))))

	for i in range(3):
		var a: Vector3 = verts[i]
		var b: Vector3 = verts[(i + 1) % 3]
		var pts: PackedVector3Array = PackedVector3Array()
		for s in range(29):
			var t: float = float(s) / 28.0
			pts.append(_on_sphere(a.slerp(b, t).normalized(), TUBE_MAIN))
		_add_tube_dirs(pts, TUBE_MAIN, LINE_COLOR)

	for i in range(3):
		_add_corner_fillet(verts[i], verts[(i + 1) % 3], verts[(i + 2) % 3])

	_add_plate("SUM OVER 180", 0.16, PLATE_Y)


## One arc at geodesic distance FILLET_ARC from the vertex, swept from the direction
## of one side to the direction of the other — the corner angle drawn, not asserted.
func _add_corner_fillet(v: Vector3, a: Vector3, b: Vector3) -> void:
	var t1: Vector3 = (a - v * v.dot(a)).normalized()
	var t2: Vector3 = (b - v * v.dot(b)).normalized()
	var sweep: float = acos(clampf(t1.dot(t2), -1.0, 1.0))
	var axis: Vector3 = t1.cross(t2)
	if axis.length() < 0.0001:
		return
	axis = axis.normalized()

	var fa: float = FILLET_ARC / maxf(radius, 0.001)
	var pts: PackedVector3Array = PackedVector3Array()
	for s in range(17):
		var t: float = float(s) / 16.0
		var u: Vector3 = t1.rotated(axis, sweep * t)
		var d: Vector3 = (v * cos(fa) + u * sin(fa)).normalized()
		pts.append(_on_sphere(d, TUBE_FILLET))
	_add_tube_dirs(pts, TUBE_FILLET, LINE_COLOR)


# ── postulate: net ──────────────────────────────────────────────────────────────

## A net of 8 meridians and 8 parallels. No caption: the cells start wide at the
## equator and collapse toward the pole, and that collapse IS the positive curvature.
## The top ring sits at 84.5°, where the meridian spacing has fallen to about 0.03 m.
func _build_net() -> void:
	for i in range(NET_MERIDIANS):
		var lon: float = TAU * float(i) / float(NET_MERIDIANS)
		_add_tube(_meridian_points(lon, 0.0, 90.0, 26), TUBE_NET, LINE_COLOR)

	for j in range(NET_PARALLELS):
		var lat_deg: float = NET_TOP_LAT_DEG * float(j) / float(NET_PARALLELS - 1)
		_add_tube(_parallel_points(deg_to_rad(lat_deg), 44), TUBE_NET, LINE_COLOR)


# ── postulate: euclid ───────────────────────────────────────────────────────────

## The flat control: two ribbons that stay PARALLEL_GAP apart from rim to rim and
## never meet, and a triangle with straight sides that closes at 180°.
func _build_flat_figures() -> void:
	var y: float = -radius * 0.3 + 0.002 + TUBE_MAIN * 0.6

	# Two chords running the full width of the disc, held 0.10 m apart the whole way.
	for i in range(2):
		var x: float = -0.06 - PARALLEL_GAP * float(i)
		var half: float = sqrt(maxf(radius * radius - x * x, 0.0))
		var pts: PackedVector3Array = PackedVector3Array()
		pts.append(Vector3(x, y, -half))
		pts.append(Vector3(x, y, half))
		_add_tube_flat(pts, TUBE_MAIN, LINE_COLOR)

	# Straight-sided triangle on the free half of the disc.
	var centre := Vector2(0.15, 0.0)
	var circum: float = 0.20
	var tri: Array[Vector3] = []
	for i in range(3):
		var ang: float = deg_to_rad(90.0 + 120.0 * float(i))
		tri.append(Vector3(centre.x + circum * cos(ang), y, centre.y + circum * sin(ang)))
	for i in range(3):
		var seg: PackedVector3Array = PackedVector3Array()
		seg.append(tri[i])
		seg.append(tri[(i + 1) % 3])
		_add_tube_flat(seg, TUBE_MAIN, LINE_COLOR)

	_add_plate("SUM = 180", 0.20, PLATE_Y_FLAT)


# ═══════════════════════════════════════════════════════════════════
# GEOMETRY HELPERS
# ═══════════════════════════════════════════════════════════════════

func _sphere_center() -> Vector3:
	return Vector3(0, -radius * 0.3, 0)


func _dir(lat: float, lon: float) -> Vector3:
	return Vector3(cos(lat) * cos(lon), sin(lat), cos(lat) * sin(lon))


## A point on the marking shell: the tube centreline stands slightly proud of the
## dome so the ribbon reads as laid ON the surface rather than sunk into it.
func _on_sphere(d: Vector3, tube_r: float) -> Vector3:
	return _sphere_center() + d * (radius + tube_r * 0.6)


func _meridian_points(lon: float, lat_from_deg: float, lat_to_deg: float, steps: int) -> PackedVector3Array:
	var pts: PackedVector3Array = PackedVector3Array()
	for i in range(steps + 1):
		var t: float = float(i) / float(steps)
		var lat: float = deg_to_rad(lerpf(lat_from_deg, lat_to_deg, t))
		pts.append(_dir(lat, lon))
	return pts


func _parallel_points(lat: float, steps: int) -> PackedVector3Array:
	var pts: PackedVector3Array = PackedVector3Array()
	for i in range(steps + 1):
		var lon: float = TAU * float(i) / float(steps)
		pts.append(_dir(lat, lon))
	return pts


## Tube along a curve given as UNIT DIRECTIONS on the sphere — the outward normal
## comes free, which keeps the cross-section frame stable with no drift.
func _add_tube(dirs: PackedVector3Array, tube_r: float, col: Color) -> void:
	var pts: PackedVector3Array = PackedVector3Array()
	var normals: PackedVector3Array = PackedVector3Array()
	for d in dirs:
		pts.append(_on_sphere(d, tube_r))
		normals.append(d.normalized())
	_commit_tube(pts, normals, tube_r, col)


## Tube along a curve already in local space, lying on the sphere.
func _add_tube_dirs(pts: PackedVector3Array, tube_r: float, col: Color) -> void:
	var centre: Vector3 = _sphere_center()
	var normals: PackedVector3Array = PackedVector3Array()
	for p in pts:
		normals.append((p - centre).normalized())
	_commit_tube(pts, normals, tube_r, col)


## Tube on the flat disc — the reference normal is simply up.
func _add_tube_flat(pts: PackedVector3Array, tube_r: float, col: Color) -> void:
	var normals: PackedVector3Array = PackedVector3Array()
	for p in pts:
		normals.append(Vector3.UP)
	_commit_tube(pts, normals, tube_r, col)


func _commit_tube(pts: PackedVector3Array, normals: PackedVector3Array, tube_r: float, col: Color) -> void:
	if pts.size() < 2:
		return

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var count: int = pts.size()
	var ring_n: PackedVector3Array = PackedVector3Array()
	var ring_b: PackedVector3Array = PackedVector3Array()

	for i in range(count):
		var tangent: Vector3
		if i == 0:
			tangent = pts[1] - pts[0]
		elif i == count - 1:
			tangent = pts[count - 1] - pts[count - 2]
		else:
			tangent = pts[i + 1] - pts[i - 1]
		if tangent.length() < 0.000001:
			tangent = Vector3.FORWARD
		tangent = tangent.normalized()

		var n: Vector3 = normals[i].normalized()
		var b: Vector3 = tangent.cross(n)
		if b.length() < 0.0001:
			b = tangent.cross(Vector3.RIGHT)
			if b.length() < 0.0001:
				b = tangent.cross(Vector3.UP)
		b = b.normalized()
		ring_b.append(b)
		ring_n.append(b.cross(tangent).normalized())

	for i in range(count - 1):
		for j in range(TUBE_SIDES):
			var a0: float = TAU * float(j) / float(TUBE_SIDES)
			var a1: float = TAU * float(j + 1) / float(TUBE_SIDES)
			var d00: Vector3 = ring_n[i] * cos(a0) + ring_b[i] * sin(a0)
			var d01: Vector3 = ring_n[i] * cos(a1) + ring_b[i] * sin(a1)
			var d10: Vector3 = ring_n[i + 1] * cos(a0) + ring_b[i + 1] * sin(a0)
			var d11: Vector3 = ring_n[i + 1] * cos(a1) + ring_b[i + 1] * sin(a1)

			var p00: Vector3 = pts[i] + d00 * tube_r
			var p01: Vector3 = pts[i] + d01 * tube_r
			var p10: Vector3 = pts[i + 1] + d10 * tube_r
			var p11: Vector3 = pts[i + 1] + d11 * tube_r

			st.set_normal(d00)
			st.add_vertex(p00)
			st.set_normal(d10)
			st.add_vertex(p10)
			st.set_normal(d11)
			st.add_vertex(p11)

			st.set_normal(d00)
			st.add_vertex(p00)
			st.set_normal(d11)
			st.add_vertex(p11)
			st.set_normal(d01)
			st.add_vertex(p01)

	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.material_override = _line_material(col)
	_own_add(mi)


func _line_material(col: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = col
	mat.metallic = 0.0
	mat.roughness = 0.45
	mat.emission_enabled = true
	mat.emission = col
	mat.emission_energy_multiplier = 0.25
	# Insurance against a flipped winding on a tight arc — the normals are authored,
	# so shading is correct either way; culling is the only thing at risk.
	mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	return mat


## A small caption plate, floating like the artifact's own label does. Text on both
## faces so the four-angle capture reads it from front and back.
func _add_plate(text: String, width: float, y: float) -> void:
	var holder := Node3D.new()
	holder.position = Vector3(0, y, 0)

	var box := MeshInstance3D.new()
	var bm := BoxMesh.new()
	bm.size = Vector3(width, PLATE_H, PLATE_D)
	box.mesh = bm
	var mat := StandardMaterial3D.new()
	mat.albedo_color = PLATE_COLOR
	mat.metallic = 0.1
	mat.roughness = 0.7
	box.material_override = mat
	holder.add_child(box)

	for i in range(2):
		var lbl := Label3D.new()
		lbl.text = text
		lbl.pixel_size = 0.0016
		lbl.font_size = 12
		lbl.modulate = LINE_COLOR
		lbl.outline_size = 0
		lbl.double_sided = false
		lbl.billboard = BaseMaterial3D.BILLBOARD_DISABLED
		if i == 0:
			lbl.position = Vector3(0, 0, PLATE_D * 0.5 + 0.001)
		else:
			lbl.position = Vector3(0, 0, -PLATE_D * 0.5 - 0.001)
			lbl.rotate_y(PI)
		holder.add_child(lbl)

	_own_add(holder)


func _own_add(n: Node) -> void:
	add_child(n)
	_own.append(n)


# ═══════════════════════════════════════════════════════════════════
# GRID CONFIG INTEGRATION
# ═══════════════════════════════════════════════════════════════════

## Reached by call_deferred from GridInteractablesComponent, AFTER _ready(). Also
## called by curation_station with {"emissive": false} one line after it has framed
## and dimmed this instance's labels — so an unconditional rebuild here would throw
## that framing away. Nothing changed means nothing happens, and nothing is printed.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_postulate: String = postulate
	var before_radius: float = radius
	var before_resolution: int = resolution

	for key in config_data:
		if key == "postulate":
			continue
		if key in self:
			set(key, config_data[key])

	if config_data.has("postulate"):
		postulate = _pick_axis(str(config_data["postulate"]), POSTULATES, postulate)

	if not _built:
		return
	var same_axis: bool = (postulate == before_postulate)
	var same_geom: bool = is_equal_approx(radius, before_radius) and resolution == before_resolution
	if same_axis and same_geom:
		return

	_rebuild_now()
	print("[EllipticSurface] Config applied — postulate=%s, radius=%.2f" % [postulate, radius])


## Accept an axis value only if it names something this artifact actually builds.
## Lower-cased and trimmed; anything else falls back rather than half-applying.
func _pick_axis(raw: String, allowed: PackedStringArray, fallback: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if allowed.has(v) else fallback


## Synchronous and inline. A deferred rebuild would leave the node empty for a frame,
## and _auto_ground_artifact — queued right behind apply_grid_config — would measure a
## zero AABB, return early, and never ground the dome.
func _rebuild_now() -> void:
	for n in _own:
		if is_instance_valid(n):
			remove_child(n)
			n.queue_free()
	_own.clear()
	_mesh_instance = null
	_label = null
	_build_all()
