extends Node3D
## Sculptural skull with carved eye/nasal cavities and separated teeth.
## Original procedural study; not a scan or an anatomical teaching specimen.
const G=preload("res://commons/artifacts/primitive_encounters/geometry.gd")
func _ready() -> void:
	var carving:=CSGCombiner3D.new();carving.name="CarvedBone";add_child(carving)
	var bone:=G.material(Color("d9d1b8"));bone.roughness=.8
	_sphere(carving,"Cranium",Vector3(0,.18,-.13),Vector3(.82,.9,.75),bone,false)
	_sphere(carving,"Face",Vector3(0,-.30,.39),Vector3(.68,.53,.48),bone,false)
	_sphere(carving,"Jaw",Vector3(0,-.77,.27),Vector3(.60,.24,.48),bone,false)
	for x in [-.31,.31]:
		_sphere(carving,"EyeSocket",Vector3(x,-.12,.76),Vector3(.255,.27,.45),bone,true)
	_sphere(carving,"NasalOpening",Vector3(0,-.46,.85),Vector3(.14,.22,.35),bone,true)
	var mouth:=CSGBox3D.new();mouth.name="MouthGap";mouth.size=Vector3(.88,.12,.6)
	mouth.position=Vector3(0,-.74,.65);mouth.operation=CSGShape3D.OPERATION_SUBTRACTION;carving.add_child(mouth)
	for i in 8:
		var x:float=(i-3.5)*.095;var z:float=.78-.45*x*x
		G.box(self,"UpperTooth",Vector3(x,-.66,z),Vector3(.080,.13,.105),bone.albedo_color,false)
		G.box(self,"LowerTooth",Vector3(x,-.85,z-.015),Vector3(.075,.10,.10),bone.albedo_color,false)
func _sphere(parent:Node3D,title:String,at:Vector3,radii:Vector3,mat:Material,subtract:bool) -> void:
	var shape:=CSGSphere3D.new();shape.name=title;shape.radius=1;shape.radial_segments=24;shape.rings=16
	shape.position=at;shape.scale=radii;shape.material=mat
	if subtract:shape.operation=CSGShape3D.OPERATION_SUBTRACTION
	parent.add_child(shape)
