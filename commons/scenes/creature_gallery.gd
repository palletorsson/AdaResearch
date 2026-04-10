# creature_gallery.gd — Showcase of all DNA organism kingdoms and presets
#
# A circular gallery room with:
#   - 12 preset pedestals (CritterPlacer presets) in an outer ring
#   - 5 kingdom clusters in the center (tree, creature, flower, fungus, hybrid)
#   - Each organism spawned from CritterDNA at LOD 0 (full detail)
#   - Slow rotation on pedestals for inspection
#   - Labels with preset/kingdom names
#
# Place as a map accessible from the Lab.

extends Node3D

const PRESET_NAMES: Array[String] = [
	"lsystem_tree", "fibonacci_flower", "turing_fungus", "flocking_creature",
	"walking_tree", "evolving_flower", "predator", "symbiont_pair",
	"hybrid_drag", "oak", "mushroom_colony",
]

const KINGDOM_NAMES: Array[String] = ["Tree", "Creature", "Flower", "Fungus", "Hybrid"]
const KINGDOM_IDS: Array[int] = [0, 1, 2, 3, 4]
const KINGDOM_COLORS: Array[Color] = [
	Color(0.2, 0.6, 0.15),  # Tree green
	Color(0.8, 0.3, 0.5),   # Creature pink
	Color(0.9, 0.4, 0.4),   # Flower red
	Color(0.5, 0.3, 0.7),   # Fungus purple
	Color(0.9, 0.7, 0.3),   # Hybrid gold
]

var _spawner: CritterSpawner = null
var _nature_root: Node3D = null
var _pedestal_organisms: Array[Node3D] = []


func _ready() -> void:
	_nature_root = Node3D.new()
	_nature_root.name = "GalleryOrganisms"
	add_child(_nature_root)

	_spawner = CritterSpawner.new(_nature_root)
	_spawner.max_population = 80
	_spawner.default_lod = 0  # Full detail for gallery

	_build_floor()
	_build_lighting()
	call_deferred("_build_preset_ring")
	call_deferred("_build_kingdom_clusters")


func _process(_delta: float) -> void:
	# Slow rotation on preset pedestals
	for org in _pedestal_organisms:
		if is_instance_valid(org):
			org.rotation.y += _delta * 0.3


# ═══════════════════════════════════════════════════════════════
# FLOOR + LIGHTING
# ═══════════════════════════════════════════════════════════════

func _build_floor() -> void:
	var floor_mesh := MeshInstance3D.new()
	floor_mesh.name = "GalleryFloor"
	var plane := PlaneMesh.new()
	plane.size = Vector2(30, 30)
	floor_mesh.mesh = plane
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.12, 0.12, 0.15)
	mat.roughness = 0.9
	floor_mesh.material_override = mat
	add_child(floor_mesh)

	# Collision
	var body := StaticBody3D.new()
	var col := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(30, 0.1, 30)
	col.shape = box
	body.add_child(col)
	body.position.y = -0.05
	add_child(body)


func _build_lighting() -> void:
	# Ambient
	var env := WorldEnvironment.new()
	var environment := Environment.new()
	environment.background_mode = Environment.BG_COLOR
	environment.background_color = Color(0.08, 0.08, 0.12)
	environment.ambient_light_color = Color(0.4, 0.4, 0.5)
	environment.ambient_light_energy = 0.5
	env.environment = environment
	add_child(env)

	# Directional
	var light := DirectionalLight3D.new()
	light.light_color = Color(0.9, 0.85, 0.8)
	light.light_energy = 0.8
	light.rotation_degrees = Vector3(-45, -30, 0)
	add_child(light)


# ═══════════════════════════════════════════════════════════════
# PRESET RING — 12 pedestals in a circle
# ═══════════════════════════════════════════════════════════════

func _build_preset_ring() -> void:
	var radius := 10.0
	var center := Vector3(0, 0, 0)

	for i in PRESET_NAMES.size():
		var angle := (float(i) / float(PRESET_NAMES.size())) * TAU
		var pos := center + Vector3(cos(angle) * radius, 0, sin(angle) * radius)
		var preset_name: String = PRESET_NAMES[i]

		# Build pedestal
		_build_pedestal(pos, preset_name)

		# Spawn organism from preset
		var dna := _load_preset_dna(preset_name)
		if dna:
			var entity := _spawner.spawn(dna, pos + Vector3(0, 1.2, 0), 0)
			if entity:
				entity.set_process(false)
				entity.set_physics_process(false)
				_pedestal_organisms.append(entity)


func _build_pedestal(pos: Vector3, label_text: String) -> void:
	# Cylinder base
	var pedestal := MeshInstance3D.new()
	pedestal.name = "Pedestal_%s" % label_text
	var cyl := CylinderMesh.new()
	cyl.top_radius = 0.4
	cyl.bottom_radius = 0.5
	cyl.height = 1.0
	cyl.radial_segments = 12
	pedestal.mesh = cyl
	pedestal.position = pos + Vector3(0, 0.5, 0)
	var mat := StandardMaterial3D.new()
	mat.albedo_color = Color(0.2, 0.2, 0.25)
	mat.metallic = 0.5
	mat.roughness = 0.3
	pedestal.material_override = mat
	add_child(pedestal)

	# Label
	var label := Label3D.new()
	label.name = "Label_%s" % label_text
	label.text = label_text.replace("_", " ").capitalize()
	label.font_size = 24
	label.pixel_size = 0.003
	label.position = pos + Vector3(0, 0.15, 0.6)
	label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	label.modulate = Color(0.8, 0.8, 0.9)
	label.outline_size = 3
	add_child(label)

	# Spotlight on the organism
	var spot := OmniLight3D.new()
	spot.light_color = Color(0.9, 0.85, 0.8)
	spot.light_energy = 1.5
	spot.omni_range = 2.5
	spot.omni_attenuation = 1.5
	spot.position = pos + Vector3(0, 2.5, 0)
	add_child(spot)


# ═══════════════════════════════════════════════════════════════
# KINGDOM CLUSTERS — 5 groups in the inner area
# ═══════════════════════════════════════════════════════════════

func _build_kingdom_clusters() -> void:
	var inner_radius := 4.0

	for ki in KINGDOM_IDS.size():
		var angle := (float(ki) / float(KINGDOM_IDS.size())) * TAU
		var cluster_center := Vector3(cos(angle) * inner_radius, 0, sin(angle) * inner_radius)
		var kingdom_id: int = KINGDOM_IDS[ki]
		var kingdom_name: String = KINGDOM_NAMES[ki]
		var kingdom_color: Color = KINGDOM_COLORS[ki]

		# Kingdom title
		var title := Label3D.new()
		title.text = kingdom_name
		title.font_size = 36
		title.pixel_size = 0.004
		title.position = cluster_center + Vector3(0, 3.0, 0)
		title.billboard = BaseMaterial3D.BILLBOARD_ENABLED
		title.modulate = kingdom_color
		title.outline_size = 4
		add_child(title)

		# Ground marker
		var marker := MeshInstance3D.new()
		marker.name = "KingdomMarker_%s" % kingdom_name
		var disc := CylinderMesh.new()
		disc.top_radius = 2.0
		disc.bottom_radius = 2.0
		disc.height = 0.02
		disc.radial_segments = 16
		marker.mesh = disc
		marker.position = cluster_center + Vector3(0, 0.01, 0)
		var disc_mat := StandardMaterial3D.new()
		disc_mat.albedo_color = Color(kingdom_color.r * 0.3, kingdom_color.g * 0.3, kingdom_color.b * 0.3, 0.5)
		disc_mat.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA
		marker.material_override = disc_mat
		add_child(marker)

		# Spawn 4 specimens per kingdom at random positions within cluster
		var rng := RandomNumberGenerator.new()
		rng.seed = hash(kingdom_name)
		for j in 4:
			var offset := Vector3(
				rng.randf_range(-1.2, 1.2),
				0,
				rng.randf_range(-1.2, 1.2)
			)
			var spawn_pos := cluster_center + offset

			var dna: CritterDNA
			if kingdom_id == 4:
				# Hybrid: random body_type between kingdoms
				dna = CritterDNA.random(rng.randi())
				dna.body_type = rng.randf_range(0.5, 3.5)
			else:
				dna = CritterDNA.random_kingdom(kingdom_id, rng.randi())

			# Scale variation
			dna.scale = rng.randf_range(0.8, 1.5)

			var entity := _spawner.spawn(dna, spawn_pos + Vector3(0, 0.5, 0), 0)
			if entity:
				entity.set_process(false)
				entity.set_physics_process(false)


# ═══════════════════════════════════════════════════════════════
# DNA PRESET LOADING — mirrors CritterPlacer.PRESETS
# ═══════════════════════════════════════════════════════════════

func _load_preset_dna(preset_name: String) -> CritterDNA:
	# Use CritterPlacer's preset system
	var placer_script = load("res://commons/artifacts/critter_placer/critter_placer.gd")
	if not placer_script:
		return CritterDNA.random()

	var presets: Dictionary = placer_script.PRESETS
	if preset_name not in presets:
		return CritterDNA.random()

	var preset: Dictionary = presets[preset_name]
	var dna := CritterDNA.new()

	# Set kingdom
	var kingdom: int = preset.get("kingdom", 0)
	if kingdom >= 0:
		dna.body_type = float(kingdom)
	elif preset.has("body_type"):
		dna.body_type = float(preset["body_type"])

	# Apply gene overrides
	for gene_name in preset:
		if gene_name in ["kingdom", "primary_color", "secondary_color", "tertiary_color"]:
			continue
		if gene_name in dna:
			dna.set(gene_name, float(preset[gene_name]))

	# Apply colors
	if preset.has("primary_color"):
		dna.primary_color = Color(preset["primary_color"])
	if preset.has("secondary_color"):
		dna.secondary_color = Color(preset["secondary_color"])
	if preset.has("tertiary_color"):
		dna.tertiary_color = Color(preset["tertiary_color"])

	return dna
