extends "res://commons/artifacts/spine_films/film_stage.gd"
const Sweep = preload("res://commons/artifacts/glyph_profile_gallery/profile_sweep.gd")
var specimens: Array[MeshInstance3D] = []
var outlines: Array[MeshInstance3D] = []
var sections: Array[MeshInstance3D] = []
var frames_by_body: Array = []
var profile_by_body: Array = []
var mesh_steps: Array = []
var colours := [Color("e8c6d2"),Color("d9bf93"),Color("a9d1d7")]
var _last_step := -1

func _build() -> void:
	title_text = "A PROFILE TRAVELS"
	phases.assign(["THE BORROWED OUTLINE","CARRY THE SECTION","CONNECT THE EDGES","WHAT STAYS OPEN"])
	notes.assign(["Two O profiles and one I. The font already decided their outlines.","Give the section depth, change its width, or carry it around a closed path.","Matching boundary points connect neighbouring sections. A surface appears.","The O keeps its sill. The vessel has no bottom. Closing I's path creates a hole."])
	source_paths.assign(["res://commons/artifacts/glyph_profile_gallery/glyph_profile_gallery.gd","res://commons/artifacts/glyph_profile_gallery/profile_sweep.gd"])
	var recipe: Node3D = load(source_paths[0]).new()
	var font := FontFile.new()
	assert(font.load_dynamic_font("res://commons/artifacts/glyph_profile_gallery/JetBrainsMono-Medium.ttf") == OK)
	for i in range(3):
		var kind: int = [0,1,4][i]
		var glyph: String = ["O","O","I"][i]
		var profile := Sweep.profile(font,glyph)
		var frames: Array[Transform3D] = recipe.call("_frames",kind)
		profile_by_body.append(profile)
		frames_by_body.append(frames)
		var placement := Node3D.new()
		placement.position = Vector3((i-1)*3.3,.25,0)
		placement.scale = Vector3.ONE*.52
		display.add_child(placement)
		var body := add_mesh(Sweep.make(profile,frames,kind==4),colours[i],Vector3.ZERO,placement)
		specimens.append(body)
		var points := PackedVector3Array()
		for edge: Vector2i in profile.boundary:
			for n: int in [edge.x,edge.y]:
				var p: Vector2 = profile.points[n]
				points.append(Vector3(p.x,p.y,0))
		var outline := add_lines(points,Color("f2e6d8"),placement)
		outline.transform = Transform3D(Basis.IDENTITY.scaled(Vector3.ONE*3.3),Vector3(0,2.4,0))
		outlines.append(outline)
		sections.append(add_lines(PackedVector3Array(),Color("f293b6"),placement))
		var steps: Array[Mesh] = []
		for j in range(25):
			var part: Array[Transform3D] = []
			if kind == 0:
				part.assign([frames[0],frames[0].interpolate_with(frames[1],maxf(float(j)/24.0,.002))])
			else:
				part.assign(frames.slice(0,maxi(2,int(ceil(float(j)/24.0*frames.size())))))
			steps.append(Sweep.make(profile,part,kind==4 and j==24))
		mesh_steps.append(steps)
		add_box(Vector3((i-1)*3.3,.10,0),Vector3(2.95,.2,3),Color("343e4c"))
		add_label(["O / DEPTH","O / CHANGING WIDTH","I / CLOSED PATH"][i],Vector3((i-1)*3.3,-.27,1.2),colours[i])
	recipe.free()
	evidence={"source_recipe_indices":[0,1,4],"source_profiles":["O","O","I"],"frame_counts":[2,49,96],"cached_construction_steps":75,"original_sources_edited":false}
	frame_scene(Vector3(0,1.45,0),12.7,.15,.32)

func _draw(time: float) -> void:
	var phase := phase_index(time)
	var progress := phase_progress(time)
	var step := mini(24,int(progress*25)) if phase==2 else 24
	for i in range(3):
		outlines[i].visible = phase == 0
		specimens[i].visible = phase >= 2
		sections[i].visible = phase == 1
		if phase>=2: specimens[i].mesh = mesh_steps[i][step]
	if phase == 1:
		var sample := int(progress*24)
		if sample != _last_step:
			_last_step=sample
			for i in range(3):
				var data: Dictionary = profile_by_body[i]
				var frames: Array = frames_by_body[i]
				var points := PackedVector3Array()
				for j in range(sample+1):
					var at := float(j)/24.0
					var f: Transform3D = frames[0].interpolate_with(frames[-1],at) if i==0 else frames[mini(frames.size()-1,int(at*(frames.size()-1)))]
					for e: Vector2i in data.boundary:
						for n: int in [e.x,e.y]:
							var p: Vector2 = data.points[n]
							points.append(f*Vector3(p.x,p.y,0))
				var mesh := ImmediateMesh.new()
				mesh.surface_begin(Mesh.PRIMITIVE_LINES)
				for p in points: mesh.surface_add_vertex(p)
				mesh.surface_end()
				sections[i].mesh=mesh
	else:
		_last_step=-1

func validation() -> Dictionary:
	var ok: bool = specimens.size()==3 and frames_by_body[0].size()==2 and frames_by_body[1].size()==49 and frames_by_body[2].size()==96
	for i in range(3):
		var expected: ArrayMesh = Sweep.make(profile_by_body[i],frames_by_body[i],i==2)
		var actual: ArrayMesh = mesh_steps[i][24]
		ok=ok and expected.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]==actual.surface_get_arrays(0)[Mesh.ARRAY_VERTEX]
	return {"passed":ok,"source_final_vertices_match":ok,"evidence":evidence}
