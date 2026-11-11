extends Node3D
## A 3.0 m floor-to-ceiling polythene dust curtain on a batten between two telescopic poles. Sheet faces +Z.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
const TarpShader := preload("res://commons/artifacts/construction_site/tarp.gdshader")

func _ready() -> void:
	var timber := Stock.finish("9b8f78", .95)
	var steel := Stock.finish("899599", .45, .72)
	var dark := Stock.finish("343b3d", .8, .2)
	Stock.box(self,"Batten",Vector3(0,5.525,0),Vector3(3.1,.05,.07),timber)
	for x in [-1.52,1.52]:
		var z := -.075
		Stock.box(self,"FootPad",Vector3(x,.01,z),Vector3(.12,.02,.12),dark)
		Stock.box(self,"HeadPad",Vector3(x,5.59,z),Vector3(.10,.02,.10),dark)
		Stock.tube(self,"PoleOuter",Vector3(x,.02,z),Vector3(x,3.0,z),.02,steel)
		Stock.tube(self,"PoleInner",Vector3(x,2.9,z),Vector3(x,5.58,z),.015,steel)
		Stock.tube(self,"Twist",Vector3(x,2.96,z),Vector3(x,3.04,z),.03,dark,false)
		Stock.box(self,"BattenClamp",Vector3(x,5.525,-.04),Vector3(.07,.08,.08),dark,false)
	# The sheet: folds from a sine across x that deepen toward the hem.
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := 16
	var rows := 14
	for row in range(rows):
		for column in range(columns):
			for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
				var uv := Vector2(float(column+corner.x)/columns,float(row+corner.y)/rows)
				surface.set_uv(uv)
				var fold: float = sin(uv.x*TAU*5.0)*(.008+.05*uv.y) + sin(uv.x*TAU*2.0+1.3)*.02*uv.y
				surface.add_vertex(Vector3(lerpf(-1.5,1.5,uv.x),lerpf(5.50,.08,uv.y),.06+fold))
	surface.generate_normals()
	var cloth := MeshInstance3D.new()
	cloth.name = "Sheet"
	cloth.mesh = surface.commit()
	var cloth_material := ShaderMaterial.new()
	cloth_material.shader = TarpShader
	cloth_material.set_shader_parameter("base_color", Color("cfd4d2"))
	cloth_material.set_shader_parameter("wind_amplitude", .03)
	cloth_material.set_shader_parameter("wind_speed", .25)
	cloth.material_override = cloth_material
	cloth.extra_cull_margin = .06
	add_child(cloth)
	var back := BoxShape3D.new()
	back.size = Vector3(2.9,5.4,.05)
	var stop := Node3D.new()
	stop.name = "SheetBacking"
	stop.position = Vector3(0,2.8,-.015)
	add_child(stop)
	Stock.collision(stop,back)
	Stock.box(self,"Tape",Vector3(0,5.475,.072),Vector3(3.0,.05,.004),dark,false)
	Stock.batch_static(self)
