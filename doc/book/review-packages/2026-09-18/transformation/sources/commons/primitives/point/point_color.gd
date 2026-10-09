# PointColor.gd - Standalone color management for 3D mesh objects
#
# ─────────────────────────────────────────────────────────────────────────────
# THE DECLARED COLOUR — repair, not an axis.
#
# This node paints its parent MeshInstance3D in _ready(), and it painted
# `current_color` — HOT_PINK — over whatever the scene's own material said. Five
# scenes share this script, and one of them, grab_sphere_point_with_color.tscn,
# is worn by FIVE registry names: grab_sphere_E, grab_sphere_F,
# grab_sphere_lambda, grab_sphere_phi and the plain primitive
# grab_sphere_point_with_color. The registry gives the first four a
# `default_params.color` each — FF6060, 4080FF, 40FF80, FF80FF — and nothing in
# the engine read it. So the four terms of QFE = F - λE(S) + φΔE(S,t) stood in
# qfeplaboratory as four identical pink pellets. Three terms of one equation,
# indistinguishable.
#
# The loader now merges a registry entry's `default_params` into the same
# `config_<key>` metadata channel a map token already uses
# (GridInteractablesComponent._place_artifact), so this node reads `config_color`
# and the declaration finally arrives. The colour VALUES are not this file's to
# choose and are unchanged; only the fact that they are delivered is new.
#
# WHY IT IS NOT A DNA AXIS. Choosing a stance value would then also choose WHICH
# TERM the sphere is. Identity is not a staging decision.
#
# THE TRAP THAT WOULD HAVE HIDDEN THE REPAIR, and the reason for the duplicate()
# below. `material_override` in grab_sphere_point_with_color.tscn is a plain
# sub-resource — no `resource_local_to_scene` — so every instance of that scene
# shares ONE StandardMaterial3D, and apply_color() mutates it IN PLACE. Today
# that is invisible because all four write the same pink. Hand them four
# different colours and the last _ready() to run wins for all of them: the
# spheres would still have been four identical pellets, merely no longer pink,
# and a per-artifact render — one instance in the frame, nothing to share with —
# would have shown the fix working. QFEP_Introduction places three of them and
# QFEP_Synthesis four. So a placement that carries a declared colour takes its
# own copy of the material first. A placement that does not carry one touches
# nothing: it keeps writing pink to the shared resource, exactly as before.
#
# WHAT IS DELIBERATELY NOT REACHED. capture_multi_angle --mode=artifact stamps
# artifact_lookup_name but never consults the registry, so a still taken that way
# still renders pink — the registry only reaches an artifact through the grid.
# `color_hex` below is the handle that makes the difference renderable without
# the grid; see the note on it. Reported, not fixed: the capture scripts are not
# this pass's files.
# ─────────────────────────────────────────────────────────────────────────────

extends Node

# Target mesh to colorize
var target_mesh: MeshInstance3D = null

# Current color
@export var current_color: Color = Color.HOT_PINK

## A declared colour as an html hex string, e.g. "FF6060" or "#FF6060". Empty
## means "no declaration", which is the shipped state of every placement — the
## default path below never reads it. It exists as a String and not as a second
## Color because the two things that declare a colour here can only speak in
## strings: registry JSON (`default_params.color`), and the capture sweep, whose
## variant params come from JSON and cannot express a Color at all. Lower
## priority than `config_color`, so a map token still wins.
@export var color_hex: String = ""

# Material settings
var use_emission: bool = true
var emission_strength: float = 0.8


func _ready():
	# Try to find target mesh in parent if not set

	if not target_mesh and get_parent() is MeshInstance3D:
		target_mesh = get_parent()

	# THE DATA GATE. `declared` is null for every placement that carries neither
	# a registry default_params.color nor a #color: token nor a color_hex — which
	# is all of them but the four QFEP terms — and everything below is skipped.
	var declared: Variant = _declared_color()
	if declared is Color:
		current_color = declared
		# Take our own copy of the shared sub-resource BEFORE painting, so four
		# terms in one room do not overwrite each other. See the header.
		if target_mesh and target_mesh.material_override is StandardMaterial3D:
			var shared: StandardMaterial3D = target_mesh.material_override as StandardMaterial3D
			target_mesh.material_override = shared.duplicate() as StandardMaterial3D

	# Apply initial color if target exists
	if target_mesh:
		apply_color(current_color)

# Set the target mesh to colorize
func set_target_mesh(mesh: MeshInstance3D):
	target_mesh = mesh
	if target_mesh and current_color != Color.WHITE:
		apply_color(current_color)

# Set the color of the target mesh
func set_color(color: Color):
	current_color = color
	apply_color(color)

# Apply color to the target mesh
func apply_color(color: Color):
	if not target_mesh:
		return

	# Create new material or modify existing one
	var material: StandardMaterial3D
	if target_mesh.material_override and target_mesh.material_override is StandardMaterial3D:
		material = target_mesh.material_override as StandardMaterial3D
	else:
		material = StandardMaterial3D.new()
		target_mesh.material_override = material

	# Apply color settings
	material.albedo_color = color

	if use_emission:
		material.emission_enabled = true
		material.emission = color * emission_strength
	else:
		material.emission_enabled = false

# Configure material properties
func configure_material(emission: bool = true, emission_str: float = 0.8, unshaded: bool = true):
	use_emission = emission
	emission_strength = emission_str

	# Reapply color with new settings
	if target_mesh:
		apply_color(current_color)


# ── the declaration ──────────────────────────────────────────────────────────

## The colour this placement was declared to have, or null if it was declared
## none. `config_color` first (registry default_params, or a map token's
## #color:, which the loader has already resolved in that order), then the
## `color_hex` export as the fallback for callers that reach this node directly.
func _declared_color() -> Variant:
	var raw: Variant = _config_color()
	if raw == null:
		var fallback: String = color_hex.strip_edges()
		if fallback.is_empty():
			return null
		raw = fallback
	if raw is Color:
		return raw
	var text: String = str(raw).strip_edges()
	if text.is_empty():
		return null
	if not Color.html_is_valid(text):
		push_warning("point_color: '%s' is not an html colour — keeping the shipped one" % text)
		return null
	return Color.html(text)


## Read `config_color` off the artifact, walking root-ward.
##
## GridInteractablesComponent sets `config_<key>` metadata on the artifact ROOT
## before add_child (so it is readable from a child's _ready), and this node sits
## two levels down — root → MeshInstance3D → here. Walking rather than assuming a
## depth keeps it working if the body is ever re-parented.
##
## The walk STOPS at the first node carrying `artifact_lookup_name`: that node is
## this artifact's own root, and a config key on some outer artifact holding us —
## curation_station, sim_cube — was addressed to that artifact, not to us.
func _config_color() -> Variant:
	var n: Node = self
	while n != null:
		if n.has_meta("config_color"):
			return n.get_meta("config_color")
		if n.has_meta("artifact_lookup_name"):
			return null
		n = n.get_parent()
	return null
