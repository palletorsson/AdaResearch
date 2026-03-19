# LandscapeScene.gd
# Open landscape — the endgame vista generated from full ecosystem state.
# Player arrives after completing all sequences. Terrain, creatures, flight,
# and the QFEP formula floating overhead. The world they grew, fully realized.

extends Node3D
class_name LandscapeScene

# ── Preloads ─────────────────────────────────────────────────────────

const QFEPFormulaScene := preload("res://commons/interfaces/qfep/formula_display/qfep_formula_3d.tscn")
const TerrainGenScript := preload("res://commons/managers/EcosystemTerrainGenerator.gd")
const NatureSpawnerScript := preload("res://commons/managers/EcosystemNatureSpawner.gd")
const SequelHookScript := preload("res://commons/scenes/SequelHookCinematic.gd")

# ── Configuration ────────────────────────────────────────────────────

const TERRAIN_SIZE := 60.0
const TERRAIN_RESOLUTION := 96
const TERRAIN_MAX_HEIGHT := 4.0
const NATURE_SPAWN_RADIUS := 25.0
const NATURE_MAX_POP := 60
const NATURE_SEED := 42

const SPAWN_POSITION := Vector3(0.0, 2.0, 25.0)
const FORMULA_POSITION := Vector3(0.0, 8.0, -8.0)
const FORMULA_SCALE := Vector3(3.0, 3.0, 3.0)
const HORIZON_MARKER_POS := Vector3(0.0, 2.0, -28.0)
const RETURN_PORTAL_POS := Vector3(0.0, 1.0, 28.0)

# ── Runtime ──────────────────────────────────────────────────────────

var _terrain: Node3D = null
var _nature: Node3D = null
var _formula: Node3D = null


func _ready() -> void:
	call_deferred("_build_landscape")


func _build_landscape() -> void:
	_setup_environment()
	_setup_lighting()
	_setup_terrain()
	_setup_nature()
	_setup_curated_creatures()
	_setup_formula()
	_setup_return_portal()
	_setup_horizon_marker()
	_setup_ambient_audio()
	_position_player()
	print("LandscapeScene: Open landscape built — terrain %.0fm, %d DNA critters + curated creatures" % [
		TERRAIN_SIZE, NATURE_MAX_POP
	])


# ── Environment ──────────────────────────────────────────────────────

func _setup_environment() -> void:
	var env := Environment.new()
	env.background_mode = Environment.BG_SKY

	var sky_mat := ProceduralSkyMaterial.new()
	sky_mat.sky_top_color = Color(0.15, 0.18, 0.35)
	sky_mat.sky_horizon_color = Color(0.55, 0.35, 0.22)
	sky_mat.ground_bottom_color = Color(0.06, 0.08, 0.12)
	sky_mat.ground_horizon_color = Color(0.45, 0.28, 0.18)
	sky_mat.sun_angle_max = 25.0
	sky_mat.sun_curve = 0.1

	var sky := Sky.new()
	sky.sky_material = sky_mat
	env.sky = sky

	# Atmospheric fog for depth during flight
	env.fog_enabled = true
	env.fog_light_color = Color(0.4, 0.35, 0.28)
	env.fog_density = 0.008
	env.fog_sky_affect = 0.6

	# Warm ambient
	env.ambient_light_source = Environment.AMBIENT_SOURCE_SKY
	env.ambient_light_energy = 0.8
	env.tonemap_mode = Environment.TONE_MAPPER_ACES

	# SSAO for grounding
	env.ssao_enabled = true
	env.ssao_radius = 1.5
	env.ssao_intensity = 1.2

	var world_env := WorldEnvironment.new()
	world_env.name = "LandscapeEnvironment"
	world_env.environment = env
	add_child(world_env)


func _setup_lighting() -> void:
	# Key light — warm sun at ~45 degrees
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-42, -30, 0)
	sun.light_color = Color(1.0, 0.92, 0.8)
	sun.light_energy = 1.3
	sun.shadow_enabled = true
	sun.directional_shadow_max_distance = 80.0
	add_child(sun)

	# Fill light — cool blue from opposite side
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-20, 150, 0)
	fill.light_color = Color(0.7, 0.75, 0.9)
	fill.light_energy = 0.3
	add_child(fill)


# ── Terrain ──────────────────────────────────────────────────────────

func _setup_terrain() -> void:
	_terrain = TerrainGenScript.new()
	_terrain.name = "LandscapeTerrain"
	_terrain.terrain_size = TERRAIN_SIZE
	_terrain.resolution = TERRAIN_RESOLUTION
	_terrain.max_height = TERRAIN_MAX_HEIGHT
	_terrain.noise_seed = NATURE_SEED
	add_child(_terrain)

	# Force self_generating mode after deferred init completes
	await get_tree().process_frame
	await get_tree().process_frame
	_terrain._current_mode = "self_generating"
	_terrain._generate_terrain()


# ── Nature ───────────────────────────────────────────────────────────

func _setup_nature() -> void:
	_nature = NatureSpawnerScript.new()
	_nature.name = "LandscapeNature"
	_nature.spawn_radius = NATURE_SPAWN_RADIUS
	_nature.max_population = NATURE_MAX_POP
	_nature.rng_seed = NATURE_SEED
	add_child(_nature)


# ── Curated Creatures & Mushrooms ────────────────────────────────────
# Hand-placed artifacts that give the landscape character beyond the
# generic DNA spawner. Hexapods on ridges, pod-eggs in valleys,
# magic mushrooms in dark hollows, fairy rings on plateaus.

func _setup_curated_creatures() -> void:
	var root := Node3D.new()
	root.name = "CuratedCreatures"
	add_child(root)

	# ── Hexapods & Walkers on terrain ridges ──
	# Big IK creatures visible from flight, roaming the high ground
	_place_scene(root, "res://commons/hazards/six_leg_critter/six_leg_critter.tscn",
		Vector3(-12.0, 2.5, -8.0), 1.2, "Hexapod_Ridge_1")
	_place_scene(root, "res://commons/hazards/six_leg_critter/six_leg_critter.tscn",
		Vector3(10.0, 2.0, -15.0), 1.0, "Hexapod_Ridge_2")
	_place_scene(root, "res://commons/hazards/four_leg_critter/four_leg_critter.tscn",
		Vector3(18.0, 1.5, 5.0), 0.9, "Quadruped_East")

	# ── Octapod IK walkers — the big ones ──
	_place_scene(root, "res://commons/hazards/octapod_ik/octapod_ik.tscn",
		Vector3(-8.0, 3.0, -18.0), 1.4, "Octapod_Summit")
	_place_scene(root, "res://commons/hazards/octapod_ik/octapod_ik.tscn",
		Vector3(15.0, 2.0, -22.0), 1.1, "Octapod_Horizon")

	# ── Dormant pod-eggs — hatch when approached ──
	# Nestled in valleys and hollows. Discovery moments.
	_place_scene(root, "res://commons/hazards/octapod_crawler/octapod_crawler.tscn",
		Vector3(-5.0, 0.5, 3.0), 0.8, "PodEgg_Valley_1")
	_place_scene(root, "res://commons/hazards/octapod_crawler/octapod_crawler.tscn",
		Vector3(7.0, 0.3, -5.0), 0.7, "PodEgg_Valley_2")
	_place_scene(root, "res://commons/hazards/octapod_crawler/octapod_crawler.tscn",
		Vector3(-15.0, 0.4, -12.0), 0.9, "PodEgg_Shadow")
	_place_scene(root, "res://commons/hazards/octapod_crawler/octapod_crawler.tscn",
		Vector3(3.0, 0.6, 15.0), 0.75, "PodEgg_Near_Spawn")

	# ── Small critters — 1, 2, 3 legs scattered around ──
	_place_scene(root, "res://commons/hazards/one_leg/one_leg.tscn",
		Vector3(5.0, 0.8, -2.0), 0.6, "Monopod_1")
	_place_scene(root, "res://commons/hazards/two_leg_critter/two_leg_critter.tscn",
		Vector3(-10.0, 1.2, 8.0), 0.7, "Bipod_1")
	_place_scene(root, "res://commons/hazards/three_leg_critter/three_leg_critter.tscn",
		Vector3(12.0, 1.0, 10.0), 0.8, "Tripod_1")
	_place_scene(root, "res://commons/hazards/five_leg_critter/five_leg_critter.tscn",
		Vector3(-18.0, 1.8, -5.0), 1.0, "Pentapod_West")

	# ── Magic mushrooms — hidden in dark hollows ──
	# Edible mushrooms with trippy shader effects
	_place_scene(root, "res://commons/hazards/mushroom/edible_mushroom.tscn",
		Vector3(-3.0, 0.2, -10.0), 1.0, "MagicMushroom_1")
	_place_scene(root, "res://commons/hazards/mushroom/edible_mushroom.tscn",
		Vector3(8.0, 0.1, -18.0), 0.9, "MagicMushroom_2")
	_place_scene(root, "res://commons/hazards/mushroom/edible_mushroom.tscn",
		Vector3(-14.0, 0.3, 2.0), 1.1, "MagicMushroom_3")

	# ── Soft body mushrooms — wobbly clusters on plateaus ──
	_place_scene(root, "res://algorithms/softbodies/mushrooms/soft_mushrooms.tscn",
		Vector3(0.0, 1.5, -4.0), 1.5, "SoftShrooms_Center")
	_place_scene(root, "res://algorithms/softbodies/mushrooms/soft_mushrooms.tscn",
		Vector3(-20.0, 0.8, -15.0), 1.2, "SoftShrooms_West")

	# ── Procedural mushroom growths — fairy rings and clusters ──
	_place_scene(root, "res://algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.tscn",
		Vector3(6.0, 0.5, -14.0), 1.8, "MushroomGrowth_FairyRing")
	_place_scene(root, "res://algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.tscn",
		Vector3(-8.0, 1.0, 12.0), 1.4, "MushroomGrowth_South")
	_place_scene(root, "res://algorithms/proceduralgeneration/growth_systems/mushrooms/mushrooms.tscn",
		Vector3(20.0, 0.6, -8.0), 1.6, "MushroomGrowth_East")

	# ── Botanical Flower Gardens ──────────────────────────────────────
	# Real Swedish wildflowers built from botanical taxonomy.
	# Each garden is a cluster of species-accurate procedural flowers.
	_setup_botanical_gardens(root)

	print("LandscapeScene: Placed %d curated creatures, mushrooms & flowers" % root.get_child_count())


func _setup_botanical_gardens(parent: Node3D) -> void:
	# Bluebell meadow — drooping bells on arching stems, near the terrain center
	var bluebell_garden := BotanicalFlower.create_garden(15, 3.0, 101, "bluebell")
	bluebell_garden.name = "BluebellMeadow"
	bluebell_garden.position = Vector3(-6.0, 1.0, -6.0)
	parent.add_child(bluebell_garden)

	# Iris patch — tall purple-violet standards and falls, east ridge
	var iris_patch := BotanicalFlower.create_garden(8, 2.0, 202, "iris")
	iris_patch.name = "IrisPatch"
	iris_patch.position = Vector3(14.0, 1.5, -10.0)
	parent.add_child(iris_patch)

	# Fritillaria cluster — checkered bells drooping from stems, in a valley
	var fritillaria := BotanicalFlower.create_garden(6, 1.5, 303, "fritillaria")
	fritillaria.name = "FritillariaCluster"
	fritillaria.position = Vector3(-12.0, 0.5, 5.0)
	parent.add_child(fritillaria)

	# Allium spheres — purple globe heads on tall stems, near the QFEP formula
	var allium := BotanicalFlower.create_garden(10, 2.5, 404, "allium")
	allium.name = "AlliumField"
	allium.position = Vector3(0.0, 1.2, -10.0)
	parent.add_child(allium)

	# Mixed wildflower meadow — random botanical species, south plateau
	var meadow := BotanicalFlower.create_garden(20, 4.0, 505)
	meadow.name = "WildflowerMeadow"
	meadow.position = Vector3(8.0, 0.8, 12.0)
	parent.add_child(meadow)

	# Crown imperial group — tall orange bells, dramatic sentinel flowers
	var crowns := BotanicalFlower.create_garden(4, 1.0, 606, "crown_imperial")
	crowns.name = "CrownImperialGroup"
	crowns.position = Vector3(-18.0, 1.8, -15.0)
	parent.add_child(crowns)

	# Daisy carpet — low white+yellow composites, near return portal
	var daisies := BotanicalFlower.create_garden(18, 3.5, 707, "daisy")
	daisies.name = "DaisyCarpet"
	daisies.position = Vector3(5.0, 0.3, 20.0)
	parent.add_child(daisies)

	# Orchid grove — bilateral flowers on racemes, hidden in the woods
	var orchids := BotanicalFlower.create_garden(5, 1.2, 808, "orchid")
	orchids.name = "OrchidGrove"
	orchids.position = Vector3(-4.0, 0.6, -18.0)
	parent.add_child(orchids)

	print("LandscapeScene: Planted 8 botanical flower gardens (~86 flowers)")


func _place_scene(parent: Node3D, scene_path: String, pos: Vector3, scale_mult: float, node_name: String) -> void:
	var scene := load(scene_path)
	if not scene:
		push_warning("LandscapeScene: Could not load %s" % scene_path)
		return

	var instance: Node = scene.instantiate()
	instance.name = node_name
	instance.position = pos
	if scale_mult != 1.0:
		instance.scale = Vector3.ONE * scale_mult
	parent.add_child(instance)


# ── QFEP Formula ─────────────────────────────────────────────────────

func _setup_formula() -> void:
	_formula = QFEPFormulaScene.instantiate()
	_formula.name = "QFEPFormula"
	_formula.position = FORMULA_POSITION
	_formula.scale = FORMULA_SCALE
	add_child(_formula)


# ── Portals ──────────────────────────────────────────────────────────

func _setup_return_portal() -> void:
	var portal_root := Node3D.new()
	portal_root.name = "ReturnPortal"
	portal_root.position = RETURN_PORTAL_POS
	add_child(portal_root)

	# Visible archway — two pillars and a lintel
	var pillar_mat := StandardMaterial3D.new()
	pillar_mat.albedo_color = Color(0.3, 0.35, 0.5)
	pillar_mat.emission_enabled = true
	pillar_mat.emission = Color(0.2, 0.25, 0.5)
	pillar_mat.emission_energy_multiplier = 0.8

	var left_pillar := _make_box(Vector3(0.15, 2.0, 0.15))
	left_pillar.position = Vector3(-1.0, 1.0, 0.0)
	left_pillar.material_override = pillar_mat
	portal_root.add_child(left_pillar)

	var right_pillar := _make_box(Vector3(0.15, 2.0, 0.15))
	right_pillar.position = Vector3(1.0, 1.0, 0.0)
	right_pillar.material_override = pillar_mat
	portal_root.add_child(right_pillar)

	var lintel := _make_box(Vector3(2.3, 0.15, 0.15))
	lintel.position = Vector3(0.0, 2.05, 0.0)
	lintel.material_override = pillar_mat
	portal_root.add_child(lintel)

	# Label
	var label := Label3D.new()
	label.text = "Return to Lab"
	label.font_size = 36
	label.pixel_size = 0.002
	label.position = Vector3(0.0, 2.5, 0.0)
	label.modulate = Color(0.7, 0.75, 1.0, 0.9)
	portal_root.add_child(label)

	# Trigger area
	var area := Area3D.new()
	area.name = "ReturnTrigger"
	portal_root.add_child(area)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(2.0, 3.0, 1.0)
	shape.shape = box
	shape.position = Vector3(0.0, 1.5, 0.0)
	area.add_child(shape)

	area.body_entered.connect(_on_return_portal_entered)


func _setup_horizon_marker() -> void:
	# Distant archway on the far horizon — the sequel hook
	var marker := Node3D.new()
	marker.name = "HorizonMarker"
	marker.position = HORIZON_MARKER_POS
	add_child(marker)

	var arch_mat := StandardMaterial3D.new()
	arch_mat.albedo_color = Color(0.2, 0.22, 0.3)
	arch_mat.emission_enabled = true
	arch_mat.emission = Color(0.15, 0.18, 0.35)
	arch_mat.emission_energy_multiplier = 0.8

	var left := _make_box(Vector3(0.2, 3.5, 0.2))
	left.position = Vector3(-1.5, 1.75, 0.0)
	left.material_override = arch_mat
	marker.add_child(left)

	var right := _make_box(Vector3(0.2, 3.5, 0.2))
	right.position = Vector3(1.5, 1.75, 0.0)
	right.material_override = arch_mat
	marker.add_child(right)

	var top := _make_box(Vector3(3.4, 0.2, 0.2))
	top.position = Vector3(0.0, 3.6, 0.0)
	top.material_override = arch_mat
	marker.add_child(top)

	# Beckoning light inside the archway
	var glow := OmniLight3D.new()
	glow.light_color = Color(0.4, 0.45, 0.7)
	glow.light_energy = 0.6
	glow.omni_range = 4.0
	glow.position = Vector3(0.0, 1.8, 0.0)
	marker.add_child(glow)

	# Hint label
	var hint := Label3D.new()
	hint.text = "..."
	hint.font_size = 48
	hint.pixel_size = 0.003
	hint.position = Vector3(0.0, 4.5, 0.0)
	hint.modulate = Color(0.5, 0.55, 0.7, 0.5)
	hint.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	marker.add_child(hint)

	# Trigger area for the cinematic
	var area := Area3D.new()
	area.name = "HorizonTrigger"
	marker.add_child(area)

	var shape := CollisionShape3D.new()
	var box := BoxShape3D.new()
	box.size = Vector3(3.0, 4.0, 2.0)
	shape.shape = box
	shape.position = Vector3(0.0, 2.0, 0.0)
	area.add_child(shape)

	# Attach cinematic script
	var cinematic := SequelHookScript.new()
	cinematic.name = "SequelHookCinematic"
	marker.add_child(cinematic)
	cinematic.setup(area)


# ── Audio ────────────────────────────────────────────────────────────

func _setup_ambient_audio() -> void:
	var ambient := AmbientSoundController.new()
	ambient.name = "LandscapeAmbient"
	add_child(ambient)
	# The controller auto-connects to EcosystemManager and loads the
	# endgame preset ("tunable_becoming") from the current stage.


# ── Player Positioning ───────────────────────────────────────────────

func _position_player() -> void:
	# Find XR origin in parent scene (base.tscn provides it)
	await get_tree().process_frame
	var xr_origin: XROrigin3D = null

	# Search parent tree for XROrigin3D
	var parent := get_parent()
	while parent:
		if parent is XROrigin3D:
			xr_origin = parent
			break
		# Also check children of parent
		var found = parent.find_children("*", "XROrigin3D", true, false)
		if found.size() > 0:
			xr_origin = found[0]
			break
		parent = parent.get_parent()

	if not xr_origin:
		# Search from scene root
		var scene = get_tree().current_scene
		if scene:
			var origins = scene.find_children("*", "XROrigin3D", true, false)
			if origins.size() > 0:
				xr_origin = origins[0]

	if xr_origin:
		xr_origin.global_position = SPAWN_POSITION
		# Face inward (toward -Z where landscape center is)
		xr_origin.rotation_degrees = Vector3(0, 180, 0)
		print("LandscapeScene: Player positioned at %s facing landscape" % SPAWN_POSITION)
	else:
		push_warning("LandscapeScene: XROrigin3D not found — player position unchanged")


# ── Callbacks ────────────────────────────────────────────────────────

func _on_return_portal_entered(body: Node3D) -> void:
	# Only trigger on player body
	if not (body is CharacterBody3D or body.name == "PlayerBody"):
		return

	print("LandscapeScene: Return portal entered — going back to lab")
	var scene_manager = get_node_or_null("/root/SceneManager")
	if scene_manager and scene_manager.has_method("_return_to_hub"):
		scene_manager._return_to_hub({"return_from": "landscape"})
	else:
		push_warning("LandscapeScene: SceneManager not found — cannot return to lab")


# ── Helpers ──────────────────────────────────────────────────────────

func _make_box(size: Vector3) -> MeshInstance3D:
	var mesh_inst := MeshInstance3D.new()
	var box := BoxMesh.new()
	box.size = size
	mesh_inst.mesh = box
	return mesh_inst
