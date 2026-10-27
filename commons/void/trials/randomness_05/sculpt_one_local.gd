extends "res://algorithms/randomness/SculptOne.gd"
## Trial-only adapter (randomness_05, R4) for sculpt_one (`sculpt_one#seed_controls:true`).
##
## 1. Suns. SculptOne builds a WorldEnvironment (pink background, SSAO, SSR, glow), two
##    DirectionalLight3D and a fill OmniLight3D in setup_environment(). floor_content
##    neutralises the environment and the suns once, after the placement enters the tree.
##    The source's seed console rebuilds the whole piece (_rebuild_now -> _build_all ->
##    setup_environment), so a NEXT or REPLAY press would add a new environment and two
##    unscoped suns that light every floor. After every build this adapter applies
##    floor_content's existing import rule again. The local fill light is kept.
##
## 2. Leak. The source create_fluid_mass() builds a `base_mesh` MeshInstance3D (a scaled
##    SphereMesh with the glossy material) and never parents or frees it: it is never shown,
##    and at exit it is reported as leaked. The default `composition` hand calls it twice
##    (base block and red blob): 2 RS instances, 2 meshes, 2 materials and their one shared
##    clearcoat shader, matching the batch-25 exit report on every run. Each seed rebuild
##    leaked two more. This copy is the source function without that orphan. It draws the
##    same numbers in the same order (the orphan used no draws), so every visible part, and
##    the seed's result, is unchanged.
func setup_environment() -> void:
	super.setup_environment()
	for environment in find_children("*", "WorldEnvironment", true, false):
		(environment as WorldEnvironment).environment = null
	for sun in find_children("*", "DirectionalLight3D", true, false):
		(sun as DirectionalLight3D).hide()

# Same signature as the source (untyped), so the override is accepted.
func create_fluid_mass(material, position, scale_vec):
	var fluid = Node3D.new()
	fluid.position = position
	# The source's unparented base_mesh is omitted: nothing showed it.
	var deform_count = rng.randi() % 5 + 5
	for i in range(deform_count):
		var deform = MeshInstance3D.new()
		var deform_mesh = SphereMesh.new()
		deform_mesh.radius = rng.randf_range(0.3, 0.7)
		deform_mesh.height = deform_mesh.radius * 2
		deform.mesh = deform_mesh
		var angle = rng.randf_range(0, TAU)
		var elevation = rng.randf_range(-1.0, 1.0)
		var radius = rng.randf_range(0.7, 1.1)
		deform.position = Vector3(
			cos(angle) * radius * scale_vec.x,
			elevation * scale_vec.y,
			sin(angle) * radius * scale_vec.z
		)
		deform.material_override = material
		fluid.add_child(deform)
	return fluid
