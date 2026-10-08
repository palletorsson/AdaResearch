extends "res://commons/artifacts/spine_films/late/late_stage.gd"
const SOURCE := "res://commons/artifacts/triangle_curvature_workbench/triangle_curvature_workbench.gd"
var _paths: Array = []
var _corners: Node3D
var _tangents: Node3D
var _sums: Node3D

func _build() -> void:
	title_text = "A TRIANGLE DEPENDS ON ITS SURFACE"
	phases.assign(["TWO SURFACES","FOLLOW THE EDGES","READ THE TANGENTS","COMPARE THE ANGLE SUMS"])
	notes.assign(["A sphere and a flat plane give the same word, triangle, different conditions.","On the sphere the source follows great-circle arcs. On the plane it joins straight edges.","An interior angle is measured between the edge tangents at each corner.","These are two distinct constructions. The animation is no proof about formal incompleteness."])
	source_paths.assign([SOURCE])
	frame_scene(Vector3(0,1.1,0),11.5,.25,.67)
	film_deck()
	var source = load(SOURCE).new()
	source.surface_radius = 1.35
	source.triangle_radius_deg = 55.0
	add_ball(Vector3(-1.8,1.0,0),1.35,Color("496979"))
	add_box(Vector3(1.8,.30,0),Vector3(2.7,.045,2.7),Color("496979"))
	_corners = film_group()
	_tangents = film_group()
	_sums = film_group()
	var sums: Array[float] = []
	var max_sphere_radius_error := 0.0
	for mode in 2:
		source._k = 1.0 if mode==0 else 0.0
		var origin := Vector3(-1.8,1,0) if mode==0 else Vector3(1.8,.33,0)
		var vertices: Array = source._triangle_vertices()
		var total := 0.0
		for i in 3:
			var samples: PackedVector3Array = source._edge_samples(vertices[i],vertices[(i+1)%3],36)
			var positioned := PackedVector3Array()
			for point in samples:
				if mode==0: max_sphere_radius_error = maxf(max_sphere_radius_error,absf(point.length()-1.35))
				positioned.append(point*1.004+origin)
			_paths.append(film_path(positioned,TEAL if mode==0 else GOLD,null,.021))
			var at: Vector3 = vertices[i]+origin
			add_ball(at,.07,CHALK,_corners)
			var angle: float = source._interior_angle(vertices[i],vertices[(i+2)%3],vertices[(i+1)%3])
			total += rad_to_deg(angle)
			for neighbour in [(i+2)%3,(i+1)%3]:
				var tangent: Vector3 = source._edge_tangent(vertices[i],vertices[neighbour])
				film_arrow(at,tangent*.52,PINK,_tangents)
			var label := add_label("%.1f°" % rad_to_deg(angle),at+Vector3(0,.2,0),CHALK,_tangents)
			label.font_size = 22
		sums.append(total)
		add_label("%.1f°" % total,origin+Vector3(0,1.95 if mode==0 else 1.2,0),TEAL if mode==0 else GOLD,_sums)
	evidence = {"sphere_angle_sum":sums[0],"plane_angle_sum":sums[1],"sphere_radius_error":max_sphere_radius_error,"sampled_edges":6,"segments_per_edge":36,"actual_functions":["_triangle_vertices","_edge_samples","_edge_tangent","_interior_angle"],"limitation":"No continuous curvature morph, area proof, or inference about Godel is made"}
	source.free()

func _draw(time: float) -> void:
	var phase := phase_index(time)
	_corners.visible = phase>0
	_tangents.visible = phase==2
	_sums.visible = phase==3
	for path in _paths: film_reveal(path,phase_progress(time) if phase==1 else (1.0 if phase>=2 else 0.0))
