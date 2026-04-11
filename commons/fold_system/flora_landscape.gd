extends Node3D
## Renders the Folding Zoo nature_layer.json as a 3D landscape.
## Ground mesh with vertex colors + SyntheticFoliage MultiMesh on top.

const PrimitiveMeshBuilder: GDScript = preload("res://commons/primitives/shared/primitive_mesh_builder.gd")
const Foliage: GDScript = preload("res://commons/fold_system/synthetic_foliage.gd")

var GROUND_COLORS := {
	"none": Color(0.18, 0.2, 0.25),
	"grass": Color(0.3, 0.6, 0.2),
	"moss": Color(0.2, 0.45, 0.15),
	"sand": Color(0.8, 0.7, 0.45),
	"stone": Color(0.55, 0.55, 0.55),
	"soil": Color(0.45, 0.3, 0.18),
}
var WATER_COLORS := {
	"puddle": Color(0.2, 0.4, 0.7),
	"stream": Color(0.15, 0.35, 0.75),
	"pond": Color(0.1, 0.3, 0.7),
}
var FLORA := {
	"grass": { "color": Color(0.3, 0.6, 0.2), "scale": 0.5, "y": 0.0 },
	"moss": { "color": Color(0.2, 0.45, 0.15), "scale": 0.4, "y": 0.0 },
	"flowers": { "color": Color(0.9, 0.4, 0.6), "scale": 0.4, "y": 0.0 },
	"ferns": { "color": Color(0.2, 0.55, 0.2), "scale": 0.45, "y": 0.0 },
	"mushrooms": { "color": Color(0.6, 0.35, 0.7), "scale": 0.5, "y": 0.0 },
	"reeds": { "color": Color(0.45, 0.55, 0.3), "scale": 0.35, "y": 0.0 },
	"tree": { "color": Color(0.2, 0.45, 0.15), "scale": 0.6, "y": 0.0 },
	"bush": { "color": Color(0.25, 0.5, 0.2), "scale": 0.5, "y": 0.0 },
	"vine": { "color": Color(0.3, 0.5, 0.25), "scale": 0.35, "y": 0.0 },
	"walker": { "color": Color(0.8, 0.6, 0.2), "scale": 0.15, "y": 0.1 },
	"flyer": { "color": Color(0.3, 0.6, 0.9), "scale": 0.12, "y": 0.5 },
	"crawler": { "color": Color(0.8, 0.3, 0.3), "scale": 0.12, "y": 0.05 },
}


func _ready() -> void:
	var path := "res://commons/maps/Folding_Zoo/nature_layer.json"
	if not FileAccess.file_exists(path):
		return
	var file := FileAccess.open(path, FileAccess.READ)
	var json := JSON.new()
	json.parse(file.get_as_text())
	file.close()
	var data: Dictionary = json.data
	var layers: Dictionary = data.get("layers", {})
	var w: int = 14
	var d: int = 16

	_build_ground(layers, w, d)
	_place_real_scenes(layers, w, d)
	_build_flora(layers, w, d)


func _build_ground(layers: Dictionary, w: int, d: int) -> void:
	var ground_grid: Array = layers.get("ground", [])
	var water_grid: Array = layers.get("water", [])
	var rng := RandomNumberGenerator.new()
	rng.seed = 12345

	var st := SurfaceTool.new()
	st.begin(Mesh.PRIMITIVE_TRIANGLES)

	var colors: Array = []
	var heights: Array = []

	for row in (d + 1):
		for col in (w + 1):
			var cr := mini(row, d - 1)
			var cc := mini(col, w - 1)
			var color: Color = GROUND_COLORS["none"]
			var h: float = 0.0

			if cr < ground_grid.size() and cc < ground_grid[cr].size():
				var cell: Dictionary = ground_grid[cr][cc]
				var t: String = cell.get("type", "none")
				var inten: float = float(cell.get("intensity", 0))
				color = GROUND_COLORS["none"].lerp(GROUND_COLORS.get(t, GROUND_COLORS["none"]), inten)
				if t == "stone":
					h = inten * 0.12

			if cr < water_grid.size() and cc < water_grid[cr].size():
				var wc: Dictionary = water_grid[cr][cc]
				var wt: String = wc.get("type", "none")
				var wi: float = float(wc.get("intensity", 0))
				if wt != "none" and wi > 0.05:
					color = color.lerp(WATER_COLORS.get(wt, Color(0.1, 0.2, 0.5)), wi * 0.8)
					h = -wi * 0.06

			h += rng.randf_range(-0.015, 0.015)
			colors.append(color)
			heights.append(h)

	for row in d:
		for col in w:
			var i00 := row * (w + 1) + col
			var i10 := i00 + 1
			var i01 := (row + 1) * (w + 1) + col
			var i11 := i01 + 1
			var v00 := Vector3(float(col), heights[i00], float(row))
			var v10 := Vector3(float(col + 1), heights[i10], float(row))
			var v01 := Vector3(float(col), heights[i01], float(row + 1))
			var v11 := Vector3(float(col + 1), heights[i11], float(row + 1))

			st.set_color(colors[i00]); st.set_normal(Vector3.UP); st.add_vertex(v00)
			st.set_color(colors[i01]); st.set_normal(Vector3.UP); st.add_vertex(v01)
			st.set_color(colors[i10]); st.set_normal(Vector3.UP); st.add_vertex(v10)
			st.set_color(colors[i10]); st.set_normal(Vector3.UP); st.add_vertex(v10)
			st.set_color(colors[i01]); st.set_normal(Vector3.UP); st.add_vertex(v01)
			st.set_color(colors[i11]); st.set_normal(Vector3.UP); st.add_vertex(v11)

	var mi := MeshInstance3D.new()
	mi.mesh = st.commit()
	mi.name = "Ground"
	var mat := StandardMaterial3D.new()
	mat.vertex_color_use_as_albedo = true
	mat.roughness = 0.85
	mi.material_override = mat
	add_child(mi)


const REAL_SCENES := {
	"flowers": "res://algorithms/machinelearning/evolvingflowers/evolvingflowers.tscn",
	"tree": "res://algorithms/proceduralgeneration/lsystem/tree_l_system.tscn",
	"mushrooms": "res://algorithms/proceduralgeneration/mushrooms/mushrooms.tscn",
}

func _place_real_scenes(layers: Dictionary, w: int, d: int) -> void:
	## Place up to 3 full artifact scenes per type at the strongest-painted cells.
	for flora_type in REAL_SCENES:
		var best: Array = []
		for layer_name in layers:
			var grid: Array = layers[layer_name]
			for row in grid.size():
				for col in grid[row].size():
					var cell: Dictionary = grid[row][col]
					if cell.get("type", "") == flora_type:
						var inten: float = float(cell.get("intensity", 0))
						if inten > 0.5:
							best.append({"r": row, "c": col, "i": inten})
		best.sort_custom(func(a, b): return float(a["i"]) > float(b["i"]))
		for i in mini(3, best.size()):
			var p: Dictionary = best[i]
			var scene: PackedScene = load(REAL_SCENES[flora_type])
			if not scene:
				continue
			var inst: Node3D = scene.instantiate()
			if not inst:
				continue
			inst.position = Vector3(float(p["c"]) + 0.5, 0.0, float(p["r"]) + 0.5)
			inst.scale = Vector3.ONE * 0.2 * float(p["i"])
			inst.rotation.y = randf() * TAU
			if inst.has_method("apply_grid_config"):
				inst.apply_grid_config({})
			add_child(inst)
			print("FloraSpawner: placed real %s at [%d,%d]" % [flora_type, p["r"], p["c"]])


func _build_flora(layers: Dictionary, w: int, d: int) -> void:
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	var instances: Dictionary = {}

	for layer_name in layers:
		var grid: Array = layers[layer_name]
		for row in grid.size():
			var row_data: Array = grid[row]
			for col in row_data.size():
				var cell: Dictionary = row_data[col]
				var ft: String = cell.get("type", "none")
				var inten: float = float(cell.get("intensity", 0))
				if ft == "none" or inten < 0.05 or not FLORA.has(ft):
					continue
				if not instances.has(ft):
					instances[ft] = []
				instances[ft].append({"r": row, "c": col, "i": inten})

	for ft in instances:
		var placements: Array = instances[ft]
		var cfg: Dictionary = FLORA[ft]
		var mesh: Mesh = _make_mesh(ft)
		var color: Color = cfg.get("color", Color.WHITE)

		var mat := StandardMaterial3D.new()
		var is_plant: bool = ft in ["grass", "moss", "flowers", "ferns", "mushrooms", "reeds", "tree", "bush", "vine"]
		if is_plant:
			mat.vertex_color_use_as_albedo = true
			mat.cull_mode = BaseMaterial3D.CULL_DISABLED
		else:
			mat.albedo_color = color
		mat.roughness = 0.75
		mat.emission_enabled = true
		mat.emission = color * 0.15
		mat.emission_energy_multiplier = 0.3

		var mm := MultiMesh.new()
		mm.transform_format = MultiMesh.TRANSFORM_3D
		mm.use_colors = true
		mm.mesh = mesh
		mm.instance_count = placements.size()

		for idx in placements.size():
			var p: Dictionary = placements[idx]
			var sc: float = cfg.get("scale", 0.1) * float(p["i"])
			var t := Transform3D.IDENTITY.scaled(Vector3(sc, sc, sc))
			t = t.rotated(Vector3.UP, rng.randf() * TAU)
			t.origin = Vector3(
				float(p["c"]) + 0.5 + rng.randf_range(-0.2, 0.2),
				cfg.get("y", 0.1),
				float(p["r"]) + 0.5 + rng.randf_range(-0.2, 0.2)
			)
			mm.set_instance_transform(idx, t)
			mm.set_instance_color(idx, color.lerp(Color.WHITE, rng.randf() * 0.1))

		var mmi := MultiMeshInstance3D.new()
		mmi.multimesh = mm
		mmi.material_override = mat
		mmi.name = "Flora_%s" % ft
		add_child(mmi)


func _make_mesh(flora_type: String) -> Mesh:
	match flora_type:
		"grass", "moss":
			return Foliage.make_grass()
		"flowers":
			return Foliage.make_flower()
		"ferns":
			return Foliage.make_fern()
		"mushrooms":
			return Foliage.make_mushroom()
		"reeds":
			return Foliage.make_reed()
		"tree":
			return Foliage.make_tree()
		"bush":
			return Foliage.make_bush()
		"vine":
			return Foliage.make_vine()
		_:
			var s := SphereMesh.new(); s.radius = 0.5; s.radial_segments = 6; return s


func apply_grid_config(_config: Dictionary) -> void:
	pass
