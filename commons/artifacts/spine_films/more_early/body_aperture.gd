extends "res://commons/artifacts/spine_films/film_stage.gd"
const G = preload("res://commons/artifacts/spine_films/early/geometry.gd")
const SOURCE = "res://commons/artifacts/approach_wall/approach_wall.gd"
var source: Node3D
var slats: Array[Node3D] = []
var visitor: Node3D
var indicators: Array[MeshInstance3D] = []
var state_label: Label3D

func _build() -> void:
	title_text = "A passage follows a body"
	phases = ["OUTSIDE THE REACH", "ARRIVE AT ONE SLAT", "THE OPENING TRAVELS", "LEAVE AND CLOSE"]
	notes = ["The wall has five resolved slats and a 2.6 metre sensing reach.", "Each target combines local distance with the source's minimum-clearance rule.", "The source's target and hinge functions respond at the body's new position.", "These are target poses. The live wall eases toward them and detects actual visitors."]
	source_paths = [SOURCE]
	source=load(SOURCE).new(); source.slats=5; source._build()
	for body: AnimatableBody3D in source._slats:
		var copy:=Node3D.new(); display.add_child(copy); slats.append(copy)
		for m: MeshInstance3D in body.find_children("*","MeshInstance3D",true,false):
			var visual:=G.mesh(copy,m.mesh,G.WHITE); visual.transform=m.transform;visual.material_override=m.material_override
		indicators.append(G.sphere(display,Vector3(source._cx[slats.size()-1],3.2,0),.065,G.PINK))
	visitor=Node3D.new(); display.add_child(visitor)
	var capsule:=CapsuleMesh.new(); capsule.radius=.23; capsule.height=1.6; capsule.radial_segments=16; capsule.rings=4
	G.mesh(visitor,capsule,G.PINK).position.y=.8
	G.sphere(visitor,Vector3(0,1.8,0),.17,G.GOLD)
	G.box(display,Vector3(0,-.1,.1),Vector3(5.6,.18,6.3),Color("253c50"))
	G.line(display,Vector3(-2.2,.015,source.reach_m),Vector3(2.2,.015,source.reach_m),G.PINK,.015)
	state_label=G.label(display,"",Vector3(0,3.5,0),G.WHITE,.17)
	evidence={"resolved_slats":source._slats.size(),"reach_m":source.reach_m,"minimum_clear_m":source.min_clear_m,"swing_degrees":source.swing_deg,"method":"_force_core / _target_for / _latch / _drive","physics_and_detector":"not run; settled targets only"}
	frame_scene(Vector3(0,1.5,.55),10.6,.48,.29)

func visitor_at(time: float) -> Vector3:
	var p:=phase_index(time); var u:=smoothstep(.08,.86,phase_progress(time))
	match p:
		0:return Vector3(-1.2,0,2.85)
		1:return Vector3(-1.2,0,lerpf(2.85,.55,u))
		2:return Vector3(lerpf(-1.2,1.2,u),0,.55)
		_:return Vector3(1.2,0,lerpf(.55,2.85,u))

func _draw(time: float) -> void:
	var at:=visitor_at(time); visitor.position=at
	source._vn=1; source._vx[0]=at.x; source._vz[0]=at.z
	source._force_core()
	var highest:=0.0
	for i in slats.size():
		var target: float=maxf(source._target_for(i),source._force[i])
		source._latch(i); source._drive(i,target)
		slats[i].transform=source._slats[i].transform
		indicators[i].scale=Vector3.ONE*lerpf(.35,1.4,target)
		highest=maxf(highest,target)
	state_label.text="body x %.2f m / distance %.2f m" % [at.x,absf(at.z)]
	evidence["current_max_target"]=highest

func validation() -> Dictionary:
	return {"passed":slats.size()==5 and is_equal_approx(source.reach_m,2.6) and source._slat_w-source.thickness_m>=source.min_clear_m,"evidence":evidence}

func _exit_tree() -> void:
	if is_instance_valid(source):source.free()
