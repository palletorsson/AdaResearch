	# Point One - Technical Tutorial

	*This tutorial reuses and extends content from `point_axioms.md`*

	## The Point as Data

	### Position in the Engine

	In a game engine like Godot, every point always has a position.
	The engine stores this position continuously as a vector.

	```gdscript
	var point_position = Vector3(3.0, 1.5, 4.0)
	```

	This vector **is** the point. The three float values (x, y, z) define position in 3D space.

	### The Point Has No Intrinsic Properties

	A point is:
	- No size (infinitely small)
	- No shape (dimensionless)
	- No direction (no orientation)

	It is defined **only by where it is**.

	```gdscript
	# A point is just a position
	var point_a = Vector3(1.0, 2.0, 3.0)
	var point_b = Vector3(4.0, 5.0, 6.0)

	# These are different points because they have different positions
	print(point_a == point_b)  # false
	```

	### Making a Point Visible

	To see a point, we represent it with a small sphere.
	The sphere is not the point — it is a **visual marker** for a position.

	```gdscript
	extends Node3D

	func create_point_marker(position: Vector3, radius: float = 0.01) -> MeshInstance3D:
		# Create sphere geometry
		var sphere_mesh = SphereMesh.new()
		sphere_mesh.radius = radius
		sphere_mesh.height = radius * 2.0  # Height = diameter for perfect sphere

		# Create mesh instance
		var mesh_instance = MeshInstance3D.new()
		mesh_instance.mesh = sphere_mesh
		mesh_instance.position = position

		# Create glowing material
		var material = StandardMaterial3D.new()
		material.albedo_color = Color(0.8, 0.95, 1, 1)
		material.emission_enabled = true
		material.emission = Color(0.3, 0.6, 0.8, 1)
		material.emission_energy = 0.5
		mesh_instance.material_override = material

		return mesh_instance
	```

	### Making a Point Interactive

	The `interactive_point_origin.tscn` in this map uses XR Tools to make the point **grabbable**:

	```gdscript
	extends XRToolsPickable

	@export var glow_color: Color = Color(0.3, 0.8, 1, 1)
	@export var glow_emission_energy: float = 2.5

	func _ready():
		# Point can be grabbed and moved
		freeze = true  # Starts frozen in place
		alter_freeze = false  # Can be un-frozen when grabbed

		# Connect grab signals
		picked_up.connect(_on_picked_up)
		dropped.connect(_on_dropped)

	func _on_picked_up(pickable):
		# Point glows brighter when held
		# Your body is now determining its position
		pass

	func _on_dropped(pickable):
		# Point remains where your hand placed it
		# The body has instantiated a new position
		pass
	```

	### Point Position Updates

	When you move a point, you're updating its Vector3 position every frame:

	```gdscript
	func _process(delta):
	    if is_picked_up:
			# The controller's position becomes the point's position
	        global_position = get_picking_hand().global_position
	```

	The point has no memory of previous positions - only its current location exists.

	## Euclidean Definition

	The floating text references Euclid's *Elements*, Book I, Definition 1:

	> "A point is that which has no part."

	In code terms:
	- A point cannot be subdivided (atomic)
	- It has zero dimensions (0D)
	- It occupies no volume (infinitesimal)

	## Key Takeaway

	A point in code is a **position marker** - three float values that locate something in 3D space. The visual sphere, the grabbable object, the glowing material - none of these **are** the point. They make the position **visible and manipulable** by bodies in VR space.

	When you grab and move the point, your hand's position becomes the point's new Vector3 coordinates. **Your body creates geometry.**
