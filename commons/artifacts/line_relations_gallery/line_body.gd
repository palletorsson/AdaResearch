extends XRToolsPickable
## A segment acquires a body. Endpoints stay explicit while the visible skin varies.
## This luminous skin is a mesh, not a simulated laser. All skins retain pickup.
@export_enum("stick", "plank", "light", "measure", "beam", "point_line") var skin: String = "stick"
@export var span: float = 2.0
const ENDPOINT_RADIUS := 0.085
const Timber = preload("res://commons/artifacts/primitive_encounters/timber_finish.gd")
var body_size: Vector3

func _ready() -> void:
	super()
	freeze = true
	release_mode = ReleaseMode.FROZEN
	gravity_scale = 0.0
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color("202329")
	mat.roughness = 0.6
	body_size = Vector3(span,0.055,0.055)
	match skin:
		"plank":
			body_size = Vector3(span,0.06,0.25)
			mat.albedo_color = Color("a97a49")
		"beam":
			body_size = Vector3(span,0.14,0.14)
			mat.metallic = 0.65
			mat.roughness = 0.4
		"measure":
			body_size = Vector3(span,0.16,0.045)
			mat.albedo_color = Color("e5daca")
		"light":
			body_size = Vector3(span,0.032,0.032)
			mat.albedo_color = Color("ed91bd")
			mat.emission_enabled = true
			mat.emission = mat.albedo_color
			mat.emission_energy_multiplier = 1.0
		"point_line":
			body_size = Vector3(span,0.038,0.038)
			mat.albedo_color = Color("ec8fba")
			mat.roughness = 0.32
			mat.emission_enabled = true
			mat.emission = Color("bb517f")
			mat.emission_energy_multiplier = 0.35
	var mesh := MeshInstance3D.new()
	mesh.name = "Skin"
	if skin == "point_line":
		var cylinder := CylinderMesh.new()
		cylinder.top_radius=0.019;cylinder.bottom_radius=0.019
		cylinder.height=span;cylinder.radial_segments=16
		mesh.mesh=cylinder;mesh.rotation.z=PI*0.5
	else:
		var box := BoxMesh.new();box.size=body_size;mesh.mesh=box
	mesh.material_override=mat;add_child(mesh)
	if skin=="plank":
		mesh.mesh=Timber.mesh(body_size);mesh.material_override=Timber.material()
	var col := CollisionShape3D.new();col.name="PickupBody"
	var shape := BoxShape3D.new()
	shape.size=body_size if skin=="plank" else Vector3(span,maxf(body_size.y,0.07),maxf(body_size.z,0.07))
	col.shape=shape;add_child(col)
	if skin == "point_line":
		var white := StandardMaterial3D.new()
		white.albedo_color=Color("f5f1e9");white.roughness=0.38
		for i in range(2):
			var end := MeshInstance3D.new()
			end.name="EndpointA" if i==0 else "EndpointB"
			var sphere := SphereMesh.new()
			sphere.radius=ENDPOINT_RADIUS;sphere.height=ENDPOINT_RADIUS*2
			sphere.radial_segments=24;sphere.rings=12
			end.mesh=sphere;end.material_override=white
			end.position.x=(-0.5 if i==0 else 0.5)*span;add_child(end)
			var boundary := CollisionShape3D.new()
			boundary.name="EndpointBoundaryA" if i==0 else "EndpointBoundaryB"
			var ball := SphereShape3D.new();ball.radius=ENDPOINT_RADIUS
			boundary.shape=ball;boundary.position=end.position;add_child(boundary)
	if skin == "measure":
		var ink := StandardMaterial3D.new();ink.albedo_color=Color("202329")
		for i in range(int(round(span*10.0))+1):
			var tick := MeshInstance3D.new();var mark := BoxMesh.new()
			mark.size=Vector3(0.008,0.13 if i%5==0 else 0.07,0.003)
			tick.mesh=mark;tick.material_override=ink
			tick.position=Vector3(-span*0.5+i*0.1,0,-0.024);add_child(tick)

func endpoints() -> Array[Vector3]:
	return [to_global(Vector3(-span*0.5,0,0)),to_global(Vector3(span*0.5,0,0))]
