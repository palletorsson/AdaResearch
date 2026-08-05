extends Node3D
## PipeScreensaver3D.gd
## Generates a neon "Windows Pipes"-style path with smoother materials and bounds-aware growth.
##
## @identity
## essence: a 3D random walk that rounds its corners — the screensaver as memory of childhood computers
## desire: watch a pipe explore a sealed cube, choosing each turn live, until the cube is full
## critical_parameter: residue — how much of the run the cube is left holding (head | tail | path | envelope | ensemble); continue_straight_chance is the inertia that decides how often the walker keeps going vs turns
## triggers: _grow_segment() fires every turn_interval seconds; bounds-aware growth halts if next cell exits bounds_extent
## emerges: a tangle of luminous pipes that fills space — same problem as Hilbert curves, approached stochastically
## needs: cardinal direction set [has]; head light + emissive material [has]; configurable bounds [has]; growth tween [has]
## relationships: the fourth walk of the group — shares the `residue` ladder word for word with [[random_walk_128]], [[random_walk_leash]] and [[random_walk_collection]]; kin to [[random_walk_terrarium]] (a constrained walk in a vessel); cousin of Hilbert/Peano curves (deterministic space-fillers)
## truth: A walker that remembers where it has been is no longer just random — it becomes a maker of structure.
##
## ─────────────────────────────────────────────────────────────────────────────
## STAGE-2 DNA PROMOTION (2026-08-05) — residue
##
## The runner refused this artifact as NO TURNABLE KNOBS, and the refusal was
## right for a reason the export list hides: eleven exports, every one of them a
## radius, an interval, a colour or an energy — how BIG and how FAST, never what
## the cube is left holding. apply_grid_config was a literal `pass`, so not one
## of them was reachable from a map token anyway.
##
##   residue   how much of the walk's own history the cube leaves standing
##
##     head  <  tail  <  path  <  envelope  <  ensemble
##
##   head      only where the pipe IS. One joint at the walker and the head light
##             on it; every segment it laid is gone. The claim, the same one
##             random_walk_128 makes: a random process seen from outside is a
##             LOCATION, and this is what the screensaver is at any single
##             instant before you grant it a memory.
##     tail      + a window. The last TAIL_SEGMENTS lengths survive and the rest
##             is dropped, so the pipe becomes a worm again — which is what it
##             looked like for the first second and a half of every run.
##     path      + the archive. Every length ever laid, nothing ever removed.
##             THIS IS THE LEGACY LINEAGE: at `path` the drawing code is the
##             shipped code, called in the shipped order, and none of the four
##             other rungs' functions is reached at all.
##     envelope  + the bound. Twelve thin rails around the smallest box the walk
##             actually stayed inside. This artifact's own desire line says the
##             pipe "explores a sealed cube ... until the cube is full", and the
##             tangle alone cannot say how much of the cube it reached. The rails
##             say it. bounds_extent is the cube it was ALLOWED; the rails are
##             the cube it USED, and they are never the same box.
##     ensemble  + the counterfactual. Three more walks under the same rule in
##             pale thin ink, sharing the cube with the real one. The run stops
##             being THE pipe and becomes ONE pipe. Nothing in the pale ink
##             happened; that is the point.
##
## THE WINDOW AT `tail` IS CUT IN TIME, not in space, and that is the one place
## this member differs from its three siblings. They draw on pages and keep
## PIXELS, so "recently" had to be approximated by a disc around the walker.
## Here the record is a list of turns in the order they were taken, so the window
## is the real thing: the last N lengths, oldest dropped first. The five rungs
## are still strictly nested — head ⊂ tail ⊂ path, and envelope and ensemble only
## add — so no rung invents pipe the run did not lay.
##
## DELIBERATELY NOT THE AXIS, and recorded so the next agent does not reopen it:
##
##   joint — the turn rule, ball vs bare vs collar. This is the strongest OTHER
##   candidate in the file and it is a real argument: the sphere at each corner
##   is what makes the walk read as continuous plumbing, and without it the
##   object is revealed as 180 loose sticks that merely overlap. It is not taken
##   here because it needs a different CAMERA from residue. A corner is 0.34 m on
##   an object whose fitted box is about 13 m across, so at the sweep's fit-by-
##   diagonal framing a joint is a handful of pixels and four values would be
##   indistinguishable — the line_interface fault exactly. It wants its own pass
##   with dna.framing near 0.3, and it cannot share a sheet with an axis whose
##   whole subject is the extent of the tangle.
##
##   continue_straight_chance — the file's former declared critical_parameter,
##   and a genuine one, but it is inertia: it changes how much tangle there is,
##   not what the tangle claims. Same reason rhizomatic_maze_space declined its
##   six growth floats.
##
##   turn_interval, growth_tween_time — rates, invisible to a still.
##
## A CORRECTION TO THE RECORD while here, not papered over: the old @identity
## called this "a self-avoiding 3D random walk ... never crossing itself". It is
## not, and never was. _choose_next_direction refuses only the reverse direction
## and any step that leaves bounds_extent; there is no occupancy set, nothing is
## remembered about where the pipe has been, and the run crosses itself freely.
## The essence and desire lines above are corrected to say what the code does.
## Making it genuinely self-avoiding would be a different artifact and a change
## to all 5 existing placements, so it is not done here.
##
## Usage in map_data.json:
##   "pipe_dream#residue:envelope"
## ─────────────────────────────────────────────────────────────────────────────

@export_group("DNA")
## THE AXIS — how much of the walk's own history this cube leaves standing. One
## ordered ladder, monotone: each rung shows everything the rung below shows plus
## one more kind of leaving. `path` is the legacy default, and at `path` none of
## the code added by this promotion runs.
@export_enum("head", "tail", "path", "envelope", "ensemble") var residue: String = "path"
## Pins the walk. -1 keeps rng.randomize() — a fresh unpredictable pipe every
## launch, which is the screensaver's whole point in a room and useless on a
## bench. Any value >= 0 seeds instead, so two runs of one rung are the same
## pipe. NO SEEDED WALK, NO MEASUREMENT: an evidence sweep of an unseeded walk
## renders five different pipes and reports the difference between the pipes as
## the axis.
@export var walk_seed: int = -1
## Bench-only, and a String enum rather than a bool on purpose — the sweep sets
## exports from a JSON fixture before _ready, and a typed bool silently rejects
## the string "true", which is the trap that has eaten fixture flags twice.
## `live` is the shipped behaviour: one length every turn_interval seconds, so
## 180 lengths take 14.4 s. The capture rig settles for 1.1 s, which photographs
## about thirteen lengths of pipe — and its AABB pre-pass settles for 0.35 s,
## which measures FOUR. `instant` lays the whole run inside _ready so the still
## is of the finished object. No placement sets it.
@export_enum("live", "instant") var growth: String = "live"

@export_group("Geometry")
@export var pipe_radius: float = 0.12
@export var segment_length: float = 0.95
@export var max_segments: int = 180
@export var bounds_extent: Vector3 = Vector3(6.0, 4.0, 6.0)

@export_group("Timing")
@export var turn_interval: float = 0.08
@export_range(0.0, 1.0, 0.01) var continue_straight_chance: float = 0.32
@export var growth_tween_time: float = 0.08

@export_group("Look")
@export var base_color: Color = Color(0.2, 0.8, 1.0, 1.0)
@export var accent_color: Color = Color(1.0, 0.35, 0.9, 1.0)
@export var metallic: float = 0.62
@export var roughness: float = 0.2
@export var emission_energy: float = 2.2
@export var add_head_light: bool = true
@export var head_light_energy: float = 1.8

const CARDINAL_DIRECTIONS: Array[Vector3] = [
	Vector3.FORWARD,
	Vector3.BACK,
	Vector3.LEFT,
	Vector3.RIGHT,
	Vector3.UP,
	Vector3.DOWN
]

## The allow-list, in ladder order — the same five words the @export_enum above
## declares, same spelling, same sequence.
const RESIDUES: PackedStringArray = ["head", "tail", "path", "envelope", "ensemble"]

## The ladder, as rank. ADOPTED WORD FOR WORD from random_walk_leash, which is
## the group's canonical table, and duplicated by hand for the same mechanical
## reason random_walk_128 and random_walk_collection duplicate it: that file
## preloads two godot-xr-tools scenes and a parse-time dependency from here would
## drag the whole XR addon into an artifact with no grabbable in it. All four
## copies say so; if one changes, change all four.
const RESIDUE_RUNGS := {
	"head": 0,      # the walker
	"tail": 1,      # + a window
	"path": 2,      # + the whole record   ← legacy default
	"envelope": 3,  # + the bound it obeyed
	"ensemble": 4,  # + the walks it did not take
}

## residue:tail — how many lengths the pipe remembers. A tenth of the run, so the
## worm is unmistakably a worm and still long enough to show it is turning.
const TAIL_SEGMENTS: int = 18

## residue:ensemble — how many counterfactual runs lie in the cube beside the
## real one.
const GHOST_WALKS: int = 3

var rng := RandomNumberGenerator.new()
var direction: Vector3 = Vector3.FORWARD
var current_position: Vector3 = Vector3.ZERO
var segment_timer: float = 0.0
var segment_count: int = 0

var _segment_root: Node3D
var _joint_root: Node3D
var _head_light: OmniLight3D

var _segment_mesh: CylinderMesh
var _joint_mesh: SphereMesh

## The run, as the turns were taken: _points[i] -> _points[i + 1] is length i.
## Recorded at every rung so a rung change can redraw the SAME walk rather than
## roll a new one.
var _points: PackedVector3Array = PackedVector3Array()

## Everything the non-default rungs build. Never constructed at `path`.
var _rail_root: Node3D
var _ghost_root: Node3D
var _head_mark: MeshInstance3D
var _rail_mesh: CylinderMesh
var _rail_box: AABB = AABB()
var _has_rail_box: bool = false

## Whether a new length tweens up from flat. False under growth:instant, and
## false during a redraw, where 180 simultaneous tweens would be a waste.
var _animate_growth: bool = true

## True once _ready has laid the first length. apply_grid_config must not redraw
## before it — config can arrive before _ready, because the grid stamps it on the
## node it is about to add.
var _built: bool = false


func _ready() -> void:
	if walk_seed >= 0:
		rng.seed = walk_seed
	else:
		rng.randomize()
	_animate_growth = growth_tween_time > 0.0 and not _is_instant()
	_setup_meshes()
	_setup_roots()
	if add_head_light:
		_setup_head_light()
	if _rung() >= 4:
		_build_ghosts()
	_create_next_segment()
	if _is_instant():
		while segment_count < max_segments:
			_create_next_segment()
		if _head_light:
			_head_light.position = current_position
	_built = true


func _process(delta: float) -> void:
	if segment_count >= max_segments:
		return

	segment_timer += delta
	while segment_timer >= turn_interval and segment_count < max_segments:
		segment_timer -= turn_interval
		_create_next_segment()

	if _head_light:
		_head_light.position = current_position


func _setup_meshes() -> void:
	_segment_mesh = CylinderMesh.new()
	_segment_mesh.top_radius = pipe_radius
	_segment_mesh.bottom_radius = pipe_radius
	_segment_mesh.height = segment_length
	_segment_mesh.radial_segments = 18

	_joint_mesh = SphereMesh.new()
	_joint_mesh.radius = pipe_radius * 1.42
	_joint_mesh.height = pipe_radius * 2.84
	_joint_mesh.radial_segments = 18
	_joint_mesh.rings = 10


func _setup_roots() -> void:
	_segment_root = Node3D.new()
	_segment_root.name = "Segments"
	add_child(_segment_root)

	_joint_root = Node3D.new()
	_joint_root.name = "Joints"
	add_child(_joint_root)


func _setup_head_light() -> void:
	_head_light = OmniLight3D.new()
	_head_light.name = "HeadLight"
	_head_light.light_color = base_color
	_head_light.light_energy = head_light_energy
	_head_light.omni_range = 2.8
	_head_light.omni_attenuation = 0.9
	add_child(_head_light)


func _create_next_segment() -> void:
	var start_pos: Vector3 = current_position
	var tentative_end: Vector3 = start_pos + direction * segment_length

	# If we are about to leave bounds, force a turn toward valid space.
	if _is_outside_bounds(tentative_end):
		direction = _choose_next_direction(rng, start_pos, direction, true)
		tentative_end = start_pos + direction * segment_length

	if _points.is_empty():
		_points.append(start_pos)
	_points.append(tentative_end)

	var segment_color := _segment_color(segment_count)
	var rung: int = _rung()

	# At every rung except `head` the pipe is drawn exactly as it always was.
	if rung >= 1:
		_add_segment(start_pos, tentative_end, segment_color)
		if segment_count > 0:
			_add_joint(start_pos, segment_color)

	current_position = tentative_end
	direction = _choose_next_direction(rng, current_position, direction, false)
	segment_count += 1

	# Everything below is off the legacy path: at `path` the rung is 2 and none
	# of these three run.
	if rung == 0:
		_mark_head(segment_color)
	elif rung == 1:
		_trim_tail()
	if rung >= 3:
		_refresh_rails(false)


func _add_segment(start_pos: Vector3, end_pos: Vector3, segment_color: Color) -> void:
	var segment := MeshInstance3D.new()
	segment.mesh = _segment_mesh
	segment.material_override = _build_pipe_material(segment_color)

	# The basis comes from the SPAN rather than from the `direction` member, so a
	# redraw can replay a recorded run without restoring walker state. During
	# growth the two are identical by construction: end_pos is start_pos plus
	# direction * segment_length and `direction` has not moved yet.
	var span: Vector3 = end_pos - start_pos
	var midpoint := (start_pos + end_pos) * 0.5
	segment.transform = Transform3D(_basis_from_direction(span), midpoint)
	segment.scale = Vector3(1.0, 0.06, 1.0)
	_segment_root.add_child(segment)

	if _animate_growth:
		var tw := create_tween()
		tw.tween_property(segment, "scale:y", 1.0, growth_tween_time)
	else:
		segment.scale.y = 1.0


func _add_joint(joint_pos: Vector3, segment_color: Color) -> void:
	var joint := MeshInstance3D.new()
	joint.mesh = _joint_mesh
	joint.position = joint_pos

	var mat := StandardMaterial3D.new()
	mat.albedo_color = segment_color.darkened(0.12)
	mat.metallic = min(1.0, metallic + 0.15)
	mat.roughness = roughness * 0.8
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.35
	mat.clearcoat_roughness = 0.05  # Godot 4: low roughness = high gloss
	mat.emission_enabled = true
	mat.emission = segment_color
	mat.emission_energy_multiplier = emission_energy * 0.75
	joint.material_override = mat

	_joint_root.add_child(joint)


func _build_pipe_material(segment_color: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = segment_color
	mat.metallic = metallic
	mat.roughness = roughness
	mat.rim_enabled = true
	mat.rim = 0.55
	mat.rim_tint = 0.35
	mat.clearcoat_enabled = true
	mat.clearcoat = 0.25
	mat.clearcoat_roughness = 0.1  # Godot 4: low roughness = high gloss
	mat.emission_enabled = true
	mat.emission = segment_color
	mat.emission_energy_multiplier = emission_energy
	return mat


func _segment_color(index: int) -> Color:
	var denom: float = maxf(1.0, float(max_segments - 1))
	var t: float = float(index) / denom
	var blend := 0.5 + 0.5 * sin(t * TAU * 2.0)
	var color := base_color.lerp(accent_color, blend)
	color.s = clampf(color.s * 1.05, 0.0, 1.0)
	color.v = clampf(color.v * 1.1, 0.0, 1.0)
	return color


## The turn rule. Takes its generator and its position as arguments so the same
## implementation serves the live walk and the ensemble's counterfactuals — one
## rule, not two that can drift. The draw order is unchanged: at most one randf()
## for the straight-ahead check, then one randi_range per shuffle swap.
func _choose_next_direction(r: RandomNumberGenerator, pos: Vector3, current_dir: Vector3, force_turn: bool) -> Vector3:
	if not force_turn and r.randf() < continue_straight_chance:
		var straight_target := pos + current_dir * segment_length
		if not _is_outside_bounds(straight_target):
			return current_dir

	var candidates: Array[Vector3] = []
	for d in CARDINAL_DIRECTIONS:
		if d == -current_dir:
			continue
		if d == current_dir and force_turn:
			continue
		candidates.append(d)

	candidates = _shuffled_directions(candidates, r)
	for candidate in candidates:
		var next_pos := pos + candidate * segment_length
		if not _is_outside_bounds(next_pos):
			return candidate

	# Fallback if boxed in: keep current direction.
	return current_dir


func _is_outside_bounds(pos: Vector3) -> bool:
	return (
		abs(pos.x) > bounds_extent.x
		or abs(pos.y) > bounds_extent.y
		or abs(pos.z) > bounds_extent.z
	)


func _basis_from_direction(dir: Vector3) -> Basis:
	# Cylinder mesh uses +Y as its long axis; align Y to direction.
	var y_axis := dir.normalized()
	var reference := Vector3.FORWARD
	if abs(y_axis.dot(reference)) > 0.99:
		reference = Vector3.RIGHT
	var x_axis := reference.cross(y_axis).normalized()
	var z_axis := x_axis.cross(y_axis).normalized()
	return Basis(x_axis, y_axis, z_axis)


func _shuffled_directions(source: Array[Vector3], r: RandomNumberGenerator) -> Array[Vector3]:
	var out: Array[Vector3] = source.duplicate()
	for i in range(out.size() - 1, 0, -1):
		var j := r.randi_range(0, i)
		var temp: Vector3 = out[i]
		out[i] = out[j]
		out[j] = temp
	return out


# ── residue: the four rungs that are not `path` ───────────────────────────────

func _is_instant() -> bool:
	return growth.strip_edges().to_lower() == "instant"


func _residue_name() -> String:
	var v: String = residue.strip_edges().to_lower()
	if RESIDUES.has(v):
		return v
	return "path"


func _rung() -> int:
	return int(RESIDUE_RUNGS.get(_residue_name(), 2))


## residue:head — one joint at the walker and nothing else. The mark is bigger
## than a corner joint because at this rung it is the whole object: a corner in
## a tangle of 180 reads at a different scale from a lone dot in an empty cube.
func _mark_head(segment_color: Color) -> void:
	if _head_mark == null:
		var mesh := SphereMesh.new()
		mesh.radius = pipe_radius * 2.2
		mesh.height = pipe_radius * 4.4
		mesh.radial_segments = 20
		mesh.rings = 12
		_head_mark = MeshInstance3D.new()
		_head_mark.name = "Head"
		_head_mark.mesh = mesh
		add_child(_head_mark)
	_head_mark.position = current_position
	var mat := StandardMaterial3D.new()
	mat.albedo_color = segment_color
	mat.metallic = metallic
	mat.roughness = roughness
	mat.emission_enabled = true
	mat.emission = segment_color
	mat.emission_energy_multiplier = emission_energy
	_head_mark.material_override = mat


## residue:tail — drop the oldest lengths so only a window survives.
func _trim_tail() -> void:
	while _segment_root.get_child_count() > TAIL_SEGMENTS:
		var seg: Node = _segment_root.get_child(0)
		_segment_root.remove_child(seg)
		seg.queue_free()
	while _joint_root.get_child_count() > TAIL_SEGMENTS:
		var jt: Node = _joint_root.get_child(0)
		_joint_root.remove_child(jt)
		jt.queue_free()


## residue:envelope — twelve rails around the smallest box the run stayed inside.
## Rebuilt only when that box actually grows, which for a 180-length walk happens
## a few dozen times and not 180.
func _refresh_rails(force: bool) -> void:
	if _points.size() < 2:
		return
	var box: AABB = AABB(_points[0], Vector3.ZERO)
	for i in range(1, _points.size()):
		box = box.expand(_points[i])
	if not force and _has_rail_box:
		var same_lo: bool = box.position.is_equal_approx(_rail_box.position)
		var same_size: bool = box.size.is_equal_approx(_rail_box.size)
		if same_lo and same_size:
			return
	_rail_box = box
	_has_rail_box = true

	if _rail_mesh == null:
		_rail_mesh = CylinderMesh.new()
		_rail_mesh.top_radius = pipe_radius * 0.28
		_rail_mesh.bottom_radius = pipe_radius * 0.28
		_rail_mesh.height = 1.0
		_rail_mesh.radial_segments = 8
	if _rail_root == null:
		_rail_root = Node3D.new()
		_rail_root.name = "Envelope"
		add_child(_rail_root)
	for c in _rail_root.get_children():
		_rail_root.remove_child(c)
		c.queue_free()

	var lo: Vector3 = box.position
	var hi: Vector3 = box.position + box.size
	var corners: Array[Vector3] = [
		Vector3(lo.x, lo.y, lo.z), Vector3(hi.x, lo.y, lo.z),
		Vector3(hi.x, lo.y, hi.z), Vector3(lo.x, lo.y, hi.z),
		Vector3(lo.x, hi.y, lo.z), Vector3(hi.x, hi.y, lo.z),
		Vector3(hi.x, hi.y, hi.z), Vector3(lo.x, hi.y, hi.z),
	]
	var edges: Array[Vector2i] = [
		Vector2i(0, 1), Vector2i(1, 2), Vector2i(2, 3), Vector2i(3, 0),
		Vector2i(4, 5), Vector2i(5, 6), Vector2i(6, 7), Vector2i(7, 4),
		Vector2i(0, 4), Vector2i(1, 5), Vector2i(2, 6), Vector2i(3, 7),
	]
	for e in edges:
		_add_rail(corners[e.x], corners[e.y])


func _add_rail(a: Vector3, b: Vector3) -> void:
	var span: Vector3 = b - a
	var span_length: float = span.length()
	if span_length < 0.001:
		return
	var rail := MeshInstance3D.new()
	rail.mesh = _rail_mesh
	var mat := StandardMaterial3D.new()
	mat.albedo_color = accent_color
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = accent_color
	mat.emission_energy_multiplier = emission_energy * 0.5
	rail.material_override = mat
	rail.transform = Transform3D(_basis_from_direction(span), (a + b) * 0.5)
	rail.scale = Vector3(1.0, span_length, 1.0)
	_rail_root.add_child(rail)


## residue:ensemble — three more runs under the same rule, in the same cube, in
## pale thin ink. Drawn as a MultiMeshInstance3D each rather than 180 nodes each:
## the capture rig's AABB counts MultiMeshInstance3D, so the ghosts are measured
## as well as seen, and three nodes replace 540.
func _build_ghosts() -> void:
	if _ghost_root != null:
		return
	_ghost_root = Node3D.new()
	_ghost_root.name = "Ensemble"
	add_child(_ghost_root)

	var ghost_mesh := CylinderMesh.new()
	ghost_mesh.top_radius = pipe_radius * 0.42
	ghost_mesh.bottom_radius = pipe_radius * 0.42
	ghost_mesh.height = 1.0
	ghost_mesh.radial_segments = 8
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(base_color.r, base_color.g, base_color.b, 0.5)
	mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.shading_mode = BaseMaterial3D.SHADING_MODE_UNSHADED
	mat.emission_enabled = true
	mat.emission = base_color
	mat.emission_energy_multiplier = emission_energy * 0.2
	ghost_mesh.material = mat

	for g in range(GHOST_WALKS):
		var g_rng := RandomNumberGenerator.new()
		if walk_seed >= 0:
			g_rng.seed = walk_seed + 977 * (g + 1)
		else:
			g_rng.randomize()
		var pts: PackedVector3Array = _ghost_walk(g_rng)
		if pts.size() < 2:
			continue
		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.mesh = ghost_mesh
		mm.instance_count = pts.size() - 1
		for i in range(pts.size() - 1):
			var a: Vector3 = pts[i]
			var b: Vector3 = pts[i + 1]
			var span: Vector3 = b - a
			var span_length: float = maxf(span.length(), 0.001)
			var bas: Basis = _basis_from_direction(span).scaled(Vector3(1.0, span_length, 1.0))
			mm.set_instance_transform(i, Transform3D(bas, (a + b) * 0.5))
		var mmi := MultiMeshInstance3D.new()
		mmi.name = "Ghost%d" % g
		mmi.multimesh = mm
		_ghost_root.add_child(mmi)


## A counterfactual run: the SAME rule as the live walk, from the same start, on
## a generator of its own. Calls _choose_next_direction, so there is exactly one
## turn rule in this file and a change to it cannot leave the ghosts behind.
func _ghost_walk(g_rng: RandomNumberGenerator) -> PackedVector3Array:
	var pts := PackedVector3Array()
	var pos: Vector3 = Vector3.ZERO
	var dir: Vector3 = Vector3.FORWARD
	pts.append(pos)
	for i in range(max_segments):
		var nxt: Vector3 = pos + dir * segment_length
		if _is_outside_bounds(nxt):
			dir = _choose_next_direction(g_rng, pos, dir, true)
			nxt = pos + dir * segment_length
		pts.append(nxt)
		pos = nxt
		dir = _choose_next_direction(g_rng, pos, dir, false)
	return pts


## Redraw the RECORDED run at a new rung. The walk is not re-rolled: _points is
## replayed, so a map that changes residue after the fact gets the same pipe
## drawn differently rather than a different pipe.
func _redraw() -> void:
	var was_animating: bool = _animate_growth
	_animate_growth = false

	for c in _segment_root.get_children():
		_segment_root.remove_child(c)
		c.queue_free()
	for c in _joint_root.get_children():
		_joint_root.remove_child(c)
		c.queue_free()
	if _rail_root != null:
		_rail_root.queue_free()
		_rail_root = null
		_has_rail_box = false
	if _ghost_root != null:
		_ghost_root.queue_free()
		_ghost_root = null
	if _head_mark != null:
		_head_mark.queue_free()
		_head_mark = null

	var rung: int = _rung()
	if rung >= 1:
		for i in range(_points.size() - 1):
			var col: Color = _segment_color(i)
			_add_segment(_points[i], _points[i + 1], col)
			if i > 0:
				_add_joint(_points[i], col)
		if rung == 1:
			_trim_tail()
	else:
		_mark_head(_segment_color(maxi(0, segment_count - 1)))
	if rung >= 3:
		_refresh_rails(true)
	if rung >= 4:
		_build_ghosts()

	_animate_growth = was_animating


func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


## GUARDED, twice over. Config can arrive before _ready (the grid stamps it on
## the node it is about to add) or after: before the first length is laid,
## assignment is enough, because _ready reads the new value on its way through.
## After it, only a word this file knows and that DIFFERS from the one it holds
## may pay for a redraw — the force_pad fault was tearing down every child on any
## call at all, including calls naming nothing it owns. None of the 5 mentions of
## this token in map_data passes a residue key, so none of them redraws anything.
##
## walk_seed and growth are deliberately NOT accepted here. Both are consumed in
## _ready and honouring them afterwards would mean re-rolling the walk, which is
## the one thing a redraw must not do.
func apply_grid_config(config: Dictionary) -> void:
	if config.is_empty():
		return
	if not config.has("residue"):
		return
	var want: String = str(config["residue"]).strip_edges().to_lower()
	if not RESIDUES.has(want):
		push_warning("pipe_dream: unknown residue '%s' — keeping '%s'" % [want, residue])
		return
	if want == _residue_name():
		return
	residue = want
	if _built:
		_redraw()
