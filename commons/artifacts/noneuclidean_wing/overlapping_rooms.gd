extends Node3D
## Connected Euclidean sectors: two overlapping galleries and a growing corner walk.
## Visual proxies contain no scripts/physics. The single PointBody is never cloned.
const B = preload("spatial_builder.gd")
const Corners = preload("corner_rooms.gd")
const Perspective = preload("perspective_corridor.gd")
const Repeating = preload("repeating_gallery.gd")
const Forest = preload("column_forest.gd")
const Labyrinth = preload("labyrinth.gd")
const PALE := Color("e9e2d5")
const DARK := Color("191e29")
const PINK := Color("ed78ad")
const BLUE := Color("70cddd")
const GOLD := Color("f2be64")
const WIDTH := 2.0
const HEIGHT := 2.8
var wing: Node3D
var lobby: Node3D
var interiors: Array[Node3D] = []
var links: Array[Dictionary] = []
var sector := -1
var point_sector := -1
var last_eye := Vector3.ZERO
var last_point := Vector3.ZERO
var have_eye := false
var crossings := 0
var stats := {"portals":0,"submitted":0,"candidates":0}
var status: Label3D
var point_surface: MeshInstance3D
var point_finish: Material
var point_split: ShaderMaterial
var was_held := false
var corners: Node3D
var perspective:Node3D
var repeating:Node3D
var forest:Node3D
var labyrinth:Node3D

func setup(owner_wing: Node3D) -> void:
	wing=owner_wing; lobby=wing.rooms[0]
	point_surface=wing.point.get_child(0); point_finish=point_surface.material_override
	var split_shader := Shader.new()
	split_shader.code="""shader_type spatial;
uniform mat4 source_inverse;
uniform vec4 colour : source_color;
varying vec3 portal_position;
void vertex(){portal_position=(source_inverse*MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;}
void fragment(){if(portal_position.z<0.0)discard;ALBEDO=colour.rgb;ROUGHNESS=0.24;}
"""
	point_split=ShaderMaterial.new(); point_split.shader=split_shader
	point_split.set_shader_parameter("colour",wing.point.tint)
	# This 6 x 3 metre shell is walkable around on all four sides.
	for x in [-2.75,0.0,2.75]:
		B.box(lobby,Vector3(x,1.5,1.5),Vector3(1.0 if x==0 else 0.5,3,0.24),DARK,true)
	B.box(lobby,Vector3(0,2.98,1.5),Vector3(6,0.36,0.24),DARK,true)
	B.box(lobby,Vector3(0,1.5,-1.5),Vector3(6,3,0.22),DARK,true)
	for x in [-3,3]: B.box(lobby,Vector3(x,1.5,0),Vector3(0.2,3,3),DARK,true)
	B.box(lobby,Vector3(0,3.12,0),Vector3(6.2,0.15,3.2),PALE,true)
	B.text(lobby,"TWO DOORS / ONE FOOTPRINT",Vector3(0,3.63,1.62),25,GOLD).pixel_size=0.006
	B.text(lobby,"Carry the point in. Leave it. Find it again.",Vector3(0,3.29,1.63),18,PALE).pixel_size=0.005
	for i in range(2):
		var room := Node3D.new(); room.name="RoseGallery" if i==0 else "BlueGallery"
		add_child(room); room.position=Vector3(i*32,90,0); interiors.append(room)
		build_interior(room,i)
		var source := Node3D.new(); lobby.add_child(source)
		source.name="RoseDoor" if i==0 else "BlueDoor"; source.position=Vector3(-1.5 if i==0 else 1.5,0,1.64)
		var target := Node3D.new(); room.add_child(target)
		target.name="ReturnDoor"; target.position=Vector3(0,0,5.84); target.rotation.y=PI
		frame(source,PINK if i==0 else BLUE,"ROSE" if i==0 else "BLUE")
		frame(target,PINK if i==0 else BLUE,"BACK TO THE SAME PAVILION")
		links.append({"source":source,"target":target,"from":-1,"to":i})
		links.append({"source":target,"target":source,"from":i,"to":-1})
	status=B.text(lobby,"",Vector3(4.9,1.85,3.2),14,GOLD); status.pixel_size=0.003
	perspective=Perspective.new();add_child(perspective);perspective.setup(self)
	repeating=Repeating.new();add_child(repeating);repeating.setup(self)
	forest=Forest.new();add_child(forest);forest.setup(self)
	labyrinth=Labyrinth.new();add_child(labyrinth);labyrinth.setup(self)
	corners=Corners.new(); add_child(corners); corners.setup(self)
	# Capture source geometry only after both door frames exist. No nested portal
	# previews are copied: one level, explicit finite visibility graph.
	for i in range(4): build_view(links[i],12+i)
	corners.ensure_neighbours(0)
	for direction in range(2):
		var link:Dictionary={"from":-1 if direction==0 else -2,"to":-2 if direction==0 else -1,"source":perspective.source if direction==0 else perspective.target,"target":perspective.target if direction==0 else perspective.source,"reference":18+direction}
		links.append(link);build_view(link,18+direction)
	for direction in range(2):
		var link:Dictionary={"from":0 if direction==0 else -3,"to":-3 if direction==0 else 0,"source":repeating.source if direction==0 else repeating.target,"target":repeating.target if direction==0 else repeating.source,"reference":40+direction}
		links.append(link);build_view(link,40+direction)
	for direction in range(2):
		var link:Dictionary={"from":1 if direction==0 else -4,"to":-4 if direction==0 else 1,"source":forest.source if direction==0 else forest.target,"target":forest.target if direction==0 else forest.source,"reference":50+direction}
		links.append(link);build_view(link,50+direction)
	for i in range(labyrinth.pairs.size()):
		var pair:Dictionary=labyrinth.pairs[i]
		for direction in range(2):
			var link:Dictionary={"from":pair.a if direction==0 else pair.b,"to":pair.b if direction==0 else pair.a,"source":pair.source if direction==0 else pair.target,"target":pair.target if direction==0 else pair.source,"reference":60+i*2+direction}
			links.append(link);build_view(link,60+i*2+direction)
	last_point=wing.point.global_position
	set_sector(-1)

func frame(at: Node3D, colour: Color, caption: String) -> void:
	for x in [-1.06,1.06]: B.box(at,Vector3(x,1.4,0),Vector3(0.12,2.8,0.18),colour,true)
	B.box(at,Vector3(0,2.84,0),Vector3(2.24,0.12,0.18),colour,true)
	B.box(at,Vector3(0,0.012,0),Vector3(2,0.024,0.3),colour)
	B.text(at,caption,Vector3(0,3.04,0.04),13,colour).pixel_size=0.003

func build_interior(room: Node3D, index: int) -> void:
	var accent := PINK if index==0 else BLUE
	B.box(room,Vector3(0,-0.2,0),Vector3(14,0.4,12),PALE,true)
	B.box(room,Vector3(0,3,-6),Vector3(14,6,0.22),DARK,true)
	B.box(room,Vector3(0,6.1,0),Vector3(14,0.2,12),PALE,true)
	for x in [-7,7]: B.box(room,Vector3(x,3,0),Vector3(0.22,6,12),PALE,true)
	for x in [-4.0,4.0]: B.box(room,Vector3(x,3,6),Vector3(6,6,0.22),DARK,true)
	B.box(room,Vector3(0,4.45,6),Vector3(2,3.1,0.22),DARK,true)
	for z in range(-5,6):
		B.box(room,Vector3(0,0.006,z),Vector3(13.7,0.012,0.025),Color("a9a6a0"))
	for x in range(-6,7): B.box(room,Vector3(x,0.008,0),Vector3(0.025,0.012,11.7),Color("a9a6a0"))
	for z in [-4.0,-0.5,3.0]:
		B.box(room,Vector3(0,5.6,z),Vector3(14,0.16,0.28),DARK)
		for x in [-5.3,5.3]:
			B.box(room,Vector3(x,0.12,z),Vector3(1.4,0.24,1.4),DARK,true)
			if index==0:
				B.cylinder(room,Vector3(x,2.6,z),0.34,5.0,accent,true)
			else:
				B.box(room,Vector3(x,2.6,z),Vector3(0.68,5,0.68),accent,true)
	B.text(room,"ENDLESS MUSEUM",Vector3(0,5.1,-5.84),36,PALE)
	B.text(room,"always another room",Vector3(0,4.63,-5.83),19,PALE)
	B.text(room,"ROSE / THE ROUND ROOM" if index==0 else "BLUE / THE SQUARE ROOM",Vector3(0,3.95,-5.82),25,accent)
	B.text(room,"14 metres wide. One small door back.",Vector3(0,3.47,-5.82),17,PALE)
	if index==0: B.ball(room,Vector3(0,2.5,-5.55),0.4,accent)
	else: B.box(room,Vector3(0,2.5,-5.55),Vector3(0.8,0.8,0.15),accent)
	# A recognisable destination and a resting place for the carried object.
	B.cylinder(room,Vector3(0,0.55,-1.8),0.75,1.1,DARK,true)
	B.cylinder(room,Vector3(0,1.12,-1.8),0.8,0.04,accent)
	B.text(room,"LEAVE YOUR POINT HERE",Vector3(0,0.68,-0.98),12,PALE).pixel_size=0.003
	for j in range(4):
		var z := -3.8+j*1.4
		if index==0:
			var torus := TorusMesh.new(); torus.inner_radius=1.05; torus.outer_radius=1.16
			var ring := B.mesh(room,torus,Vector3(0,2.5,z),GOLD)
			ring.rotation.x=PI/2
		else:
			for x in [-1.4,1.4]: B.box(room,Vector3(x,2.55,z),Vector3(0.12,2.8,0.12),accent)
			for y in [1.15,3.95]: B.box(room,Vector3(0,y,z),Vector3(2.92,0.12,0.12),accent)
	# Real room lights; proxies use a matching inexpensive directional finish.
	for x in [-4,4]:
		var light := OmniLight3D.new(); room.add_child(light)
		light.position=Vector3(x,4.8,1); light.omni_range=18; light.light_energy=2
	room.visible=false

func build_view(link: Dictionary, reference: int) -> void:
	var source: Node3D=link.source
	var writer := B.material(Color(1,1,1,0),true)
	writer.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	writer.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
	writer.render_priority=-100; writer.stencil_mode=BaseMaterial3D.STENCIL_MODE_CUSTOM
	writer.stencil_flags=BaseMaterial3D.STENCIL_FLAG_WRITE; writer.stencil_reference=reference
	var mask := MeshInstance3D.new(); var quad := QuadMesh.new(); quad.size=Vector2(WIDTH,HEIGHT)
	mask.mesh=quad; mask.material_override=writer; source.add_child(mask); mask.position=Vector3(0,HEIGHT/2,0.005)
	mask.set_meta("portal_view",true); link.writer=mask
	var view := Node3D.new(); source.add_child(view); view.set_meta("portal_view",true); link.view=view
	link.meshes=[]
	var destination: Node3D=sector_room(link.to)
	var transfer: Transform3D=link.target.global_transform*Transform3D(Basis(Vector3.UP,PI),Vector3.ZERO)*source.global_transform.affine_inverse()
	link.transfer=transfer
	var receiver_shader := Shader.new()
	receiver_shader.code="""shader_type spatial;
render_mode unshaded, cull_back, depth_draw_always;
stencil_mode read, compare_equal, %d;
uniform vec4 colour : source_color;
uniform mat4 aperture_inverse;
varying vec3 aperture_position;
varying vec3 world_normal;
varying vec3 aperture_eye;
void vertex() {
 aperture_position=(aperture_inverse*MODEL_MATRIX*vec4(VERTEX,1.0)).xyz;
 #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
 aperture_eye=(aperture_inverse*INV_VIEW_MATRIX*vec4(0.0,0.0,0.0,1.0)).xyz;
 #else
 aperture_eye=(aperture_inverse*INV_VIEW_MATRIX*vec4(EYE_OFFSET,1.0)).xyz;
 #endif
 world_normal=MODEL_NORMAL_MATRIX*NORMAL;
}
void fragment() {
 if(aperture_position.z>0.015) discard;
 ALBEDO=colour.rgb*(0.68+0.32*max(dot(normalize(world_normal),normalize(vec3(-0.4,0.8,0.5))),0.0));
 ALPHA=1.0;
 // Fit virtual depths into a thin interval in front of the aperture. Stencil
 // already excludes opaque foregrounds; depth writes order remote surfaces.
 float ratio=max(aperture_eye.z,0.001)/max(aperture_eye.z-aperture_position.z,0.001);
 float compressed=0.97+0.025*(1.0-exp(-max(-aperture_position.z,0.0)*0.1));
 vec4 projected=PROJECTION_MATRIX*vec4(VERTEX*ratio*compressed,1.0);
 DEPTH=projected.z/projected.w;
 #if CURRENT_RENDERER == RENDERER_COMPATIBILITY
 DEPTH=DEPTH*0.5+0.5;
 #endif
}
"""%reference
	link.shader=receiver_shader
	for original in destination.find_children("*","MeshInstance3D",true,false):
		if is_view(original) or not original.material_override is StandardMaterial3D: continue
		var copy := MeshInstance3D.new(); view.add_child(copy); copy.mesh=original.mesh
		copy.global_transform=transfer.affine_inverse()*original.global_transform
		copy.material_override=receiver_material(receiver_shader,original.material_override.albedo_color,source)
		copy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
		copy.ignore_occlusion_culling=true # local solid walls must not hide another sector
		link.meshes.append(copy)
		if original.get_meta("portal_dynamic",false):copy.set_meta("original",weakref(original))
	var point_view := MeshInstance3D.new(); view.add_child(point_view)
	point_view.mesh=wing.point.get_child(0).mesh
	point_view.material_override=receiver_material(receiver_shader,wing.point.tint,source)
	point_view.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	point_view.ignore_occlusion_culling=true
	link.point_view=point_view

func receiver_material(shader: Shader, colour: Color, source: Node3D) -> ShaderMaterial:
	var mat := ShaderMaterial.new(); mat.shader=shader
	mat.set_shader_parameter("colour",colour)
	mat.set_shader_parameter("aperture_inverse",source.global_transform.affine_inverse())
	return mat

func is_view(node: Node) -> bool:
	var ancestor := node
	while ancestor!=null:
		if ancestor.get_meta("portal_view",false): return true
		ancestor=ancestor.get_parent()
	return false

func set_sector(value: int) -> void:
	sector=value
	if corners!=null:
		corners.ensure_neighbours(maxi(0,sector-2))
		corners.show_sector(sector)
	lobby.visible=wing.current==0 and sector==-1
	for i in range(2): interiors[i].visible=wing.current==0 and sector==i
	if perspective!=null:perspective.room.visible=wing.current==0 and sector==-2
	if repeating!=null:repeating.room.visible=wing.current==0 and sector==-3
	if forest!=null:forest.room.visible=wing.current==0 and sector==-4
	if labyrinth!=null:labyrinth.show_sector(sector)
	have_eye=false
	for link in links: link.view.visible=false; link.writer.visible=false
	point_surface.material_override=point_finish

func sector_room(index: int) -> Node3D:
	if index==-1: return lobby
	if index==-2:return perspective.room
	if index==-3:return repeating.room
	if index==-4:return forest.room
	if index<=-5:return labyrinth.rooms[-index-5]
	if index<2: return interiors[index]
	return corners.resident[index-2].room

static func swept(a: Vector3,b: Vector3, margin := 0.16) -> bool:
	if a.z<=0 or b.z>0: return false
	var hit := a.lerp(b,a.z/(a.z-b.z))
	return absf(hit.x)<WIDTH/2-margin and hit.y>0.05 and hit.y<HEIGHT-0.05

func cross(link: Dictionary) -> void:
	# Every door has parallel paired frames: transfer is translation. Keep
	# this explicit so player orientation and XR hold targets need no rotation.
	var transfer: Transform3D=link.transfer
	assert(transfer.basis.is_equal_approx(Basis.IDENTITY))
	wing.move_together(transfer.origin)
	if wing.point.held(): point_sector=link.to
	set_sector(link.to); crossings+=1
	last_eye=wing.eye_position(); have_eye=true
	last_point=wing.point.global_position

func update(delta: float) -> bool:
	if wing.current!=0:
		if sector!=-1: set_sector(-1)
		for link in links: link.view.visible=false; link.writer.visible=false
		return false
	var eye: Vector3=wing.eye_position()
	if repeating!=null and repeating.tick_wrap():eye=wing.eye_position()
	if forest!=null:forest.update_hand()
	if labyrinth!=null:labyrinth.update_hand()
	if wing.point.held(): point_sector=sector
	if have_eye:
		var crossed: Dictionary={}
		for link in links:
			if link.from==sector and swept(link.source.to_local(last_eye),link.source.to_local(eye)):
				crossed=link; break
		if not crossed.is_empty(): cross(crossed); eye=wing.eye_position()
	if not wing.point.held():
		for link in links:
			var p: Vector3=link.source.to_local(wing.point.global_position)
			var released_through: bool=was_held and p.z<=0 and absf(p.x)<0.915 and p.y>0.085 and p.y<2.715
			if link.from==point_sector and (released_through or swept(link.source.to_local(last_point),p,0.085)):
				wing.point.global_transform=link.transfer*wing.point.global_transform
				point_sector=link.to; break
	was_held=wing.point.held()
	last_eye=eye; have_eye=true; last_point=wing.point.global_position
	# A point left in another sector remains physically there and is shown only
	# through that sector's aperture. Recall is an explicit visitor action.
	wing.point.visible=point_sector==sector
	var camera := get_viewport().get_camera_3d()
	if camera!=null: update_visibility(camera)
	return sector!=-1

func aperture_visible(link: Dictionary, camera: Camera3D) -> bool:
	if link.from!=sector or wing.current!=0: return false
	var eye: Vector3=link.source.to_local(camera.global_position)
	if eye.z< -0.08: return false
	# Conservative frame bound, expanded for near-plane and stereo head margin.
	var bounds := AABB(Vector3(-1.12,-0.12,-0.12),Vector3(2.24,3.04,0.24))
	var world_bounds: AABB=link.source.global_transform*bounds
	for plane in camera.get_frustum():
		var outside := true
		for corner in range(8):
			if plane.distance_to(world_bounds.get_endpoint(corner))<=0.12: outside=false; break
		if outside: return false
	return true

func in_aperture_cone(copy: MeshInstance3D, link: Dictionary, camera: Camera3D) -> bool:
	var inverse: Transform3D=link.source.global_transform.affine_inverse()
	var eye := inverse*camera.global_position
	if eye.z<0.12: return true # Never pop geometry at the threshold.
	var bounds: AABB=inverse*copy.global_transform*copy.get_aabb()
	var corners: Array[Vector3]=[]
	for j in range(8): corners.append(bounds.get_endpoint(j))
	# Each inequality describes one half-space of the eye/aperture pyramid.
	for side in range(5):
		var all_out := true
		for p in corners:
			var depth := eye.z-p.z
			var dx := (p.x-eye.x)*eye.z+eye.x*depth
			var dy := (p.y-eye.y)*eye.z+eye.y*depth
			var inside: bool=[dx<=1.12*depth,dx>=-1.12*depth,dy<=2.92*depth,dy>=-0.12*depth,p.z<=0.12][side]
			if inside: all_out=false; break
		if all_out: return false
	return true

func update_visibility(camera: Camera3D) -> void:
	stats={"portals":0,"submitted":0,"candidates":0}
	point_surface.material_override=point_finish
	for link in links:
		var active := aperture_visible(link,camera)
		link.writer.visible=active; link.view.visible=active
		link.point_view.visible=false
		stats.candidates+=link.meshes.size()
		if not active: continue
		stats.portals+=1
		for copy: MeshInstance3D in link.meshes:
			if copy.has_meta("original"):
				var original:MeshInstance3D=copy.get_meta("original").get_ref()
				if original!=null:
					copy.global_transform=link.transfer.affine_inverse()*original.global_transform
					copy.visible=original.visible and in_aperture_cone(copy,link,camera)
					if copy.visible:stats.submitted+=1
					continue
			copy.visible=in_aperture_cone(copy,link,camera)
			if copy.visible: stats.submitted+=1
		link.point_view.global_transform=link.transfer.affine_inverse()*wing.point.global_transform
		link.point_view.visible=point_sector==link.to and in_aperture_cone(link.point_view,link,camera)
		# The hand can enter before the head. Split the visual sphere at the
		# aperture while retaining one live pickable and its unchanged hold target.
		var p: Vector3=link.source.to_local(wing.point.global_position)
		if wing.point.held() and point_sector==sector and p.z<0.085 and absf(p.x)<0.915 and p.y>0.085 and p.y<2.715:
			point_surface.material_override=point_split
			point_split.set_shader_parameter("source_inverse",link.source.global_transform.affine_inverse())
			link.point_view.global_transform=wing.point.global_transform
			link.point_view.visible=true
	status.text="PORTAL VISIBILITY\n%d doors / %d of %d preview meshes"%[stats.portals,stats.submitted,stats.candidates]
