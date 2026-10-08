extends "res://commons/artifacts/spine_films/film_stage.gd"
const E = preload("res://commons/artifacts/spine_films/early/geometry.gd")
var bodies: Array[Node3D] = []
var ghosts: Array[Node3D] = []
var first: Transform3D
var second: Transform3D
var anchors := [Vector3(-1.8,1.5,0), Vector3(1.3,1.5,0)]

func _build() -> void:
	title_text = "The same operations, another order"
	phases.assign(["One body, two beginnings", "First operation", "Second operation", "Bring the results together"])
	notes.assign(["Rotate then translate / translate then rotate.", "The intermediate pose belongs to the construction.", "T2 * T1 applies T1 first.", "These final poses come from the workbench's actual transforms."])
	source_paths.assign(["res://commons/artifacts/transform_composition_workbench/transform_composition_workbench.gd"])
	var source: Node3D = load(source_paths[0]).new()
	source.call("_init_pairs")
	var pair: Dictionary = source.get("_pairs")[0]
	first = pair.t1_xform
	second = pair.t2_xform
	for i in range(2):
		var body: Node3D = source.call("_build_tet_shape", E.PINK if i==0 else E.BLUE, false)
		body.get_child(0).scale=Vector3.ONE*1.7
		display.add_child(body)
		bodies.append(body)
		var ghost: Node3D = source.call("_build_tet_shape", Color(0.8,0.85,0.95,0.18), true)
		ghost.get_child(0).scale=Vector3.ONE*1.7
		display.add_child(ghost)
		ghost.transform = Transform3D(Basis.IDENTITY, anchors[i])
		ghosts.append(ghost)
		E.label(display, "ROTATE / TRANSLATE" if i==0 else "TRANSLATE / ROTATE", Vector3(anchors[i].x,0.4,0), E.WHITE,0.17)
		E.box(display, Vector3(anchors[i].x,0.1,0),Vector3(2.5,0.14,1.7),E.INK)
	evidence = {"source_pair":0,"orders":[second*first,first*second],"different_outcomes":not (second*first).is_equal_approx(first*second),"source_geometry":true}
	source.free()
	frame_scene(Vector3(0,1.3,0),7.2,0.18,0.32)

func _draw(time: float) -> void:
	var p := phase_index(time)
	var u := phase_progress(time)
	for i in range(2):
		var a: Transform3D = first if i==0 else second
		var b: Transform3D = second if i==0 else first
		var transform := Transform3D.IDENTITY
		if p==1: transform = Transform3D.IDENTITY.interpolate_with(a,smoothstep(0,1,u))
		elif p>=2: transform = Transform3D.IDENTITY.interpolate_with(b,smoothstep(0,1,u) if p==2 else 1.0)*a
		var at: Vector3 = anchors[i].lerp(Vector3(-0.4,1.5,0),smoothstep(0,1,u)) if p==3 else anchors[i]
		bodies[i].transform = Transform3D(Basis.IDENTITY,at)*transform
