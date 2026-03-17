## Villa San Michele — Anacapri Demo Scene
##
## Standalone demo recreating the atmosphere of Bengt Böckman's 1992 watercolor
## of Axel Munthe's Villa San Michele in Anacapri, Capri.
##
## Creates:
##   - Warm Mediterranean environment (blue sky, golden sunlight)
##   - The villa facade loaded from the plan JSON via FacadePlanImporter
##   - Camera positioned slightly below, looking up (matching the watercolor viewpoint)
##   - Terracotta ground plane
##   - Title label
##   - Abstract Mediterranean pines framing the composition
##
## Run this scene directly (F6) to view the villa.
extends Node3D


const VILLA_PLAN_PATH := "res://commons/mesh_grammar/study_packs/villa_san_michele_plan.json"


func _ready() -> void:
	_create_environment()
	_create_ground()
	_create_villa()
	_create_title()
	_create_trees()


# ─── ENVIRONMENT ───────────────────────────────────────────────────────────

func _create_environment() -> void:
	# Mediterranean sky — bright, warm blue
	var env := Environment.new()
	env.background_mode = Environment.BG_COLOR
	env.background_color = Color(0.55, 0.75, 0.95)
	env.ambient_light_source = Environment.AMBIENT_SOURCE_COLOR
	env.ambient_light_color = Color(0.85, 0.82, 0.75)
	env.ambient_light_energy = 0.6
	env.tonemap_mode = Environment.TONE_MAPPER_FILMIC
	env.tonemap_white = 1.2
	env.ssao_enabled = true
	env.glow_enabled = true
	env.glow_intensity = 0.3
	env.glow_bloom = 0.1

	var world_env := WorldEnvironment.new()
	world_env.name = "WorldEnvironment"
	world_env.environment = env
	add_child(world_env)

	# Sun — warm golden light from above-left (late morning Mediterranean sun)
	var sun := DirectionalLight3D.new()
	sun.name = "Sun"
	sun.rotation_degrees = Vector3(-50, 30, 0)
	sun.light_color = Color(1.0, 0.94, 0.82)
	sun.light_energy = 1.6
	sun.shadow_enabled = true
	sun.shadow_bias = 0.02
	add_child(sun)

	# Fill light — warm bounce from stone/ground
	var fill := DirectionalLight3D.new()
	fill.name = "FillLight"
	fill.rotation_degrees = Vector3(-10, -120, 0)
	fill.light_color = Color(0.75, 0.70, 0.60)
	fill.light_energy = 0.3
	fill.shadow_enabled = false
	add_child(fill)

	# Camera — slightly below and in front, looking up at the villa
	# This matches the watercolor's viewpoint: standing below on the path,
	# looking up at the loggia and white walls above
	var cam := Camera3D.new()
	cam.name = "VillaCamera"
	cam.position = Vector3(8.0, 2.5, 16.0)
	cam.rotation_degrees = Vector3(-8, 0, 0)
	cam.fov = 45
	add_child(cam)


# ─── GROUND ────────────────────────────────────────────────────────────────

func _create_ground() -> void:
	var floor_body := StaticBody3D.new()
	floor_body.name = "Ground"
	add_child(floor_body)

	var floor_mesh := MeshInstance3D.new()
	var plane := PlaneMesh.new()
	plane.size = Vector2(60, 40)
	floor_mesh.mesh = plane

	# Terracotta/warm stone ground — typical of Anacapri paths
	var floor_mat := StandardMaterial3D.new()
	floor_mat.albedo_color = Color(0.72, 0.58, 0.42)
	floor_mat.roughness = 0.95
	floor_mesh.material_override = floor_mat
	floor_body.add_child(floor_mesh)

	var col := CollisionShape3D.new()
	var col_shape := BoxShape3D.new()
	col_shape.size = Vector3(60, 0.1, 40)
	col.shape = col_shape
	col.position.y = -0.05
	floor_body.add_child(col)


# ─── VILLA FACADE ──────────────────────────────────────────────────────────

func _create_villa() -> void:
	var plan_node := FacadePlanNode.new()
	plan_node.name = "VillaSanMichele"
	plan_node.plan_path = VILLA_PLAN_PATH
	plan_node.position = Vector3(0, 0, 0)
	add_child(plan_node)


# ─── TITLE ─────────────────────────────────────────────────────────────────

func _create_title() -> void:
	# Main title — positioned floating in front of the villa
	var title := Label3D.new()
	title.name = "TitleLabel"
	title.text = "Villa San Michele — Anacapri"
	title.font_size = 64
	title.pixel_size = 0.003
	title.position = Vector3(8.0, -0.3, 1.0)
	title.modulate = Color(0.35, 0.30, 0.22)
	title.outline_modulate = Color(0.9, 0.85, 0.75, 0.5)
	title.outline_size = 2
	add_child(title)

	# Subtitle
	var subtitle := Label3D.new()
	subtitle.name = "SubtitleLabel"
	subtitle.text = "After Bengt Böckman, 1992 — Axel Munthe's Villa"
	subtitle.font_size = 32
	subtitle.pixel_size = 0.002
	subtitle.position = Vector3(8.0, -0.7, 1.0)
	subtitle.modulate = Color(0.5, 0.45, 0.35)
	add_child(subtitle)


# ─── TREES (Abstract Mediterranean Pines) ─────────────────────────────────
#
# The iconic stone pines (Pinus pinea) are prominent in the Böckman watercolor,
# framing the villa from left and right. We represent them abstractly as
# simple CSG cylinders (trunks) + spheres (canopy).

func _create_trees() -> void:
	_add_pine(Vector3(-2.5, 0, 6.0), 6.5, 2.8)    # Left foreground pine — tall
	_add_pine(Vector3(18.0, 0, 5.0), 5.5, 2.4)     # Right foreground pine
	_add_pine(Vector3(-1.0, 0, -2.0), 7.0, 3.0)    # Left background pine — tallest


func _add_pine(base_pos: Vector3, height: float, canopy_radius: float) -> void:
	var tree := Node3D.new()
	tree.name = "Pine"
	tree.position = base_pos
	add_child(tree)

	# Trunk — slender, slightly rough bark
	var trunk := CSGCylinder3D.new()
	trunk.name = "Trunk"
	trunk.radius = 0.12
	trunk.height = height * 0.75
	trunk.sides = 8
	trunk.position = Vector3(0, trunk.height * 0.5, 0)

	var trunk_mat := StandardMaterial3D.new()
	trunk_mat.albedo_color = Color(0.35, 0.28, 0.18)
	trunk_mat.roughness = 0.95
	trunk.material = trunk_mat
	tree.add_child(trunk)

	# Canopy — flattened sphere (umbrella pine shape)
	var canopy := CSGSphere3D.new()
	canopy.name = "Canopy"
	canopy.radius = canopy_radius
	canopy.radial_segments = 16
	canopy.rings = 8
	# Scale Y to flatten the sphere into an umbrella shape
	canopy.scale = Vector3(1.0, 0.45, 1.0)
	canopy.position = Vector3(0, height * 0.75 + canopy_radius * 0.2, 0)

	var canopy_mat := StandardMaterial3D.new()
	canopy_mat.albedo_color = Color(0.22, 0.38, 0.18)
	canopy_mat.roughness = 0.9
	canopy.material = canopy_mat
	tree.add_child(canopy)
