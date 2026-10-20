extends RefCounted
## A fixed glass finish. It consumes no values from the exhibit's random stream.
static var _transmission: ImageTexture
static var _normal: NoiseTexture2D

static func material() -> StandardMaterial3D:
	if _transmission==null:
		var image:=Image.create(1,1,false,Image.FORMAT_RGBA8)
		image.set_pixel(0,0,Color(1,1,1,0.46))
		_transmission=ImageTexture.create_from_image(image)
		var noise:=FastNoiseLite.new()
		noise.seed=83
		noise.frequency=0.075
		_normal=NoiseTexture2D.new()
		_normal.width=128;_normal.height=128
		_normal.noise=noise
		_normal.as_normal_map=true
		_normal.bump_strength=0.65
	var mat:=StandardMaterial3D.new()
	mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	mat.cull_mode=BaseMaterial3D.CULL_DISABLED
	# Keep albedo RGB as the exact three draws. The shared texture supplies alpha.
	mat.albedo_texture=_transmission
	mat.roughness=0.23
	mat.metallic_specular=0.75
	mat.normal_enabled=true
	mat.normal_texture=_normal
	mat.normal_scale=0.45
	return mat

static func frame(parent: Node3D, centre: Vector3, width: float, height: float, cols: int, rows: int, step: Vector2, cell: Vector2, floor_supports: bool = true) -> void:
	var stage=load("res://commons/artifacts/randomness_space/museum_exhibit_stage.gd")
	var outer:=Color("30271f")
	var lead:=Color("242622")
	for side in [-1,1]:
		stage.box(parent,centre+Vector3(side*(width+0.042)*0.5,0,0),Vector3(0.042,height+0.084,0.12),outer)
		stage.box(parent,centre+Vector3(0,side*(height+0.042)*0.5,0),Vector3(width,0.042,0.12),outer)
		var foot_height:=maxf(0.0,centre.y-height*0.5-0.042)
		if floor_supports and foot_height>0.05:
			stage.box(parent,Vector3(centre.x+side*(width+0.042)*0.5,foot_height*0.5,centre.z),Vector3(0.042,foot_height,0.12),outer,true)
	for x in range(1,cols):
		var at:=centre+Vector3(-width*0.5+cell.x+(x-1)*step.x+(step.x-cell.x)*0.5,0,0)
		stage.box(parent,at,Vector3(step.x-cell.x+0.003,height,0.024),lead)
	for y in range(1,rows):
		var at:=centre+Vector3(0,-height*0.5+cell.y+(y-1)*step.y+(step.y-cell.y)*0.5,0)
		stage.box(parent,at,Vector3(width,step.y-cell.y+0.003,0.024),lead)
	# The window is solid, but its surface remains transparent from either side.
	var body:=StaticBody3D.new()
	body.collision_layer=1;body.collision_mask=0
	body.position=centre
	var collision:=CollisionShape3D.new()
	var shape:=BoxShape3D.new()
	shape.size=Vector3(width,height,0.025)
	collision.shape=shape
	body.add_child(collision)
	parent.add_child(body)
