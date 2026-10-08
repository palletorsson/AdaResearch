extends "res://commons/artifacts/spine_films/late/late_stage.gd"
const SOURCE := "res://commons/artifacts/boids_aquarium/boids_aquarium.gd"
var _snapshots: Array = []
var _bodies: Array[MeshInstance3D] = []
var _headings: Array[MeshInstance3D] = []
var _vectors: Array[Node3D] = []
var _links: Array[MeshInstance3D] = []
var _perception: MeshInstance3D
var _readout: Label3D

func _build() -> void:
	title_text = "ONE BODY, SEVERAL NEIGHBOURS"
	phases.assign(["THE NEIGHBOURHOOD","THREE CONTRIBUTIONS","THE NEXT VELOCITY","BACK INTO THE FLOCK"])
	notes.assign(["The selected body only reads neighbours within its perception radius.","Separation, alignment and cohesion contribute different vectors.","Their weighted sum changes velocity. The source then limits its speed.","The same source updater advances the private flock, in its original sequential order."])
	source_paths.assign([SOURCE])
	frame_scene(Vector3(0,1.4,0),11.5,.32,.30)
	film_deck()
	var script = load(SOURCE)
	var source = script.new()
	source.tank_size = Vector3(4,3,4)
	source.perception_radius = .95
	source.separation_weight = .06
	source.alignment_weight = .6
	source.cohesion_weight = .3
	var points: Array[Vector3] = [Vector3.ZERO,Vector3(.5,.15,.2),Vector3(-.35,.2,.45),Vector3(.2,-.25,-.65),Vector3(-.65,-.15,-.3),Vector3(1.3,.1,.8),Vector3(-1.1,.6,-.85),Vector3(.8,-.6,1.2)]
	for i in points.size(): source._boids.append(script.BoidData.new(points[i],Vector3(.22-.03*i,.03*sin(i),.07*cos(i))))
	var separation := Vector3.ZERO
	var alignment := Vector3.ZERO
	var cohesion := Vector3.ZERO
	var count := 0
	for i in range(1,points.size()):
		if points[i].length()<source.perception_radius:
			count += 1
			separation -= points[i]/points[i].length_squared()
			alignment += source._boids[i].velocity
			cohesion += points[i]
			_links.append(add_rod(_place(Vector3.ZERO),_place(points[i]),.018,SLATE))
	separation *= source.separation_weight
	alignment = (alignment/count-source._boids[0].velocity)*source.alignment_weight
	cohesion = (cohesion/count)*source.cohesion_weight
	for i in 3:
		_vectors.append(film_arrow(_place(Vector3.ZERO),[separation,alignment,cohesion][i]*16,[PINK,TEAL,GOLD][i]))
	var expected: Vector3 = source._boids[0].velocity+(separation+alignment+cohesion)*.025
	if expected.length()>source.max_speed: expected = expected.normalized()*source.max_speed
	var next_arrow := film_arrow(_place(Vector3.ZERO),expected*4,CHALK)
	_vectors.append(next_arrow)
	_snapshots.append(_snapshot(source))
	for step in 300:
		source._update_boids(.025)
		_snapshots.append(_snapshot(source))
		if step==0: evidence["first_velocity_error"] = source._boids[0].velocity.distance_to(expected)
	for i in points.size():
		_bodies.append(add_ball(_place(points[i]),.12 if i==0 else .075,GOLD if i==0 else CHALK))
		_headings.append(film_unit_rod(GOLD if i==0 else TEAL,null,.020))
	_perception = add_ball(_place(Vector3.ZERO),source.perception_radius*1.6,Color(TEAL,.07))
	_readout = add_label("",Vector3(0,3.15,0),CHALK)
	evidence.merge({"body_count":points.size(),"selected_neighbours":count,"perception_radius":source.perception_radius,"simulation_steps":300,"source_delta":.025,"snapshot_count":_snapshots.size(),"actual_function":"_update_boids","private_fixture":true,"sequential_source_order":true,"acceleration_arrow_scale":16,"velocity_arrow_scale":4})
	source.free()

func _snapshot(source: Node3D) -> Dictionary:
	var positions := PackedVector3Array()
	var velocities := PackedVector3Array()
	for body in source._boids:
		positions.append(body.position)
		velocities.append(body.velocity)
	return {"positions":positions,"velocities":velocities}

func _place(p: Vector3) -> Vector3:
	return p*1.6+Vector3(0,1.4,0)

func _draw(time: float) -> void:
	var phase := phase_index(time)
	var u := phase_progress(time)
	var index := mini(299,int(u*300)) if phase==3 else 0
	var record: Dictionary = _snapshots[index]
	for i in _bodies.size():
		_bodies[i].position = _place(record.positions[i])
		film_rod_pose(_headings[i],_bodies[i].position,_bodies[i].position+record.velocities[i]*.6)
	_perception.visible = phase==0
	for link in _links: link.visible = phase==0
	for i in _vectors.size(): _vectors[i].visible = (phase==1 and i<=mini(2,int(u*3))) or (phase==2 and i==3)
	_readout.text = ["4 neighbours / one bounded view","separate / align / cohere  (vectors enlarged ×16)","v next = v + acceleration × delta","%d original update steps / private copy" % index][phase]
