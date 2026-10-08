extends "res://commons/artifacts/timing_machines/machine_stage.gd"
## A physical comparison inspired by Palle Torsson's 2021 Unity experiment.
## Finite batches and observation windows; no entropy or optimisation is inferred.
const NAMES := ["SINE", "RANDOM HEIGHTS", "PERLIN", "WORLEY F1"]
const CENTRES := [Vector3(-1.55,0,-2.35),Vector3(1.55,0,-2.35),Vector3(-1.55,0,2.35),Vector3(1.55,0,2.35)]
const AMPLITUDES := [0.12,0.30,0.55]
const ANGLES := [0.0,20.0,35.0]
const RADII := [0.045,0.075,0.105]
const WINDOWS := [8,12,20]
const NX := 20
const NZ := 32
const BATCH := 32
var amp_index := 1
var angle_index := 1
var radius_index := 1
var window_index := 1
var seed_value := 1729
var ticks := 0
var running := false
var has_run := false
var reveal := false
var trays: Array[Node3D] = []
var bodies: Array[RigidBody3D] = []
var states: Array[int] = [] # 0 on tray/unresolved, 1 crossed outlet, 2 other exit
var terrain_meshes: Array[MeshInstance3D] = []
var surfaces: Array[PackedFloat32Array] = []
var labels: Array[Label3D] = []
var settings_panel: Node3D
var run_panel: Node3D
var details: Label3D
var gravity := 9.8
var hz := 60

func _ready() -> void:
	gravity=float(ProjectSettings.get_setting("physics/3d/default_gravity",9.8))
	hz=Engine.physics_ticks_per_second
	for i in 4:
		var tray=Node3D.new();tray.name=NAMES[i].replace(" ","");tray.position=CENTRES[i]+Vector3.UP*1.3;add_child(tray);trays.append(tray)
		for x in [-1.04,1.04]:box(Vector3(x,0.30,0),Vector3(0.08,0.9,3.3),material("253c48"),true,tray)
		box(Vector3(0,0.30,-1.64),Vector3(2.16,0.9,0.08),material("253c48"),true,tray)
		box(Vector3(0,-0.10,0),Vector3(2.16,0.10,3.3),material("263b45"),true,tray)
		box(Vector3(0,0.02,1.64),Vector3(2.0,0.02,0.035),material("eebd6d",true),false,tray)
		# Supports stay under the central pivot rather than piercing the low end of the tilted surface.
		for x in [-0.8,0.8]:box(CENTRES[i]+Vector3(x,0.59,0),Vector3(0.12,1.18,0.22),material("263b45"),true)
		# The collection display stores outcomes, rather than feeding them back into the tray.
		box(CENTRES[i]+Vector3(0,0.30,2.02),Vector3(2.15,0.12,0.66),material("182b35"),true)
		var caption=label("",CENTRES[i]+Vector3(0,0.53,2.43),0.00115);labels.append(caption)
		box(CENTRES[i]+Vector3(0,0.53,2.38),Vector3(2.7,0.48,0.055),material("13212b"))
	settings_panel=load("res://commons/artifacts/timing_machines/machine_stage.gd").new();add_child(settings_panel)
	settings_panel.position=Vector3(4.9,0,0);settings_panel.rotation.y=PI/2
	settings_panel.console(["TILT","RELIEF","SIZE","SEED","WINDOW"],0,"SAME CONDITIONS, FOUR SURFACES")
	run_panel=load("res://commons/artifacts/timing_machines/machine_stage.gd").new();add_child(run_panel)
	run_panel.position=Vector3(0,0,6);run_panel.console(["RELEASE","PAUSE","RESET","RULE"],0,"PREDICT WHAT WILL LEAVE")
	for panel in [settings_panel,run_panel]:
		for id in panel.buttons:
			buttons[id]=panel.buttons[id];panel.buttons[id].pressed.connect(act.bind(id))
	details=label("",Vector3(0,3.25,-4.5),0.002)
	box(Vector3(0,3.25,-4.55),Vector3(6.3,1.25,0.08),material("13212b"))
	for x in [-2.9,2.9]:box(Vector3(x,1.6,-4.55),Vector3(0.1,3.2,0.1),material("263b45"),true)
	rebuild()

func generate_samples(mode: int) -> PackedFloat32Array:
	var values=PackedFloat32Array();var rng=RandomNumberGenerator.new();rng.seed=seed_value
	var noise=FastNoiseLite.new();noise.seed=seed_value;noise.frequency=0.9;noise.fractal_type=FastNoiseLite.FRACTAL_NONE
	noise.noise_type=FastNoiseLite.TYPE_PERLIN if mode==2 else FastNoiseLite.TYPE_CELLULAR
	noise.cellular_return_type=FastNoiseLite.RETURN_DISTANCE
	noise.cellular_distance_function=FastNoiseLite.DISTANCE_EUCLIDEAN
	for iz in NZ+1:
		for ix in NX+1:
			var x=-1.0+2.0*ix/NX;var z=-1.6+3.2*iz/NZ;var v:float
			match mode:
				0:v=sin(TAU*0.9*x)*sin(TAU*0.9*z)
				1:v=rng.randf_range(-1,1)
				_:v=noise.get_noise_2d(x,z)
			values.append(v)
	# A declared per-tray min/max normalisation holds peak-to-trough relief equal.
	var lo=values[0];var hi=values[0]
	for v in values:lo=minf(lo,v);hi=maxf(hi,v)
	for i in values.size():values[i]=AMPLITUDES[amp_index]*(values[i]-lo)/maxf(hi-lo,0.000001)
	return values

func rebuild() -> void:
	reset_batch()
	for m in terrain_meshes:
		var body=m.get_parent();body.get_parent().remove_child(body);body.queue_free()
	terrain_meshes.clear();surfaces.clear()
	for mode in 4:
		trays[mode].rotation.x=deg_to_rad(ANGLES[angle_index])
		var values=generate_samples(mode);surfaces.append(values)
		var st=SurfaceTool.new();st.begin(Mesh.PRIMITIVE_TRIANGLES)
		for iz in NZ:
			for ix in NX:
				for corner in [Vector2i(0,0),Vector2i(1,0),Vector2i(0,1),Vector2i(1,0),Vector2i(1,1),Vector2i(0,1)]:
					var a=ix+corner.x;var b=iz+corner.y
					st.set_color(Color("294c68").lerp(Color("9fcaca"),values[b*(NX+1)+a]/AMPLITUDES[amp_index]))
					st.add_vertex(Vector3(-1.0+2.0*a/NX,values[b*(NX+1)+a],-1.6+3.2*b/NZ))
		st.generate_normals();var mesh=st.commit()
		var body=StaticBody3D.new();body.name="MeasuredSurface";trays[mode].add_child(body)
		var pm=PhysicsMaterial.new();pm.friction=0.45;pm.bounce=0.0;body.physics_material_override=pm
		var collider=CollisionShape3D.new();collider.shape=mesh.create_trimesh_shape();body.add_child(collider)
		var finish=material("ffffff");finish.vertex_color_use_as_albedo=true;finish.roughness=0.95
		var visual=MeshInstance3D.new();visual.mesh=mesh;visual.material_override=finish;body.add_child(visual);terrain_meshes.append(visual)
	refresh()

func reset_batch() -> void:
	running=false;has_run=false;ticks=0
	for body in bodies:
		if is_instance_valid(body):body.get_parent().remove_child(body);body.queue_free()
	bodies.clear();states.clear()
	refresh()

func release() -> void:
	reset_batch();has_run=true
	for mode in 4:
		for i in BATCH:
			var body=RigidBody3D.new();body.mass=0.1;body.gravity_scale=1;body.linear_damp_mode=RigidBody3D.DAMP_MODE_REPLACE;body.linear_damp=0.05;body.angular_damp_mode=RigidBody3D.DAMP_MODE_REPLACE;body.angular_damp=0.05
			body.continuous_cd=true;body.freeze=true
			var pm=PhysicsMaterial.new();pm.friction=0.45;pm.bounce=0.0;body.physics_material_override=pm
			var radius:float=RADII[radius_index];var shape=SphereShape3D.new();shape.radius=radius
			var collision=CollisionShape3D.new();collision.shape=shape;body.add_child(collision)
			var sphere=SphereMesh.new();sphere.radius=radius;sphere.height=radius*2
			var visual=MeshInstance3D.new();visual.mesh=sphere;visual.material_override=material("f8d583");body.add_child(visual)
			# A shared tray-local release keeps every sphere above the tray when tilt changes.
			add_child(body);body.global_position=trays[mode].to_global(Vector3(-0.75+0.5*(i%4),1.1,-1.3+0.28*(i/4)))
			bodies.append(body);states.append(0)
	# Enable on the next physics tick, after all collision shapes are registered.
	running=true;refresh()

func record_exit(index: int, kind: int) -> void:
	if states[index]!=0:return
	states[index]=kind
	var body=bodies[index];body.freeze=true;body.collision_layer=0;body.collision_mask=0
	var mode=index/BATCH;var slot=index%BATCH
	body.position=CENTRES[mode]+Vector3(-0.92+(slot%8)*0.26,0.48+(slot/8)*0.12,2.0)
	if kind==2:body.get_child(1).material_override=material("7c8392")

func _physics_process(_delta: float) -> void:
	if not running:return
	if ticks==0:
		for b in bodies:b.freeze=false
	for i in bodies.size():
		if states[i]!=0:continue
		var mode=i/BATCH;var p=trays[mode].to_local(bodies[i].global_position);var r:float=RADII[radius_index]
		if absf(p.x)>1.06+r or p.z < -1.68-r or p.y < -0.4:record_exit(i,2)
		elif p.z>1.6+r:record_exit(i,1)
	ticks+=1
	if ticks>=WINDOWS[window_index]*hz:
		running=false
		for b in bodies:b.freeze=true
	if ticks%6==0 or not running:refresh()

func counts(mode:int) -> Array:
	var out=[0,0,0]
	for i in range(mode*BATCH,mini((mode+1)*BATCH,states.size())):out[states[i]]+=1
	return out

func act(id: String) -> void:
	match id:
		"RELEASE":release()
		"RESET":reset_batch()
		"PAUSE":
			if has_run and ticks<WINDOWS[window_index]*hz:
				running=not running
				for i in bodies.size():bodies[i].freeze=not running or states[i]!=0
		"RULE":reveal=not reveal
		"TILT":angle_index=(angle_index+1)%ANGLES.size();rebuild()
		"RELIEF":amp_index=(amp_index+1)%AMPLITUDES.size();rebuild()
		"SIZE":radius_index=(radius_index+1)%RADII.size();reset_batch()
		"SEED":seed_value+=1;rebuild()
		"WINDOW":window_index=(window_index+1)%WINDOWS.size();reset_batch()
	refresh()

func refresh() -> void:
	if labels.size()!=4 or run_panel==null:return
	for mode in 4:
		var c=counts(mode);labels[mode].text="%s\nOUTLET %d / STILL IN %d / OTHER EXIT %d\n32 released together; fixed observation window"%[NAMES[mode],c[1],c[0],c[2]] if has_run else NAMES[mode]+"\nPredict what leaves.\nSame release, different surface."
	var state="READY"
	if has_run:state="WINDOW ENDED" if ticks>=WINDOWS[window_index]*hz else ("RUNNING" if running else "PAUSED")
	run_panel.readout.text="%s  %.1f / %d s\nRELEASE repeats; RESET keeps settings"%[state,float(ticks)/hz,WINDOWS[window_index]]
	settings_panel.readout.text="Tilt %.0f deg / relief %.2f m / radius %.3f m\nSeed %d / window %d s"%[ANGLES[angle_index],AMPLITUDES[amp_index],RADII[radius_index],seed_value,WINDOWS[window_index]]
	if details:
		details.text="WHAT LEAVES? WHAT REMAINS?\nFour physical surfaces. One release pattern.\nStill in at the deadline does not mean permanently trapped."
		if reveal:details.text="A PHYSICAL COMPARISON, NOT GRADIENT DESCENT\n20 x 32 triangulated cells; each tray normalised to the same relief.\nGravity %.2f m/s2 / friction 0.45 / bounce 0 / %d physics ticks/s\nSeed replays the field; contact trajectories need not replay exactly."%[gravity,hz]

func snapshot() -> Dictionary:
	var result={"seed":seed_value,"tilt_degrees":ANGLES[angle_index],"relief_m":AMPLITUDES[amp_index],"radius_m":RADII[radius_index],"window_seconds":WINDOWS[window_index],"elapsed_ticks":ticks,"physics_hz":hz,"gravity":gravity,"batch_per_tray":BATCH,"counts":{}}
	for mode in 4:
		var c=counts(mode);result.counts[NAMES[mode]]={"outlet":c[1],"still_in":c[0],"other_exit":c[2]}
	return result
