extends Node3D
const Drone = preload("drone.gd")
const Flight = preload("flight.gd")
const PointBody = preload("res://commons/artifacts/particle_swarm_walk/point_body.gd")
const DisplaySelector = preload("res://commons/interactables/physical_stepped_slider.gd")
const LightHalo = preload("light_halo.gdshader")
enum Appearance { DRONE, POINT, LIGHT }
const SELECTOR_HOME := Vector3(-5.8,1.15,-.55)
const COUNT := 12
const HOME := Vector3(-5.8,1.18,0)
const BLUE := Color("67d9e5")
const PINK := Color("f58fbc")
const GOLD := Color("ffdb91")
var flights: Array[Node3D] = []
var point: XRToolsPickable
var target_offset := Vector3.ZERO
var guides := true
var playing := true
var slots: Array[MeshInstance3D] = []
var beacons: Array[MeshInstance3D] = []
var arrows: Array[MeshInstance3D] = []
var tips: Array[MeshInstance3D] = []
var witnesses: Array[MeshInstance3D] = []
var neighbour_links: Array[MeshInstance3D] = []
var destination_links: Array[MeshInstance3D] = []
var status: Label3D
var elapsed := 0.0
var released_time := 0.0
var appearance := Appearance.DRONE
var display_selector: Node3D
var display_readout: Label3D
var body_views: Array[Array] = []

func mat(colour: Color, glow := false) -> StandardMaterial3D:
	var m:=StandardMaterial3D.new();m.albedo_color=colour;m.roughness=.4;m.metallic=.15
	if glow: m.emission_enabled=true;m.emission=colour;m.emission_energy_multiplier=.45
	return m

func part(mesh: Mesh, at: Vector3, colour: Color, parent: Node3D = self) -> MeshInstance3D:
	var n:=MeshInstance3D.new();n.mesh=mesh;n.position=at;n.material_override=mat(colour);parent.add_child(n);return n

func box(size:Vector3,at:Vector3,colour:Color,parent:Node3D=self) -> MeshInstance3D:
	var mesh:=BoxMesh.new();mesh.size=size;return part(mesh,at,colour,parent)

func ring(r:float,thin:float,at:Vector3,colour:Color,parent:Node3D=self) -> MeshInstance3D:
	var mesh:=TorusMesh.new();mesh.inner_radius=r-thin;mesh.outer_radius=r+thin;mesh.rings=24;mesh.ring_segments=6
	return part(mesh,at,colour,parent)

func label(words:String,at:Vector3,size:=26) -> Label3D:
	var n:=Label3D.new();n.text=words;n.position=at;n.font_size=size;n.pixel_size=.003;n.outline_size=7
	n.billboard=BaseMaterial3D.BILLBOARD_ENABLED;add_child(n);return n

func line(colour:Color,width:=.012) -> MeshInstance3D:
	var mesh:=CylinderMesh.new();mesh.top_radius=width;mesh.bottom_radius=width;mesh.height=1;mesh.radial_segments=6
	var n:=part(mesh,Vector3.ZERO,colour)
	n.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	return n

func between(n:MeshInstance3D,a:Vector3,b:Vector3) -> void:
	var length:=a.distance_to(b);n.visible=guides and length>.001
	if length<.001:return
	n.position=(a+b)*.5
	n.basis=Basis(Quaternion(Vector3.UP,(b-a)/length)).scaled(Vector3(1,length,1))

func _ready() -> void:
	var rng:=RandomNumberGenerator.new();rng.seed=101101
	var starts:Array[Vector3]=[];var velocities:Array[Vector3]=[]
	for i in range(COUNT):
		starts.append(Vector3((i%4-1.5)*1.2+rng.randf_range(-.32,.32),rng.randf_range(-.15,.15),(i/4-1)*.85+rng.randf_range(-.2,.2)))
		velocities.append(Vector3(.4,rng.randf_range(-.08,.08),rng.randf_range(-.25,.25)))
	for group in range(2):
		var colour:Color=BLUE if group==0 else PINK
		var flight:=Flight.new();flight.name="AssignedFlight" if group==0 else "NeighbourFlight"
		flight.assigned=group==0;flight.encounter=self;flight.position=Vector3(0,2.1,-3.1 if group==0 else 3.1)
		add_child(flight);flights.append(flight)
		# Floor markings are display only; the middle aisle remains fully walkable.
		box(Vector3(8.8,.016,4.0),Vector3(0,.014,flight.position.z),Color("263345"))
		for z in [-2.0,2.0]:box(Vector3(8.8,.022,.04),Vector3(0,.026,flight.position.z+z),colour)
		for x in [-4.4,4.4]:box(Vector3(.04,.022,4.0),Vector3(x,.026,flight.position.z),colour)
		label("ASSIGNED SLOTS" if group==0 else "NEIGHBOURS + COMMON TARGET",Vector3(0,3.4,flight.position.z),48)
		label("Each body has its own destination" if group==0 else "Alignment + cohesion + separation",Vector3(0,3.05,flight.position.z),28)
		var light:=OmniLight3D.new();light.position=flight.position+Vector3(0,2.5,0)
		light.omni_range=8;light.light_energy=2.2;light.shadow_enabled=false;add_child(light)
		for i in range(COUNT):
			var d:=Drone.new();d.name="Drone%02d"%i;d.flight=flight
			d.slot=Vector3((i%4-1.5)*1.2,0,(i/4-1)*.85)
			d.max_speed=1.3;d.min_speed=0;d.max_force=1
			d.perception_radius=2.0;d.avoid_radius=.85;d.separation_weight=2.2
			d.alignment_weight=0.0 if group==0 else .85;d.cohesion_weight=0.0 if group==0 else .75
			d.boundary_size=Vector3(8.8,2,4);d.boundary_margin=.4;d.boundary_force=8;d.boundary_frame=flight
			flight.add_child(d);flight.drones.append(d);d.position=starts[i]
			d.velocity=global_basis.orthonormalized()*velocities[i]
			_build_drone(d, GOLD if i==0 else colour)
			if group==0: slots.append(ring(.18,.015,flight.position+d.slot,BLUE))
		beacons.append(ring(.32,.018,flight.position,colour))
		witnesses.append(ring(.48,.014,flight.position,GOLD))
		arrows.append(line(GOLD,.022));destination_links.append(line(colour,.007))
		var tip:=CylinderMesh.new();tip.top_radius=0;tip.bottom_radius=.08;tip.height=.18;tip.radial_segments=8
		tips.append(part(tip,Vector3.ZERO,GOLD))
	for i in range(COUNT-1):neighbour_links.append(line(PINK,.006))
	box(Vector3(.38,1.02,.38),Vector3(HOME.x,.51,0),Color("e7e6df"))
	var stand:=StaticBody3D.new();stand.name="PointStand";stand.collision_layer=1;stand.collision_mask=0
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.38,1.02,.38)
	collision.shape=shape;stand.add_child(collision);add_child(stand);stand.position=Vector3(HOME.x,.51,0)
	point=PointBody.new();point.name="GuidancePoint";add_child(point);point.position=HOME
	point.action_pressed.connect(func(_p):
		if point.held():guides=not guides)
	label("TWO KINDS OF GUIDANCE",Vector3(-5.6,2.25,0),30)
	label("Carry the point: shift both destinations\nTrigger / left click: show or hide guidance\nLet go: both destinations return to centre",Vector3(-5.6,1.86,0),18)
	status=label("",Vector3(-5.6,1.49,0),17)
	_build_display_selector()
	_refresh()

func _build_drone(d:Node3D,colour:Color) -> void:
	# Views are built once under the existing body. Changing the view touches
	# visibility only: no new agents, destinations, random draws or motion state.
	var drone_view:=Node3D.new();drone_view.name="DroneView";d.add_child(drone_view)
	var mesh:=SphereMesh.new();mesh.radius=.13;mesh.height=.26;mesh.radial_segments=16;mesh.rings=8
	part(mesh,Vector3.ZERO,Color("171e2a"),drone_view)
	for x in [-.23,.23]:
		for z in [-.23,.23]:
			ring(.14,.025,Vector3(x,0,z),colour,drone_view)
			box(Vector3(.27,.024,.025),Vector3(x,0,z),Color("ccd3da"),drone_view)
	for angle in [-PI/4,PI/4]:
		var arm:=box(Vector3(.66,.045,.045),Vector3.ZERO,colour,drone_view);arm.rotation.y=angle
	var eye:=SphereMesh.new();eye.radius=.045;eye.height=.09;eye.radial_segments=8;eye.rings=4
	part(eye,Vector3(0,0,-.13),colour,drone_view)
	var point_view:=Node3D.new();point_view.name="PointView";d.add_child(point_view)
	part(mesh,Vector3.ZERO,colour,point_view)
	var light_view:=Node3D.new();light_view.name="LightView";d.add_child(light_view)
	var core_mesh:=SphereMesh.new();core_mesh.radius=.085;core_mesh.height=.17;core_mesh.radial_segments=12;core_mesh.rings=6
	var core:=part(core_mesh,Vector3.ZERO,colour.lightened(.65),light_view)
	core.material_override.shading_mode=BaseMaterial3D.SHADING_MODE_UNSHADED
	core.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	var halo_mesh:=SphereMesh.new();halo_mesh.radius=.22;halo_mesh.height=.44;halo_mesh.radial_segments=16;halo_mesh.rings=8
	var halo:=part(halo_mesh,Vector3.ZERO,colour,light_view)
	var glow:=ShaderMaterial.new();glow.shader=LightHalo;glow.set_shader_parameter("tint",colour)
	halo.material_override=glow;halo.cast_shadow=GeometryInstance3D.SHADOW_CASTING_SETTING_OFF
	body_views.append([drone_view,point_view,light_view])
	point_view.hide();light_view.hide()

func _build_display_selector() -> void:
	box(Vector3(.18,1.02,.18),Vector3(SELECTOR_HOME.x,.51,SELECTOR_HOME.z),Color("e7e6df"))
	var base:=StaticBody3D.new();base.name="DisplayStand";base.collision_layer=1;base.collision_mask=0
	var collision:=CollisionShape3D.new();var shape:=BoxShape3D.new();shape.size=Vector3(.18,1.02,.18)
	collision.shape=shape;base.add_child(collision);add_child(base);base.position=Vector3(SELECTOR_HOME.x,.51,SELECTOR_HOME.z)
	display_selector=DisplaySelector.new();display_selector.name="AppearanceSelector"
	display_selector.step_count=3;display_selector.param_name="APPEARANCE"
	display_selector.position=SELECTOR_HOME;display_selector.rotation.y=-PI/2
	add_child(display_selector)
	display_selector.value_changed.connect(func(v):set_appearance(roundi(v*2)))
	display_readout=label("",SELECTOR_HOME+Vector3(0,.55,-.3),18)
	label("1 DRONE / 2 POINT / 3 LIGHT\nSlide to change appearance",SELECTOR_HOME+Vector3(0,.32,-.3),14)
	set_appearance(Appearance.DRONE)

func set_appearance(mode:int) -> void:
	appearance=clampi(mode,Appearance.DRONE,Appearance.LIGHT)
	for views in body_views:
		for i in range(3):views[i].visible=i==appearance
	if display_selector!=null:display_selector.set_normalized_value(appearance/2.0)
	if display_readout!=null:display_readout.text="LOOK: "+["DRONE","POINT","LIGHT"][appearance]

func _physics_process(dt:float) -> void:
	if point.held():
		released_time=0
		var displacement:=to_local(point.global_position)-HOME
		target_offset=Vector3(clampf(displacement.x,-1.6,1.6),clampf(displacement.y,-.45,.45),clampf(displacement.z,-.65,.65))
	else:
		released_time+=dt;target_offset=target_offset.move_toward(Vector3.ZERO,dt*1.5)
		if released_time>1.5:point.global_position=to_global(HOME)
	for flight in flights:
		for d in flight.drones:d.set_physics_process(playing)

func _process(dt:float) -> void:
	elapsed+=dt;_refresh()

func _refresh() -> void:
	if flights.size()!=2:return
	for group in range(2):
		var flight:Node3D=flights[group];var d=flight.drones[0]
		var at:=to_local(d.global_position);var acceleration:Vector3=global_basis.inverse()*d.acceleration
		beacons[group].position=flight.position+target_offset;beacons[group].visible=guides
		witnesses[group].position=at;witnesses[group].visible=guides
		var end:=at+acceleration*.25
		between(arrows[group],at,end);tips[group].visible=guides and acceleration.length()>.001
		if acceleration.length()>.001:
			tips[group].position=end;tips[group].basis=Basis(Quaternion(Vector3.UP,acceleration.normalized()))
		between(destination_links[group],at,to_local(d.destination()))
	for i in range(COUNT):
		slots[i].position=flights[0].position+target_offset+flights[0].drones[i].slot;slots[i].visible=guides
	var witness=flights[1].drones[0]
	for i in range(1,COUNT):
		var other=flights[1].drones[i]
		between(neighbour_links[i-1],to_local(witness.global_position),to_local(other.global_position))
		neighbour_links[i-1].visible=guides and witness.global_position.distance_to(other.global_position)<witness.perception_radius
	if status!=null:status.text="Hand offset: %.2f, %.2f, %.2f m\nGold arrow: steering, 0.25 m per m/s²"%[target_offset.x,target_offset.y,target_offset.z]

func get_museum_occupied_cells() -> Array[Vector2i]:
	var result:Array[Vector2i]=[]
	for spec in [[HOME,.19],[SELECTOR_HOME,.09]]:
		var p:=to_global(spec[0]);var extent:float=spec[1]
		for x in range(floori(p.x-extent),floori(p.x+extent)+1):
			for z in range(floori(p.z-extent),floori(p.z+extent)+1):
				var cell:=Vector2i(x,z)
				if not result.has(cell):result.append(cell)
	return result
