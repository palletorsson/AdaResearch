extends Node3D
class_name SurveillancePanopticon

# @identity
# essence: a dark opaque tower ringed by ten open cells, each cell held in a translucent cone thrown from a window band that glows outward and admits no sight inward — the asymmetry built as geometry, not written on a sign
# desire: to put Bentham's plan on the floor at body scale so a visitor stands where the inmate stands, sees the light that lands on them, and finds nothing to look back at
# critical_parameter: cell_count against ring_radius — how tightly the cells crowd the tower; at 8 the ring reads as architecture, at 12 it reads as a wall of occupancy, and the tower never changes
# triggers: _ready() raises the tower, seals its window band with an opaque emissive skin, rings the floor with three-walled cells facing inward, and throws one cone from the band to each cell; _process steps which cone is bright so the sweep never rests
# emerges: you can read who is being watched from anywhere in the room, and you cannot read who is watching from anywhere at all — visibility as a one-way material property of the building
# needs: CylinderMesh tower and cones [Godot built-ins]; CapsuleMesh occupants [built-in]; Grid.gdshader for the cell shells [present]; TextScreen PAD plate [present]; ~4 x 3 x 4 m of floor
# relationships: the centrepiece of the criticalalgorithms bias gallery — algorithmic_bias supplies the asymmetric error rate, excluded_class_visualizer supplies who falls outside the boundary, and this supplies the building both of them are running inside
# truth: the tower does not need anyone in it. Power here is a property of sightlines, not of a watcher — which is why an unstaffed camera and a staffed one do the same work on the body underneath.

## Room-scale, 4 x 3 x 4. The argument is load-bearing geometry: every surface of
## the tower is opaque, every cone is unshaded and translucent, and the cells are
## open only on the face that points at the tower. Nothing about the asymmetry is
## carried by text — the plaque names the piece and stops there.

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const TextScreenScript := preload("res://commons/ui/text_screen.gd")

@export_range(6, 14, 1) var cell_count: int = 10
@export var ring_radius: float = 1.52
@export var tower_radius: float = 0.42
@export var tower_height: float = 2.35
@export var cell_height: float = 1.55
@export var sweep_period: float = 1.1
@export var show_occupants: bool = true
@export var panopticon_label: String = "PANOPTICON"

const FLOOR_RADIUS: float = 1.94
const CELL_W: float = 0.72
const CELL_D: float = 0.70
const WALL_T: float = 0.06
const BAND_H: float = 0.32

## Where the cones leave the tower — the centre of the window band.
const BAND_FRACTION: float = 0.74

var _built: bool = false
var _t: float = 0.0
var _active: int = 0

var _cone_mats: Array[StandardMaterial3D] = []
var _occupant_mats: Array[StandardMaterial3D] = []

## Every node THIS script parented onto itself. A rebuild frees these and nothing
## else — the grid adds label plates, packaging and tags after us.
var _created: Array[Node] = []


func _ready() -> void:
	_build_all()
	_built = true
	set_process(true)


func _build_all() -> void:
	_cone_mats.clear()
	_occupant_mats.clear()
	_active = 0
	_t = 0.0
	_build_floor()
	_build_tower()
	_build_cells()
	_build_cones()
	_build_label()
	_apply_sweep()


## The sweep never stops and never announces where it will be next. Only the
## cone's opacity moves; every cone stays lit, because the claim is that you
## cannot tell which one is live, not that only one exists.
func _process(delta: float) -> void:
	if not _built or _cone_mats.is_empty():
		return
	_t += delta
	if _t < maxf(0.15, sweep_period):
		return
	_t = 0.0
	_active = (_active + 1) % _cone_mats.size()
	_apply_sweep()


func _apply_sweep() -> void:
	for i in range(_cone_mats.size()):
		var mat: StandardMaterial3D = _cone_mats[i]
		if not is_instance_valid(mat):
			continue
		var c: Color = mat.albedo_color
		c.a = 0.34 if i == _active else 0.11
		mat.albedo_color = c
	for i in range(_occupant_mats.size()):
		var om: StandardMaterial3D = _occupant_mats[i]
		if not is_instance_valid(om):
			continue
		om.emission_energy_multiplier = 1.9 if i == _active else 0.35


# ── geometry ─────────────────────────────────────────────────────────

func _own(n: Node) -> Node:
	_created.append(n)
	add_child(n)
	return n


func _count() -> int:
	return clampi(cell_count, 6, 14)


func _angle(i: int) -> float:
	return TAU * float(i) / float(_count())


func _band_y() -> float:
	return tower_height * BAND_FRACTION


## A dark disc. The cells and the tower need one continuous ground or the ring
## reads as furniture standing about rather than a plan.
func _build_floor() -> void:
	var mi := MeshInstance3D.new()
	mi.name = "Yard"
	var cyl := CylinderMesh.new()
	cyl.top_radius = FLOOR_RADIUS
	cyl.bottom_radius = FLOOR_RADIUS
	cyl.height = 0.04
	cyl.radial_segments = 40
	mi.mesh = cyl
	mi.position = Vector3(0.0, 0.02, 0.0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.11, 0.115, 0.135)
	mat.roughness = 0.95
	mi.material_override = mat
	_own(mi)


## Shaft, window band, roof. Every piece opaque. The band is the only lit surface
## on the whole tower and it is a SEALED one — it throws light out and returns no
## interior, which is the entire asymmetry stated in one material.
func _build_tower() -> void:
	var shaft := MeshInstance3D.new()
	shaft.name = "Tower"
	var cyl := CylinderMesh.new()
	cyl.top_radius = tower_radius
	cyl.bottom_radius = tower_radius * 1.08
	cyl.height = tower_height
	cyl.radial_segments = 28
	shaft.mesh = cyl
	shaft.position = Vector3(0.0, 0.04 + tower_height * 0.5, 0.0)
	var dark := StandardMaterial3D.new()
	dark.albedo_color = Color(0.055, 0.06, 0.075)
	dark.roughness = 0.88
	dark.metallic = 0.15
	shaft.material_override = dark
	_own(shaft)

	var band := MeshInstance3D.new()
	band.name = "WindowBand"
	var bcyl := CylinderMesh.new()
	bcyl.top_radius = tower_radius * 1.035
	bcyl.bottom_radius = tower_radius * 1.035
	bcyl.height = BAND_H
	bcyl.radial_segments = 28
	band.mesh = bcyl
	band.position = Vector3(0.0, 0.04 + _band_y(), 0.0)
	var glow := StandardMaterial3D.new()
	# Unshaded and fully opaque on purpose: it reads as light and cannot be seen
	# through. A translucent band here would put an interior on stage and lose
	# the piece.
	glow.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	glow.albedo_color = Color(0.98, 0.90, 0.55, 1.0)
	band.material_override = glow
	_own(band)

	# A shallow eave over the band, so the glow is a slot in a building rather
	# than a stripe painted on a post.
	var eave := MeshInstance3D.new()
	eave.name = "Eave"
	var ecyl := CylinderMesh.new()
	ecyl.top_radius = tower_radius * 0.35
	ecyl.bottom_radius = tower_radius * 1.30
	ecyl.height = 0.30
	ecyl.radial_segments = 28
	eave.mesh = ecyl
	eave.position = Vector3(0.0, 0.04 + tower_height + 0.14, 0.0)
	eave.material_override = dark
	_own(eave)


func _build_cells() -> void:
	var n: int = _count()
	for i in range(n):
		var a: float = _angle(i)
		var holder := Node3D.new()
		holder.name = "Cell_%d" % i
		holder.position = Vector3(cos(a) * ring_radius, 0.04, sin(a) * ring_radius)
		# Local +Z points outward, so local -Z — the open face — points at the tower.
		holder.rotation = Vector3(0.0, PI * 0.5 - a, 0.0)
		_own(holder)

		var shell: Material = _cell_mat()

		holder.add_child(_slab(
			Vector3(CELL_W, 0.05, CELL_D),
			Vector3(0.0, 0.025, 0.0), shell))                              # floor
		holder.add_child(_slab(
			Vector3(CELL_W, cell_height, WALL_T),
			Vector3(0.0, cell_height * 0.5, CELL_D * 0.5), shell))         # back wall
		holder.add_child(_slab(
			Vector3(WALL_T, cell_height, CELL_D),
			Vector3(-CELL_W * 0.5, cell_height * 0.5, 0.0), shell))        # left wall
		holder.add_child(_slab(
			Vector3(WALL_T, cell_height, CELL_D),
			Vector3(CELL_W * 0.5, cell_height * 0.5, 0.0), shell))         # right wall
		# A half ceiling over the back only. A full one would seal the cell from
		# every raised camera angle; a half one still says "cell" and leaves the
		# cone a way in.
		holder.add_child(_slab(
			Vector3(CELL_W, 0.05, CELL_D * 0.5),
			Vector3(0.0, cell_height, CELL_D * 0.25), shell))

		if show_occupants:
			var body := MeshInstance3D.new()
			body.name = "Occupant"
			var cap := CapsuleMesh.new()
			cap.radius = 0.095
			cap.height = 0.58
			cap.radial_segments = 10
			cap.rings = 4
			body.mesh = cap
			body.position = Vector3(0.0, 0.34, 0.06)
			var om := StandardMaterial3D.new()
			om.albedo_color = Color(0.78, 0.80, 0.86)
			om.emission_enabled = true
			om.emission = Color(0.95, 0.86, 0.60)
			om.emission_energy_multiplier = 0.35
			om.roughness = 0.6
			body.material_override = om
			holder.add_child(body)
			_occupant_mats.append(om)


## One cone per cell, thrown from the window band. Narrow at the tower, wide at
## the cell: the beam is aimed, and what it lands on is a person-sized volume.
func _build_cones() -> void:
	var n: int = _count()
	var origin_y: float = 0.04 + _band_y()
	for i in range(n):
		var a: float = _angle(i)
		var from: Vector3 = Vector3(cos(a) * tower_radius * 1.05, origin_y, sin(a) * tower_radius * 1.05)
		var to: Vector3 = Vector3(cos(a) * ring_radius, 0.04 + 0.42, sin(a) * ring_radius)
		var mat := StandardMaterial3D.new()
		mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		mat.depth_draw_mode = BaseMaterial3D.DEPTH_DRAW_DISABLED
		mat.albedo_color = Color(0.98, 0.90, 0.55, 0.11)
		var cone := _beam(from, to, 0.045, 0.40, mat)
		cone.name = "Cone_%d" % i
		_own(cone)
		_cone_mats.append(mat)


## A box at a local offset. Cheap enough to call five times per cell.
func _slab(size: Vector3, pos: Vector3, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mi.mesh = box
	mi.position = pos
	mi.material_override = mat
	return mi


## A tapered cylinder from p1 to p2, oriented so its own Y axis runs the line.
## The mesh's -Y end sits at p1, so bottom_radius is the tower end.
func _beam(p1: Vector3, p2: Vector3, r_start: float, r_end: float, mat: Material) -> MeshInstance3D:
	var mi := MeshInstance3D.new()
	var cyl := CylinderMesh.new()
	var d: float = p1.distance_to(p2)
	cyl.bottom_radius = r_start
	cyl.top_radius = r_end
	cyl.height = maxf(0.001, d)
	cyl.radial_segments = 14
	cyl.rings = 1
	mi.mesh = cyl
	var dir: Vector3 = (p2 - p1).normalized()
	var up: Vector3 = Vector3.UP
	if absf(dir.dot(up)) > 0.999:
		up = Vector3.RIGHT
	var xa: Vector3 = up.cross(dir).normalized()
	var za: Vector3 = dir.cross(xa).normalized()
	mi.transform = Transform3D(Basis(xa, dir, za), (p1 + p2) * 0.5)
	mi.material_override = mat
	return mi


func _build_label() -> void:
	# Configure BEFORE add_child — TextScreen rebuilds on each setter once in-tree.
	# The plaque names the building. It does not explain the asymmetry; if the
	# geometry needs a caption to make the point, the geometry has failed.
	var ts := TextScreenScript.new()
	ts.name = "PanopticonPlate"
	ts.mode = 2                            # Mode.PAD — reclined plaque
	ts.width_m = 0.52
	ts.position = Vector3(0.0, 0.055, FLOOR_RADIUS - 0.22)
	if ts.has_method("set_text"):
		ts.set_text(panopticon_label, "%d cells, one tower" % _count())
	_created.append(ts)
	add_child(ts)


# ── material ─────────────────────────────────────────────────────────

func _cell_mat() -> Material:
	return _grid_material(Color(0.24, 0.26, 0.31), Color(0.42, 0.52, 0.66), 0.7)


func _grid_material(fill: Color, wire: Color, emit: float) -> Material:
	var shader: Shader = load(SHADER_PATH)
	if shader:
		var m := ShaderMaterial.new()
		m.shader = shader
		m.set_shader_parameter("modelColor", fill)
		m.set_shader_parameter("wireframeColor", wire)
		m.set_shader_parameter("emissionColor", wire)
		m.set_shader_parameter("width", 1.0)
		m.set_shader_parameter("blur", 1.0)
		m.set_shader_parameter("emission_strength", emit)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.6
	return fallback


# ── config ───────────────────────────────────────────────────────────

## Synchronous and scoped to our own children. Nothing deferred: the grid frames
## labels and grounds the artifact right after add_child, and a deferred rebuild
## would land after both and undo them.
func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_build_all()


func apply_grid_config(config_data: Dictionary) -> void:
	var before_count: int = cell_count
	var before_ring: float = ring_radius
	var before_occupants: bool = show_occupants
	var before_label: String = panopticon_label

	if config_data.has("cell_count"):
		cell_count = clampi(int(config_data["cell_count"]), 6, 14)
	if config_data.has("ring_radius"):
		ring_radius = clampf(float(config_data["ring_radius"]), 1.0, 1.75)
	if config_data.has("sweep_period"):
		# Speed alone never needs a rebuild — _process reads it every frame.
		sweep_period = maxf(0.15, float(config_data["sweep_period"]))
	if config_data.has("show_occupants"):
		show_occupants = bool(config_data["show_occupants"])
	if config_data.has("label"):
		panopticon_label = str(config_data["label"])

	if not _built:
		# _ready has not run yet; it will build with the values just resolved.
		return
	if (cell_count == before_count and is_equal_approx(ring_radius, before_ring)
			and show_occupants == before_occupants and panopticon_label == before_label):
		# Nothing geometric changed. curation_station hands every artifact it
		# curates {"emissive": false} moments after framing labels — rebuilding
		# here would throw that framing away and never get it back.
		return

	_rebuild_now()
	print("[SurveillancePanopticon] Config applied — %d cells at r=%.2f" % [_count(), ring_radius])
