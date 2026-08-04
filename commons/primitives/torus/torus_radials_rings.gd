# torus_radials_rings.gd - Configurable torus with rings and ring segments
# Usage: torus_radials_rings:90:1:#config:16:8 for 16 rings and 8 ring_segments
# rings = divisions around the main circle (donut path)
# ring_segments = divisions around the tube cross-section
extends Node3D

# @identity
# essence: TorusMesh(rings, ring_segments, inner_radius, outer_radius) — a circle revolved around an axis
# desire: learner understands the torus as a product of two circles — one for the path, one for the tube
# critical_parameter: ring_segments — tube cross-section resolution; at 4 it looks square, at 32 it looks round
# triggers: grid config syntax (torus_radials_rings#config:16:8) or apply_grid_config() call at runtime
# emerges: that the torus has a topology distinct from a sphere — it has a hole and cannot be flattened
# needs: the hole itself as a variable, so genus 1 is shown rather than asserted [has, 2026-08-03 — the `hole` axis]. Missing: VR controls — configured via map data, no live slider
# relationships: used in combine_portals and diamondtoruscollection; shares config pattern with capsule
# truth: the torus is topologically distinct from the sphere — its genus is 1, meaning it has exactly one hole

# --- DNA (stage 2, promoted 2026-08-03) — axis `hole` ---
#
# WHAT WAS ALREADY HERE. rings and ring_segments were exported and reachable from a map
# token (#config:16:8), and the whole corpus uses them: every one of the eleven
# placements says either nothing or #config:8:4. Both are RESOLUTION — how finely the
# same donut is cut into triangles. Nothing in this file ever varied the shape.
#
# WHAT THE HARD-CODED CONSTANTS WERE HIDING. inner_radius 0.3 and outer_radius 0.5 sat
# as fixed numbers, and their RATIO is not a size setting: it is which torus this is.
# Godot's TorusMesh derives tube radius = (outer - inner) / 2 and path radius =
# (outer + inner) / 2 from that pair, and the classical family follows directly:
#
#   tube < path   ring torus     genus 1 — a hole you can see through
#   tube = path   horn torus     the hole has closed to a single point
#
# The file's own truth statement is "the torus is topologically distinct from the sphere
# — its genus is 1, meaning it has exactly one hole". Shipped, that is an assertion the
# artifact makes and never tests. `hole` is the knob that tests it: walk the ratio and
# the hole shuts while you watch, and the claim about genus acquires an edge case.
#
# OUTER RADIUS IS HELD AT 0.5 FOR EVERY VALUE, on purpose. If the silhouette grew too,
# the axis would be measuring size and the argument would be lost inside it. Same
# footprint, same one-cell spatial_needs, different topology.
const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")

## Which torus this is — the ratio of tube to hole, not the resolution.
## hoop = a wire ring, almost all hole. ring = the shipped donut. thick = the hole nearly
## shut. horn = tube radius equals path radius, so the hole closes to a point.
@export_enum("hoop", "ring", "thick", "horn") var hole: String = "ring"

@export var base_color: Color = Color(0.5, 0.2, 0.35)  # Darker magenta for contrast
@export var wireframe_color: Color = Color(1.0, 1.0, 1.0)  # White wireframe for contrast
@export var rings: int = 8  # Low divisions for visible triangular structure
@export var ring_segments: int = 4  # Low tube segments - visible triangles
@export var inner_radius: float = 0.3  # Radius of the hole (distance from center to tube center)
@export var outer_radius: float = 0.5  # Outer radius (inner_radius + tube_radius)

const HOLES: PackedStringArray = ["hoop", "ring", "thick", "horn"]

## The one radius every value shares, so the axis moves the hole and not the size.
const HOLE_OUTER: float = 0.5

## `horn` wants inner_radius 0.0 exactly. It is held one millimetre off zero because
## TorusMesh's own property hint starts at 0.001, and a value the engine might refuse
## would leave the radii untouched — five identical frames and a false INERT verdict.
## At 0.2% of the outer radius the hole is closed as far as any still can show.
const HOLE_HORN_INNER: float = 0.001

var _mesh_instance: MeshInstance3D

func _ready():
	# The radii come from `hole` FIRST, so an explicit #inner:/#outer: in a map token
	# still wins below and in apply_grid_config. On the default this writes 0.3 / 0.5 —
	# the same pair the .tscn already carries — so no shipped placement moves.
	if has_meta("config_hole"):
		hole = _pick_hole(str(get_meta("config_hole")))
	hole = _pick_hole(hole)
	_apply_hole_profile()

	# Check for config metadata set by grid system
	if has_meta("config_config"):
		var config_str = str(get_meta("config_config"))
		_parse_config_string(config_str)

	_build_torus()

## Named ratios, not sizes. Every value keeps outer_radius at HOLE_OUTER; only the hole
## moves. The `_:` arm and the "ring" arm are deliberately the same numbers, so an
## unrecognised string renders the shipped donut rather than nothing.
func _apply_hole_profile() -> void:
	outer_radius = HOLE_OUTER
	match hole:
		"hoop":
			inner_radius = 0.45   # tube 0.025, path 0.475 — a wire, almost all hole
		"ring":
			inner_radius = 0.3    # tube 0.10,  path 0.40  — SHIPPED
		"thick":
			inner_radius = 0.12   # tube 0.19,  path 0.31  — the hole nearly shut
		"horn":
			inner_radius = HOLE_HORN_INNER  # tube = path — the hole closed to a point
		_:
			inner_radius = 0.3

func _pick_hole(raw: String) -> String:
	var v: String = raw.to_lower().strip_edges()
	return v if HOLES.has(v) else "ring"

# Parse config string like "16:8" for rings:ring_segments
func _parse_config_string(config_str: String) -> void:
	var parts = config_str.split(":")
	if parts.size() >= 1 and parts[0].is_valid_int():
		rings = max(3, int(parts[0]))  # Minimum 3 for a valid torus
	if parts.size() >= 2 and parts[1].is_valid_int():
		ring_segments = max(3, int(parts[1]))  # Minimum 3 for tube cross-section
	print("Torus configured: rings=%d, ring_segments=%d" % [rings, ring_segments])

# Called by grid system for #config syntax
func apply_grid_config(config_data: Dictionary) -> void:
	var before_hole: String = hole
	var before_rings: int = rings
	var before_segments: int = ring_segments
	var before_inner: float = inner_radius
	var before_outer: float = outer_radius

	# `hole` is read FIRST and only when the caller actually named it, so an explicit
	# #inner:/#outer: below still wins and a placement that never mentions the axis
	# never has its radii rewritten.
	if config_data.has("hole"):
		hole = _pick_hole(str(config_data["hole"]))
		_apply_hole_profile()
	if config_data.has("config"):
		_parse_config_string(str(config_data.config))
	if config_data.has("rings"):
		rings = max(3, int(config_data.rings))
	if config_data.has("segments"):
		ring_segments = max(3, int(config_data.segments))
	if config_data.has("ring_segments"):
		ring_segments = max(3, int(config_data.ring_segments))
	if config_data.has("inner"):
		inner_radius = float(config_data.inner)
	if config_data.has("outer"):
		outer_radius = float(config_data.outer)

	# Rebuild ONLY after _ready has built once, and ONLY on a real change. The grid calls
	# this deferred for every placement, several of them with a config that resolves to
	# the values already in place; tearing the mesh down and rebuilding it identically is
	# a cost every shipped map would pay for this axis existing.
	if _mesh_instance == null:
		return
	var unchanged: bool = hole == before_hole and rings == before_rings
	unchanged = unchanged and ring_segments == before_segments
	unchanged = unchanged and is_equal_approx(inner_radius, before_inner)
	unchanged = unchanged and is_equal_approx(outer_radius, before_outer)
	if unchanged:
		return
	_build_torus()

func _build_torus() -> void:
	# Clean up existing mesh
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

	# Use Godot's TorusMesh with our parameters
	var torus_mesh = TorusMesh.new()
	torus_mesh.inner_radius = inner_radius
	torus_mesh.outer_radius = outer_radius
	torus_mesh.rings = rings
	torus_mesh.ring_segments = ring_segments

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = torus_mesh
	_mesh_instance.name = "TorusMesh"
	# Use distinct wireframe color for visible triangular structure
	_mesh_instance.material_override = GridMaterialFactory.make(base_color, {
		"wireframe_color": wireframe_color,
		"wireframe_width": 2.5,
		"wireframe_brightness": 3.0
	})
	add_child(_mesh_instance)

	# Add collision (approximate with multiple capsules or use convex)
	_create_collision()

func _create_collision() -> void:
	# Remove existing collision
	var existing = get_node_or_null("TorusCollision")
	if existing:
		existing.queue_free()

	var static_body = StaticBody3D.new()
	static_body.name = "TorusCollision"
	add_child(static_body)

	# Create convex collision from mesh
	if _mesh_instance and _mesh_instance.mesh:
		var collision = CollisionShape3D.new()
		# Use a simple approximation - a flattened cylinder covering the torus
		var shape = CylinderShape3D.new()
		shape.radius = outer_radius
		shape.height = (outer_radius - inner_radius)  # Tube diameter
		collision.shape = shape
		static_body.add_child(collision)

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

# Convenience method to update torus parameters
func set_torus_params(new_rings: int = -1, new_ring_segments: int = -1, new_inner: float = -1, new_outer: float = -1) -> void:
	if new_rings > 0:
		rings = max(3, new_rings)
	if new_ring_segments > 0:
		ring_segments = max(3, new_ring_segments)
	if new_inner > 0:
		inner_radius = new_inner
	if new_outer > 0:
		outer_radius = new_outer

	_build_torus()
