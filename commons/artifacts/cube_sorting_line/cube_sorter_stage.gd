extends Node3D
## The sorting line's fixed stage. Gameplay owns the belt velocity, folding,
## stamping, collection, and controls; this class only builds their physical homes.
const STAGE_PUSH = preload("res://commons/interactables/push_button.tscn")
const STAGE_NET = preload("res://commons/infoboards_3d/visualizations/polyhedron_nets_cube.tscn")
const STAGE_CARTON = preload("res://commons/artifacts/prefab_box_library/edition_carton.tscn")

var belt: StaticBody3D
var baskets: Array[Area3D] = []
var buttons: Dictionary = {}
var readout: Label3D
var net: Node3D
var stamp_visual: MeshInstance3D
var belt_marks: Array[MeshInstance3D] = []

func build_stage() -> void:
	if is_instance_valid(belt):
		return
	var steel := stage_material(Color("283b43"), 0.62)
	var rubber := stage_material(Color("263136"))
	var cream := stage_material(Color("f2efe5"))
	var brass := stage_material(Color("e5b66e"), 0.45)
	var ink := Color("19333d")
	# The top is exactly 0.95 m. A moving-surface collider carries free cubes;
	# the outfeed has no stop, tray, or private floor to catch missed deliveries.
	belt = StaticBody3D.new()
	belt.name = "ConveyorSurface"
	belt.position = Vector3(0, 0.91, 0)
	belt.collision_layer = 1
	belt.collision_mask = 0
	var friction := PhysicsMaterial.new()
	friction.friction = 1.0
	belt.physics_material_override = friction
	stage_collision(belt, Vector3(5.2, 0.08, 0.48))
	add_child(belt)
	stage_box("BeltRubber", Vector3(0, 0.915, 0), Vector3(5.2, 0.07, 0.48), rubber)
	for z in [-0.285, 0.285]:
		stage_box("FrameRail", Vector3(0, 0.79, z), Vector3(5.18, 0.16, 0.065), steel, true)
		stage_box("DirectionStripe", Vector3(0, 0.875, z), Vector3(5.10, 0.025, 0.072), brass)
		for x in [-2.2, 0.0, 2.2]:
			stage_box("BeltLeg", Vector3(x, 0.36, z), Vector3(0.075, 0.72, 0.075), steel, true)
			stage_box("LegFoot", Vector3(x, 0.028, z), Vector3(0.20, 0.056, 0.17), steel)
	for x in [-2.47, 2.47]:
		stage_roller(Vector3(x, 0.80, 0), 0.115, 0.57, brass)
	for i in range(8):
		stage_roller(Vector3(-2.1 + i * 0.6, 0.78, 0), 0.06, 0.48, steel)
	for i in range(15):
		belt_marks.append(stage_box("BeltTread", Vector3(-2.6 + i * 5.2 / 15.0, 0.953, 0), Vector3(0.035, 0.005, 0.43), stage_material(Color("67777a"))))
	stage_label("FOLD", Vector3(-2.1, 0.71, 0.325), 0.0017, Color("f2efe5"))
	stage_label("PRINT", Vector3(-0.9, 0.71, 0.325), 0.0017, Color("f2efe5"))
	stage_label("SORT  >", Vector3(1.3, 0.71, 0.325), 0.0017, Color("f2efe5"))
	_build_net_rack(steel, cream, brass, ink)
	_build_printer(steel, cream, brass, ink)
	_build_basket(0, 0.50, "AGAIN", Color("f2efe5"), Color("cc473c"), steel)
	_build_basket(1, 1.65, "YET", Color("c5e2cf"), Color("167c79"), steel)
	_build_console(steel, cream, brass, ink)
	var lamp := OmniLight3D.new()
	lamp.name = "WorkLight"
	lamp.position = Vector3(-0.1, 2.9, 0.8)
	lamp.light_color = Color(1.0, 0.95, 0.85)
	lamp.light_energy = 0.6
	lamp.omni_range = 6.5
	lamp.shadow_enabled = false
	add_child(lamp)

func _build_net_rack(steel: Material, cream: Material, brass: Material, ink: Color) -> void:
	for z in [-0.53, 0.53]:
		stage_box("FoldUpright", Vector3(-2.35, 1.30, z), Vector3(0.07, 2.60, 0.07), steel, true)
		stage_box("FoldBrace", Vector3(-1.76, 2.58, z), Vector3(1.60, 0.07, 0.07), steel)
	stage_box("FoldHeader", Vector3(-1.70, 2.72, 0.555), Vector3(1.65, 0.28, 0.055), cream)
	stage_label("ONE NET / MANY CUBES", Vector3(-1.70, 2.72, 0.589), 0.00125, ink)
	stage_box("FoldMark", Vector3(-1.70, 2.555, 0.555), Vector3(1.65, 0.022, 0.055), brass)
	net = STAGE_NET.instantiate()
	net.name = "FeederNet"
	net.set("edge_length", 0.42)
	net.set("auto_fold", false)
	net.set("fall_cycle", false)
	net.set("loop_fold", false)
	net.set("face_color", Color("f2efe5"))
	net.set("edge_color", Color("c28b44"))
	# Keep even the fully open left flap clear of the hall's existing partition.
	net.position = Vector3(-1.80, 2.2, 0)
	# An exhibit's saved camera must never steal the museum or headset camera.
	for camera in net.find_children("*", "Camera3D", true, false):
		camera.get_parent().remove_child(camera)
		camera.free()
	add_child(net)

func _build_printer(steel: Material, cream: Material, brass: Material, ink: Color) -> void:
	for z in [-0.51, 0.51]:
		stage_box("PrinterPost", Vector3(-0.90, 0.88, z), Vector3(0.10, 1.76, 0.10), steel, true)
	stage_box("PrinterHead", Vector3(-0.90, 1.75, 0), Vector3(0.52, 0.22, 1.12), cream, true)
	stamp_visual = stage_box("StampHead", Vector3(-0.90, 1.59, 0), Vector3(0.32, 0.10, 0.46), brass)
	stage_label("TWO EDITIONS", Vector3(-0.90, 1.75, 0.567), 0.00105, ink)
	stage_box("PrintIndicator", Vector3(-0.90, 1.89, 0), Vector3(0.26, 0.04, 0.10), brass)

func _build_basket(index: int, x: float, word: String, paper: Color, accent: Color, steel: Material) -> void:
	# The +Z side stays open for the visitor. The basket's near rim sits
	# just beyond the narrower belt, rather than between the player and it.
	var at := Vector3(x, 0, -0.78)
	var tint := stage_material(paper)
	var stripe := stage_material(accent)
	stage_box(word + "BasketFloor", at + Vector3(0, 0.56, 0), Vector3(0.85, 0.08, 0.85), tint, true)
	# Rail colliders enclose a 0.74 m square; the open visual slats show the
	# small sorted cubes inside while the whole low wall retains physical cubes.
	for side in [-1.0, 1.0]:
		stage_solid(word + "WallX", at + Vector3(side * 0.3975, 0.81, 0), Vector3(0.055, 0.42, 0.85))
		stage_solid(word + "WallZ", at + Vector3(0, 0.81, side * 0.3975), Vector3(0.74, 0.42, 0.055))
		for y in [0.63, 0.79, 0.995]:
			stage_box("BasketRail", at + Vector3(side * 0.40, y, 0), Vector3(0.05, 0.045, 0.85), stripe)
			stage_box("BasketRail", at + Vector3(0, y, side * 0.40), Vector3(0.85, 0.045, 0.05), stripe)
		for other in [-1.0, 1.0]:
			stage_box("BasketLeg", at + Vector3(side * 0.3975, 0.51, other * 0.3975), Vector3(0.05, 1.02, 0.05), steel, true)
	# Raise the front-facing label at the rear of the cage so the belt does
	# not hide it and the open mouth stays free for the held delivery.
	stage_box("BasketPlaque", at + Vector3(0, 1.30, -0.405), Vector3(0.63, 0.23, 0.026), tint)
	stage_label(word, at + Vector3(0, 1.305, -0.388), 0.0020, accent)
	var marker: Node3D = STAGE_CARTON.instantiate()
	marker.name = word + "EditionSample"
	marker.set("word", word)
	marker.set("paper_color", paper)
	marker.set("accent_color", accent)
	marker.set("ink_color", Color("19333d"))
	marker.scale = Vector3.ONE * 0.30
	marker.position = at + Vector3(0, 1.55, -0.41)
	stage_box("SampleShelf", at + Vector3(0, 1.535, -0.41), Vector3(0.29, 0.03, 0.26), stripe)
	stage_box("SamplePost", at + Vector3(0, 1.06, -0.43), Vector3(0.03, 1.00, 0.03), steel)
	add_child(marker)
	var area := Area3D.new()
	area.name = word + "Basket"
	area.position = at + Vector3(0, 0.87, 0)
	area.collision_layer = 0
	area.collision_mask = 6
	area.monitorable = false
	area.set_meta("sort_kind", index)
	stage_collision(area, Vector3(0.74, 0.36, 0.74))
	add_child(area)
	baskets.append(area)

func _build_console(steel: Material, cream: Material, brass: Material, ink: Color) -> void:
	stage_box("ConsoleTop", Vector3(2.70, 0.96, 1.50), Vector3(1.06, 0.08, 0.65), steel, true)
	stage_box("ConsoleLeg", Vector3(2.70, 0.46, 1.50), Vector3(0.16, 0.92, 0.24), steel, true)
	stage_box("ConsoleFoot", Vector3(2.70, 0.025, 1.50), Vector3(0.65, 0.05, 0.55), steel)
	for index in range(2):
		var id: String = ["PAUSE", "RESET"][index]
		var button: Node3D = STAGE_PUSH.instantiate()
		button.name = id + "Button"
		# The shared scene faces forward by default; turn its cap upward for
		# this waist-height control surface, reachable by touch and pointer.
		button.rotation = Vector3.ZERO
		button.scale = Vector3.ONE * 1.65
		button.position = Vector3(2.47 + index * 0.46, 1.015, 1.48)
		button.set("released_color", Color("e5b66e") if index == 0 else Color("cc473c"))
		add_child(button)
		button.connect("pressed", Callable(self, "act").bind(id))
		buttons[id] = button
		var caption := stage_label(id, Vector3(button.position.x, 1.017, 1.68), 0.0011, Color("f2efe5"))
		caption.rotation_degrees.x = -90
	stage_box("ReadoutPanel", Vector3(2.70, 1.53, 1.18), Vector3(1.13, 0.63, 0.055), cream)
	stage_box("ReadoutPost", Vector3(2.70, 1.25, 1.13), Vector3(0.04, 0.65, 0.04), steel)
	stage_box("ReadoutStripe", Vector3(2.70, 1.845, 1.18), Vector3(1.13, 0.024, 0.06), brass)
	readout = stage_label("SORT THE CUBES", Vector3(2.70, 1.53, 1.218), 0.00082, ink)
	readout.name = "SortingReadout"
	stage_label("MATCH THE WORD + STRIPE", Vector3(1.10, 1.85, -1.17), 0.00115, ink)

func stage_material(color: Color, metal: float = 0.0) -> StandardMaterial3D:
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.62
	material.metallic = metal
	return material

func stage_box(title: String, at: Vector3, size: Vector3, material: Material, solid: bool = false) -> MeshInstance3D:
	var visual := MeshInstance3D.new()
	visual.name = title
	visual.position = at
	var mesh := BoxMesh.new()
	mesh.size = size
	visual.mesh = mesh
	visual.material_override = material
	add_child(visual)
	if solid:
		stage_solid(title + "Body", at, size)
	return visual

func stage_solid(title: String, at: Vector3, size: Vector3) -> StaticBody3D:
	var body := StaticBody3D.new()
	body.name = title
	body.position = at
	body.collision_layer = 1
	body.collision_mask = 0
	stage_collision(body, size)
	add_child(body)
	return body

func stage_collision(body: CollisionObject3D, size: Vector3) -> void:
	var collision := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collision.shape = shape
	body.add_child(collision)

func stage_label(words: String, at: Vector3, pixels: float, color: Color) -> Label3D:
	var label := Label3D.new()
	label.text = words
	label.position = at
	label.font_size = 42
	label.pixel_size = pixels
	label.modulate = color
	label.outline_size = 0
	add_child(label)
	return label

func stage_roller(at: Vector3, radius: float, length: float, material: Material) -> void:
	var roller := MeshInstance3D.new()
	roller.name = "BeltRoller"
	roller.position = at
	roller.rotation.x = PI * 0.5
	var mesh := CylinderMesh.new()
	mesh.top_radius = radius
	mesh.bottom_radius = radius
	mesh.height = length
	mesh.radial_segments = 16
	roller.mesh = mesh
	roller.material_override = material
	add_child(roller)

func act(_id: String) -> void:
	pass
