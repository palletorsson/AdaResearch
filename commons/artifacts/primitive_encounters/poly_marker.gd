extends XRToolsPickable
## Exact vertex-count specimens; the orange square pyramid is an association
## with a traffic cone, not a claim that a smooth cone has five vertices.
const Geometry = preload("geometry.gd")
@export_enum("pyramid","bipyramid") var form := "pyramid"
func _ready() -> void:
	super()
	freeze=true;release_mode=ReleaseMode.FROZEN;gravity_scale=0
	var points := PackedVector3Array()
	var faces: Array=[]
	if form=="pyramid":
		points=PackedVector3Array([Vector3(-.3,0,-.3),Vector3(.3,0,-.3),Vector3(.3,0,.3),Vector3(-.3,0,.3),Vector3(0,.9,0)])
		faces=[[0,3,2,1],[0,1,4],[1,2,4],[2,3,4],[3,0,4]]
	else:
		for i in 5:points.append(Vector3(cos(TAU*i/5)*.42,.45,sin(TAU*i/5)*.42))
		points.append(Vector3(0,.9,0));points.append(Vector3.ZERO)
		for i in 5:faces.append([i,(i+1)%5,5]);faces.append([(i+1)%5,i,6])
	var visible := MeshInstance3D.new();visible.name="ExactPolyhedron";visible.mesh=Geometry.mesh(points,faces)
	if form=="pyramid":
		# Metre-based UVs carry the band into both Godot and exported GLBs.
		var arrays := visible.mesh.surface_get_arrays(0)
		var uv := PackedVector2Array()
		for p: Vector3 in arrays[Mesh.ARRAY_VERTEX]:uv.append(Vector2(.5,p.y/.9))
		arrays[Mesh.ARRAY_TEX_UV]=uv
		var banded := ArrayMesh.new();banded.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays);visible.mesh=banded
		var gradient := Gradient.new()
		var orange := Color("ed4e16");var ivory := Color("f4efdf")
		gradient.offsets=PackedFloat32Array([0,.33,.34,.54,.55,1])
		gradient.colors=PackedColorArray([orange,orange,ivory,ivory,orange,orange])
		var texture := GradientTexture2D.new();texture.gradient=gradient;texture.width=8;texture.height=256
		texture.fill_from=Vector2.ZERO;texture.fill_to=Vector2(0,1)
		var finish := StandardMaterial3D.new();finish.albedo_texture=texture;finish.roughness=.48;visible.material_override=finish
	else:
		var finish := StandardMaterial3D.new();finish.albedo_color=Color("626e7d");finish.metallic=.35;finish.roughness=.28;visible.material_override=finish
	add_child(visible)
	var collision := CollisionShape3D.new();collision.name="ExactHull"
	var hull := ConvexPolygonShape3D.new();hull.points=points;collision.shape=hull;add_child(collision)
	set_meta("vertex_count",points.size());set_meta("face_count",faces.size())
