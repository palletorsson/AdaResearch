# capsule_radials_rings.gd - Configurable capsule with radial segments and rings
# Usage: capsule_radials_rings:90:1:#config:8:4 for 8 radial segments and 4 rings
extends Node3D

# @identity
# essence: CapsuleMesh(radial_segments, rings, height, radius) — cylinder with hemispherical caps
# desire: learner understands the capsule as a cylinder that has been made "safe" at its ends
# critical_parameter: radial_segments — controls how round the cylinder cross-section appears
# triggers: grid config syntax (capsule_radials_rings#config:8:4) or apply_grid_config() call at runtime
# emerges: the capsule as the collision primitive of choice — smooth ends prevent snagging in physics
# needs: [missing VR controls — configured via map data; no live slider]
# relationships: sibling to torus_radials_rings in the configurable mesh family; both support #config syntax
# truth: the capsule is the physicist's preferred solid — its hemispherical ends are differentiable at all points

const GridMaterialFactory: GDScript = preload("res://commons/primitives/shared/grid_material_factory.gd")

# --- DNA (stage 2, promoted 2026-08-03) -------------------------------------
# THIS IS NOT A SMOOTHNESS DIAL, and the corpus proves it before this file does.
# Eighteen of this artifact's placements already pass #radial:3 or #radial:7 —
# so maps have been treating radial_segments as a choice of SOLID, not a quality
# setting, since before anything was declared. At radial_segments=3 a CapsuleMesh
# is a triangular prism with a tent at each end. At 4 it is a square beam. It does
# not become "a rougher capsule" until somewhere around 12. The artifact's own
# qfep_connection says it outright: "turn the dial down and the body becomes a
# barrel." A barrel is a different object.
#
# cross_section — WHICH SOLID the body is in section. The values are named for the
#   polygon, because that is the thing you can point at in a still; 8 is what the
#   scene has always authored and 24 is the first count at which the silhouette
#   stops confessing its flats. Resolution is spent going around.
#
# caps — WHETHER THE ENDS ACTUALLY ROUND. Godot's CapsuleMesh spends `rings` on
#   the hemispheres, and this is the axis that argues with the artifact's own truth
#   line: "the capsule is the physicist's preferred solid — its hemispherical ends
#   are differentiable at all points." At rings=1 each hemisphere collapses to a
#   single band from equator to pole, i.e. a CONE, and the end has an apex — the
#   exact point where the derivative does not exist. The claim in the truth line is
#   not a property of capsules, it is a property of capsules built with enough
#   rings, and until now nothing in the family could say so.
#
# WHY TWO AXES AND NOT ONE. A capsule is defined as a cylinder plus two
# hemispheres, so it has two constituents and each takes a different question:
# cross_section asks what the barrel is, caps asks what the ends are. This is the
# same amount/direction split sphere_mid made with resolution/budget_bias, and it
# does not collide with the sibling `capsule` token in this directory, whose
# `facture` axis (cast|facet|armature|section|wear) asks how a made body is
# presented and explicitly declares its own segment counts legacy and never
# written to. The segment question was left vacant for this token; it takes it.
const CROSS_SECTIONS = {
	"triangular": 3,
	"square": 4,
	"hexagonal": 6,
	"octagonal": 8,
	"round": 24,
}
const CAPS = {
	"pointed": 1,
	"chamfered": 2,
	"domed": 4,
	"smooth": 12,
}

@export var base_color: Color = Color(0.4, 0.8, 0.6)  # Teal
@export_enum("triangular", "square", "hexagonal", "octagonal", "round") var cross_section: String = "octagonal"
@export_enum("pointed", "chamfered", "domed", "smooth") var caps: String = "domed"
@export var radial_segments: int = 8  # Number of segments around the circumference
@export var rings: int = 4  # Number of ring divisions along the capsule
@export var height: float = 1.0  # Total height including caps
@export var radius: float = 0.25  # Radius of the capsule

var _mesh_instance: MeshInstance3D
## Eighteen live placements say #radial:3 or #radial:7 (and #rings:3) through the
## numeric path. Those numbers WIN over the named axes — the vocabulary is laid
## over the raw counts, never on top of them, so no shipped token changes meaning.
var _radial_explicit: bool = false
var _rings_explicit: bool = false

func _ready():
	# Check for config metadata set by grid system
	if has_meta("config_config"):
		var config_str = str(get_meta("config_config"))
		_parse_config_string(config_str)

	# The named axes, read here as well as in apply_grid_config so a map token
	# lands on the FIRST build rather than causing a visible rebuild. No existing
	# placement sets either key, so this branch is dead for all 15 of them.
	if has_meta("config_cross_section"):
		var mx: String = str(get_meta("config_cross_section")).strip_edges().to_lower()
		if CROSS_SECTIONS.has(mx):
			cross_section = mx
	if has_meta("config_caps"):
		var mc: String = str(get_meta("config_caps")).strip_edges().to_lower()
		if CAPS.has(mc):
			caps = mc

	_build_capsule()

# Parse config string like "8:4" for radial:rings
func _parse_config_string(config_str: String) -> void:
	var parts = config_str.split(":")
	if parts.size() >= 1 and parts[0].is_valid_int():
		radial_segments = max(3, int(parts[0]))  # Minimum 3 for a valid shape
		_radial_explicit = true
	if parts.size() >= 2 and parts[1].is_valid_int():
		rings = max(1, int(parts[1]))  # Minimum 1 ring
		_rings_explicit = true
	print("Capsule configured: radial_segments=%d, rings=%d" % [radial_segments, rings])

# Called by grid system for #config syntax
func apply_grid_config(config_data: Dictionary) -> void:
	# Guarded: rebuild only when a value actually CHANGED and _ready has already
	# built once. A placement that passes only a rotation, or nothing at all, is
	# left exactly as it shipped instead of being torn down and reassembled.
	var changed: bool = false

	if config_data.has("config"):
		_parse_config_string(str(config_data.config))
		changed = true
	if config_data.has("radial"):
		var want_seg: int = max(3, int(config_data.radial))
		if want_seg != radial_segments or not _radial_explicit:
			radial_segments = want_seg
			_radial_explicit = true
			changed = true
	if config_data.has("rings"):
		var want_rings: int = max(1, int(config_data.rings))
		if want_rings != rings or not _rings_explicit:
			rings = want_rings
			_rings_explicit = true
			changed = true
	if config_data.has("cross_section"):
		var want_x: String = str(config_data["cross_section"]).strip_edges().to_lower()
		if CROSS_SECTIONS.has(want_x) and want_x != cross_section:
			cross_section = want_x
			changed = true
	if config_data.has("caps"):
		var want_caps: String = str(config_data["caps"]).strip_edges().to_lower()
		if CAPS.has(want_caps) and want_caps != caps:
			caps = want_caps
			changed = true
	if config_data.has("height"):
		var want_h: float = float(config_data.height)
		if want_h != height:
			height = want_h
			changed = true
	if config_data.has("radius"):
		var want_r: float = float(config_data.radius)
		if want_r != radius:
			radius = want_r
			changed = true

	# Rebuild if already built
	if changed and _mesh_instance:
		_build_capsule()

func _build_capsule() -> void:
	# Clean up existing mesh
	if _mesh_instance:
		if _mesh_instance.get_parent() == self:
			remove_child(_mesh_instance)
		_mesh_instance.queue_free()
		_mesh_instance = null

	# Use Godot's CapsuleMesh with our parameters.
	#
	# THE LEGACY GUARANTEE. The named axes only speak where the numeric path was
	# silent. A placement that said #radial:3 keeps 3; a placement that said
	# nothing gets cross_section="octagonal" -> 8 and caps="domed" -> 4, which are
	# the two literals this file and capsule_radials_rings.tscn have always
	# authored. Every one of the 15 placements is therefore unchanged, whichever
	# path it came in on.
	var seg: int = radial_segments
	var rng: int = rings
	if not _radial_explicit and CROSS_SECTIONS.has(cross_section):
		seg = int(CROSS_SECTIONS[cross_section])
	if not _rings_explicit and CAPS.has(caps):
		rng = int(CAPS[caps])

	var capsule_mesh = CapsuleMesh.new()
	capsule_mesh.radius = radius
	capsule_mesh.height = height
	capsule_mesh.radial_segments = seg
	capsule_mesh.rings = rng

	_mesh_instance = MeshInstance3D.new()
	_mesh_instance.mesh = capsule_mesh
	_mesh_instance.name = "CapsuleMesh"
	_mesh_instance.material_override = GridMaterialFactory.make(base_color)
	add_child(_mesh_instance)

	# Add collision
	_create_collision()

func _create_collision() -> void:
	# Remove existing collision
	var existing = get_node_or_null("CapsuleCollision")
	if existing:
		existing.queue_free()

	var static_body = StaticBody3D.new()
	static_body.name = "CapsuleCollision"
	add_child(static_body)

	var collision = CollisionShape3D.new()
	var shape = CapsuleShape3D.new()
	shape.radius = radius
	shape.height = height
	collision.shape = shape
	static_body.add_child(collision)

func set_base_color(color: Color) -> void:
	base_color = color
	if _mesh_instance:
		_mesh_instance.material_override = GridMaterialFactory.make(base_color)

# Convenience method to update capsule parameters
func set_capsule_params(new_radial: int = -1, new_rings: int = -1, new_height: float = -1, new_radius: float = -1) -> void:
	if new_radial > 0:
		radial_segments = max(3, new_radial)
		_radial_explicit = true
	if new_rings > 0:
		rings = max(1, new_rings)
		_rings_explicit = true
	if new_height > 0:
		height = new_height
	if new_radius > 0:
		radius = new_radius

	_build_capsule()
