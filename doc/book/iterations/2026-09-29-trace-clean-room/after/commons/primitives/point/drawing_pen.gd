extends XRToolsPickable
## A plain, ambidextrous drawing tool. Local -Z is the visible nib and aim.
## Board pens reuse build_body before entering the tree, so XRTools sees the grip.
var pen_color := Color.WHITE
var desktop_held := false

func _ready() -> void:
	build_body(self, pen_color)
	super()

func on_desktop_grab(_pointer: Node) -> void:
	desktop_held = true

func on_desktop_drop(_pointer: Node) -> void:
	desktop_held = false
	dropped.emit(self)

func is_drawing_ready() -> bool:
	return desktop_held or (is_picked_up() and _grab_driver.state == XRToolsGrabDriver.GrabState.SNAP)

static func build_body(pen: XRToolsPickable, color: Color) -> Marker3D:
	var barrel := CylinderMesh.new()
	barrel.top_radius = 0.012
	barrel.bottom_radius = 0.012
	barrel.height = 0.19
	barrel.radial_segments = 16
	part(pen, "Barrel", barrel, Vector3(0, 0, -0.025), color)
	var taper := CylinderMesh.new()
	taper.top_radius = 0.002
	taper.bottom_radius = 0.012
	taper.height = 0.035
	taper.radial_segments = 16
	part(pen, "Nib", taper, Vector3(0, 0, -0.1375), Color(0.08, 0.08, 0.09))
	var band := CylinderMesh.new()
	band.top_radius = 0.0125
	band.bottom_radius = 0.0125
	band.height = 0.045
	band.radial_segments = 16
	part(pen, "GripSleeve", band, Vector3(0, 0, -0.07), Color(0.19, 0.19, 0.20))
	var shape := CapsuleShape3D.new()
	shape.radius = 0.015
	shape.height = 0.22
	var collider := CollisionShape3D.new()
	collider.name = "CollisionShape3D"
	collider.shape = shape
	collider.rotation.x = PI / 2.0
	collider.position.z = -0.0375
	pen.add_child(collider)
	var nib := Marker3D.new()
	nib.name = "WritingTip"
	nib.position.z = -0.155
	pen.add_child(nib)
	# A general fixed grip works with both hands. No retained approach angle:
	# XRTools aligns this frame with the pickup's forward direction.
	var grip := XRToolsGrabPoint.new()
	grip.name = "WritingGrip"
	pen.add_child(grip)
	return nib

static func part(parent: Node3D, part_name: String, mesh: Mesh, at: Vector3, color: Color) -> void:
	var node := MeshInstance3D.new()
	node.name = part_name
	node.mesh = mesh
	node.position = at
	node.rotation.x = -PI / 2.0
	var material := StandardMaterial3D.new()
	material.albedo_color = color
	material.roughness = 0.55
	node.material_override = material
	parent.add_child(node)
