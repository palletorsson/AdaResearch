extends Node3D
## A spatial collection of real scene families. Sources remain unchanged.
## Cache batched display PackedScenes per source/configuration; copies share meshes,
## while every pickable has its own transform and physics state.
const CATALOG := "res://commons/artifacts/prefab_box_library/catalog.json"
const ROWS := 4
@export_range(1.1, 2.0, 0.01) var column_pitch: float = 1.48
const BASE := 0.22
const STEP := 0.87
@export var worktable_x: float = 2.45
@export var worktable_z: float = 2.35
var _worktable: Node3D
var items: Array[Node3D] = []
var homes: Array[Transform3D] = []
var cache: Dictionary = {}
var catalog: Dictionary
var _age := 0.0

func apply_grid_config(config: Dictionary) -> void:
	# Move the table independently so the full library can share a hall.
	if config.has("column_pitch") and not is_node_ready():
		column_pitch = clampf(float(config["column_pitch"]), 1.1, 2.0)
	if config.has("worktable_x"):
		worktable_x = float(config["worktable_x"])
	if config.has("worktable_z"):
		worktable_z = float(config["worktable_z"])
	if is_instance_valid(_worktable):
		_worktable.position = Vector3(worktable_x, 0, worktable_z)

func _ready() -> void:
	catalog=JSON.parse_string(FileAccess.get_file_as_string(CATALOG))
	var cream := material(Color(0.86,0.86,0.81),0.5,0.1)
	var steel := material(Color(0.045,0.052,0.065),0.32,0.65)
	var lettering := Color(0.045,0.052,0.065)
	var rack_width := 6.0 * column_pitch + 0.24
	var half_rack := rack_width * 0.5 - 0.01
	for row in range(ROWS+1):
		var y := BASE+row*STEP
		box("Shelf",Vector3(rack_width,0.065,1.04),Vector3(0,y-0.0325,0),cream)
		box("BackLip",Vector3(rack_width,0.085,0.028),Vector3(0,y+0.01,-0.515),steel)
	for x in [-half_rack,-half_rack/3.0,half_rack/3.0,half_rack]:
		for z in [-0.50,0.50]:box("Upright",Vector3(0.045,3.76,0.045),Vector3(x,1.88,z),steel)
	box("LibraryHeader",Vector3(rack_width,0.35,0.07),Vector3(0,3.98,0),cream)
	label("A LIBRARY OF BOXES",Vector3(-rack_width*0.285,3.98,0.041),0.0044,lettering,44)
	label("SAME SOURCE / ANOTHER ARRANGEMENT",Vector3(rack_width*0.225,3.98,0.041),0.0020,lettering,36)
	for column in catalog.columns.size():
		var definition: Dictionary=catalog.columns[column]
		var x := (float(column)-2.5)*column_pitch
		label(str(definition.label),Vector3(x,3.57,0.538),0.0014,lettering,32)
		for row in ROWS:
			var config: Dictionary=definition.base.duplicate(true)
			config.merge(definition.rows[row],true)
			var key := str(definition.source)+JSON.stringify(config)
			if not cache.has(key):cache[key]=bake_prefab(str(definition.source),config)
			var package: Dictionary=cache[key]
			var bounds: AABB=package.bounds
			var factor := minf(1.0,minf(0.99/bounds.size.x,minf(0.64/bounds.size.y,0.82/bounds.size.z)))
			var size := bounds.size*factor
			var body := XRToolsPickable.new();body.name="Box_%02d_%02d" % [column,row]
			body.collision_layer=6;body.collision_mask=7;body.freeze=true
			body.release_mode=XRToolsPickable.ReleaseMode.UNFROZEN
			body.mass=0.6;body.continuous_cd=true;body.linear_damp=0.2;body.angular_damp=0.4
			body.physics_material_override=PhysicsMaterial.new();body.physics_material_override.friction=0.8
			var visual: Node3D=package.scene.instantiate();visual.name="Prefab"
			visual.scale=Vector3.ONE*factor;visual.position=-bounds.get_center()*factor;body.add_child(visual)
			var collider := CollisionShape3D.new();collider.name="CollisionShape3D";var shape := BoxShape3D.new();shape.size=size
			collider.shape=shape;body.add_child(collider)
			body.set_meta("prefab_source",definition.source);body.set_meta("edition_key",key)
			body.set_meta("edition_config",config);body.set_meta("held",false)
			body.picked_up.connect(func(_body):body.set_meta("held",true))
			body.dropped.connect(func(_body):body.set_meta("held",false))
			add_child(body);body.position=Vector3(x,BASE+row*STEP+size.y*0.5+0.002,0)
			items.append(body);homes.append(body.transform)
	for x in [-3.0,0.0,3.0]:
		var light := OmniLight3D.new();light.position=Vector3(x,3.8,1.15)
		light.light_color=Color(1,0.94,0.84);light.light_energy=0.6;light.omni_range=5.0
		light.shadow_enabled=false;add_child(light)
	# The empty worktop gives taking a copy down a destination.
	_worktable = Node3D.new();_worktable.name = "Worktable"
	_worktable.position = Vector3(worktable_x, 0, worktable_z);add_child(_worktable)
	box("Worktop",Vector3(2.7,0.07,1.05),Vector3(0,0.74,0),cream,_worktable)
	for x in [-1.18,1.18]:
		for z in [-0.41,0.41]:box("TableLeg",Vector3(0.045,0.71,0.045),Vector3(x,0.355,z),steel,_worktable)
	label("TAKE A COPY. MAKE ANOTHER ARRANGEMENT.",Vector3(0,0.732,0.531),0.0018,lettering,32,_worktable)
	label("REPETITION IS MATERIAL",Vector3(-2.2,0.12,0.55),0.0022,lettering,34)

func _physics_process(delta: float) -> void:
	_age+=delta
	if _age<1:return
	_age=0
	for i in items.size():
		var item: RigidBody3D=items[i]
		if item.get_meta("held",false):continue
		var local := to_local(item.global_position)
		if local.y < -2 or local.length()>25:
			item.freeze=true;item.linear_velocity=Vector3.ZERO;item.angular_velocity=Vector3.ZERO
			item.global_transform=global_transform*homes[i]

func bake_prefab(path: String, config: Dictionary) -> Dictionary:
	var source: Node3D=load(path).instantiate()
	# Apply exported values before _ready constructs the authored geometry.
	for key in config:
		var value: Variant=config[key]
		if source.get(key) is Color:value=Color(str(value))
		source.set(key,value)
	add_child(source)
	var baked := Node3D.new();baked.name="LibraryEdition"
	var surfaces: Dictionary={}
	var bounds := AABB();var first := true
	var meshes := source.find_children("*","MeshInstance3D",true,false)
	for node: MeshInstance3D in meshes:
		if node.mesh==null:continue
		var transform_to_source: Transform3D=source.global_transform.affine_inverse()*node.global_transform
		var bound: AABB=transform_to_source*node.mesh.get_aabb()
		bounds=bound if first else bounds.merge(bound);first=false
		for surface in node.mesh.get_surface_count():
			var mat: Material=node.get_active_material(surface)
			var id: int=mat.get_instance_id() if mat!=null else 0
			if not surfaces.has(id):
				var st := SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES);st.set_material(mat)
				surfaces[id]=st
			var st: SurfaceTool=surfaces[id]
			st.append_from(node.mesh,surface,transform_to_source)
	var geometry := MeshInstance3D.new();geometry.name="BatchedGeometry"
	var mesh := ArrayMesh.new()
	for st: SurfaceTool in surfaces.values():st.commit(mesh)
	geometry.mesh=mesh;baked.add_child(geometry);geometry.owner=baked
	for original: Label3D in source.find_children("*","Label3D",true,false):
		var copy: Label3D=original.duplicate();copy.set_script(null)
		copy.transform=source.global_transform.affine_inverse()*original.global_transform
		copy.no_depth_test=false;baked.add_child(copy);copy.owner=baked
	baked.set_meta("source_scene",path)
	var packed := PackedScene.new();var result := packed.pack(baked)
	assert(result==OK,"Cannot pack library edition: "+path)
	remove_child(source);source.queue_free();baked.free()
	return {"scene":packed,"bounds":bounds,"source_meshes":meshes.size(),"surfaces":mesh.get_surface_count()}

func material(colour: Color, roughness: float, metal: float) -> StandardMaterial3D:
	var m := StandardMaterial3D.new();m.albedo_color=colour;m.roughness=roughness;m.metallic=metal;return m

func box(title: String,size: Vector3,at: Vector3,mat: Material,parent: Node3D = null) -> void:
	var body := StaticBody3D.new();body.name=title;body.position=at;body.collision_layer=1;body.collision_mask=0
	var visual := MeshInstance3D.new();var mesh := BoxMesh.new();mesh.size=size;visual.mesh=mesh;visual.material_override=mat
	var collision := CollisionShape3D.new();var shape := BoxShape3D.new();shape.size=size;collision.shape=shape
	body.add_child(visual);body.add_child(collision)
	if parent == null:parent = self
	parent.add_child(body)

func label(words: String,at: Vector3,pixel: float,colour: Color,font: int,parent: Node3D = null) -> void:
	var text := Label3D.new();text.text=words;text.position=at;text.pixel_size=pixel;text.font_size=font
	text.modulate=colour;text.outline_size=0
	if parent == null:parent = self
	parent.add_child(text)
