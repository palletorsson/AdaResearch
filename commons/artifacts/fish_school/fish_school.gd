extends Node3D
## Balcony encounter: existing Boid rules + an explicit, bounded hand term.
const Fish = preload("fish.gd")
const PointBody = preload("res://commons/artifacts/particle_swarm_walk/point_body.gd")
const COUNT := 72
const RADIUS := 8.0
const HAND_FORCE := 5.0
const HOME := Vector3(0,1.18,0)
const CENTRE := Vector3(-3.2,2.1,0)
const CYAN := Color("65e2e5")
const PINK := Color("ff85b0")
var boids: Array[Node3D] = []
var point: XRToolsPickable
var boundary: Node3D
var scatter := false
var playing := true
var ring: MeshInstance3D
var range_rings: Array[MeshInstance3D] = []
var vector: MeshInstance3D
var arrowhead: MeshInstance3D
var status: Label3D
var witness: MeshInstance3D
var elapsed := 0.0
var ui_elapsed := 0.0
var unheld_seconds := 0.0

func material(colour: Color, glow := false) -> StandardMaterial3D:
	var m := StandardMaterial3D.new()
	m.albedo_color=colour; m.roughness=0.3; m.metallic=0.25
	if glow:
		m.emission_enabled=true; m.emission=colour; m.emission_energy_multiplier=0.65
	return m

func part(mesh: Mesh, at: Vector3, colour: Color, parent: Node3D = self) -> MeshInstance3D:
	var n := MeshInstance3D.new(); n.mesh=mesh; n.position=at
	n.material_override=material(colour); parent.add_child(n); return n

func torus(radius: float, thickness: float, colour: Color) -> MeshInstance3D:
	var mesh := TorusMesh.new(); mesh.inner_radius=radius-thickness; mesh.outer_radius=radius+thickness
	mesh.rings=64; mesh.ring_segments=6
	return part(mesh,Vector3.ZERO,colour)

func caption(words: String, at: Vector3, size := 30) -> Label3D:
	var l := Label3D.new(); l.text=words; l.position=at
	l.font_size=size; l.pixel_size=0.003; l.outline_size=8
	l.billboard=BaseMaterial3D.BILLBOARD_ENABLED; add_child(l); return l

func _ready() -> void:
	boundary=Node3D.new(); boundary.name="SchoolBoundary"; add_child(boundary); boundary.position=CENTRE
	var plinth := CylinderMesh.new(); plinth.top_radius=.23; plinth.bottom_radius=.33; plinth.height=1.03
	part(plinth,Vector3(0,.515,0),Color("e2e1da"))
	var stand:=StaticBody3D.new();stand.name="PointStand";stand.collision_layer=1
	var collision:=CollisionShape3D.new();var shape:=CylinderShape3D.new();shape.radius=.33;shape.height=1.03
	collision.shape=shape;collision.position.y=.515;stand.add_child(collision);add_child(stand)
	var base := CylinderMesh.new(); base.top_radius=.40; base.bottom_radius=.40; base.height=.06
	part(base,Vector3(0,.03,0),Color("242d36"))
	point=PointBody.new(); point.name="SchoolPoint"; add_child(point); point.position=HOME
	point.action_pressed.connect(func(_p): scatter=true if point.held() else false)
	point.action_released.connect(func(_p): scatter=false)
	point.dropped.connect(func(_p): scatter=false)
	ring=torus(.105,.009,CYAN)
	status=caption("",HOME+Vector3(0,.35,0),23)
	caption("A SCHOOL WITHIN REACH",Vector3(0,2.12,0),34)
	caption("Hold the point: gather\nHold trigger / left click: scatter\nLet go: their rules continue",Vector3(0,1.78,0),20)
	for axis in range(3):
		var r:=torus(RADIUS,.008,CYAN)
		if axis==1: r.rotation.x=PI/2
		if axis==2: r.rotation.z=PI/2
		r.visible=false; range_rings.append(r)
	var shaft := CylinderMesh.new(); shaft.top_radius=.016; shaft.bottom_radius=.016; shaft.height=1.0; shaft.radial_segments=8
	vector=part(shaft,Vector3.ZERO,CYAN); vector.visible=false
	var tip:=CylinderMesh.new();tip.top_radius=0;tip.bottom_radius=.07;tip.height=.18;tip.radial_segments=8
	arrowhead=part(tip,Vector3.ZERO,CYAN);arrowhead.visible=false
	witness=torus(.30,.012,Color("ffe49a"))
	_spawn()
	_refresh()

func _spawn() -> void:
	var rng:=RandomNumberGenerator.new(); rng.seed=101010
	var body_mesh:=SphereMesh.new(); body_mesh.radius=.16; body_mesh.height=.32
	body_mesh.radial_segments=12; body_mesh.rings=6
	var fin_mesh:=ArrayMesh.new()
	var arrays:=[]; arrays.resize(Mesh.ARRAY_MAX)
	arrays[Mesh.ARRAY_VERTEX]=PackedVector3Array([
		Vector3(0,0,.19),Vector3(0,.23,.47),Vector3(0,-.23,.47),
		Vector3(0,.07,-.12),Vector3(0,.30,.10),Vector3(0,.07,.19),
		Vector3(-.08,0,0),Vector3(-.28,-.03,.16),Vector3(-.07,0,.20),
		Vector3(.08,0,0),Vector3(.07,0,.20),Vector3(.28,-.03,.16)])
	var normals:=PackedVector3Array()
	for i in range(0,12,3):
		var a:Vector3=arrays[Mesh.ARRAY_VERTEX][i];var b:Vector3=arrays[Mesh.ARRAY_VERTEX][i+1];var c:Vector3=arrays[Mesh.ARRAY_VERTEX][i+2]
		var normal:Vector3=(b-a).cross(c-a).normalized()
		for j in range(3):normals.append(normal)
	arrays[Mesh.ARRAY_NORMAL]=normals
	fin_mesh.add_surface_from_arrays(Mesh.PRIMITIVE_TRIANGLES,arrays)
	var palette: Array[Color]=[Color("91e5e4"),Color("51a8d3"),Color("b3cfe8"),Color("e8c47f")]
	var eye_mesh:=SphereMesh.new(); eye_mesh.radius=.028;eye_mesh.height=.056;eye_mesh.radial_segments=8;eye_mesh.rings=4
	for i in range(COUNT):
		var b=Fish.new(); b.name="Fish%02d"%i
		b.min_speed=.65; b.max_speed=2.3; b.max_force=1.0
		b.perception_radius=2.6; b.avoid_radius=1.15; b.separation_weight=2.6
		b.boundary_size=Vector3(11,4,10); b.boundary_margin=1.0; b.boundary_force=8.0
		b.boundary_frame=boundary; b.steering_source=self
		add_child(b)
		b.position=CENTRE+Vector3(rng.randf_range(-4,4),rng.randf_range(-1.2,1.2),rng.randf_range(-3.8,3.8))
		b.velocity=global_basis.orthonormalized()*Vector3(.8,rng.randf_range(-.18,.18),rng.randf_range(-.5,.5)).normalized()*1.6
		var colour:Color=palette[i%palette.size()]
		var body:=part(body_mesh,Vector3.ZERO,colour,b);body.scale=Vector3(.6,1,1.8)
		var tail:=part(fin_mesh,Vector3.ZERO,colour.darkened(.12),b)
		tail.material_override.cull_mode=BaseMaterial3D.CULL_DISABLED
		part(eye_mesh,Vector3(-.086,.035,-.15),Color("111820"),b)
		part(eye_mesh,Vector3(.086,.035,-.15),Color("111820"),b)
		boids.append(b)

func get_boids() -> Array[Node3D]: return boids

func steering_at(world_position: Vector3, velocity: Vector3) -> Vector3:
	if not is_instance_valid(point) or not point.held(): return Vector3.ZERO
	var toward:=point.global_position-world_position
	var distance:=toward.length()
	if distance>=RADIUS or distance<.001: return Vector3.ZERO
	var direction:=toward/distance
	# Near the sphere, arrive rather than drive through the hand. Scatter keeps speed.
	var desired:=direction*(-2.3 if scatter else 2.3*minf(distance/1.4,1.0))
	return (desired-velocity).limit_length(HAND_FORCE)*(1.0-distance/RADIUS)

func _physics_process(dt: float) -> void:
	# Pausing for a comparison stops integration, not rendering or the held point.
	for b in boids: b.set_physics_process(playing)
	if not point.held():
		scatter=false; unheld_seconds+=dt
		# Return a dropped point after a short pause; it cannot be lost in the void.
		if unheld_seconds>1.5: point.global_position=to_global(HOME)
	else: unheld_seconds=0.0

func _process(dt: float) -> void:
	elapsed+=dt; ui_elapsed+=dt
	if ui_elapsed>.08:
		ui_elapsed=0; _refresh()

func _refresh() -> void:
	if not is_instance_valid(point): return
	var active:bool=point.held()
	var colour:=PINK if scatter and active else CYAN
	ring.global_position=point.global_position
	ring.material_override.albedo_color=colour
	ring.visible=active
	var nearby:=0
	for b in boids:
		if b.global_position.distance_to(point.global_position)<RADIUS: nearby+=1
	status.global_position=point.global_position+Vector3.UP*.30
	status.text=("SCATTER" if scatter else "GATHER")+" | %d within 8 m"%nearby if active else "POINT | grip to gather"
	for r in range_rings:
		r.global_position=point.global_position; r.visible=active
		r.material_override.albedo_color=colour.darkened(.25)
	if boids.is_empty(): return
	# A stable witness, not a nearest-fish identity that changes every frame.
	var b:Node3D=boids[0]
	witness.global_position=b.global_position
	var force:=steering_at(b.global_position,b.velocity)
	vector.visible=force.length()>.01
	arrowhead.visible=vector.visible
	if vector.visible:
		var end:=b.global_position+force*.55
		vector.global_position=(b.global_position+end)*.5
		var y:=force.normalized();var helper:=Vector3.RIGHT if absf(y.dot(Vector3.UP))>.95 else Vector3.UP
		var x:=helper.cross(y).normalized()
		vector.global_basis=Basis(x,y,y.cross(x)).scaled(Vector3(1,force.length()*.55,1))
		vector.material_override.albedo_color=colour
		arrowhead.global_position=end
		arrowhead.global_basis=Basis(x,y,y.cross(x))
		arrowhead.material_override.albedo_color=colour

func get_museum_occupied_cells() -> Array[Vector2i]:
	# Only the stand blocks walking. Fish and range rings have no body collider.
	var cells:Array[Vector2i]=[]
	for x in range(floori(global_position.x-.33),floori(global_position.x+.33)+1):
		for z in range(floori(global_position.z-.33),floori(global_position.z+.33)+1):cells.append(Vector2i(x,z))
	return cells

func apply_grid_config(_config: Dictionary) -> void: pass
