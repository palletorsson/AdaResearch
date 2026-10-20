extends "res://commons/artifacts/fence_segment/fence_segment.gd"
## The existing chain-link prefab, fitted to the puzzle's moving door.
const FONT = preload("res://commons/font/static/Roboto_Condensed-Bold.ttf")

func _ready() -> void:
	fence_width = 1.8; fence_height = 2.6
	cols = 1; rows = 1; tube_radius = .03; show_razor = false
	super._ready()
	var sign := Node3D.new(); sign.name = "DangerSign"
	sign.position = Vector3(0,1.62,.045); add_child(sign)
	plate(sign,Vector3.ZERO,Vector3(1.16,.86,.018),Color("f5f3eb"))
	plate(sign,Vector3(0,.237,.012),Vector3(1.10,.31,.005),Color("17191c"))
	var oval := MeshInstance3D.new(); oval.name = "RedOval"
	var mesh := CylinderMesh.new()
	mesh.top_radius = 1; mesh.bottom_radius = 1; mesh.height = .005; mesh.radial_segments = 64
	oval.mesh = mesh; oval.rotation.x = PI/2; oval.scale = Vector3(.5,1,.13)
	oval.position = Vector3(0,.237,.018); oval.material_override = ink(Color("d9201b"));sign.add_child(oval)
	lettering(sign,"DANGER",Vector3(0,.237,.025),72,.0025,Color.WHITE)
	lettering(sign,"DO NOT ENTER",Vector3(0,-.01,.02),54,.0020,Color("141518"))
	plate(sign,Vector3(0,-.105,.014),Vector3(1.02,.008,.005),Color("141518"))
	lettering(sign,"AUTHORIZED\nPERSONNEL ONLY",Vector3(0,-.245,.02),42,.0019,Color("141518"))
	# Four fixings make this a plate attached to the mesh, rather than floating text.
	for x in [-.54,.54]:
		for y in [-.39,.39]:
			var fixing := MeshInstance3D.new(); var bolt := CylinderMesh.new()
			bolt.top_radius=.012;bolt.bottom_radius=.012;bolt.height=.018;bolt.radial_segments=8
			fixing.mesh=bolt;fixing.rotation.x=PI/2;fixing.position=Vector3(x,y,.014)
			fixing.material_override=_make_steel_mat(frame_color);sign.add_child(fixing)

func _build_chainlink_panel() -> void:
	# Keep the original frame, but use thin real wire instead of its flat texture.
	# Two clipped diagonal families share one mesh/draw call and have real holes.
	var poses: Array[Transform3D] = []
	var half := fence_width*.5-tube_radius
	var low := tube_radius; var high := fence_height-tube_radius
	for slope in [-1.0,1.0]:
		for step in range(floori((low-half)/.16),ceili((high+half)/.16)+1):
			var intercept := step*.16
			var ends: Array[Vector3] = []
			for x in [-half,half]:
				var y: float=slope*x+intercept
				if y>=low and y<=high: ends.append(Vector3(x,y,slope*.003))
			for y in [low,high]:
				var x: float=(y-intercept)/slope
				if x>=-half and x<=half: ends.append(Vector3(x,y,slope*.003))
			if ends.size()<2 or ends[0].distance_to(ends[1])<.001: continue
			var offset := ends[1]-ends[0]
			var basis := Basis(Quaternion(Vector3.UP,offset.normalized()))
			basis.y *= offset.length()
			poses.append(Transform3D(basis,(ends[0]+ends[1])*.5))
	var wire := CylinderMesh.new()
	wire.top_radius=.0035;wire.bottom_radius=.0035;wire.height=1;wire.radial_segments=8;wire.rings=0
	wire.material=_make_steel_mat(mesh_color)
	var panel := MultiMeshInstance3D.new();panel.name="ChainLinkPanel"
	panel.multimesh=MultiMesh.new();panel.multimesh.transform_format=MultiMesh.TRANSFORM_3D
	panel.multimesh.mesh=wire;panel.multimesh.instance_count=poses.size()
	for i in range(poses.size()): panel.multimesh.set_instance_transform(i,poses[i])
	panel.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	add_child(panel)

func ink(colour: Color) -> StandardMaterial3D:
	var mat := StandardMaterial3D.new()
	mat.albedo_color=colour;mat.roughness=1;mat.metallic_specular=0
	mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return mat

func plate(parent: Node3D, at: Vector3, size: Vector3, colour: Color) -> void:
	var node := MeshInstance3D.new(); var mesh := BoxMesh.new()
	mesh.size=size;node.mesh=mesh;node.material_override=ink(colour);node.position=at;parent.add_child(node)

func lettering(parent: Node3D, text: String, at: Vector3, size: int, pixel: float, colour: Color) -> void:
	var label := Label3D.new()
	label.text=text;label.font=FONT;label.font_size=size;label.pixel_size=pixel
	label.modulate=colour;label.outline_size=0;label.position=at;parent.add_child(label)
