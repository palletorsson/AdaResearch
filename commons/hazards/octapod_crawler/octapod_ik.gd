# @identity
# essence: octapod_gait(t) = alternating_tetrapods(1357, 2468) -- eight legs split into two fours
# desire: to be the ladder's last rung instead of its hole
# critical_parameter: the tetrapod split -- four down at all times, so the body never negotiates a fall
# triggers: _walk drives the body; a tetrapod lifts when its worst foot passes step_threshold
# emerges: at eight legs the support polygon stops being a constraint and becomes a floor
# needs: a Body child carrying this script [has]; 8 FABRIK chains + SpringArms [has, from the .tscn]
# relationships: eighth and last of the 1-to-8 progression; six_leg_critter is the rung below
# truth: eight legs is where gait stops being a problem -- any four of them already hold the body up.

extends "res://commons/hazards/octapod_crawler/leg_walker_base.gd"

## THE EIGHTH RUNG, WHICH WAS A HOLE (2026-08-27, Palle: "write the octapod_ik
## rung properly").
##
## octapod_ik.tscn shipped as 57 nodes of finished rig — eight skeletons, eight
## FABRIK chains with their magnets, eight SpringArms with foot targets, all of
## it correct — and no body, no script and no mesh. It measured 0.00 x 0.00 x
## 0.00 m and rendered nothing. commons/maps/Hazards_Zoo_3 has been showing a
## row captioned "From 1 to 8 legs" with six critters and an invisible eighth
## since the day it was placed.
##
## Nothing about the rig needed fixing. It needed a body put on it, the legs
## and arms reparented under that body so the FABRIK NodePaths still resolve,
## and this: the gait its siblings already have, at the scale it was authored.
##
## IT IS A TWENTIETH THE SIZE OF ITS SIBLINGS. The other six space their bones
## 1.0 apart for a five-unit leg; this one uses 0.12, for a leg 0.6 long and a
## shoulder ring of radius 0.30. Every gait number is a WORLD-SPACE distance
## compared by distance_to, so they are set here before super._ready() reads
## them — a 1.5 m step threshold on a 0.6 m leg is the failure head_crab
## already paid for: four rigid stilts that never lift.

const LEG_COUNT: int = 8
const RING_R: float = 0.30      ## the SpringArm ring the .tscn authored
const RIDE: float = 0.45        ## body height above the foot plane

## eight shoulders at 45 degrees, on the ring the arms already stand on
var _shoulders: Array[Vector3] = []

var _feet: Array[Marker3D] = []
var _leg_planted: Array[Vector3] = []
var _leg_stepping: Array[bool] = []
var _leg_step_from: Array[Vector3] = []
var _leg_step_to: Array[Vector3] = []
var _leg_step_time: Array[float] = []
## THE ALTERNATING TETRAPOD, actually implemented. four_leg_critter declares a
## diagonal trot in its identity block and steps one leg at a time; six_leg
## declares two tripods and does the same. This one does what it says.
const TETRAPODS := [[0, 2, 4, 6], [1, 3, 5, 7]]
var _tetra: int = 0


func _ready() -> void:
	# BEFORE super, which captures these as the authored values that scale
	step_threshold = 0.17
	step_height = 0.11
	step_duration = 0.16
	step_overshoot = 0.07
	patrol_speed = 0.30
	move_speed = 0.60
	super._ready()

	for i in range(LEG_COUNT):
		var a: float = TAU * float(i) / float(LEG_COUNT)
		_shoulders.append(Vector3(cos(a) * RING_R, -RIDE, sin(a) * RING_R))

	# a body: a low dome rather than a box, because eight legs around a box
	# reads as a table and the whole rung is about an animal
	var body := SphereMesh.new()
	body.radius = 0.16
	body.height = 0.20
	body.radial_segments = 20
	body.rings = 10
	mesh = body
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.22, 0.20, 0.26)
	mat.roughness = 0.55
	material_override = mat

	_feet.resize(LEG_COUNT)
	_leg_planted.resize(LEG_COUNT)
	_leg_stepping.resize(LEG_COUNT)
	_leg_step_from.resize(LEG_COUNT)
	_leg_step_to.resize(LEG_COUNT)
	_leg_step_time.resize(LEG_COUNT)

	for i in range(LEG_COUNT):
		var sk: Skeleton3D = get_node_or_null("IK_leg_%d/Armature/Skeleton3D" % i) as Skeleton3D
		if sk != null:
			_add_skinned_mesh(sk, "LegMesh_%d" % i)
		_feet[i] = get_node_or_null("SpringArm3D_%d/FootTarget_%d" % [i, i]) as Marker3D
		_leg_stepping[i] = false
		_leg_step_from[i] = Vector3.ZERO
		_leg_step_to[i] = Vector3.ZERO
		_leg_step_time[i] = 0.0
		_leg_planted[i] = global_transform * _shoulders[i]
		_leg_planted[i].y = _ground()

	var missing := 0
	for f in _feet:
		if f == null: missing += 1
	if missing > 0:
		push_warning("octapod_ik: %d of %d foot targets missing — the .tscn changed" % [missing, LEG_COUNT])
	print("[OctapodIK] eight legs ready — threshold %.2f, ring %.2f" % [step_threshold, RING_R])


func _process(delta: float) -> void:
	_walk(delta)
	_update_gait(delta)


func _update_gait(delta: float) -> void:
	var homes: Array[Vector3] = []
	homes.resize(LEG_COUNT)
	for i in range(LEG_COUNT):
		homes[i] = global_transform * _shoulders[i]
		homes[i].y = _ground()

	var any_stepping := false
	for i in range(LEG_COUNT):
		if _leg_stepping[i]:
			_leg_step_time[i] += delta / maxf(0.01, step_duration)
			if _leg_step_time[i] >= 1.0:
				_leg_step_time[i] = 1.0
				_leg_stepping[i] = false
				_leg_planted[i] = _leg_step_to[i]
			else:
				any_stepping = true

	# a whole tetrapod lifts at once, and only when its worst foot has fallen
	# far enough behind — so four feet are always on the floor
	if not any_stepping:
		var group: Array = TETRAPODS[_tetra]
		var worst := 0.0
		for li in group:
			worst = maxf(worst, (_leg_planted[li] as Vector3).distance_to(homes[li]))
		if worst > step_threshold:
			var forward: Vector3 = -global_transform.basis.z.normalized()
			for li in group:
				_leg_stepping[li] = true
				_leg_step_time[li] = 0.0
				_leg_step_from[li] = _leg_planted[li]
				var tgt: Vector3 = (homes[li] as Vector3) + forward * step_overshoot
				tgt.y = _ground()
				_leg_step_to[li] = tgt
			_tetra = 1 - _tetra

	for i in range(LEG_COUNT):
		var foot: Marker3D = _feet[i]
		if foot == null or not is_instance_valid(foot):
			continue
		var pos: Vector3
		if _leg_stepping[i]:
			var t: float = _leg_step_time[i]
			var smooth: float = t * t * (3.0 - 2.0 * t)
			pos = (_leg_step_from[i] as Vector3).lerp(_leg_step_to[i] as Vector3, smooth)
			pos.y += sin(t * PI) * step_height
		else:
			pos = _leg_planted[i]
		foot.global_position = pos


## the family's own skinning, at this rig's bone spacing
func _add_skinned_mesh(skeleton: Skeleton3D, mesh_name: String) -> void:
	var skin := Skin.new()
	skin.set_bind_count(6)
	for i in range(6):
		var bname: String = "Bone" if i == 0 else "Bone.%03d" % i
		skin.set_bind_name(i, bname)
		skin.set_bind_bone(i, -1)
		skin.set_bind_pose(i, Transform3D(Basis.IDENTITY, Vector3(0, -float(i) * 0.12, 0)))

	var mi := MeshInstance3D.new()
	mi.name = mesh_name
	mi.mesh = _make_tapered_tube(6, 0.12, 0.020, 0.005, 8)
	mi.skin = skin
	mi.skeleton = NodePath("..")
	var leg_mat := StandardMaterial3D.new()
	leg_mat.albedo_color = Color(0.17, 0.16, 0.20)
	leg_mat.roughness = 0.45
	leg_mat.metallic = 0.35
	leg_mat.cull_mode = BaseMaterial3D.CULL_DISABLED
	mi.material_override = leg_mat
	skeleton.add_child(mi)


func _make_tapered_tube(bone_count: int, spacing: float, base_r: float, tip_r: float, segs: int) -> ArrayMesh:
	var verts := PackedVector3Array()
	var norms := PackedVector3Array()
	var idx := PackedInt32Array()
	for b in range(bone_count):
		var y: float = float(b) * spacing
		var r: float = lerpf(base_r, tip_r, float(b) / float(maxi(1, bone_count - 1)))
		for s in range(segs):
			var a: float = TAU * float(s) / float(segs)
			var n := Vector3(cos(a), 0.0, sin(a))
			verts.append(Vector3(n.x * r, y, n.z * r))
			norms.append(n)
	for b in range(bone_count - 1):
		for s in range(segs):
			var s2: int = (s + 1) % segs
			var a0: int = b * segs + s
			var a1: int = b * segs + s2
			var b0: int = (b + 1) * segs + s
			var b1: int = (b + 1) * segs + s2
			idx.append_array([a0, b0, a1, a1, b0, b1])
	var arrays := []
	arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX] = verts
	arrays[Mesh.ARRAY_NORMAL] = norms
	arrays[Mesh.ARRAY_INDEX] = idx
	# every vertex is bound to its own bone, which is what makes the tube bend
	var bones := PackedInt32Array()
	var weights := PackedFloat32Array()
	for b2 in range(bone_count):
		for s3 in range(segs):
			bones.append_array([b2, 0, 0, 0])
			weights.append_array([1.0, 0.0, 0.0, 0.0])
	arrays[Mesh.ARRAY_BONES] = bones
	arrays[Mesh.ARRAY_WEIGHTS] = weights
	var am := ArrayMesh.new()
	am.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES, arrays)
	return am
