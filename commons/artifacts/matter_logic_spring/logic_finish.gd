extends RefCounted
## The construction kit's chamfered timber, with quiet steel fittings.
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
static var timber: StandardMaterial3D
static var steel: StandardMaterial3D
static func wood() -> StandardMaterial3D:
	if timber==null:
		timber = Timber.material().duplicate();timber.albedo_color = Color("d5ba97");timber.roughness = .58
	return timber
static func metal() -> StandardMaterial3D:
	if steel==null:
		steel = StandardMaterial3D.new();steel.albedo_color = Color("282c36");steel.metallic = .55;steel.roughness = .42
	return steel
static func bolts(host: Node3D,points: Array[Vector3]) -> void:
	var bolt := CylinderMesh.new();bolt.top_radius = .009;bolt.bottom_radius = .009;bolt.height = .006;bolt.radial_segments = 8
	var mm := MultiMesh.new();mm.transform_format = MultiMesh.TRANSFORM_3D;mm.mesh = bolt;mm.instance_count = points.size()
	for i in points.size():mm.set_instance_transform(i,Transform3D(Basis.IDENTITY,points[i]))
	var fitting := MultiMeshInstance3D.new();fitting.name = "RecessedSteelFasteners";fitting.multimesh = mm;fitting.material_override = metal();host.add_child(fitting)
