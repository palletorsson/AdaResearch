extends "res://commons/artifacts/spine_films/film_stage.gd"
const E=preload("res://commons/artifacts/spine_films/early/geometry.gd")
const Shapes=preload("res://commons/soft_body/soft_body_shapes.gd")
var snapshots:Array[PackedVector3Array]=[]
var springs:Array=[]
var masses:Array[MeshInstance3D]=[]
var bonds:Array[MeshInstance3D]=[]
var ghosts:Array[MeshInstance3D]=[]
var step_label:Label3D

func _build()->void:
	title_text="A network settles into a body"
	phases.assign(["The bench begins with a lattice", "Give neighbours a resting distance", "Eighty existing solver steps", "The rule has found a form"])
	notes.assign(["A private replay of the bench's 4 x 3 x 4 particles, with a fixed jitter seed.","These are the factory's actual edge and face-diagonal springs.","The original Verlet and distance-constraint solver runs unchanged.","The pale ghost retains the start. The museum bench displays the settled snapshot."])
	source_paths.assign(["res://commons/artifacts/mass_spring_bench/mass_spring_bench.gd","res://commons/soft_body/soft_body_shapes.gd","res://commons/soft_body/soft_body_sim.gd"])
	var sim=Shapes.make_jelly_grid(4,3,4,0.16,0.6)
	sim.floor_y=0.0;sim.gravity=Vector3(0,-4.5,0);sim.damping=0.985
	var rng:=RandomNumberGenerator.new();rng.seed=7
	for i in range(sim.positions.size()):
		sim.positions[i]+=Vector3(rng.randf_range(-0.01,0.01),0,rng.randf_range(-0.01,0.01))
		sim.prev_positions[i]=sim.positions[i]
	snapshots.append(sim.positions.duplicate())
	for i in range(80):
		sim.step();snapshots.append(sim.positions.duplicate())
	springs=sim.springs.duplicate(true)
	for p in snapshots[0]:
		masses.append(E.sphere(display,pose(p),0.072,E.PINK))
		ghosts.append(E.sphere(display,pose(p),0.041,Color(0.9,0.93,1,0.23)))
	for spring in springs:bonds.append(E.line(display,pose(snapshots[0][spring[0]]),pose(snapshots[0][spring[1]]),E.BLUE,0.014))
	E.box(display,Vector3(0,0.28,0),Vector3(4,0.16,3.7),E.INK)
	step_label=E.label(display,"STEP 0 / 80",Vector3(0,3.6,0),E.WHITE,0.16)
	evidence={"particles":masses.size(),"springs":springs.size(),"cached_states":snapshots.size(),"steps":80,"seed":7,"solver":"original SoftBodySim.step","replay_of_initialization":true,"start":snapshots[0],"finish":snapshots[-1]}
	frame_scene(Vector3(0,1.7,0),8.4,0.55,0.28)

func pose(p:Vector3)->Vector3:return p*3.7+Vector3(0,0.42,0)

func _draw(time:float)->void:
	var p:=phase_index(time);var u:=phase_progress(time)
	var step:=clampi(int(u*80),0,80) if p==2 else (80 if p==3 else 0)
	var state:PackedVector3Array=snapshots[step]
	for i in range(masses.size()):
		masses[i].position=pose(state[i]);masses[i].visible=p>0 or i<=int(u*48)
		ghosts[i].visible=p==3
	for i in range(bonds.size()):
		E.line_pose(bonds[i],pose(state[springs[i][0]]),pose(state[springs[i][1]]))
		bonds[i].visible=p>1 or (p==1 and i<=int(u*bonds.size()))
	step_label.text="STEP %d / 80"%step
