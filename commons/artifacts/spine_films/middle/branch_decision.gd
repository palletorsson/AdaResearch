extends "res://commons/artifacts/spine_films/film_stage.gd"
const Kit = preload("res://commons/artifacts/spine_films/middle/film_kit.gd")
var states: Array = []
var decision: Dictionary = {}
var branches: Array[MeshInstance3D] = []
var targets: Array[MeshInstance3D] = []
var assignments: Array[MeshInstance3D] = []
var arrows: Array[MeshInstance3D] = []
var resultant: MeshInstance3D
var readout: Label3D
var final_rows: Array = []

func _build() -> void:
	title_text = "WHICH REQUESTS MAKE THE NEXT BRANCH?"
	duration = 26.0
	phases.assign(["A FIELD OF REQUESTS", "SUM UNIT DIRECTIONS", "TAKE ONE STEP", "OLDER SITES CAN ANSWER AGAIN"])
	notes.assign(["The museum's asymmetric target field assigns each request to its nearest eligible site.", "Each assigned request contributes a unit direction. Distance does not increase its vote.", "The sum is normalized, then multiplied by the source's half-metre step.", "This is the NETWORK policy: older sites remain eligible. Targets disappear when reached."])
	source_paths.assign(["res://algorithms/proceduralgeneration/growth_systems/space_colonization_algorithm/SpaceColonizationAlgorithm.gd","res://algorithms/proceduralgeneration/growth_systems/space_colonization_algorithm/colonization_lesson.gd"])
	var fixture = load(source_paths[1]).new()
	fixture.field_index = 1
	var field: Array[Vector3] = fixture.points_for_field()
	fixture.free()
	var model = load(source_paths[0]).new()
	model.growth_origin = Vector3.ZERO; model.origin_type = 0
	model.segment_length = .5; model.influence_distance = 8.0; model.kill_distance = .32
	model.node_budget = 192; model.max_iterations = 60; model.growth_policy = "network"
	model.show_growth_animation = false
	model.attraction_points = field.duplicate(); model.active_attraction_points = field.duplicate()
	model.create_root_nodes()
	decision = model.decision_snapshot().duplicate(true)
	states.append({"count":1,"targets":model.active_attraction_points.duplicate()})
	for iteration in 25:
		var grew: bool = model.grow_iteration()
		states.append({"count":model.all_nodes.size(),"targets":model.active_attraction_points.duplicate()})
		if not grew: break
	var forks := 0
	for row in model.all_nodes:
		final_rows.append({"position":row.position,"parent":model.all_nodes.find(row.parent)})
		if row.children.size() > 1: forks += 1
	for row in final_rows:
		if row.parent < 0: continue
		branches.append(Kit.rod(display,final_rows[row.parent].position,row.position,.05,Kit.material(Kit.WHITE)))
	for point in field:
		targets.append(Kit.dot(display,point,.11,Kit.material(Kit.PINK,true)))
	for assignment in decision.assignments:
		assignments.append(Kit.rod(display,assignment.site,assignment.point,.014,Kit.material(Color("667a8d"))))
		arrows.append(Kit.rod(display,Vector3.ZERO,assignment.direction,.03,Kit.material(Kit.TEAL,true)))
	var sum: Vector3 = decision.sites[0].sum
	resultant = Kit.rod(display,Vector3.ZERO,sum.normalized()*.5,.08,Kit.material(Kit.GOLD,true))
	Kit.dot(display,Vector3.ZERO,.13,Kit.material(Kit.GOLD))
	readout = Kit.label(display,"",Vector3(0,5.8,0),Kit.WHITE,.007)
	evidence = {"fixture":"ASYMMETRIC FIELD","target_count":field.size(),"first_assignments":decision.assignments.size(),"policy":"network","nodes":final_rows.size(),"forks":forks,"states":states.size(),"first_step_length":final_rows[1].position.length(),"changes_source":false}
	# GrowthNode records keep parent/child links: release this off-tree copy explicitly.
	for row in model.all_nodes: row.parent = null; row.children.clear()
	model.free()

func _draw(time: float) -> void:
	var state_index := 0 if time < 13.0 else clampi(1+int(maxf(time-19.5,0)*3.0),1,states.size()-1)
	var state: Dictionary = states[state_index]
	for i in branches.size(): branches[i].visible = time >= 13.0 and i < state.count-1
	for target in targets: target.visible = target.position in state.targets
	for line in assignments: line.visible = time < 8.5
	var sum := Vector3.ZERO
	for i in arrows.size():
		var direction: Vector3 = decision.assignments[i].direction
		var start := sum*Kit.progress(time,8,10)
		# Unit vectors gather head-to-tail; the sum is then normalized for the step.
		Kit.set_rod(arrows[i],start,start+direction)
		arrows[i].visible = time >= 6.5 and time < 13.0
		sum += direction
	var length_ := lerpf(sum.length(),.5,Kit.progress(time,10,12.5))
	Kit.set_rod(resultant,Vector3.ZERO,sum.normalized()*length_)
	resultant.visible = time >= 9 and time < 19.5
	readout.text = "8 REQUESTS / ONE SITE" if time < 9 else ("NORMALIZE THE SUM → 0.5 m" if time < 19.5 else "%d SITES / %d REQUESTS LEFT" % [state.count,state.targets.size()])
	var wide := Kit.progress(time,7,8.5)*(1.0-Kit.progress(time,12,13.5))
	frame_scene(Vector3(0,lerpf(3.0,3.8,wide),0),lerpf(16.7,20.0,wide),lerpf(.18,.65,Kit.progress(time,16,26)),.13)
