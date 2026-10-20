extends Node3D
## One labelled position, with independently authored visual and bodily conditions.
## The held variant reuses the museum's existing XR/desktop pickable point.
@export_enum("absent", "visible", "solid", "held", "pedestal") var condition: String = "absent"
const RADIUS := 0.14
const HELD_RADIUS := 0.07
const CENTRE := Vector3(0, 1.12, 0)
const PICKABLE := preload("res://commons/primitives/point/interactive_point_origin.tscn")
var point: Node3D

func _ready() -> void:
	var label := Label3D.new()
	label.name = "PointOneLabel"
	label.text = "Point one"
	label.font_size = 48
	label.pixel_size = 0.0018
	label.modulate = Color(0.12, 0.12, 0.14)
	label.outline_size = 0
	label.no_depth_test = false
	label.position = Vector3(0, 0.68, 0.17)
	add_child(label)
	if condition == "absent":
		# The empty first marker keeps its support. The visible/solid comparison
		# has no support: only the sphere's added collider may stop the body.
		_make_pedestal(Vector3(0.82, CENTRE.y - RADIUS, 0.82), "PointPlinth")
		label.position = Vector3(0, 0.68, 0.421)
	elif condition in ["visible", "solid"]:
		label.position = Vector3(0, 0.012, 0.48)
		label.rotation.x = -PI / 2.0
	if condition == "absent":
		return
	if condition == "held":
		var held := PICKABLE.instantiate() as Node3D
		held.name = "HeldPoint"
		held.position = CENTRE
		held.set("coordinate_id", "point_one_main")
		held.set("finish", "dark")
		held.get_node("MeshInstance3D/Sphere").set("radius", HELD_RADIUS)
		var shape := SphereShape3D.new()
		shape.radius = HELD_RADIUS
		held.get_node("CollisionShape3D").set("shape", shape)
		add_child(held)
		# The lesson's black sphere stays black on pickup; the inherited coordinate
		# label, haptics and pickup signals still respond. No force-morph is added.
		held.get_node("MeshInstance3D").set("material_override", material(Color(0.008, 0.008, 0.012)))
		held.get_node("MeshInstance3D/OmniLight3D").set("light_energy", 0.0)
		point = held
		return
	var radius: float = 0.65 if condition == "pedestal" else RADIUS
	var centre: Vector3 = Vector3(0, 1.40, 0) if condition == "pedestal" else CENTRE
	var body := MeshInstance3D.new()
	body.name = "VisiblePoint"
	var sphere := SphereMesh.new()
	sphere.radius = radius
	sphere.height = radius * 2.0
	sphere.radial_segments = 48
	sphere.rings = 24
	body.mesh = sphere
	body.material_override = _future_material() if condition == "pedestal" else material(Color(0.97, 0.97, 0.95))
	body.position = centre
	add_child(body)
	point = body
	if condition in ["solid", "pedestal"]:
		var solid := StaticBody3D.new()
		solid.name = "PointCollision"
		solid.position = centre
		solid.collision_layer = 1
		var collider := CollisionShape3D.new()
		var sphere_shape := SphereShape3D.new()
		sphere_shape.radius = radius
		collider.shape = sphere_shape
		solid.add_child(collider)
		add_child(solid)
	if condition == "pedestal":
		_make_pedestal(Vector3(0.94, 0.75, 0.94), "Pedestal")
		label.position = Vector3(0, 0.49, 0.481)

func apply_grid_config(config: Dictionary) -> void:
	# The Void requests supports for its three-point display. The source
	# corridor keeps its unsupported visible/solid comparison by default.
	if condition not in ["absent", "visible", "solid"]: return
	var supported := bool(config.get("study_plinth", condition == "absent"))
	var pedestal := get_node_or_null("PointPlinth")
	if supported and pedestal == null:
		_make_pedestal(Vector3(0.82, CENTRE.y - RADIUS, 0.82), "PointPlinth")
	elif not supported and pedestal != null:
		pedestal.free()
	var label := get_node("PointOneLabel") as Label3D
	label.position = Vector3(0, 0.68, 0.421) if supported else Vector3(0, 0.012, 0.48)
	label.rotation.x = 0.0 if supported else -PI / 2.0

func _make_pedestal(size: Vector3, node_name: String) -> void:
	var pedestal := MeshInstance3D.new()
	pedestal.name = node_name
	var box := BoxMesh.new()
	box.size = size
	pedestal.mesh = box
	pedestal.position.y = size.y * 0.5
	var finish := material(Color(0.90, 0.895, 0.875))
	finish.roughness = 0.82
	pedestal.material_override = finish
	add_child(pedestal)
	var base := StaticBody3D.new()
	base.name = "PlinthCollision"
	base.collision_layer = 1
	var collider := CollisionShape3D.new()
	var shape := BoxShape3D.new()
	shape.size = size
	collider.shape = shape
	base.add_child(collider)
	pedestal.add_child(base)

func _future_material() -> StandardMaterial3D:
	var finish := material(Color(0.008, 0.009, 0.014))
	finish.roughness = 0.085
	finish.metallic_specular = 0.75
	finish.clearcoat_enabled = true
	finish.clearcoat = 0.8
	finish.clearcoat_roughness = 0.06
	return finish

func material(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color = colour
	mat.roughness = 0.32
	return mat
