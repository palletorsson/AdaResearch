extends RefCounted
## Map-authored west balcony. The floor meets the hall at y=0; the flock is untouched.
## Rect is in map metres. The doorway is authored in the structure layer.

static func install(hall: Node3D, declaration: Dictionary, vestibule: float) -> Array[Vector2i]:
	var cells: Array[Vector2i] = []
	if declaration.is_empty() or hall.has_node("ObservationBalcony"):
		return cells
	var rect: Array = declaration.get("rect", [])
	if rect.size() != 4 or float(rect[2]) <= 0 or float(rect[3]) <= 0:
		return cells
	var x: float = rect[0]
	var z: float = rect[1]
	var w: float = rect[2]
	var d: float = rect[3]
	var balcony := Node3D.new()
	balcony.name = "ObservationBalcony"
	balcony.position.z = vestibule
	hall.add_child(balcony)
	balcony.set_meta("map_rect", rect)
	var stone := StandardMaterial3D.new()
	stone.albedo_color = Color("b7b9c1")
	stone.roughness = 0.78
	var metal := StandardMaterial3D.new()
	metal.albedo_color = Color("303640")
	metal.metallic = 0.65
	metal.roughness = 0.34
	var light := StandardMaterial3D.new()
	light.albedo_color = Color("efa5c3")
	light.emission_enabled = true
	light.emission = Color("df729f")
	light.emission_energy_multiplier = 0.5
	# The 2 cm overlap removes a seam at the existing hall floor.
	box(balcony, "Deck", Vector3(x+w/2+.01,-.12,z+d/2), Vector3(w+.02,.24,d), stone, true)
	for ix in range(int(x), int(ceil(x+w))):
		for iz in range(int(z), int(ceil(z+d))):
			cells.append(Vector2i(ix,iz))
	# Thin visible rails and full-height collision guards: views below remain open.
	rail(balcony, Vector3(x+.08,0,z), Vector3(x+.08,0,z+d), metal, light)
	rail(balcony, Vector3(x,0,z+.08), Vector3(x+w,0,z+.08), metal, light)
	rail(balcony, Vector3(x,0,z+d-.08), Vector3(x+w,0,z+d-.08), metal, light)
	# Subtle metre seams let the extension read as part of the museum floor.
	for ix in range(int(x)+1, int(x+w)):
		box(balcony,"TileSeam",Vector3(ix,.002,z+d/2),Vector3(.008,.003,d-.18),metal)
	for iz in range(int(z)+1, int(z+d)):
		box(balcony,"TileSeam",Vector3(x+w/2,.002,iz),Vector3(w-.18,.003,.008),metal)
	var door: Array = declaration.get("door_z", [z,z+d])
	var middle: float = (float(door[0])+float(door[1]))/2
	var sign := Label3D.new()
	sign.name = "BalconySign"
	sign.text = "FLOCK OBSERVATORY  /  STEP OUTSIDE"
	sign.position = Vector3(.99,2.5,middle)
	sign.rotation_degrees.y = 90
	sign.font_size = 42
	sign.pixel_size = .0015
	sign.modulate = Color("f0dae5")
	sign.outline_size = 3
	balcony.add_child(sign)
	box(balcony,"ThresholdLight",Vector3(.5,.004,middle),Vector3(1,.006,.06),light)
	return cells

static func box(parent: Node3D, title: String, at: Vector3, size: Vector3, material: Material, solid := false) -> void:
	var mesh := MeshInstance3D.new()
	mesh.name = title
	mesh.position = at
	var shape := BoxMesh.new()
	shape.size = size
	mesh.mesh = shape
	mesh.material_override = material
	parent.add_child(mesh,true)
	if solid:
		collider(parent,title+"Collision",at,size)

static func collider(parent: Node3D, title: String, at: Vector3, size: Vector3) -> void:
	var body := StaticBody3D.new()
	body.name = title
	body.position = at
	body.collision_layer = 1
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)
	parent.add_child(body,true)

static func rail(parent: Node3D, start: Vector3, end: Vector3, material: Material, glow: Material) -> void:
	var along := end-start
	var centre := (start+end)/2
	var extent := Vector3(absf(along.x),0,absf(along.z))
	box(parent,"Handrail",centre+Vector3.UP*1.05,extent+Vector3(.055,.055,.055),material)
	box(parent,"ToeRail",centre+Vector3.UP*.065,extent+Vector3(.07,.13,.07),material)
	box(parent,"EdgeLight",centre+Vector3.UP*.15,extent+Vector3(.015,.015,.015),glow)
	collider(parent,"EdgeGuard",centre+Vector3.UP*.55,extent+Vector3(.10,1.1,.10))
	var count := maxi(1,int(ceil(along.length())))
	for i in range(count+1):
		box(parent,"RailPost",start+along*float(i)/count+Vector3.UP*.54,Vector3(.035,1.08,.035),material)
