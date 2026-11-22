extends Node3D
## Capture the existing native prefab once. Geometry is normalized exactly like
## the Three.js source snapshots. Literal boxes use matching solid box shapes;
## other meshes retain their triangles. Separate frame bars keep openings clear.
const Steel = preload("res://commons/void/steel_module.gd")
const Finishes=preload("construction_materials.gd")
const Workshop=preload("res://commons/artifacts/scaffold_workstation/geometry.gd")
const WorkshopModel=preload("res://commons/artifacts/scaffold_workstation/model.gd")
const FittedWorkshop=preload("res://commons/artifacts/scaffold_workstation/fitted_geometry.gd")
const BauhausWorkshop=preload("res://commons/artifacts/scaffold_workstation/bauhaus_kit.gd")
var phase:="monochrome"
var cache: Dictionary = {}
var finishes: Dictionary = {}

func material(color: String) -> StandardMaterial3D:
	if finishes.has(color):return finishes[color]
	var mat := StandardMaterial3D.new()
	mat.albedo_color=Color(color);mat.roughness=.65
	finishes[color]=mat
	return mat

func box(host: Node3D, size: Vector3, at: Vector3, color: String) -> void:
	var mesh:=MeshInstance3D.new();var geometry:=BoxMesh.new();geometry.size=size
	mesh.mesh=geometry;mesh.position=at;mesh.material_override=material(color);host.add_child(mesh)

func source(key: String) -> Dictionary:
	if cache.has(key): return cache[key]
	var original: Node3D
	if key.begins_with("scaffold_"):
		original=Steel.new();original.kind=key;original.material_phase=phase
	elif key=="box": original=load("res://commons/artifacts/primitive_encounters/platform_block.tscn").instantiate()
	elif key=="crate": original=load("res://commons/artifacts/crate/crate.tscn").instantiate()
	elif key=="wedge": original=load("res://commons/artifacts/primitive_encounters/wedge_blocker.tscn").instantiate()
	elif key=="platform": original=load("res://commons/artifacts/primitive_encounters/timber_panel_2x2.tscn").instantiate()
	elif key=="plank": original=load("res://commons/artifacts/primitive_encounters/timber_plank_2m.tscn").instantiate()
	elif key=="barrier": original=load("res://commons/artifacts/do_not_cross_barrier/do_not_cross_barrier.tscn").instantiate()
	elif key=="tc":
		original=load("res://commons/artifacts/movable_pivot/route_lift.gd").new()
		original.preview=true
	else: original=Node3D.new()
	add_child(original)
	if key=="paddle":
		box(original,Vector3(.84,.7,.25),Vector3(0,.35,0),"292b34")
		for x in [-.46,.46]: box(original,Vector3(.08,.7,.28),Vector3(x,.35,0),"ef72aa")
		box(original,Vector3(.05,.04,.29),Vector3(0,.71,0),"f3eadd")
	elif key in ["window-frame","frame"]:
		for x in [-.45,.45]: box(original,Vector3(.1,1,1),Vector3(x,.5,0),"ef72aa")
		for y in [.05,.95]: box(original,Vector3(.8,.1,1),Vector3(0,y,0),"ef72aa")
	elif key=="drum":
		var mesh:=MeshInstance3D.new();var cylinder:=CylinderMesh.new()
		cylinder.top_radius=.5;cylinder.bottom_radius=.5;cylinder.height=1;cylinder.radial_segments=32
		mesh.mesh=cylinder;mesh.position.y=.5;mesh.material_override=material("f3eadd");original.add_child(mesh)
	elif key=="fan":
		box(original,Vector3(.76,.16,.2),Vector3(0,.5,0),"242a30")
		box(original,Vector3(.16,.76,.2),Vector3(0,.5,0),"242a30")
		for side in [-1,1]:
			box(original,Vector3(.12,.18,.22),Vector3(side*.44,.5,0),"ff5698")
			box(original,Vector3(.18,.12,.22),Vector3(0,.5+side*.44,0),"ff5698")
		var hub:=MeshInstance3D.new()
		var cylinder:=CylinderMesh.new()
		cylinder.top_radius=.12;cylinder.bottom_radius=.12;cylinder.height=.25;cylinder.radial_segments=16
		hub.mesh=cylinder;hub.position.y=.5;hub.rotation.x=PI/2;hub.material_override=material("fffbed")
		original.add_child(hub)
	elif key=="pipe":
		_add_pipe(original)
	elif key=="green-field":
		# Literal scale is marked as an exception to the rigid construction kit.
		# A translucent volume remains a visible, non-solid spatial reference.
		box(original,Vector3.ONE,Vector3(0,.5,0),"65e995")
	original.process_mode=Node.PROCESS_MODE_DISABLED
	var pieces: Array=[]
	var bounds:=AABB()
	for mesh in original.find_children("*","MeshInstance3D",true,false):
		if mesh.mesh==null or not mesh.is_visible_in_tree(): continue
		var transform: Transform3D=original.global_transform.affine_inverse()*mesh.global_transform
		var b: AABB=transform*mesh.mesh.get_aabb()
		bounds=b if pieces.is_empty() else bounds.merge(b)
		pieces.append({"mesh":mesh.mesh,"pose":transform,"material":mesh.material_override})
	assert(not pieces.is_empty(),"Unsupported native grid source: "+key)
	var normalizer:=Transform3D(Basis.from_scale(Vector3.ONE/bounds.size),Vector3.ZERO)*Transform3D(Basis.IDENTITY,-Vector3(bounds.get_center().x,bounds.position.y,bounds.get_center().z))
	for piece in pieces: piece.pose=normalizer*piece.pose
	var colliders:Array=[]
	if key.begins_with("scaffold_"):
		for shape in original.find_children("*","CollisionShape3D",true,false):
			if shape.shape == null or shape.disabled:continue
			var pose:Transform3D=normalizer*original.global_transform.affine_inverse()*shape.global_transform
			colliders.append({"shape":shape.shape,"pose":pose})
	cache[key]={"pieces":pieces,"source_bounds":bounds,"colliders":colliders}
	original.free()
	return cache[key]

func _add_pipe(host: Node3D) -> void:
	var surface:=SurfaceTool.new()
	surface.begin(Mesh.PRIMITIVE_TRIANGLES)
	# Outer wall, inner wall and both rims. Keep the aperture out of the collision mesh.
	for i in 28:
		var a:=Vector2.from_angle(TAU*i/28.0)
		var b:=Vector2.from_angle(TAU*(i+1)/28.0)
		for edge in [[.5,-.5,.5,.5],[.5,.5,.39,.5],[.39,.5,.39,-.5],[.39,-.5,.5,-.5]]:
			var a0:=Vector3(a.x*edge[0],.5+a.y*edge[0],edge[1])
			var b0:=Vector3(b.x*edge[0],.5+b.y*edge[0],edge[1])
			var a1:=Vector3(a.x*edge[2],.5+a.y*edge[2],edge[3])
			var b1:=Vector3(b.x*edge[2],.5+b.y*edge[2],edge[3])
			for v in [a0,a1,b0,b0,a1,b1]: surface.add_vertex(v)
	surface.generate_normals()
	var mesh:=MeshInstance3D.new()
	mesh.mesh=surface.commit()
	mesh.material_override=material("242a30")
	host.add_child(mesh)

func populate(body: Node3D, part: Dictionary) -> void:
	if str(part.source).begins_with("workshop_"):
		populate_workshop(body,part)
		return
	var data:=source(part.source)
	var scale_pose:=Transform3D(Basis.from_scale(Vector3(part.size[0],part.size[1],part.size[2])),Vector3.ZERO)
	var authored_collision:bool=str(part.source).begins_with("scaffold_")
	var faces:=PackedVector3Array()
	for piece in data.pieces:
		var mesh:=MeshInstance3D.new();mesh.mesh=piece.mesh;mesh.transform=scale_pose*piece.pose
		var role:=Finishes.part_role(part)
		if part.source=="tc" and piece.material is StandardMaterial3D and piece.material.albedo_color.get_luminance()<.15:role="steel"
		mesh.material_override=piece.material if authored_collision and not part.get("electrical",false) else Finishes.surface(role,phase,piece.material)
		body.add_child(mesh)
		if not authored_collision and part.get("collision",true) and part.source!="green-field":
			var b:Basis=mesh.transform.basis
			var axes:=b.orthonormalized()
			var orthogonal:bool=absf(b.x.normalized().dot(b.y.normalized()))<.00001 and absf(b.x.normalized().dot(b.z.normalized()))<.00001 and absf(b.y.normalized().dot(b.z.normalized()))<.00001
			if piece.mesh is BoxMesh and orthogonal:
				# Moving concave box soups expose interior/back faces during Jolt's
				# capsule recovery, especially on TC's upward leg. This is the same
				# authored box, not a hull around the whole prefab or its openings.
				var shape:=CollisionShape3D.new();var box_shape:=BoxShape3D.new()
				box_shape.size=piece.mesh.size*b.get_scale().abs();shape.shape=box_shape
				shape.transform=Transform3D(axes,mesh.transform.origin);body.add_child(shape)
			else:
				for vertex in piece.mesh.get_faces(): faces.append(mesh.transform*vertex)
	if not faces.is_empty():
		var shape:=CollisionShape3D.new();var triangles:=ConcavePolygonShape3D.new()
		triangles.set_faces(faces);triangles.backface_collision=true;shape.shape=triangles;body.add_child(shape)
	if authored_collision and part.get("collision",true):
		for collider in data.colliders:
			_add_scaffold_collider(body, collider.shape, scale_pose*collider.pose)

func _add_scaffold_collider(body:Node3D, authored:Shape3D, pose:Transform3D)->void:
	var basis:=pose.basis
	var axes:=basis.orthonormalized()
	var dimensions:=basis.get_scale().abs()
	var result:Shape3D
	if authored is BoxShape3D and is_equal_approx(absf(basis.determinant()), dimensions.x*dimensions.y*dimensions.z):
		var shape:=BoxShape3D.new()
		shape.size=authored.size*dimensions
		result=shape
	elif authored is CylinderShape3D and is_equal_approx(dimensions.x,dimensions.z):
		var shape:=CylinderShape3D.new()
		shape.radius=authored.radius*dimensions.x
		shape.height=authored.height*dimensions.y
		result=shape
	else:
		# A stretched diagonal or round fitting may no longer be orthogonal.
		# Bake its authored surface into a convex hull before handing it to Jolt.
		var mesh:PrimitiveMesh
		if authored is CylinderShape3D:
			var cylinder:=CylinderMesh.new()
			cylinder.top_radius=authored.radius
			cylinder.bottom_radius=authored.radius
			cylinder.height=authored.height
			cylinder.radial_segments=16
			mesh=cylinder
		elif authored is BoxShape3D:
			var box_mesh:=BoxMesh.new()
			box_mesh.size=authored.size
			mesh=box_mesh
		else:return
		var points:=mesh.get_faces()
		for i in points.size():points[i]=basis*points[i]
		var hull:=ConvexPolygonShape3D.new()
		hull.points=points
		result=hull
		axes=Basis.IDENTITY
	var collider:=CollisionShape3D.new()
	collider.shape=result
	collider.transform=Transform3D(axes,pose.origin)
	body.add_child(collider)

func populate_workshop(body:Node3D,part:Dictionary)->void:
	# Use the workbench's actual meshes and shapes at their native size. The
	# generic prefab normalizer must never resize an authorized construction part.
	var record:Dictionary=WorkshopModel.canonical(part.workshop_record)
	assert(not record.is_empty() and part.source=="workshop_"+record.kind)
	# Opt-in flush fittings use the very same seated geometry as the workbench.
	# Old recipes retain their authored joints; only fitted new assemblies opt in.
	if part.get("workshop_seated",false):record._seated=true
	var bauhaus:bool=part.get("workshop_palette","")==BauhausWorkshop.PALETTE_BAUHAUS
	var fitted:bool=(not bauhaus) and part.get("workshop_profile","")=="fitted" and FittedWorkshop.workshop_fitted(record)
	var library=BauhausWorkshop if bauhaus else (FittedWorkshop if fitted else Workshop)
	var b_scheme:String=str(part.get("workshop_color_scheme",phase))
	var key:String=record.kind+str(record.get("half",0))+"/"+str(record.get("span",1))+"/"+str(record.get("_seated",false))+"/"+("bauhaus/"+b_scheme if bauhaus else str(fitted))
	if not cache.has(key):
		var original:MeshInstance3D=library.visual(record,WorkshopModel.WORLD_STEP,b_scheme if bauhaus else phase)
		var pieces:Array=[{"mesh":original.mesh,"pose":Transform3D.IDENTITY,"material":original.material_override}]
		for child in original.get_children():
			if child is MeshInstance3D:pieces.append({"mesh":child.mesh,"pose":child.transform,"material":child.material_override})
		cache[key]={"pieces":pieces,"shape":library.shape_for(record,WorkshopModel.WORLD_STEP)}
		original.free()
	for piece in cache[key].pieces:
		var mesh:=MeshInstance3D.new();mesh.mesh=piece.mesh;mesh.transform=piece.pose;mesh.material_override=piece.material;body.add_child(mesh)
	# Rods outline the neutral panels in the coloured-edge palette.
	var palette: String = part.get("workshop_palette", "")
	if palette in ["trans", "coloured_edges"]:
		var rod: bool = record.kind in ["rod", "rod_short"]
		var tint := Color("5bcefa" if rod else "ffffff")
		if palette == "trans" and not rod and record.kind != "point":
			tint = Color("f5a9b8")
		for child in body.get_children():
			if child is MeshInstance3D and child.material_override is StandardMaterial3D:
				var original:StandardMaterial3D=child.material_override
				var tint_key: String = palette + "/" + record.kind + "/" + str(original.get_instance_id())
				if not finishes.has(tint_key):
					var painted:StandardMaterial3D=original.duplicate();painted.albedo_color=tint
					finishes[tint_key]=painted
				child.material_override=finishes[tint_key]
	var shape:=CollisionShape3D.new();shape.shape=cache[key].shape;body.add_child(shape)
	body.set_meta("workshop_record",record)
	body.set_meta("workshop_assembly",part.get("assembly",""))
