extends XRToolsPickable
## A rectangular sheet built from two triangles per face. Nominal dimensions
## stay exact; the visual edge has a small chamfer. Root = bottom-face centre.
const Timber = preload("timber_finish.gd")
@export var panel_size := Vector2.ONE
@export var thickness := .045
func _ready() -> void:
	super()
	freeze=true;release_mode=ReleaseMode.FROZEN;gravity_scale=0
	var size := Vector3(panel_size.x,thickness,panel_size.y)
	var visible := MeshInstance3D.new();visible.name="TimberSheet"
	visible.mesh=Timber.mesh(size);visible.material_override=Timber.material();visible.position.y=thickness/2;add_child(visible)
	var collision := CollisionShape3D.new();collision.name="PanelCollision"
	var shape := BoxShape3D.new();shape.size=size;collision.shape=shape;collision.position=visible.position;add_child(collision)
	# Four flush fixings are visual only; the nominal supporting sheet stays flat.
	var screws := SurfaceTool.new();screws.begin(Mesh.PRIMITIVE_TRIANGLES)
	var head := CylinderMesh.new();head.top_radius=.006;head.bottom_radius=.006;head.height=.0015;head.radial_segments=10
	for x in [-1,1]:
		for z in [-1,1]:
			screws.append_from(head,0,Transform3D(Basis.IDENTITY,Vector3(x*(size.x/2-.055),thickness+.0005,z*(size.z/2-.055))))
	var fixings := MeshInstance3D.new();fixings.name="FlushFixings";fixings.mesh=screws.commit()
	var metal := StandardMaterial3D.new();metal.albedo_color=Color("57554e");metal.metallic=.7;metal.roughness=.45;fixings.material_override=metal;add_child(fixings)
	set_meta("construction_dimensions",size)
	set_meta("insertion_anchor","bottom-face centre")
