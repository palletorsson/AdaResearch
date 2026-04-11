# @identity
# essence: rotation(beam) -> sweep(player) -> pit(death) — a spinning arm that sweeps you off the edge
# desire: to make rotation felt as a force — not an angle but a sweep that catches your body
# critical_parameter: rotation_speed / arm_length — the windmill must be readable: see it coming, time your move
# triggers: constant rotation around Y axis; AnimatableBody3D collision pushes player on contact
# emerges: Don Quixote's windmill — the world rotates and you must dance with it or be swept away
# needs: AnimatableBody3D [has]; pivot rotation [has]; DangerZone below [external]
# relationships: sibling to pusher_block (translation) and grower_block (scale); the rotation lesson
# truth: rotation is the transformation you feel in your inner ear — the one that makes VR real.

# SweeperBlock.gd
# A beam that rotates around a central pivot, sweeping players off edges
# into pits. Like Don Quixote's windmill — the world spins and you must
# time your crossing or be knocked into the void.
#
# The beam is an AnimatableBody3D so it physically pushes the player.
# Place at center of a platform with pits on the edges.

extends Node3D
class_name SweeperBlock

@export var arm_length: float = 3.0            ## Length of the sweeping beam (one side)
@export var arm_height: float = 0.8            ## Height of the beam (should be above player knee)
@export var arm_thickness: float = 0.3         ## Thickness of the beam
@export var rotation_speed: float = 0.8        ## Radians per second (full turn ~8 seconds)
@export var block_size: float = 1.0            ## Grid cube size for alignment

var _pivot: Node3D = null
var _body: AnimatableBody3D = null
var _mesh: MeshInstance3D = null
var _angle: float = 0.0


func _ready() -> void:
	_build_pivot()
	_build_beam()


func _physics_process(delta: float) -> void:
	_angle += rotation_speed * delta
	_pivot.rotation.y = _angle
	# Sync the AnimatableBody3D position from the pivot
	_body.global_transform = _pivot.global_transform * _body.transform


func _build_pivot() -> void:
	_pivot = Node3D.new()
	_pivot.name = "Pivot"
	_pivot.position = Vector3(0, 0, 0)
	add_child(_pivot)


func _build_beam() -> void:
	# AnimatableBody3D: rotates via code, pushes player on contact
	_body = AnimatableBody3D.new()
	_body.name = "SweeperBody"

	# Position beam so it extends from -arm_length to +arm_length through center
	# The beam center is at the pivot
	_body.position = Vector3(0, arm_height * 0.5, 0)
	_pivot.add_child(_body)

	# Collision shape — long box
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(arm_length * 2.0, arm_height, arm_thickness)
	col.shape = box
	_body.add_child(col)

	# Visual mesh
	_mesh = MeshInstance3D.new()
	_mesh.name = "BeamMesh"
	var box_mesh := BoxMesh.new()
	box_mesh.size = Vector3(arm_length * 2.0, arm_height, arm_thickness)
	_mesh.mesh = box_mesh

	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.5, 0.9)
	mat.emission_enabled = true
	mat.emission = Color(0.2, 0.4, 0.9)
	mat.emission_energy_multiplier = 1.0
	mat.metallic = 0.6
	mat.roughness = 0.2
	_mesh.material_override = mat
	_body.add_child(_mesh)

	# Center post (visual only — thin cylinder at the pivot)
	var post := MeshInstance3D.new()
	post.name = "CenterPost"
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.08
	cyl.bottom_radius = 0.1
	cyl.height = arm_height + 0.2
	post.mesh = cyl
	post.position = Vector3(0, arm_height * 0.5, 0)
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.4, 0.4, 0.5)
	post_mat.metallic = 0.7
	post_mat.roughness = 0.2
	post.material_override = post_mat
	add_child(post)


func apply_grid_config(config_data: Dictionary) -> void:
	if config_data.has("speed"):
		rotation_speed = float(config_data["speed"])
	if config_data.has("length"):
		arm_length = float(config_data["length"])
	if config_data.has("height"):
		arm_height = float(config_data["height"])
