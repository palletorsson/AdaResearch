extends Node3D
## The guest's leg: the kit's leg.gd with the colours written out, and without
## the white beam that showed the ray. A leg is a chain that follows its foot.
## This node is the hip. It names nothing outside this folder.

const BODY := Color("c6ff3d")     # the kit's BODY colour, written out
const SECOND := Color("22d9ff")   # the kit's SECOND colour, written out

@export var segments := 3    # parts in the chain
@export var total := 0.8     # metres from hip to foot, whatever the number of parts
@export var reach := 0.35    # metres from the hip, along the leg at rest, to where its ray starts
@export_flags_3d_physics var ground := 1   # the layers that are ground for this foot

var chain: Array[Node3D] = []   # the parts, the hip's end first
var length := 0.0               # metres, of one part
var target := Vector3.ZERO      # where the foot is going
var foot := Vector3.ZERO        # where the foot is now
var led := Vector3.ZERO         # where the loop led the hip's end of the chain
var lead := Vector3.ZERO        # how far from its rest place the ray starts, in the room's axes

func _ready() -> void:
	length = total / segments
	for i in segments:
		var part := Node3D.new()
		add_child(part)
		part.position = Vector3(0, -length * i, 0)   # laid out along the hip's own down
		part.rotation.x = -PI / 2.0                  # its -z, the way it looks, along that down
		var bone := MeshInstance3D.new()
		var box := BoxMesh.new()
		box.size = Vector3(0.05, 0.05, length)
		bone.mesh = box
		bone.material_override = paint(BODY)
		bone.position.z = -length / 2.0              # from the part's own place to its far end
		part.add_child(bone)
		chain.append(part)
	$Mark.material_override = paint(SECOND)
	target = to_global(Vector3(0, -total, 0))
	foot = target

func paint(color: Color) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.8
	return material

## The follow loop: the foot leads, each part follows the next, the hip comes last.
func follow(to: Vector3) -> void:
	var aim := to
	for i in range(chain.size() - 1, -1, -1):
		var part := chain[i]
		part.look_at(aim, global_basis.z)                           # it looks at the next
		part.global_position = aim + part.global_basis.z * length   # and keeps its length
		aim = part.global_position
	led = aim
	for part in chain:                                              # the hip holds: the chain is carried back to it
		part.global_position += global_position - led

## Where the chain ends now: the far end of its last part.
func tip() -> Vector3:
	return chain[-1].global_position - chain[-1].global_basis.z * length

## The ray looks straight down from the leg's rest place. True if it found ground.
func find_ground() -> bool:
	var ray: RayCast3D = $Ray
	ray.collision_mask = ground
	ray.global_position = to_global(Vector3(0, -reach, 0)) + lead
	ray.target_position = ray.to_local(ray.global_position + Vector3.DOWN * 2.0)
	ray.force_raycast_update()
	if ray.is_colliding():
		target = ray.get_collision_point()
	return ray.is_colliding()

## One frame of the foot: it glides to its target, lifted while on its way, and the chain follows.
func step(delta: float) -> void:
	foot = foot.move_toward(target, 1.5 * delta)
	$Mark.global_position = target
	follow(foot + Vector3.UP * minf(0.1, foot.distance_to(target)))
