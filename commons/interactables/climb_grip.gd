@tool
extends Node3D
class_name ClimbGrip

# @identity
# essence: a chunky textured rung you grab and pull yourself by — the CLIMB modality, the only hand verb
#          that moves the BODY instead of the object. Grab it and your hand stays fixed in the world while
#          you haul past it; let go and momentum carries you. The lab's example of locomotion-by-grip.
# desire: to bear the player's weight. Where the grab cube comes to you, the climb grip holds firm and you
#         come to IT — the inversion that makes climbing: the world handle that does not move so that you do.
# critical_parameter: placement + the grab layer (handled by the wrapped XRToolsClimbable on the grab-handle
#         layer). The grip must be reachable and firm; the climb function on the player rig does the hauling.
# triggers: a hand grab closes on it -> climbed(by); the player rig's movement-climb pulls the body; release
#          -> released(by), with leftover velocity.
# emerges: vertical and lateral self-movement by the arms — the body as the thing that moves. Ladders,
#          ledges, cliff faces. The grip teaches that a hand can anchor to the world and move the self.
# needs: an XRToolsClimbable [instanced child]; a visible textured rung [present]
# relationships: the inverse of grab_cube (object-moves vs body-moves); requires the player movement-climb
#                function to feel its effect; the locomotion member of the gadget wall.
# truth: every other gadget moves a thing with the hand; the climb grip moves the SELF. It is the lab's
#        reminder that the hand's oldest job is not to operate the world but to haul the body through it.

@export var grip_length: float = 0.18
@export var grip_radius: float = 0.022
@export var grip_color: Color = Color(0.85, 0.7, 0.35, 1.0)

var _built: bool = false


func _ready() -> void:
	if _built:
		return
	_build()


func _build() -> void:
	_built = true

	# Two mounting posts.
	var post_mat := StandardMaterial3D.new()
	post_mat.albedo_color = Color(0.10, 0.11, 0.13)
	post_mat.metallic = 0.5
	post_mat.roughness = 0.6
	for sx in [-1.0, 1.0]:
		var post := MeshInstance3D.new()
		post.name = "Post%s" % ("L" if sx < 0 else "R")
		var pm := BoxMesh.new()
		pm.size = Vector3(0.03, 0.03, 0.06)
		post.mesh = pm
		post.material_override = post_mat
		post.position = Vector3(sx * grip_length * 0.5, 0, -0.03)
		add_child(post)

	# The rung itself (visual).
	var rung := MeshInstance3D.new()
	rung.name = "RungMesh"
	var rm := CylinderMesh.new()
	rm.top_radius = grip_radius
	rm.bottom_radius = grip_radius
	rm.height = grip_length
	rm.radial_segments = 16
	rung.mesh = rm
	var grip_mat := StandardMaterial3D.new()
	grip_mat.albedo_color = grip_color
	grip_mat.metallic = 0.3
	grip_mat.roughness = 0.55
	grip_mat.emission_enabled = true
	grip_mat.emission = grip_color
	grip_mat.emission_energy_multiplier = 0.2
	rung.material_override = grip_mat
	rung.rotation_degrees = Vector3(0, 0, 90)
	add_child(rung)

	if Engine.is_editor_hint():
		return

	# Wrap the real XR-tools climbable so the player movement-climb works.
	var climb_path: String = "res://addons/godot-xr-tools/objects/climbable.tscn"
	if ResourceLoader.exists(climb_path):
		var climb_scene: PackedScene = load(climb_path)
		var climb: Node = climb_scene.instantiate()
		climb.name = "Climbable"
		add_child(climb)
		# Size the climbable collision to the rung.
		var cs: CollisionShape3D = climb.get_node_or_null("CollisionShape3D")
		if cs and cs.shape is BoxShape3D:
			var new_shape: BoxShape3D = cs.shape.duplicate()
			new_shape.size = Vector3(grip_length, grip_radius * 2.2, grip_radius * 2.2)
			cs.shape = new_shape
		elif cs:
			# climbable ships without a shape — give it a box sized to the rung.
			var box := BoxShape3D.new()
			box.size = Vector3(grip_length, grip_radius * 2.2, grip_radius * 2.2)
			cs.shape = box
