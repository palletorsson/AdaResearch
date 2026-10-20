extends Node3D
## One 3.2 m scaffold bay: open front, side braces, planked deck and tied rear tarp.
const Stock := preload("res://commons/artifacts/construction_site/stock.gd")
const TarpShader := preload("res://commons/artifacts/construction_site/tarp.gdshader")

func _ready() -> void:
	var steel := Stock.finish("929fa3", .43, .78)
	var dark := Stock.finish("3d464b", .6, .65)
	var timber := Stock.finish("9b8f78", .95)
	for x in [-1.49,1.49]:
		for z in [-.52,.52]:
			Stock.box(self,"SoleBoard",Vector3(x,.035,z),Vector3(.22,.07,.28),timber)
			Stock.box(self,"BasePlate",Vector3(x,.08,z),Vector3(.15,.025,.15),steel)
			Stock.tube(self,"JackScrew",Vector3(x,.08,z),Vector3(x,.27,z),.023,dark)
			Stock.tube(self,"Upright",Vector3(x,.20,z),Vector3(x,3.48,z),.025,steel)
			for y in [1.05,2.29,3.31]:
				Stock.tube(self,"Coupler",Vector3(x,y-.035,z),Vector3(x,y+.035,z),.043,dark,false)
		for y in [.35,1.05,2.29,2.81,3.31]:
			Stock.tube(self,"EndRail",Vector3(x,y,-.52),Vector3(x,y,.52),.025,steel)
		Stock.tube(self,"DiagonalBrace",Vector3(x,.35,.52),Vector3(x,2.29,-.52),.019,steel)
	for z in [-.52,.52]:
		for y in [2.29,2.81,3.31]: Stock.tube(self,"Ledger",Vector3(-1.49,y,z),Vector3(1.49,y,z),.025,steel)
		Stock.box(self,"ToeBoard",Vector3(0,2.48,z),Vector3(2.96,.16,.035),timber)
	for i in range(4):
		var plank := Stock.box(self,"DeckPlank",Vector3(0,2.36,-.39+i*.26),Vector3(3.13,.07,.245),timber)
		for x in [-1.37,1.37]:
			Stock.box(plank,"EndBand",Vector3(x,.037,0),Vector3(.06,.005,.245),dark,false)
	var surface := SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	var columns := 24
	var rows := 20
	for row in range(rows):
		for column in range(columns):
			for corner in [Vector2i(0,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,1)]:
				var uv := Vector2(float(column+corner.x)/columns,float(row+corner.y)/rows)
				surface.set_uv(uv)
				var fold := sin(uv.x*TAU*7)*.027*sin(uv.y*PI/2)
				surface.add_vertex(Vector3(lerpf(-1.42,1.42,uv.x),lerpf(3.27,.38,uv.y)-.07*sin(uv.x*PI),-.57+fold))
	surface.generate_normals()
	var cloth := MeshInstance3D.new()
	cloth.name = "Tarp"
	cloth.mesh = surface.commit()
	var cloth_material := ShaderMaterial.new()
	cloth_material.shader = TarpShader
	cloth_material.set_shader_parameter("base_color", Color("394964"))
	cloth_material.set_shader_parameter("wind_amplitude", .045)
	cloth_material.set_shader_parameter("wind_speed", .32)
	cloth.material_override = cloth_material
	cloth.extra_cull_margin = .08
	add_child(cloth)
	var back := BoxShape3D.new()
	back.size = Vector3(2.84,2.84,.06)
	var stop := Node3D.new()
	stop.name = "TarpBacking"
	stop.position = Vector3(0,1.82,-.57)
	add_child(stop)
	Stock.collision(stop,back)
	for i in range(7):
		var x := -1.38+i*.46
		var ring := MeshInstance3D.new()
		var torus := TorusMesh.new()
		torus.inner_radius = .018
		torus.outer_radius = .029
		torus.rings = 12
		torus.ring_segments = 6
		ring.mesh = torus
		ring.material_override = steel
		ring.position = Vector3(x,3.20,-.575)
		ring.rotation_degrees.x = 90
		add_child(ring)
		Stock.tube(self,"TarpTie",Vector3(x,3.20,-.59),Vector3(x,3.33,-.52),.006,dark,false)
	Stock.batch_static(self)
