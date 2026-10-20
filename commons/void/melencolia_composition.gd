extends Node3D
## A small adapter around the original pickable solids, not new shape generators.
const Kit = preload("res://commons/artifacts/ignorance_gallery/gallery_kit.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
var homes: Dictionary = {}
var readout: Label3D
var elapsed := 0.0

static func prepare(body: XRToolsPickable, colour: Color) -> void:
	# Normalize the visible source mesh, then derive collision from that exact
	# transform. Never scale the RigidBody: the old cube is only 10 cm across.
	var visual: MeshInstance3D = body.get_node("MeshInstance3D")
	var bounds := visual.mesh.get_aabb()
	var factor := .65 / maxf(bounds.size.x,maxf(bounds.size.y,bounds.size.z))
	visual.scale = Vector3.ONE*factor
	visual.position = -bounds.get_center()*factor
	var finish := Kit.material(colour)
	finish.emission_enabled = true; finish.emission = colour
	finish.emission_energy_multiplier = .06; finish.roughness = .48
	visual.material_override = finish
	var points := PackedVector3Array()
	for surface in visual.mesh.get_surface_count():
		for vertex: Vector3 in visual.mesh.surface_get_arrays(surface)[Mesh.ARRAY_VERTEX]:
			points.append(visual.transform*vertex)
	var shape := ConvexPolygonShape3D.new(); shape.points = points
	var collider: CollisionShape3D = body.get_node("CollisionShape3D")
	collider.transform = Transform3D.IDENTITY; collider.shape = shape
	body.scale = Vector3.ONE; body.freeze = true
	body.release_mode = XRToolsPickable.ReleaseMode.FROZEN
	body.snap_to_shelf = false
	body.position.y = .83+bounds.size.y*factor*.5
	body.set_meta("editor_label",["Tetrahedron / compose","Cube / compose","Octahedron / compose"][int(str(body.name).right(1))])
	var light := OmniLight3D.new(); light.name = "CarriedLight"
	light.light_color = colour; light.light_energy = 1.15
	light.omni_range = 2.5; light.shadow_enabled = false; light.visible = false
	body.add_child(light)
	body.picked_up.connect(func(_object): light.show(); finish.emission_energy_multiplier=.6)
	body.dropped.connect(func(_object): light.hide(); finish.emission_energy_multiplier=.06)

func _ready() -> void:
	Kit.block(self,Vector3(4.55,.8,.05),Vector3(0,1.35,-1.4),Color("292530"),false).name="ReadingPlate"
	readout = Kit.label(self,"",Vector3(0,1.35,-1.37),.00125)
	readout.name = "ArrangementReadout"; readout.modulate = Color("eee1d2")
	var button: Node3D = PushButton.instantiate()
	button.name = "RestoreButton"; button.position = Vector3(2,.82,.9)
	button.rotation = Vector3.ZERO; add_child(button)
	button.pressed.connect(restore_arrangement)
	var caption := Kit.label(self,"RESTORE",Vector3(2,.805,.62),.0011)
	caption.rotation.x = -PI/2
	Kit.lamp(self,Vector3(0,2.2,0),1.0,4.2)
	capture_homes.call_deferred()

func capture_homes() -> void:
	# Capture AFTER editor placement. A copied table on its own works as furniture;
	# it never reaches into another hall to reset somebody else's objects.
	homes.clear()
	for i in 3:
		var body := get_parent().get_parent().get_node_or_null("CompositionSolid%d"%i) as XRToolsPickable
		if body != null: homes[body] = body.transform
	update_readout()

func changed_count() -> int:
	var count := 0
	for body in homes:
		if is_instance_valid(body) and not body.transform.is_equal_approx(homes[body]): count+=1
	return count

func restore_arrangement() -> void:
	for body in homes:
		if not is_instance_valid(body) or body.is_picked_up(): continue
		body.freeze = true; body.transform = homes[body]
		body.linear_velocity = Vector3.ZERO; body.angular_velocity = Vector3.ZERO
		PhysicsServer3D.body_set_state(body.get_rid(),PhysicsServer3D.BODY_STATE_TRANSFORM,body.global_transform)
	update_readout()

func _process(delta: float) -> void:
	elapsed += delta
	if elapsed < .2: return
	elapsed = 0; update_readout()

func update_readout() -> void:
	var available := 0
	for body in homes:
		if is_instance_valid(body): available+=1
	readout.text = "SAME BODIES / YOUR ARRANGEMENT\nPick up. Place. Step back.\n%d OF %d PLACEMENTS CHANGED\nThe vertices stay. The relations change." % [changed_count(),available]
