extends Node3D
## Seven installed museum encounters. One carried PointBody, seven uses.
## Physical support stays Euclidean. H2 x R / H3 use an explicit metric renderer.
const K = preload("geometry_kernel.gd")
const B = preload("spatial_builder.gd")
const Point = preload("point_body.gd")
const PushButton = preload("res://commons/interactables/push_button.tscn")
const CURVED = preload("curved_space.gdshader")
const Overlap = preload("overlapping_rooms.gd")
const PALE := Color("e9e2d5")
const DARK := Color("191e29")
const PINK := Color("ed78ad")
const GOLD := Color("f2be64")
const BLUE := Color("70cddd")
const TITLES = ["A ROOM THAT WILL NOT FIT", "THE CORRIDOR RETURNS YOUR POINT", "ITS ARROW DOES NOT RETURN", "THE EDGE YOU CANNOT REACH", "HYPERBOLIC GALLERIES / H2 x R", "THE ROOM CURVES UPWARDS TOO / H3", "AIM STRAIGHT. WATCH THE PATH."]
const SUBTITLES = [
	"A narrow door. A larger interior.\nConnected Euclidean rooms: a portal does not create curvature.",
	"Carry the point through either end. Return without turning.\nA periodic flat corridor: its connections change; local curvature is zero.",
	"Move the point sideways in your hand to carry an arrow around three arcs.\nThree right angles. The same position; a different direction.",
	"Move the held point sideways and up. Watch the triangle change.\nEqual intrinsic steps crowd together in the Poincare disk.",
	"Hold the point away from your chest and press its trigger to travel.\nHorizontal distances are hyperbolic. Vertical height stays ordinary.",
	"Point sideways, forwards or upwards. Hold the trigger to move the view.\nCurvature in every plane. The platform remains an ordinary physical support.",
	"Hold the point; move it sideways to aim. Press its trigger to launch.\nThe visible arc and the hit test use the same hyperbolic distance."
]
var museum: Node3D
var rooms: Array[Node3D] = []
var readouts: Array[Label3D] = []
var point: RigidBody3D
var current := -1
var built := false
var held_trigger := false
var last_eye := Vector3.ZERO
var have_eye := false
var crossing_cooldown := 0.0
var wraps := 0
var sphere_progress := 0.0
var sphere_tip: MeshInstance3D
var sphere_arrow: Node3D
var disk_root: Node3D
var disk_klein := false
var disk_c := Vector3(0.08,0,0.65)
var disk_dirty := true
var observer := Projection.IDENTITY
var field_materials: Array[ShaderMaterial] = []
var field_roots: Array[Node3D] = []
var travel_distance := 0.0
var product_height := 0.0
var shot_root: Node3D
var shot_marker: MeshInstance3D
var shot_target: MeshInstance3D
var shot_start := K.from_ball(Vector3(-0.6,0,-0.25))
var shot_end := K.from_ball(Vector3(0.55,0,0.1))
var shot_angle := 0.15
var shot_t := 0.0
var shooting := false
var shot_hit := false
var last_point := Vector3.ZERO
var entry_preview: Node3D
var entry_writer: MeshInstance3D
var test_eye := Vector3(INF,INF,INF)
var sweep_count := 0
var point_preview: MeshInstance3D
var visual_tick := 0.0
var overlap: Node3D

func _ready() -> void:
	set_meta("em_keep_scale",true)
	# The museum may fit an artifact during its first frame. Build remote rooms
	# afterwards so only the entry frame participates in placement measurements.
	B.box(self,Vector3(-1.1,1.45,0),Vector3(0.2,2.9,0.25),DARK,true)
	B.box(self,Vector3(1.1,1.45,0),Vector3(0.2,2.9,0.25),DARK,true)
	B.box(self,Vector3(0,2.85,0),Vector3(2.4,0.2,0.25),PINK,true)
	B.box(self,Vector3(0,3.23,-0.05),Vector3(3.2,0.6,0.12),DARK)
	B.text(self,"SEVEN SPACES",Vector3(0,3.32,0.03),24,PALE).pixel_size=0.004
	B.text(self,"Take the point through the door",Vector3(0,3.10,0.03),18,PALE).pixel_size=0.004
	build.call_deferred()

func build() -> void:
	# Metres in the existing hall, including its vestibule. This approach was
	# surveyed against the live raised floor; the registry cell is only an anchor.
	if str(get_parent().get_meta("em_map",""))=="NonEuclidean_Spaces":
		position=Vector3(13,1,7); rotation=Vector3.ZERO; scale=Vector3.ONE
	var parent := get_parent()
	while parent != null:
		if parent.has_method("_eye_pos"):
			museum=parent
			break
		parent=parent.get_parent()
	for i in range(7):
		var room := Node3D.new()
		room.name="Chamber%02d"%(i+1)
		add_child(room)
		room.position=Vector3(i*32.0,60,0)
		rooms.append(room)
		build_room(room,i)
	point=Point.new()
	point.name="CarriedPoint"
	add_child(point)
	point.position=Vector3(-0.65,1.2,0.9)
	point.action_pressed.connect(func(_p): trigger(true))
	point.action_released.connect(func(_p): trigger(false))
	B.cylinder(self,Vector3(-0.65,0.5,0.9),0.19,1.0,PALE,true)
	B.text(self,"THE SAME POINT",Vector3(-0.65,0.83,1.12),11,DARK).pixel_size=0.003
	overlap=Overlap.new(); add_child(overlap); overlap.setup(self)
	build_portal()
	for room in rooms: room.visible=false
	built=true
	last_point=point.global_position
	update_sphere()
	redraw_disk()
	redraw_shot()

func build_room(room: Node3D, i: int) -> void:
	var curved := i in [4,5]
	B.box(room,Vector3(0,-0.2,0),Vector3(14,0.4,12),DARK if curved else PALE,true)
	if not curved:
		for side in [-1,1]:
			B.box(room,Vector3(side*7.0,3,0),Vector3(0.2,6,12),PALE,true)
		B.box(room,Vector3(0,3,-6),Vector3(14,6,0.2),DARK,true)
		# Split the rear wall: the entrance never hides a solid collision face.
		for side in [-1,1]: B.box(room,Vector3(side*4.1,3,6),Vector3(5.8,6,0.2),PALE,true)
		B.box(room,Vector3(0,4.5,6),Vector3(2.4,3,0.2),PALE,true)
		if i!=0: B.box(room,Vector3(0,1.5,6),Vector3(2.4,3,0.2),PALE,true)
		for x in [-5.6,5.6]:
			for z in [-4,0,4]:
				B.cylinder(room,Vector3(x,2.8,z),0.15,5.6,DARK)
		for z in range(-5,6): B.box(room,Vector3(0,0.008,z),Vector3(13.6,0.015,0.016),Color("b2afa8"))
		B.text(room,"ENDLESS MUSEUM",Vector3(0,5.25,-5.86),42)
		B.text(room,"always another room",Vector3(0,4.78,-5.85),20)
		B.text(room,"%02d  /  %s"%[i+1,TITLES[i]],Vector3(0,4.12,-5.8),26,PINK)
		B.text(room,SUBTITLES[i],Vector3(0,3.43,-5.8),18)
	else:
		# A tangible small control deck, surrounded by the metric architecture.
		B.text(room,TITLES[i],Vector3(0,3.7,-2.7),26,PINK)
		B.text(room,SUBTITLES[i],Vector3(0,3.02,-2.7),16)
		for x in [-6.8,6.8]: B.box(room,Vector3(x,0.5,0),Vector3(0.18,1,12),DARK,true)
		for z in [-5.8,5.8]: B.box(room,Vector3(0,0.5,z),Vector3(14,1,0.18),DARK,true)
	var light := OmniLight3D.new()
	light.position=Vector3(0,5,1); light.omni_range=18; light.light_energy=2.5
	room.add_child(light)
	var fill := OmniLight3D.new()
	fill.position=Vector3(-4,3,-2); fill.omni_range=15; fill.light_energy=1.8
	fill.light_color=Color(0.8,0.86,1)
	room.add_child(fill)
	B.box(room,Vector3(0,0.48,4.75),Vector3(5.8,0.96,0.75),DARK,true).set_meta("wing_control",true)
	B.box(room,Vector3(-4.25,1.65,3.45),Vector3(3.35,0.82,0.08),DARK)
	var readout := B.text(room,"",Vector3(-4.25,1.65,3.50),18,GOLD)
	readout.pixel_size=0.003
	readouts.append(readout)
	add_button(room,"Previous",Vector3(-2.3,1.03,4.85),func():
		if i==0: leave()
		else: visit(i-1))
	add_button(room,"Museum",Vector3(1.55,1.03,4.85),func(): leave())
	add_button(room,"Next",Vector3(2.35,1.03,4.85),func(): visit((i+1)%7))
	add_button(room,"Recall point",Vector3(-1.3,1.03,4.85),func(): recall())
	if i==0: build_large_room(room)
	elif i==1: build_corridor(room)
	elif i==2: build_sphere(room)
	elif i==3: build_disk(room)
	elif i in [4,5]: build_curved(room,i)
	elif i==6: build_target(room)
	if i in [2,3,4,5,6]: add_button(room,"Reset",Vector3(0.55,1.03,4.85),func(): reset_experiment())
	if i==2: add_button(room,"One arc",Vector3(-0.4,1.03,4.85),func(): sphere_progress=fmod(sphere_progress+1.0,3.01); update_sphere())
	if i==3: add_button(room,"Disk / Klein",Vector3(-0.4,1.03,4.85),func(): disk_klein=not disk_klein; redraw_disk())
	if i in [4,5]:
		add_button(room,"Step forward",Vector3(-0.4,1.03,4.85),func(): metric_step(Vector3.FORWARD*0.25))
		for j in range(4):
			var direction: Vector3 = [Vector3.LEFT,Vector3.RIGHT,Vector3.UP,Vector3.DOWN][j]
			add_button(room,["Left","Right","Up","Down"][j],Vector3(-1.8+j*1.1,1.03,4.5),func(): metric_step(direction*0.25))
	if i==6: add_button(room,"Launch",Vector3(-0.4,1.03,4.85),func(): fire())
	# Leave a direct walk from the portal into every chamber. Controls sit along
	# the left approach rather than forming a barrier across the doorway.
	for child in room.get_children():
		if child is Node3D and child.get_meta("wing_control",false):
			if i==0:
				var turn:=Basis(Vector3.UP,PI/2)
				child.position=Vector3(-6.2,0,0)+turn*(child.position-Vector3(0,0,4.75))
				child.basis=turn*child.basis
			else: child.position+=Vector3(-3.4,0,-1.8)

func add_button(room: Node3D, caption: String, at: Vector3, action: Callable) -> void:
	var button = PushButton.instantiate()
	button.name=caption.replace(" ","").replace("/","")
	room.add_child(button)
	button.position=at
	button.set_meta("wing_control",true)
	button.pressed.connect(action)
	var label := B.text(room,caption,at+Vector3(0,0.13,0.19),10,PALE)
	label.rotation.x=-0.6
	label.set_meta("wing_control",true)

func build_large_room(room: Node3D) -> void:
	readouts[0].text="Two doors. Two interiors in one apparent footprint.\nTake your point into one; return and find it."

func build_corridor(room: Node3D) -> void:
	for z in [-4.0,0.0,4.0]:
		for x in [-2.8,2.8]: B.box(room,Vector3(x,1.8,z),Vector3(0.22,3.6,0.22),PINK,true)
		B.box(room,Vector3(0,3.55,z),Vector3(5.8,0.16,0.2),PINK)
	for z in [-3.9,3.9]:
		B.box(room,Vector3(0,0.025,z),Vector3(5.3,0.04,0.13),BLUE)
	B.text(room,"CROSS EITHER BLUE LINE\nYou keep walking in the same direction",Vector3(0,2.4,-3.95),21)
	readouts[1].text="Winding count: 0   |   Local curvature: 0"

func build_sphere(room: Node3D) -> void:
	var centre := Vector3(0,2,-1)
	B.ball(room,centre,1.9,Color("293442"))
	for axis in [Vector3.RIGHT,Vector3.UP,Vector3.BACK]:
		var start := Vector3.UP if axis==Vector3.RIGHT else Vector3.RIGHT
		for j in range(64): B.tube(room,centre+start.rotated(axis,TAU*j/64.0)*1.93,centre+start.rotated(axis,TAU*(j+1)/64.0)*1.93,Color("566472"),0.012)
	var vertices := [Vector3.RIGHT,Vector3.UP,Vector3.BACK,Vector3.RIGHT]
	for a in range(3):
		for j in range(24): B.tube(room,centre+vertices[a].slerp(vertices[a+1],j/24.0)*1.96,centre+vertices[a].slerp(vertices[a+1],(j+1)/24.0)*1.96,PINK,0.035)
	B.tube(room,centre+Vector3.RIGHT*1.98,centre+Vector3.RIGHT*1.98+Vector3.UP*0.7,GOLD,0.03)
	sphere_tip=B.ball(room,Vector3.ZERO,0.12,PALE)
	sphere_arrow=Node3D.new(); room.add_child(sphere_arrow)

func update_sphere() -> void:
	if sphere_tip==null: return
	var vertices := [Vector3.RIGHT,Vector3.UP,Vector3.BACK,Vector3.RIGHT]
	var progress := clampf(sphere_progress,0,3)
	var leg := mini(int(progress),2)
	var u := progress-leg
	var p: Vector3 = vertices[leg].slerp(vertices[leg+1],u)
	var arrow := Vector3.UP
	for i in range(leg): arrow=K.transport_sphere(arrow,vertices[i],vertices[i+1])
	arrow=K.transport_sphere(arrow,vertices[leg],p)
	sphere_tip.position=Vector3(0,2,-1)+p*1.99
	clear(sphere_arrow)
	B.tube(sphere_arrow,sphere_tip.position,sphere_tip.position+arrow*0.72,BLUE,0.04)
	B.ball(sphere_arrow,sphere_tip.position+arrow*0.72,0.075,BLUE)
	readouts[2].text="Arc %.2f / 3   |   Triangle: 270 degrees\nGold: original tangent. Blue: transported tangent."%progress

func build_disk(room: Node3D) -> void:
	B.cylinder(room,Vector3(0,0.02,-0.55),4.15,0.08,DARK)
	disk_root=Node3D.new(); room.add_child(disk_root)
	B.text(room,"A FINITE PICTURE OF UNBOUNDED DISTANCE",Vector3(0,2.7,-5.78),19,BLUE)

func display_disk(p: Vector4) -> Vector3:
	var q: Vector3 = K.to_klein(p) if disk_klein else K.to_ball(p)
	return Vector3(q.x*4,0.18,q.z*4-0.55)

func redraw_disk() -> void:
	if disk_root==null: return
	clear(disk_root)
	var p := [K.from_ball(Vector3(-0.56,0,-0.32)),K.from_ball(Vector3(0.57,0,-0.24)),K.from_ball(disk_c)]
	for j in range(96): B.tube(disk_root,Vector3(cos(TAU*j/96.0)*4,0.15,sin(TAU*j/96.0)*4-0.55),Vector3(cos(TAU*(j+1)/96.0)*4,0.15,sin(TAU*(j+1)/96.0)*4-0.55),BLUE,0.016)
	for a in range(3):
		B.ball(disk_root,display_disk(p[a]),0.10,PALE)
		for j in range(32): B.tube(disk_root,display_disk(K.geodesic(p[a],p[(a+1)%3],j/32.0)),display_disk(K.geodesic(p[a],p[(a+1)%3],(j+1)/32.0)),PINK,0.028)
	for j in range(10):
		var q: Vector4=K.boost(K.origin(),Vector3(-0.7,0,0.72),j*0.6)
		B.ball(disk_root,display_disk(q)+Vector3.UP*0.035,0.065,GOLD)
	var determinant := Basis(Vector3(p[0].x,p[0].z,p[0].w),Vector3(p[1].x,p[1].z,p[1].w),Vector3(p[2].x,p[2].z,p[2].w)).determinant()
	if absf(determinant)<0.00001:
		readouts[3].text="No triangle: coincident or collinear corners.\nMove the point away from the line."
	else:
		readouts[3].text="%s | Angle sum: %.2f degrees\nGold marks: 0.60 units apart in the metric."%["Klein" if disk_klein else "Poincare",rad_to_deg(K.triangle_sum(p[0],p[1],p[2]))]
	disk_dirty=false

func build_curved(room: Node3D, index: int) -> void:
	var field := Node3D.new(); room.add_child(field); field_roots.append(field)
	var mesh := ImmediateMesh.new()
	mesh.surface_begin(Mesh.PRIMITIVE_TRIANGLES)
	# Finite architecture, not a claimed regular tessellation. Hyperboloid
	# coordinates choose the columns; the observer metric determines their view.
	for ring in range(1,4):
		for j in range(16):
			var angle := TAU*j/16.0+ring*0.07
			var r := ring*1.2
			var centre := Vector3(cos(angle)*sinh(r),0,sin(angle)*sinh(r))
			for level in range(-1,2):
				var h := level*1.2
				var vertices: Array[Vector3] = []
				for end in [-1,1]:
					for side in range(4):
						var p := centre+Vector3(cos(side*PI/2+PI/4)*0.065,h+end*0.45,sin(side*PI/2+PI/4)*0.065)
						vertices.append(p)
				var colour: Color = [PALE,PINK,BLUE][posmod(j+level,3)]
				for side in range(4):
					var next := (side+1)%4
					for n in [side,next,side+4,next,next+4,side+4]:
						mesh.surface_set_color(colour*(0.65+side*0.1)); mesh.surface_add_vertex(vertices[n])
	# Bands join columns into surrounding galleries; their samples lie on exact
	# geodesics. A narrow ribbon has four vertices at each sample interval.
	for h in [-1.8,-0.6,0.6,1.8]:
		for ring in range(1,4):
			for j in range(16):
				var a := Vector3(cos(TAU*j/16+ring*0.07)*sinh(ring*1.2),h,sin(TAU*j/16+ring*0.07)*sinh(ring*1.2))
				var b := Vector3(cos(TAU*(j+1)/16+ring*0.07)*sinh(ring*1.2),h,sin(TAU*(j+1)/16+ring*0.07)*sinh(ring*1.2))
				for step in range(8):
					var aa := field_sample(a,b,step/8.0,index==4)
					var bb := field_sample(a,b,(step+1)/8.0,index==4)
					for v in [aa-Vector3.UP*0.025,bb-Vector3.UP*0.025,aa+Vector3.UP*0.025,bb-Vector3.UP*0.025,bb+Vector3.UP*0.025,aa+Vector3.UP*0.025]:
						mesh.surface_set_color(GOLD if ring==1 else PALE*0.6); mesh.surface_add_vertex(v)
	mesh.surface_end()
	var n := MeshInstance3D.new(); n.mesh=mesh
	n.custom_aabb=AABB(Vector3.ONE*-100000,Vector3.ONE*200000)
	n.extra_cull_margin=1000
	n.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var mat := ShaderMaterial.new(); mat.shader=CURVED
	mat.set_shader_parameter("product_space",index==4)
	mat.set_shader_parameter("radius",6.0)
	n.material_override=mat; field_materials.append(mat)
	field.add_child(n)
	readouts[index].text="Hold point + trigger to travel.\nPhysical deck; metric architecture around you."

func field_sample(a: Vector3,b: Vector3,t: float, product: bool) -> Vector3:
	var av := Vector3(a.x,0,a.z) if product else a
	var bv := Vector3(b.x,0,b.z) if product else b
	var q: Vector4=K.geodesic(Vector4(av.x,av.y,av.z,sqrt(1+av.length_squared())),Vector4(bv.x,bv.y,bv.z,sqrt(1+bv.length_squared())),t)
	return Vector3(q.x,lerpf(a.y,b.y,t) if product else q.y,q.z)

func metric_step(step: Vector3) -> void:
	if current not in [4,5]: return
	if current==4:
		product_height=clampf(product_height+step.y,-2,2)
		step.y=0
		update_fields()
		readouts[4].text="Horizontal: %.2f radii | Height: %.2f radii\nHeight changes without a vertical boost."%[travel_distance,product_height]
	if step.length()<0.00001: return
	# Bound the finite exhibit to a stable numerical range; no false infinity.
	if travel_distance+step.length()>5.0:
		readouts[current].text="End of this finite patch. Reset to explore another direction."
		return
	var axis := -step.normalized()
	var m := Projection(K.boost(Vector4(1,0,0,0),axis,step.length()),K.boost(Vector4(0,1,0,0),axis,step.length()),K.boost(Vector4(0,0,1,0),axis,step.length()),K.boost(Vector4(0,0,0,1),axis,step.length()))
	observer=m*observer
	travel_distance+=step.length()
	readouts[current].text="Travel: %.2f curvature radii\n%s"%[travel_distance,"Ordinary height: %.2f radii"%product_height if current==4 else "Horizontal AND vertical curvature"]
	update_fields()

func update_fields() -> void:
	for i in range(field_materials.size()):
		var anchor := rooms[i+4].global_transform*Transform3D(Basis.IDENTITY,Vector3(0,1.6,0))
		field_materials[i].set_shader_parameter("anchor_world",anchor)
		field_materials[i].set_shader_parameter("anchor_inverse",anchor.affine_inverse())
		field_materials[i].set_shader_parameter("observer",observer)
		field_materials[i].set_shader_parameter("product_height",product_height)

func build_target(room: Node3D) -> void:
	B.cylinder(room,Vector3(0,0.02,-0.55),4.15,0.08,DARK)
	shot_root=Node3D.new(); room.add_child(shot_root)
	shot_marker=B.ball(room,Vector3.ZERO,0.14,PALE)
	shot_target=B.ball(room,shot_display(shot_end),0.26,PINK)
	B.text(room,"Your point aims. The shot follows a geodesic.",Vector3(0,2.9,-5.8),20)

func shot_display(p: Vector4) -> Vector3:
	var q: Vector3=K.to_ball(p)
	return Vector3(q.x*4,0.8,q.z*4-0.55)

func aimed_endpoint() -> Vector4:
	var tangent := Vector3(cos(shot_angle),0,sin(shot_angle))
	# Move origin ray into the start frame by an isometry, not Euclidean lerp.
	var local_end: Vector4=K.boost(K.origin(),tangent,2.8)
	var displacement := Vector3(shot_start.x,shot_start.y,shot_start.z)
	return K.boost(local_end,displacement.normalized(),K.distance(K.origin(),shot_start))

func redraw_shot() -> void:
	if shot_root==null: return
	clear(shot_root)
	var end := aimed_endpoint()
	for j in range(60): B.tube(shot_root,shot_display(K.geodesic(shot_start,end,j/60.0)),shot_display(K.geodesic(shot_start,end,(j+1)/60.0)),BLUE,0.018)
	if not shooting: shot_marker.position=shot_display(shot_start)
	readouts[6].text="Move the point sideways to aim; trigger launches.\nTarget radius: 0.18 metric units. The display is a model."

func fire() -> void:
	if current!=6 or shooting: return
	shot_t=0; shooting=true; shot_hit=false
	shot_target.material_override=B.material(PINK)

func tick_shot(delta: float) -> void:
	if not shooting: return
	var end := aimed_endpoint()
	var previous := shot_t
	shot_t=minf(2.8,shot_t+delta*0.7)
	# Substeps bound every tested interval to <=0.025 metric units, so a shot
	# cannot leap over a target between rendered frames.
	var steps := maxi(1,ceili((shot_t-previous)/0.025))
	for j in range(steps+1):
		var q: Vector4=K.geodesic(shot_start,end,lerpf(previous,shot_t,float(j)/steps)/2.8)
		if K.distance(q,shot_end)<=0.18: shot_hit=true
	shot_marker.position=shot_display(K.geodesic(shot_start,end,shot_t/2.8))
	if shot_hit:
		shot_target.material_override=B.material(GOLD,true)
		readouts[6].text="HIT / a distance in the metric, not a screen overlap"
		shooting=false
	elif shot_t>=2.8:
		readouts[6].text="MISSED / change the direction and try again"
		shooting=false

func clear(node: Node) -> void:
	for child in node.get_children(): node.remove_child(child); child.queue_free()

func build_portal() -> void:
	var writer := B.material(Color(1,1,1,0),true)
	writer.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	writer.depth_draw_mode=BaseMaterial3D.DEPTH_DRAW_DISABLED
	writer.render_priority=-100
	writer.stencil_mode=BaseMaterial3D.STENCIL_MODE_CUSTOM
	writer.stencil_flags=BaseMaterial3D.STENCIL_FLAG_WRITE
	writer.stencil_reference=5
	var quad := QuadMesh.new(); quad.size=Vector2(2,2.7)
	entry_writer=MeshInstance3D.new(); entry_writer.mesh=quad; entry_writer.material_override=writer
	entry_writer.position=Vector3(0,1.35,0.01); add_child(entry_writer)
	entry_preview=Node3D.new(); add_child(entry_preview)
	for original in rooms[0].find_children("*","MeshInstance3D",true,false):
		# Visual geometry only. No duplicate physics bodies or student objects.
		if not original.material_override is StandardMaterial3D: continue
		var copy := MeshInstance3D.new()
		copy.mesh=original.mesh
		entry_preview.add_child(copy)
		copy.transform=rooms[0].global_transform.affine_inverse()*original.global_transform
		copy.position.z-=5.7
		var mat: StandardMaterial3D=original.material_override.duplicate()
		mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
		mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
		mat.stencil_mode=BaseMaterial3D.STENCIL_MODE_CUSTOM
		mat.stencil_flags=BaseMaterial3D.STENCIL_FLAG_READ
		mat.stencil_compare=BaseMaterial3D.STENCIL_COMPARE_EQUAL
		mat.stencil_reference=5
		# The mask already depth-tests against opaque foreground objects. A wall
		# behind the aperture must not occlude the remote room's virtual depth.
		mat.no_depth_test=true
		copy.material_override=mat
		copy.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	point_preview=B.ball(entry_preview,Vector3.ZERO,0.085,DARK)
	var point_mat: StandardMaterial3D=point_preview.material_override
	point_mat.transparency=BaseMaterial3D.TRANSPARENCY_ALPHA
	point_mat.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	point_mat.no_depth_test=true
	point_mat.stencil_mode=BaseMaterial3D.STENCIL_MODE_CUSTOM
	point_mat.stencil_flags=BaseMaterial3D.STENCIL_FLAG_READ
	point_mat.stencil_compare=BaseMaterial3D.STENCIL_COMPARE_EQUAL
	point_mat.stencil_reference=5
	B.text(rooms[0],"MUSEUM",Vector3(0,2.7,5.72),22,PINK).rotation.y=PI
	for side in [-1,1]: B.box(rooms[0],Vector3(side*1.1,1.4,5.7),Vector3(0.2,2.8,0.2),PINK,true)

func eye_position() -> Vector3:
	if is_finite(test_eye.x): return test_eye
	if museum!=null: return museum.call("_eye_pos")
	var camera := get_viewport().get_camera_3d()
	return camera.global_position if camera!=null else global_position+Vector3(0,1.6,2)

func shift_player(delta: Vector3) -> void:
	if is_finite(test_eye.x): test_eye+=delta
	if museum==null: return
	if bool(museum.get("_vr")):
		var rig: Node3D=museum.call("_vr_rig")
		if rig!=null:
			var body=rig.find_child("PlayerBody",true,false)
			if body!=null and body.has_method("teleport"):
				var pose: Transform3D=body.global_transform; pose.origin+=delta; body.teleport(pose)
			else: rig.global_position+=delta
	else:
		var walker: Node3D=museum.get("_player")
		if walker!=null: walker.global_position+=delta

func enter_by_door() -> void:
	var delta := rooms[0].to_global(Vector3(0,0,5.7))-global_position
	move_together(delta)
	activate(0)
	crossing_cooldown=0.4; sweep_count+=1
	last_eye=eye_position()

func return_by_door() -> void:
	var delta := global_position-rooms[0].to_global(Vector3(0,0,5.7))
	move_together(delta)
	activate(-1)
	crossing_cooldown=0.4; sweep_count+=1
	last_eye=eye_position()

func activate(index: int) -> void:
	current=index; held_trigger=false
	for i in range(rooms.size()): rooms[i].visible=i==index
	if overlap!=null: overlap.set_sector(-1)
	point.visible=true
	entry_preview.visible=index==-1; entry_writer.visible=index==-1
	observer=Projection.IDENTITY; travel_distance=0; product_height=0
	update_fields()

func visit(index: int) -> void:
	if not built: return
	index=clampi(index,0,6)
	var eye := eye_position()
	var target := rooms[index].to_global(Vector3(3.5 if index==1 else 0.0,1.6,5.55))
	var delta := target-eye
	move_together(delta)
	activate(index)
	if not point.held(): recall()
	crossing_cooldown=0.8; last_eye=eye_position(); have_eye=true

func leave() -> void:
	var delta := to_global(Vector3(0,1.6,1.8))-eye_position()
	move_together(delta)
	activate(-1)
	if not point.held(): recall()
	crossing_cooldown=0.8; last_eye=eye_position()

func recall() -> void:
	if point.held(): return
	point.linear_velocity=Vector3.ZERO; point.angular_velocity=Vector3.ZERO
	point.global_position=to_global(Vector3(-0.65,1.2,0.9)) if current<0 else rooms[current].to_global(Vector3(-0.85,1.3,4.9))
	if overlap!=null: overlap.point_sector=-1
	point.visible=true
	last_point=point.global_position

func move_together(delta: Vector3) -> void:
	var old_point := point.global_position
	shift_player(delta)
	# Works both for a world-owned XRTools body and a reparented desktop body.
	if point.held(): point.global_position=old_point+delta

func trigger(pressed: bool) -> void:
	held_trigger=pressed
	if overlap!=null and overlap.forest!=null:overlap.forest.trigger(pressed)
	if pressed and current==6: fire()

func reset_experiment() -> void:
	sphere_progress=0; update_sphere()
	disk_c=Vector3(0.08,0,0.65); redraw_disk()
	observer=Projection.IDENTITY; travel_distance=0; product_height=0; update_fields()
	shooting=false; shot_t=0; shot_angle=0.15; redraw_shot()
	if current in [4,5]: readouts[current].text="Origin restored. Hold the point + trigger to travel."

static func swept_door(a: Vector3,b: Vector3) -> bool:
	if a.z<=0 or b.z>0: return false
	var t := a.z/(a.z-b.z)
	var hit := a.lerp(b,t)
	return absf(hit.x)<0.96 and hit.y>0.05 and hit.y<2.68

func _process(delta: float) -> void:
	if not built: return
	if overlap!=null and overlap.update(delta):
		last_eye=eye_position(); have_eye=true
		last_point=point.global_position
		return
	visual_tick+=delta
	crossing_cooldown=maxf(0,crossing_cooldown-delta)
	var eye := eye_position()
	if have_eye and crossing_cooldown<=0:
		if current==-1 and swept_door(to_local(last_eye),to_local(eye)): enter_by_door(); eye=eye_position()
		elif current==0:
			var a := rooms[0].to_local(last_eye)-Vector3(0,0,5.7)
			var b := rooms[0].to_local(eye)-Vector3(0,0,5.7)
			a.z=-a.z; b.z=-b.z
			if swept_door(a,b): return_by_door(); eye=eye_position()
		elif current==1:
			var local := rooms[1].to_local(eye)
			var before := rooms[1].to_local(last_eye)
			if absf(local.x)<2.6 and ((before.z<=4 and local.z>4) or (before.z>=-4 and local.z< -4)):
				var shift := rooms[1].global_basis*Vector3(0,0,-signf(local.z)*7.9)
				move_together(shift)
				wraps+=1; crossing_cooldown=0.3; eye=eye_position()
				readouts[1].text="Winding count: %d   |   Same position class; curvature 0"%wraps
	last_eye=eye; have_eye=true
	if current>=0 and point.held():
		var p := rooms[current].to_local(point.global_position)
		if current==2 and visual_tick>0.05:
			sphere_progress=clampf((p.x+0.85)*1.5,0,3); update_sphere()
		elif current==3 and visual_tick>0.1:
			var c := Vector3(p.x*0.65,0,(p.y-1.1)*0.9)
			c=c.limit_length(0.92)
			if c.distance_to(disk_c)>0.015: disk_c=c; redraw_disk()
		elif current in [4,5] and held_trigger:
			var hand := point.global_position-eye
			var direction := (rooms[current].global_basis.inverse()*hand).limit_length(1.0)
			metric_step(direction*delta*0.5)
		elif current==6 and not shooting and visual_tick>0.1:
			var angle := clampf(p.x*0.8,-1.3,1.3)
			if absf(angle-shot_angle)>0.015: shot_angle=angle; redraw_shot()
	if current in [4,5]: update_fields()
	if current==6: tick_shot(delta)
	if visual_tick>0.1: visual_tick=0
	# A free point also crosses the ordinary portal without a replacement instance.
	if not point.held() and crossing_cooldown<=0:
		if current==-1 and swept_door(to_local(last_point),to_local(point.global_position)):
			point.global_position+=rooms[0].to_global(Vector3(0,0,5.7))-global_position
		elif current==0:
			var a := rooms[0].to_local(last_point)-Vector3(0,0,5.7)
			var b := rooms[0].to_local(point.global_position)-Vector3(0,0,5.7)
			a.z=-a.z; b.z=-b.z
			if swept_door(a,b): point.global_position+=global_position-rooms[0].to_global(Vector3(0,0,5.7))
	var pp := rooms[0].to_local(point.global_position)
	point_preview.visible=current==-1 and absf(pp.x)<7 and absf(pp.z)<6 and absf(pp.y)<6
	point_preview.position=pp-Vector3(0,0,5.7)
	last_point=point.global_position
