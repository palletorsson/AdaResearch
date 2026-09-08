extends Node3D
class_name CarveGrid

# @identity
# essence: a solid block of small cubes standing in the way, which loses every cube your body touches, so walking through it cuts a tunnel that stays cut
# desire: the visitor stops seeing translation as something a cube does on a plinth and feels it as something their own body does to a room
# critical_parameter: bite_m — the margin by which a solid body is allowed to reach past the surface physics stops it at, and therefore whether the artifact moves at all
# triggers: any player body or museum walker inside the lattice's Area3D; continuous, by overlap, not by a switch
# emerges: a wall becomes a corridor with your own shape in it, and the corridor is the only record of where you went
# needs: nothing outside itself — no manager, no map data, no provider
# relationships: the first of three body-operated transformations in this chapter — this one removes what you touch, the wall opens what you face, the field shrinks what you stand among
# truth: the shape of a path is the shape of the body that took it
#
## 2026-09-08, Palle: "Collider movement space. A cube grid and when we walk it
## space is created by removing what our collider touches."
##
## THE VISITOR'S BODY IS THE TRANSFORMATION. Everywhere else in this chapter a
## cube is translated while you watch: the artifact is the operator and you are
## the audience. Here you are the operator and the room is the operand. Nothing in
## this lattice moves on its own — it has no animation, no timer and no randomness
## — and yet after a minute it is a different object, because translation is the
## one transformation you can perform with your legs.
##
## It is also the chapter's standing ruling, "transformation creates empty space,
## the holes are the pathway", taken one step past where a map can follow. The hole
## is not authored into the structure layer. You make it by arriving, and it stays
## made: regrow_s is 0 by default because the corridor is the record.
##
## THE BITE IS THE WHOLE ARTIFACT, and it is the fact that cost the most to get
## right. The visitor is a solid body and the cubes are solid, so physics stops the
## visitor AT the surface and their collider never overlaps a cube's centre — a
## naive "delete what I intersect" test deletes nothing, forever, and the artifact
## photographs as a handsome inert block. So the test is not against the visitor's
## capsule but against the capsule INFLATED by bite_m: any live cube whose box is
## within bite_m of the real body dies. That margin is what lets you press into the
## face of the lattice and advance one shell at a time. Below about half a cell it
## stalls; the default 0.16 against a 0.34 cell clears roughly one shell per press.
##
## IT MASKS LAYER 1 AS WELL AS LAYER 20, AND THAT IS WHAT MAKES IT WORK IN THE
## MUSEUM. The endless museum's walker is a bare CharacterBody3D named "Walker" on
## collision layer 1, in group `em_walker` and nothing else: not in any grid player
## group, no XROrigin3D above it, not on layer 20. An Area3D masking the player
## layer alone never overlaps it — no error, no refusal, no log line — and the
## artifact is simply furniture. This masks 1 | 524288, so the VR player, the
## desktop player and the walker all cut the same tunnel.
##
## THE COST OF THAT, which will bite anyone who copies the mask: our own lattice is
## a StaticBody3D, and StaticBody3D defaults to collision_layer 1 — the walker's
## layer. The area therefore reports OUR OWN BODY as a visitor, standing exactly at
## the lattice centre, and the first physics frame would eat a visitor-sized hole
## out of the middle of an empty room. It cannot move off layer 1 without ceasing
## to be solid world geometry, so it stays, and `_accepts` refuses it by ANCESTRY —
## it is our own descendant and nothing else in the hall is. approach_wall and
## approach_scale each met this independently and refuse the same way.
##
## The museum's walker does hand us a capsule (radius 0.32, height 1.5, seated so
## the feet are the body origin — endless_museum.gd:3405), so the exported
## visitor_radius_m / visitor_height_m are a fallback for a rig that hides its
## shape, not the normal path. The capsule is read once per body and cached; the
## per-frame work is a distance test over the handful of cells the body can
## actually reach, never over the lattice.

const PLAYER_LAYER := 524288          # physics layer 20 — the grid's player body
const WALKER_LAYER := 1               # physics layer 1  — the museum's Walker
## Overlap is tracked by signal, not by polling, so nothing is allocated per
## frame. This is how often we ask the area for the truth anyway, to heal an
## exit that never fired because a body was freed or teleported.
const RESYNC_S := 0.75
## How long a visitor stands inside the lattice before a lattice that has cut
## nothing is a complaint rather than a coincidence.
const INERT_AFTER_S := 3.5
## More cubes than this and a Quest spends the frame in the physics server at
## build time. The lattice is clamped down to fit and says so.
const MAX_CELLS := 4096

## How many cubes across, up and deep. The block is centred on the artifact in x
## and z and stands ON the floor in y, because it is a thing you walk into rather
## than a thing that floats.
@export var cells_x: int = 11
@export var cells_y: int = 4
@export var cells_z: int = 11
## Centre-to-centre spacing of the cubes, metres. Also the size of the smallest
## hole you can leave behind, so it is the resolution of your own silhouette.
@export var cell_m: float = 0.34
## How much of that spacing is left as air, metres. Without it the cubes fuse into
## one grey mass and the removal cannot be read as removal.
@export var gap_m: float = 0.05
## How far past your own skin the lattice counts as touched, metres. See the
## header — at 0 the artifact can never cut anything, because physics stops you
## before you reach.
@export var bite_m: float = 0.16
## Seconds until a cut cube returns. 0 leaves the tunnel open for good, which is
## the point; above 0 the room heals behind you and the walk becomes a race.
@export var regrow_s: float = 0.0
## The body we assume when a visitor will not show us its collision shape.
@export var visitor_radius_m: float = 0.30
@export var visitor_height_m: float = 1.7
@export var lattice_color: Color = Color(0.46, 0.50, 0.58)
## How much darker the bottom of the block is than the top, 0-1. Depth is the only
## cue that this is a solid volume and not a wall, until you cut into it.
@export var depth_shade: float = 0.45

## Cubes removed this frame. Fires only on frames that actually cut.
signal carved(count: int)
## A visitor has been inside the lattice for INERT_AFTER_S and nothing has been
## cut. Said out loud because a lattice that stands there looking correct while
## refusing to open is this artifact's one failure mode, and its four causes —
## bite_m too small, the mask missing the visitor's layer, the visitor's capsule
## mis-measured, the lattice built somewhere the visitor is not — are identical
## from a screenshot.
signal inert(why: String)

var _mmi: MultiMeshInstance3D
var _mm: MultiMesh
var _solid: StaticBody3D
var _area: Area3D

# Lattice state. Built once, written in place, never reallocated.
var _count := 0
var _alive := PackedByteArray()
var _owner := PackedInt32Array()       # shape-owner id per cube
var _centre := PackedVector3Array()    # local centre per cube
var _carved := 0
var _ox := 0.0                         # local x of column 0
var _oz := 0.0
var _edge := 0.34                      # the side of one drawn cube
var _half := 0.17

# Removal is a zero-scale basis rather than compaction of visible_instance_count.
# Compaction would renumber every instance above the one removed, and regrow_s
# needs index -> instance to hold still for as long as the artifact is alive.
# The cost is one degenerate instance per cut, which draws nothing.
var _gone := Basis(Vector3.ZERO, Vector3.ZERO, Vector3.ZERO)

# Regrow queue. regrow_s is constant, so cut order IS return order and the queue
# is sorted by construction — a head cursor, no sorting, no per-frame sweep of
# the lattice.
var _rg_idx := PackedInt32Array()
var _rg_due := PackedFloat32Array()
var _rg_head := 0

# Visitors, kept by enter/exit signal. Parallel arrays rather than a dictionary:
# there are one or two of these and they are read every physics frame.
var _visitors: Array[Node3D] = []
var _v_shape: Array[Node3D] = []       # the CollisionShape3D we measured, if any
var _v_r := PackedFloat32Array()
var _v_hs := PackedFloat32Array()      # half the capsule's straight section

var _clock := 0.0
var _resync := 0.0
var _visit_s := 0.0
var _said_inert := false


func _ready() -> void:
	_build()


func apply_grid_config(config_data: Dictionary) -> void:
	# `cells` sets the footprint only. Height is deliberately not swept with it:
	# a lattice as tall as it is wide is a cube of fog you cannot see over.
	if config_data.has("cells"):
		cells_x = int(config_data["cells"])
		cells_z = cells_x
	if config_data.has("cells_x"):
		cells_x = int(config_data["cells_x"])
	if config_data.has("cells_y"):
		cells_y = int(config_data["cells_y"])
	if config_data.has("cells_z"):
		cells_z = int(config_data["cells_z"])
	if config_data.has("cell_m"):
		cell_m = float(config_data["cell_m"])
	if config_data.has("gap_m"):
		gap_m = float(config_data["gap_m"])
	if config_data.has("bite_m"):
		bite_m = float(config_data["bite_m"])
	if config_data.has("regrow"):
		regrow_s = float(config_data["regrow"])
	if config_data.has("depth_shade"):
		depth_shade = float(config_data["depth_shade"])
	if config_data.has("visitor_radius"):
		visitor_radius_m = float(config_data["visitor_radius"])
	if config_data.has("visitor_height"):
		visitor_height_m = float(config_data["visitor_height"])
	if config_data.has("color"):
		var c: Variant = config_data["color"]
		if c is Color:
			lattice_color = c
		elif typeof(c) == TYPE_STRING and Color.html_is_valid(str(c)):
			lattice_color = Color.html(str(c))
	if is_inside_tree():
		_build()


# ── building ─────────────────────────────────────────────────────────────────

func _build() -> void:
	# queue_free is deferred, so the old area survives this frame and would fire
	# body_exited into the new visitor list as it leaves the tree — dropping a
	# visitor who never left. Cut the wires before the rebuild.
	if _area != null and is_instance_valid(_area):
		if _area.body_entered.is_connected(_on_entered):
			_area.body_entered.disconnect(_on_entered)
		if _area.body_exited.is_connected(_on_exited):
			_area.body_exited.disconnect(_on_exited)
	_area = null
	_solid = null
	_mm = null
	_mmi = null
	for c in get_children():
		c.queue_free()
	_visitors.clear()
	_v_shape.clear()
	_v_r.clear()
	_v_hs.clear()
	_carved = 0
	_visit_s = 0.0
	_said_inert = false
	_rg_head = 0

	cells_x = clampi(cells_x, 1, 64)
	cells_y = clampi(cells_y, 1, 64)
	cells_z = clampi(cells_z, 1, 64)
	cell_m = maxf(cell_m, 0.04)
	depth_shade = clampf(depth_shade, 0.0, 1.0)
	# Every cube is a shape owner in the physics server, so the ceiling is a real
	# budget and not a tidiness rule. Losing height first keeps the footprint,
	# which is what the visitor walks into.
	var want := Vector3i(cells_x, cells_y, cells_z)
	while cells_x * cells_y * cells_z > MAX_CELLS and cells_y > 1:
		cells_y -= 1
	while cells_x * cells_y * cells_z > MAX_CELLS and cells_x > 1:
		cells_x -= 1
		cells_z = mini(cells_z, cells_x)
	# Out loud, because a map that asked for a 21-deep block and silently got an
	# 11-deep one is the same quiet substitution this whole artifact is built to
	# argue against.
	if want != Vector3i(cells_x, cells_y, cells_z):
		push_warning("carve_grid: %dx%dx%d is over the %d-cube ceiling; built %dx%dx%d"
			% [want.x, want.y, want.z, MAX_CELLS, cells_x, cells_y, cells_z])

	_edge = maxf(cell_m - maxf(gap_m, 0.0), cell_m * 0.2)
	_half = _edge * 0.5
	_ox = -float(cells_x - 1) * 0.5 * cell_m
	_oz = -float(cells_z - 1) * 0.5 * cell_m
	_count = cells_x * cells_y * cells_z

	_alive.resize(_count)
	_owner.resize(_count)
	_centre.resize(_count)
	_rg_idx.resize(0)
	_rg_due.resize(0)

	_build_draw()
	_build_solid()
	_build_area()


func _build_draw() -> void:
	_mm = MultiMesh.new()
	# transform_format, use_colors and the mesh must all be set before
	# instance_count: the buffer is sized from them and resizing later drops data.
	_mm.transform_format = MultiMesh.TRANSFORM_3D
	_mm.use_colors = true
	var box := BoxMesh.new()
	box.size = Vector3(_edge, _edge, _edge)
	_mm.mesh = box
	_mm.instance_count = _count

	var span_y: float = float(cells_y) * cell_m
	var deep: float = maxf(float(cells_y - 1), 1.0)
	for ix in cells_x:
		for iy in cells_y:
			for iz in cells_z:
				var idx: int = (ix * cells_y + iy) * cells_z + iz
				var c := Vector3(_ox + float(ix) * cell_m,
					(float(iy) + 0.5) * cell_m,
					_oz + float(iz) * cell_m)
				_centre[idx] = c
				_alive[idx] = 1
				_mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, c))
				# Darker with depth. Deterministic, never randf: five captures of
				# this artifact have to be five pictures of one object.
				var f: float = 0.0 if cells_y <= 1 else 1.0 - float(iy) / deep
				_mm.set_instance_color(idx, lattice_color.lerp(Color(0, 0, 0), f * depth_shade))

	_mmi = MultiMeshInstance3D.new()
	_mmi.name = "Lattice"
	_mmi.multimesh = _mm
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.62
	mat.emission_enabled = true
	mat.emission = lattice_color
	mat.emission_energy_multiplier = 0.22
	_mmi.material_override = mat
	# The MultiMesh recomputes its own bounds from live instances, so a lattice
	# carved down to a corridor would start culling itself at the wrong moment.
	# Pin the box to the built extent.
	_mmi.custom_aabb = AABB(
		Vector3(_ox - _half, 0.0, _oz - _half),
		Vector3(float(cells_x - 1) * cell_m + _edge, span_y, float(cells_z - 1) * cell_m + _edge))
	add_child(_mmi)

	# THE CAPTURE AABB COUNTS MeshInstance3D ONLY, so an artifact drawn with a
	# MultiMesh measures as a 1 m box and every screenshot of it is framed on a
	# corner. This anchor is the real extent. `layers = 0` and not visible=false,
	# because visibility is hierarchical and would hide anything parented here
	# later, and not material_override, which a pickup highlight swap would fight.
	var anchor := MeshInstance3D.new()
	anchor.name = "ExtentAnchor"
	var am := BoxMesh.new()
	am.size = Vector3(float(cells_x - 1) * cell_m + _edge, span_y, float(cells_z - 1) * cell_m + _edge)
	anchor.mesh = am
	anchor.position = Vector3(0, span_y * 0.5, 0)
	anchor.layers = 0
	add_child(anchor)


func _build_solid() -> void:
	_solid = StaticBody3D.new()
	_solid.name = "Solid"
	add_child(_solid)
	# ONE BoxShape3D for every owner. A Shape3D is a Resource and nothing here
	# ever resizes a single cube, so sharing it costs one allocation instead of
	# several hundred.
	var shape := BoxShape3D.new()
	shape.size = Vector3(_edge, _edge, _edge)
	# Shape owners rather than a CollisionShape3D per cube: hundreds of nodes with
	# transforms, names and notifications is what makes this artifact unshippable
	# on a Quest. The owner api puts the boxes straight in the physics server.
	for i in _count:
		var oid: int = _solid.create_shape_owner(_solid)
		_solid.shape_owner_add_shape(oid, shape)
		_solid.shape_owner_set_transform(oid, Transform3D(Basis.IDENTITY, _centre[i]))
		_owner[i] = oid


func _build_area() -> void:
	_area = Area3D.new()
	_area.name = "Reach"
	_area.collision_layer = 0
	_area.monitorable = false
	_area.collision_mask = PLAYER_LAYER | WALKER_LAYER
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	var span_y: float = float(cells_y) * cell_m
	# Wide enough that a body is already tracked before it can touch anything, so
	# the first cut never waits on a signal that arrives a frame late.
	var pad: float = visitor_radius_m + bite_m + cell_m
	box.size = Vector3(
		float(cells_x - 1) * cell_m + _edge + pad * 2.0,
		span_y + pad * 2.0,
		float(cells_z - 1) * cell_m + _edge + pad * 2.0)
	col.shape = box
	col.position.y = span_y * 0.5
	_area.add_child(col)
	add_child(_area)
	_area.body_entered.connect(_on_entered)
	_area.body_exited.connect(_on_exited)


# ── the visitor ──────────────────────────────────────────────────────────────

## WHO COUNTS AS A VISITOR, and why it is not "any CharacterBody3D".
##
## The three visitors agree on nothing a single test could use. The desktop player
## is a CharacterBody3D in group `player_body` (desktop_player.tscn:11); the
## museum's Walker is a CharacterBody3D in `em_walker` and nothing else; the VR
## body is an XRToolsPlayerBody in NO group at all — the addon never calls
## add_to_group — which is why the group test cannot see it and why the obvious
## fallback is to take any CharacterBody3D.
##
## THAT FALLBACK IS WRONG, and it is wrong quietly. `hazard_creature_base` extends
## CharacterBody3D, so every silhouette, head crab and stalker in the museum would
## have counted: they would cut the tunnel, and a visitor arriving after them would
## find the corridor already dug and no way to tell it had not always been there.
## An artifact about the trace of YOUR body cannot be carved by the traffic.
##
## So the VR body is recognised by the one thing only it has: an XROrigin3D over
## it. Shared verbatim with approach_wall and approach_scale.
## Our own lattice is solid on layer 1 with the museum's walker — see the header —
## so it arrives here as a candidate and is refused by ancestry, which is also what
## approach_wall and approach_scale do with their own bodies.
func _accepts(body: Node3D) -> bool:
	if body == null or is_ancestor_of(body):
		return false
	if body.is_in_group("em_walker") or body.is_in_group("player_body") \
		or body.is_in_group("player") or body.is_in_group("vr_player"):
		return true
	var n: Node = body.get_parent()
	while n != null:
		if n is XROrigin3D:
			return true
		n = n.get_parent()
	return false


func _on_entered(body: Node3D) -> void:
	if not _accepts(body) or _index_of(body) >= 0:
		return
	_add_visitor(body)


func _on_exited(body: Node3D) -> void:
	var i: int = _index_of(body)
	if i >= 0:
		_drop_at(i)


func _add_visitor(body: Node3D) -> void:
	var shp: CollisionShape3D = _find_capsule(body, 0)
	var r: float = visitor_radius_m
	var hs: float = maxf(visitor_height_m * 0.5 - r, 0.0)
	if shp != null:
		var s: Shape3D = shp.shape
		if s is CapsuleShape3D:
			r = (s as CapsuleShape3D).radius
			hs = maxf((s as CapsuleShape3D).height * 0.5 - r, 0.0)
		elif s is CylinderShape3D:
			r = (s as CylinderShape3D).radius
			hs = maxf((s as CylinderShape3D).height * 0.5, 0.0)
	_visitors.append(body)
	_v_shape.append(shp)
	_v_r.append(r)
	_v_hs.append(hs)


func _drop_at(i: int) -> void:
	_visitors.remove_at(i)
	_v_shape.remove_at(i)
	# PackedFloat32Array has no remove_at that keeps order cheaply enough to care
	# about at this size; there are never more than a few visitors.
	var r := PackedFloat32Array()
	var h := PackedFloat32Array()
	for j in _v_r.size():
		if j == i:
			continue
		r.append(_v_r[j])
		h.append(_v_hs[j])
	_v_r = r
	_v_hs = h


func _index_of(body: Node) -> int:
	for i in _visitors.size():
		if _visitors[i] == body:
			return i
	return -1


## The rig that owns the capsule is not always the body: the desktop player nests
## its shape, the walker keeps it as a direct child. Two levels is enough for both
## and stops this from being a tree walk.
func _find_capsule(n: Node, depth: int) -> CollisionShape3D:
	for c in n.get_children():
		if c is CollisionShape3D:
			var s: Shape3D = (c as CollisionShape3D).shape
			if s is CapsuleShape3D or s is CylinderShape3D:
				return c as CollisionShape3D
	if depth >= 2:
		return null
	for c in n.get_children():
		if c is Node3D:
			var found: CollisionShape3D = _find_capsule(c, depth + 1)
			if found != null:
				return found
	return null


# ── the cut ──────────────────────────────────────────────────────────────────

func _physics_process(delta: float) -> void:
	# A headless probe instances this, ticks it and expects nothing: with the
	# lattice half-built or the area empty there is no visitor, no cut and no null.
	if _mm == null or _solid == null:
		return
	_clock += delta
	_regrow()

	_resync -= delta
	if _resync <= 0.0:
		_resync = RESYNC_S
		_heal_visitors()

	if _visitors.is_empty():
		return
	_visit_s += delta

	# One inverse for the whole frame. The grid only ever yaws an artifact, so
	# local +y is still world up and the capsule stays vertical in lattice space —
	# which is what makes the distance test below exact instead of approximate.
	var inv := global_transform.affine_inverse()
	var cut := 0
	for i in _visitors.size():
		var body: Node3D = _visitors[i]
		if not is_instance_valid(body):
			continue
		var c: Vector3
		var shp: Node3D = _v_shape[i]
		if shp != null and is_instance_valid(shp):
			c = inv * shp.global_position
		else:
			# No shape to read: the body origin is the feet on every rig in this
			# project, so lift by half the assumed height to find the centre.
			c = inv * (body.global_position + Vector3(0.0, visitor_height_m * 0.5, 0.0))
		cut += _bite_at(c, _v_r[i] + bite_m, _v_hs[i])

	if cut > 0:
		carved.emit(cut)
	elif _carved == 0 and not _said_inert and _visit_s > INERT_AFTER_S:
		_said_inert = true
		var why: String = "stood in the lattice %.1fs, cut nothing — bite_m %.2f, cell_m %.2f, %d cubes, %d visitor(s)" % [_visit_s, bite_m, cell_m, _count, _visitors.size()]
		push_warning("carve_grid: " + why)
		inert.emit(why)


## Cubes within reach of one vertical capsule, and only those. The capsule's axis
## is parallel to the lattice's y, so the distance from the axis SEGMENT to a
## cube's axis-aligned box separates into three independent terms and the test is
## exact rather than a bounding-sphere guess — an approximation here would carve
## cubes over your head and under your feet, which reads as the artifact being
## broken rather than generous.
func _bite_at(c: Vector3, r: float, hs: float) -> int:
	var reach: float = r + _half
	var r2: float = r * r
	var y0: float = c.y - hs
	var y1: float = c.y + hs

	var ix0: int = maxi(int(floor((c.x - reach - _ox) / cell_m)), 0)
	var ix1: int = mini(int(ceil((c.x + reach - _ox) / cell_m)), cells_x - 1)
	var iz0: int = maxi(int(floor((c.z - reach - _oz) / cell_m)), 0)
	var iz1: int = mini(int(ceil((c.z + reach - _oz) / cell_m)), cells_z - 1)
	if ix0 > ix1 or iz0 > iz1:
		return 0
	var iy0: int = maxi(int(floor((y0 - r - _half) / cell_m - 0.5)), 0)
	var iy1: int = mini(int(ceil((y1 + r + _half) / cell_m - 0.5)), cells_y - 1)
	if iy0 > iy1:
		return 0

	var cut := 0
	for ix in range(ix0, ix1 + 1):
		var dx: float = maxf(absf(c.x - (_ox + float(ix) * cell_m)) - _half, 0.0)
		if dx > r:
			continue
		for iz in range(iz0, iz1 + 1):
			var dz: float = maxf(absf(c.z - (_oz + float(iz) * cell_m)) - _half, 0.0)
			var flat: float = dx * dx + dz * dz
			if flat > r2:
				continue
			for iy in range(iy0, iy1 + 1):
				var idx: int = (ix * cells_y + iy) * cells_z + iz
				if _alive[idx] == 0:
					continue
				var cy: float = (float(iy) + 0.5) * cell_m
				var dy: float = maxf(maxf(cy - _half - y1, y0 - (cy + _half)), 0.0)
				if flat + dy * dy > r2:
					continue
				_kill(idx)
				cut += 1
	return cut


## Hiding the instance and disabling its shape owner live in one function, so the
## picture and the physics can never disagree about which cubes are there — the
## failure that would let a visitor walk into a hole that is still solid.
func _kill(idx: int) -> void:
	_alive[idx] = 0
	_mm.set_instance_transform(idx, Transform3D(_gone, _centre[idx]))
	_solid.shape_owner_set_disabled(_owner[idx], true)
	_carved += 1
	if regrow_s > 0.0:
		_rg_idx.append(idx)
		_rg_due.append(_clock + regrow_s)


func _revive(idx: int) -> void:
	_alive[idx] = 1
	_mm.set_instance_transform(idx, Transform3D(Basis.IDENTITY, _centre[idx]))
	_solid.shape_owner_set_disabled(_owner[idx], false)
	_carved -= 1


func _regrow() -> void:
	# Nothing due is the normal case — regrow_s defaults to 0 and the queue is
	# never written. Leave before paying for a matrix inverse.
	if _rg_head >= _rg_idx.size() or _rg_due[_rg_head] > _clock:
		return
	var inv := global_transform.affine_inverse()
	while _rg_head < _rg_idx.size() and _rg_due[_rg_head] <= _clock:
		var idx: int = _rg_idx[_rg_head]
		# Never rebuild a cube inside somebody. The queue stalls at the head
		# instead of skipping, so the room heals in the order it was cut and the
		# cube you are standing in waits for you rather than trapping you.
		if _occupied(idx, inv):
			return
		if _alive[idx] == 0:
			_revive(idx)
		_rg_head += 1
	# Reclaim the consumed head once it is most of the queue. Not every frame:
	# this allocates, and the queue is usually empty.
	if _rg_head > 64 and _rg_head * 2 > _rg_idx.size():
		_rg_idx = _rg_idx.slice(_rg_head)
		_rg_due = _rg_due.slice(_rg_head)
		_rg_head = 0


func _occupied(idx: int, inv: Transform3D) -> bool:
	if _visitors.is_empty():
		return false
	var c: Vector3 = _centre[idx]
	for i in _visitors.size():
		var body: Node3D = _visitors[i]
		if not is_instance_valid(body):
			continue
		var p: Vector3
		var shp: Node3D = _v_shape[i]
		if shp != null and is_instance_valid(shp):
			p = inv * shp.global_position
		else:
			p = inv * (body.global_position + Vector3(0.0, visitor_height_m * 0.5, 0.0))
		var r: float = _v_r[i] + bite_m
		var hs: float = _v_hs[i]
		var dx: float = maxf(absf(p.x - c.x) - _half, 0.0)
		var dz: float = maxf(absf(p.z - c.z) - _half, 0.0)
		var dy: float = maxf(maxf(c.y - _half - (p.y + hs), (p.y - hs) - (c.y + _half)), 0.0)
		if dx * dx + dy * dy + dz * dz <= r * r:
			return true
	return false


## Signals are the cheap path and the truth is the area. An exit does not fire for
## a body that was freed or teleported out, so once every RESYNC_S the two are
## reconciled — one Array allocation a second instead of one a frame.
func _heal_visitors() -> void:
	if _area == null or not is_instance_valid(_area):
		return
	var here := _area.get_overlapping_bodies()
	for b in here:
		if _accepts(b) and _index_of(b) < 0:
			_add_visitor(b)
	for i in range(_visitors.size() - 1, -1, -1):
		var v: Node3D = _visitors[i]
		if not is_instance_valid(v) or not here.has(v):
			_drop_at(i)
	if _visitors.is_empty():
		_visit_s = 0.0


# ── for a map, and for a probe ───────────────────────────────────────────────

## How much of the block the room has eaten. The number a walk is worth.
func carved_fraction() -> float:
	if _count <= 0:
		return 0.0
	return float(_carved) / float(_count)


## One name across all three, because the first question about a dead artifact is
## always whether it can see anybody at all.
func visitor_count() -> int:
	return _visitors.size()


func live_count() -> int:
	return _count - _carved


## Put every cube back without rebuilding the lattice — the corridor undone, not
## the artifact reloaded.
func reset_lattice() -> void:
	if _mm == null or _solid == null:
		return
	for i in _count:
		if _alive[i] == 0:
			_revive(i)
	_rg_idx.resize(0)
	_rg_due.resize(0)
	_rg_head = 0
	_carved = 0
	_visit_s = 0.0
	_said_inert = false
