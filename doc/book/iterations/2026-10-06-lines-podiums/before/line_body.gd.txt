extends XRToolsPickable
## A segment acquires a body. Endpoints stay explicit while the visible skin varies.
## This luminous skin is a mesh, not a simulated laser. All skins retain pickup.
@export_enum("stick", "plank", "light", "measure", "beam") var skin: String = "stick"
@export var span: float = 2.0
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
			body_size = Vector3(span,0.12,0.25)
			mat.albedo_color = Color("a97a49")
		"beam": body_size = Vector3(span,0.14,0.14)
		"measure":
			body_size = Vector3(span,0.06,0.16)
			mat.albedo_color = Color("dac393")
		"light":
			body_size = Vector3(span,0.022,0.022)
			mat.albedo_color = Color("fff5d8")
			mat.emission_enabled = true
			mat.emission = mat.albedo_color
			mat.emission_energy_multiplier = 1.0
	var mesh := MeshInstance3D.new()
	mesh.name = "Skin"
	var box := BoxMesh.new();box.size=body_size;mesh.mesh=box
	mesh.material_override=mat;add_child(mesh)
	var col := CollisionShape3D.new();col.name="PickupBody"
	var shape := BoxShape3D.new()
	shape.size=Vector3(span,maxf(body_size.y,0.07),maxf(body_size.z,0.07))
	col.shape=shape;add_child(col)
	if skin == "measure":
		var ink := StandardMaterial3D.new();ink.albedo_color=Color("202329")
		for i in range(int(round(span*10.0))+1):
			var tick := MeshInstance3D.new();var mark := BoxMesh.new()
			mark.size=Vector3(0.008,0.004,0.13 if i%10==0 else 0.07)
			tick.mesh=mark;tick.material_override=ink
			tick.position=Vector3(-span*0.5+i*0.1,0.032,0);add_child(tick)

func endpoints() -> Array[Vector3]:
	return [to_global(Vector3(-span*0.5,0,0)),to_global(Vector3(span*0.5,0,0))]
