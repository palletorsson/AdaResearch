extends Node3D
class_name SoftBodySlicer

# @identity
# essence: a spring-mass jelly settled on a bench and a grabbable emissive plane above it; let the plane go and every spring whose two particles sit on opposite sides of it is deleted, the wire mesh is rebuilt from what survives, and the halves sag apart under their own weight
# desire: to take the word "cut" away from geometry. Nothing is subtracted here — the same 64 particles are still there after the slice, at the same positions, with the same masses. Only the graph between them is smaller
# critical_parameter: the blade's resting plane at the moment of release — its point and normal in the body's own space. Springs are removed by SIGN TEST, so where the plane sits decides the topology, and a plane that grazes the corner removes four springs while a plane through the middle removes eighty
# triggers: the blade is an XRTools pickable; its dropped signal reads the plane out of the blade's global transform, sign-tests every spring against it, keeps the crossing point inside the blade's finite rectangle, and rewrites sim.springs with the survivors
# emerges: the sag is the lesson. No force is applied at the cut — the halves fall because the constraints that were holding them up stopped existing, and Verlet does the rest with no idea a knife was involved
# needs: soft_body_shapes.make_jelly_grid + soft_body_sim.gd [present]; grab_cube.tscn as the blade handle [present]; a bench top to seat the body on and a floor_y to stop it
# relationships: the destructive counterpart to pressure_soft_body, which moves a coefficient and leaves the graph intact; both bodies are the same object seen through the two things you can change about it — its forces or its wiring
# truth: a mesh boolean asks where the surface goes. A soft body does not have a surface — it has a graph, and the surface is a picture drawn of the graph afterwards. Cut the graph and the picture follows; cut the picture and nothing happens at all.

## A jelly cube and a knife on a bench. The sim is the project's own deterministic
## Verlet solver (commons/soft_body/soft_body_sim.gd); the cut is a filter over
## its spring list. Everything is built procedurally in _ready().

const SHADER_PATH := "res://commons/resourses/shaders/Grid.gdshader"
const SBShapes := preload("res://commons/soft_body/soft_body_shapes.gd")
const GrabCubeScene := preload("res://commons/interactables/grab_cube.tscn")

const BENCH_W := 1.60
const BENCH_D := 0.66
const BENCH_TOP := 0.79           # y of the working surface
const TOP_T := 0.07               # bench top thickness
const LEG := 0.08

const BLADE_W := 0.50
const BLADE_H := 0.50
const BLADE_T := 0.006
# The handle rides high enough to grab, low enough that the plate hangs THROUGH
# the settled jelly — a knife already set in the cut, not one stored above it.
const HANDLE_Y := BENCH_TOP + 0.72

const PARTICLE_R := 0.030
const JELLY_COLOR := Color(0.86, 0.40, 0.50)
const WIRE_COLOR := Color(0.45, 0.90, 1.00)

## Particles per side of the jelly grid. 4 gives 64 particles and 288 springs —
## dense enough that a cut removes a visible band, sparse enough to solve at 60 Hz.
@export_range(2, 6) var grid_n: int = 4
## Edge length of one grid cell, in metres.
@export_range(0.05, 0.20, 0.005) var cell: float = 0.115
## Spring stiffness fed to the constraint solver. Fixed for the life of a build —
## the artifact's variable is the spring LIST, not the spring strength.
@export_range(0.1, 1.0, 0.01) var stiffness: float = 0.7
## Apply the cut at the blade's resting plane during _ready(), so a still capture
## shows a body that has already been sliced instead of one waiting to be.
@export var precut: bool = false

var _built: bool = false
var _created: Array[Node] = []

## Untyped: soft_body_sim.gd and grab_cube.tscn's root script carry no class_name,
## so typed handles would fail static analysis on every property we touch.
var _sim = null
var _blade = null
var _blade_plane: MeshInstance3D = null
var _particles: MultiMeshInstance3D = null
var _wires: MeshInstance3D = null
var _wire_mat: StandardMaterial3D = null
var _readout: Label3D = null

var _spring_count_initial: int = 0
var _cut_total: int = 0


func _ready() -> void:
	_build_all()
	_built = true


func _own(n: Node) -> void:
	_created.append(n)
	add_child(n)


func _build_all() -> void:
	_build_bench()
	_build_jelly()
	_build_blade()
	_build_readout()
	if precut:
		_cut_at_blade()


# --- bench ----------------------------------------------------------------

func _build_bench() -> void:
	var top := MeshInstance3D.new()
	top.name = "BenchTop"
	var box := BoxMesh.new()
	box.size = Vector3(BENCH_W, TOP_T, BENCH_D)
	top.mesh = box
	top.position = Vector3(0.0, BENCH_TOP - TOP_T * 0.5, 0.0)
	top.material_override = _grid_material(
		Color(0.19, 0.20, 0.25), Color(0.40, 0.46, 0.56), 0.35)
	_own(top)

	var leg_h: float = BENCH_TOP - TOP_T
	for sx in [-1.0, 1.0]:
		for sz in [-1.0, 1.0]:
			var leg := MeshInstance3D.new()
			var lb := BoxMesh.new()
			lb.size = Vector3(LEG, leg_h, LEG)
			leg.mesh = lb
			leg.position = Vector3(
				float(sx) * (BENCH_W * 0.5 - 0.12),
				leg_h * 0.5,
				float(sz) * (BENCH_D * 0.5 - 0.12))
			leg.material_override = _grid_material(
				Color(0.24, 0.25, 0.30), Color(0.42, 0.48, 0.58), 0.3)
			_own(leg)


# --- the body -------------------------------------------------------------

func _build_jelly() -> void:
	_sim = SBShapes.make_jelly_grid(grid_n, grid_n, grid_n, cell, stiffness, Vector3.ZERO)
	_sim.floor_y = BENCH_TOP + PARTICLE_R
	_sim.gravity = Vector3(0.0, -9.8, 0.0)
	_sim.damping = 0.985
	_sim.constraint_passes = 5
	# make_jelly_grid stacks the body a full ny*cell above its origin; drop it so
	# the bottom layer starts a hair above the bench rather than a metre above it.
	_seat(BENCH_TOP + PARTICLE_R + 0.004)
	_spring_count_initial = _sim.springs.size()
	_cut_total = 0

	# Let it settle before anyone sees it, so a capture shows a resting jelly and
	# not a cube caught mid-drop.
	_sim.simulate(90)

	var root: Node3D = SBShapes.to_node3d(_sim, {
		"color": [JELLY_COLOR.r, JELLY_COLOR.g, JELLY_COLOR.b],
		"wire_color": [WIRE_COLOR.r, WIRE_COLOR.g, WIRE_COLOR.b],
		"show_wires": true,
		"particle_radius": PARTICLE_R,
		"roughness": 0.5,
	})
	_own(root)
	# Explicit casts: get_children() hands back Node, and narrowing an assignment
	# without one does not survive static analysis.
	for child in root.get_children():
		if child is MultiMeshInstance3D:
			_particles = child as MultiMeshInstance3D
		elif child is MeshInstance3D:
			_wires = child as MeshInstance3D
	if _wires != null:
		_wire_mat = StandardMaterial3D.new()
		_wire_mat.albedo_color = WIRE_COLOR
		_wire_mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
		_wires.material_override = _wire_mat
	_refresh_render()


## Shift every particle (and its Verlet history, or the body launches itself)
## so the lowest one sits at target_min_y.
func _seat(target_min_y: float) -> void:
	if _sim == null:
		return
	var min_y: float = INF
	for i in _sim.positions.size():
		min_y = minf(min_y, _sim.positions[i].y)
	if not is_finite(min_y):
		return
	var dy: float = target_min_y - min_y
	var shift := Vector3(0.0, dy, 0.0)
	for i in _sim.positions.size():
		_sim.positions[i] = _sim.positions[i] + shift
		_sim.prev_positions[i] = _sim.prev_positions[i] + shift


# --- the blade ------------------------------------------------------------

func _build_blade() -> void:
	_blade = GrabCubeScene.instantiate()
	_blade.name = "Blade"
	if "cube_size" in _blade:
		_blade.cube_size = 0.075
	if "cube_color" in _blade:
		_blade.cube_color = Color(0.55, 0.95, 1.0)
	_own(_blade)
	# Local placement AFTER add_child so it lands in our space, not the world's.
	(_blade as Node3D).position = Vector3(0.0, HANDLE_Y, 0.0)
	# Rotated so the blade's own +Z — the plane's normal — runs along our X. The
	# cut therefore separates a left half from a right half along the bench.
	(_blade as Node3D).rotation_degrees = Vector3(0.0, 90.0, 0.0)

	_blade_plane = MeshInstance3D.new()
	_blade_plane.name = "Plane"
	var pb := BoxMesh.new()
	pb.size = Vector3(BLADE_W, BLADE_H, BLADE_T)
	_blade_plane.mesh = pb
	_blade_plane.position = Vector3(0.0, -BLADE_H * 0.5 - 0.05, 0.0)
	var pm := StandardMaterial3D.new()
	pm.albedo_color = Color(0.60, 0.95, 1.0, 0.55)
	pm.emission_enabled = true
	pm.emission = Color(0.60, 0.95, 1.0)
	pm.emission_energy_multiplier = 1.6
	pm.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	pm.cull_mode = BaseMaterial3D.CULL_DISABLED
	_blade_plane.material_override = pm
	_blade.add_child(_blade_plane)

	if _blade.has_signal("dropped"):
		_blade.connect("dropped", Callable(self, "_on_blade_dropped"))


func _on_blade_dropped(_pickable: Variant = null) -> void:
	_cut_at_blade()


## The cut. Every spring is sign-tested against the blade's plane; a spring whose
## two particles disagree, AND whose crossing point falls inside the blade's
## finite rectangle, is deleted. No particle is touched, no mesh is subtracted,
## no force is applied. The gap opens because gravity is no longer being argued
## with across that seam.
func _cut_at_blade() -> int:
	if _sim == null or _blade_plane == null or not is_instance_valid(_blade_plane):
		return 0
	var blade_xform: Transform3D = _blade_plane.global_transform
	var inv_self: Transform3D = global_transform.affine_inverse()
	# Plane in OUR space, which is the space sim.positions live in.
	var p: Vector3 = inv_self * blade_xform.origin
	var n: Vector3 = (inv_self.basis * blade_xform.basis.z).normalized()
	if n.length_squared() < 0.5:
		return 0
	# The blade rectangle, for bounding the cut to the metal that is actually there.
	var to_blade: Transform3D = blade_xform.affine_inverse() * global_transform
	var half_w: float = BLADE_W * 0.5
	var half_h: float = BLADE_H * 0.5

	var kept: Array = []
	var removed: int = 0
	for s in _sim.springs:
		var pa: Vector3 = _sim.positions[s[0]]
		var pb: Vector3 = _sim.positions[s[1]]
		var da: float = (pa - p).dot(n)
		var db: float = (pb - p).dot(n)
		if (da > 0.0) == (db > 0.0):
			kept.append(s)
			continue
		var denom: float = da - db
		if absf(denom) < 1e-9:
			kept.append(s)
			continue
		var t: float = da / denom
		var crossing: Vector3 = pa + (pb - pa) * t
		var local_hit: Vector3 = to_blade * crossing
		if absf(local_hit.x) > half_w or absf(local_hit.y) > half_h:
			kept.append(s)          # the plane passes here, the blade does not
			continue
		removed += 1

	if removed == 0:
		return 0
	_sim.springs = kept
	_cut_total += removed
	_refresh_render()
	_refresh_readout()
	print("[SoftBodySlicer] Cut %d springs — %d of %d remain" % [
		removed, _sim.springs.size(), _spring_count_initial])
	return removed


# --- render ---------------------------------------------------------------

## Push the current particle positions into the MultiMesh and rebuild the spring
## wires from scratch. The wire mesh is the ONLY place the topology is visible,
## so it has to be regenerated from sim.springs rather than transformed.
func _refresh_render() -> void:
	if _sim == null:
		return
	if _particles != null and is_instance_valid(_particles) and _particles.multimesh != null:
		var mm: MultiMesh = _particles.multimesh
		var count: int = mini(mm.instance_count, _sim.positions.size())
		for i in count:
			var t := Transform3D.IDENTITY
			t.origin = _sim.positions[i]
			mm.set_instance_transform(i, t)
	if _wires != null and is_instance_valid(_wires):
		var im: ImmediateMesh = _wires.mesh as ImmediateMesh
		if im != null:
			im.clear_surfaces()
			if _sim.springs.size() > 0:
				im.surface_begin(Mesh.PRIMITIVE_LINES, _wire_mat)
				for s in _sim.springs:
					im.surface_add_vertex(_sim.positions[s[0]])
					im.surface_add_vertex(_sim.positions[s[1]])
				im.surface_end()


func _process(delta: float) -> void:
	if _sim == null:
		return
	_sim.step(minf(delta, 1.0 / 30.0))
	_refresh_render()


# --- readout --------------------------------------------------------------

func _build_readout() -> void:
	_readout = Label3D.new()
	_readout.name = "Readout"
	_readout.font_size = 40
	_readout.pixel_size = 0.0011
	_readout.outline_size = 5
	_readout.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_readout.modulate = WIRE_COLOR
	_readout.position = Vector3(0.0, HANDLE_Y + 0.22, 0.0)
	_own(_readout)

	var note := Label3D.new()
	note.name = "Note"
	note.text = "a cut is a topology edit, not a mesh boolean"
	note.font_size = 40
	note.pixel_size = 0.00085
	note.outline_size = 4
	note.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	note.modulate = Color(0.72, 0.76, 0.84)
	note.position = Vector3(0.0, HANDLE_Y + 0.15, 0.0)
	_own(note)

	_refresh_readout()


func _refresh_readout() -> void:
	if _readout == null or not is_instance_valid(_readout) or _sim == null:
		return
	_readout.text = "%d springs   %d cut" % [_sim.springs.size(), _cut_total]


# --- material -------------------------------------------------------------

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
		m.set_shader_parameter("modelOpacity", 1.0)
		m.set_shader_parameter("wireframeOpacity", 1.0)
		m.set_shader_parameter("globalOpacity", 1.0)
		m.set_shader_parameter("show_interior", true)
		return m
	var fallback := StandardMaterial3D.new()
	fallback.albedo_color = fill
	fallback.roughness = 0.4
	return fallback


func _rebuild_now() -> void:
	for c in _created:
		if is_instance_valid(c) and c.get_parent() == self:
			remove_child(c)
			c.queue_free()
	_created.clear()
	_sim = null
	_blade = null
	_blade_plane = null
	_particles = null
	_wires = null
	_wire_mat = null
	_readout = null
	_build_all()


## Grid config. Keys: "grid_n" (2-6), "cell", "stiffness", "precut".
## Any of them changes the spring graph, so any of them rebuilds — there is no
## way to move a particle count in place without inventing springs.
func apply_grid_config(config_data: Dictionary) -> void:
	var before_n: int = grid_n
	var before_cell: float = cell
	var before_stiff: float = stiffness
	var before_precut: bool = precut

	if config_data.has("grid_n"):
		grid_n = clampi(int(config_data["grid_n"]), 2, 6)
	if config_data.has("cell"):
		cell = clampf(float(config_data["cell"]), 0.05, 0.20)
	if config_data.has("stiffness"):
		stiffness = clampf(float(config_data["stiffness"]), 0.1, 1.0)
	if config_data.has("precut"):
		precut = bool(config_data["precut"])

	if not _built:
		return
	if grid_n == before_n and is_equal_approx(cell, before_cell) \
			and is_equal_approx(stiffness, before_stiff) and precut == before_precut:
		# Nothing about the graph changed. curation_station hands every artifact it
		# frames a config right after setting its labels; rebuilding on a no-op
		# would discard that framing and re-drop a jelly that had already settled.
		return

	_rebuild_now()
	print("[SoftBodySlicer] Config applied — grid_n=%d cell=%.3f precut=%s" % [
		grid_n, cell, str(precut)])
