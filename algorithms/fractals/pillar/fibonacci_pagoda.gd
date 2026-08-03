# ===========================================================================
# Fibonacci Pagoda
# Uses pillarpart.tscn stacked with Fibonacci-based scaling
#
# Traditional pagoda architecture meets Fibonacci mathematical patterns
# Each tier's scale follows the inverse Fibonacci sequence for tapering
# ===========================================================================

@tool
extends Node3D

## Fibonacci Pagoda
## Creates a pagoda structure using pillarpart instances scaled by Fibonacci ratios
## Chapter 08: Fractals - Mathematical patterns in architecture

# @identity
# essence: tier_scale(n) = base_scale / phi^(n*0.5), stacking Fibonacci-ratioed tiers with golden finial
# desire: To be looked up at — each tier smaller by the golden ratio, converging to a point that never quite arrives
# critical_parameter: use_golden_ratio — toggles between pure Fibonacci integer ratios and continuous phi scaling, producing subtly different tapering
# triggers: num_tiers increase → taller, more converging structure; roof_overhang → how far the eaves extend beyond the body
# emerges: The visual impression of weightlessness at the top — pure mathematics making stone look like it floats
# needs: VR tier-count slider [missing], walk-inside collision [missing]
# relationships: Bridges fibonacci_sequences (abstract math) to architecture; contrasts with romanesco (organic Fibonacci)
# truth: The golden ratio is not imposed on the pagoda — the pagoda is what the golden ratio looks like when it tries to be architecture.

const PILLAR_SCENE = preload("res://algorithms/fractals/pillar/pillarpart.tscn")

@export var num_tiers: int = 8
@export var base_scale: float = 3.0  # Scale of the bottom tier
@export var tier_height: float = 1.2  # Vertical spacing between tiers
@export var roof_overhang: float = 1.3  # How much wider the roof extends
@export var use_golden_ratio: bool = true  # Use golden ratio or pure Fibonacci

# ═══════════════════════════════════════════════════════════════════════════
# STAGE-2 DNA — `profile`
# ═══════════════════════════════════════════════════════════════════════════
#
# THE SILHOUETTE THE EIGHT TIERS CUT. This artifact's whole claim is in its own
# truth line: the pagoda is not a pagoda with phi applied to it, it is what phi
# looks like when it tries to be architecture. But a claim about ONE ratio needs
# something to be a claim AGAINST, and shipped as a singleton it has none — the
# golden taper reads as "how pagodas are", not as a decision. So the axis is the
# law that governs the descent, and the other four values are the arguments the
# golden one was silently winning.
#
# ADOPTED WORD FOR WORD from carousel_cake, which is the same geometric object —
# a stack of N layers of falling radius — asking the same question of it. Same
# spelling, same five values, same order, same default, so a tiered stack in one
# room and a tiered stack in another are measured on one scale.
#
#   cake      the shipped law, untouched: scale(n) = base / phi^(n/2), or the
#             inverse-Fibonacci ratios when use_golden_ratio is off. Byte for
#             byte the legacy pagoda.  (DEFAULT)
#   ziggurat  a straight line from wide to narrow. No ratio at all — the taper
#             an arithmetic mind reaches for, and the pre-Greek stack it built.
#             Sides that read as one flat slope instead of a curve.
#   column    no taper. Every tier the same width, eaves stacked like a shaft of
#             identical roofs. The refusal to converge, and the thing phi is
#             most obviously NOT.
#   spindle   waisted — wide at the foot, pinched to a third at the fourth tier,
#             wide again at the crown. Convergence abandoned in the middle and
#             taken back up, which is what a stack looks like with no single law.
#   flare     the shipped golden taper STANDING ON ITS HEAD: the same eight
#             numbers in reverse, so the smallest tier is at the ground and the
#             widest carries the finial. The identical ratio, the identical
#             quantity of building, and an object that reads as top-heavy — phi
#             shown to be a claim about DIRECTION and not only about proportion.
#
# EVERY VALUE KEEPS THE SAME TOTAL. The four non-default laws are normalised so
# their tier scales SUM to the shipped sum, and tier height is derived from tier
# scale, so all five pagodas are the same height and use the same quantity of
# stone. Only the distribution moves. Without that, `column` would run 12 m tall
# against the shipped 7.2 m and the bite critic would be reporting a size
# difference and calling it a silhouette.
#
# STRICTLY ADDITIVE. _profile_scale() hands `cake` straight to the untouched
# _get_tier_scale(), so the four existing placements build exactly what they
# always built. There is no RNG anywhere in this artifact and no animation:
# _ready ends in set_process(false).
const PROFILES: PackedStringArray = ["cake", "ziggurat", "column", "spindle", "flare"]
@export_enum("cake", "ziggurat", "column", "spindle", "flare") var profile: String = "cake"

## Stand an INVISIBLE box (layers = 0) around the shipped envelope, so the
## framing walk sizes all five shots identically. The heights already match, but
## `column` is half the width of `cake` at its base, and a camera placed from
## each variant's own AABB would push the narrow ones away and pull the wide ones
## in — the bite report would then be partly a picture of the zoom.
## Sized from the SHIPPED taper via _get_tier_scale, which no profile touches.
## Default false — not one placement changes.
@export var capture_anchor: bool = false

## Ziggurat's narrow end, as a fraction of its wide end, before normalisation.
const ZIGGURAT_NARROW := 0.2
## Spindle's waist, as a fraction of its ends, before normalisation.
const SPINDLE_WAIST := 0.3

## Sum of the shipped tier scales. Every other law is rescaled to match it, so no
## profile spends more building than `cake` does. -1.0 means "not computed yet";
## it cannot be computed before _generate_fibonacci_sequence has run.
var _shipped_sum: float = -1.0

var _sim_root: Node3D
var _status_label: Label3D
var _tiers: Array = []
var _fibonacci_sequence: Array = []
var _golden_ratio: float = (1.0 + sqrt(5.0)) / 2.0

func _ready() -> void:
	_read_dna()
	_generate_fibonacci_sequence(num_tiers + 5)
	_setup_environment()
	_build_pagoda()
	# APPENDED LAST. Builds nothing unless asked; see the capture_anchor note.
	if capture_anchor:
		_add_capture_anchor()
	set_process(false)

func _generate_fibonacci_sequence(count: int) -> void:
	"""Generate Fibonacci sequence for scaling calculations"""
	_fibonacci_sequence = [1, 1]
	for i in range(2, count):
		_fibonacci_sequence.append(_fibonacci_sequence[i-1] + _fibonacci_sequence[i-2])

func _setup_environment() -> void:
	_sim_root = Node3D.new()
	_sim_root.name = "PagodaRoot"
	add_child(_sim_root)
	
	_status_label = Label3D.new()
	_status_label.billboard = BaseMaterial3D.BILLBOARD_ENABLED
	_status_label.font_size = 32
	_status_label.modulate = Color(1.0, 0.9, 0.8)
	_status_label.position = Vector3(0, num_tiers * tier_height + 2.0, 0)
	_status_label.text = "Fibonacci Pagoda | Tiers: %d" % num_tiers
	_sim_root.add_child(_status_label)

func _build_pagoda() -> void:
	"""Build the pagoda from bottom to top using Fibonacci scaling"""
	var current_height: float = 0.0
	
	for tier in range(num_tiers):
		var tier_data = _create_tier(tier, current_height)
		current_height += tier_data["height"]
	
	# Add finial (top ornament) using smallest pillar
	_create_finial(current_height)

func _get_tier_scale(tier_index: int) -> float:
	"""Calculate scale for a tier using Fibonacci ratios"""
	if use_golden_ratio:
		# Scale decreases by golden ratio each tier
		return base_scale / pow(_golden_ratio, tier_index * 0.5)
	else:
		# Use inverse Fibonacci ratio for scaling
		var fib_index = num_tiers - tier_index
		var max_fib = float(_fibonacci_sequence[num_tiers])
		var tier_fib = float(_fibonacci_sequence[fib_index])
		return base_scale * (tier_fib / max_fib)

func _create_tier(tier_index: int, y_position: float) -> Dictionary:
	"""Create a single pagoda tier with roof"""
	# PROFILE: the drawn tier scale. "cake" returns _get_tier_scale unchanged,
	# which is what every existing placement gets.
	var scale_factor = _profile_scale(tier_index)
	var tier_container = Node3D.new()
	tier_container.name = "Tier_%d" % tier_index
	tier_container.position = Vector3(0, y_position, 0)
	_sim_root.add_child(tier_container)
	
	# Create the main pillar body for this tier
	var pillar = PILLAR_SCENE.instantiate()
	pillar.scale = Vector3(scale_factor, scale_factor * 0.8, scale_factor)
	_apply_tier_material(pillar, tier_index)
	tier_container.add_child(pillar)
	
	# Create roof overhang using scaled pillars rotated
	_create_roof_layer(tier_container, scale_factor, tier_index)
	
	# Create corner pillars for structural detail
	_create_corner_pillars(tier_container, scale_factor, tier_index)
	
	_tiers.append(tier_container)
	
	return {
		"height": tier_height * scale_factor / base_scale + 0.3,
		"scale": scale_factor
	}

func _create_roof_layer(parent: Node3D, scale_factor: float, tier_index: int) -> void:
	"""Create the characteristic pagoda roof overhang"""
	var roof_scale = scale_factor * roof_overhang
	
	# Create 4 roof eaves pointing outward (N, S, E, W)
	var directions = [
		Vector3(1, 0, 0),
		Vector3(-1, 0, 0),
		Vector3(0, 0, 1),
		Vector3(0, 0, -1)
	]
	
	for i in range(directions.size()):
		var roof_part = PILLAR_SCENE.instantiate()
		var eave_scale = scale_factor * 0.4
		roof_part.scale = Vector3(eave_scale, eave_scale * 0.3, eave_scale * 0.5)
		
		# Position at the edge of the tier, angled downward
		var offset = directions[i] * scale_factor * 0.5
		roof_part.position = offset + Vector3(0, scale_factor * 0.35, 0)
		
		# Rotate to point outward and tilt down slightly
		roof_part.rotation_degrees = Vector3(
			-20 if directions[i].z != 0 else 0,  # Tilt down
			90 * i,  # Face outward
			-20 if directions[i].x != 0 else 0   # Tilt down
		)
		
		_apply_roof_material(roof_part, tier_index)
		parent.add_child(roof_part)
	
	# Add corner eaves for more traditional look
	var corner_directions = [
		Vector3(1, 0, 1).normalized(),
		Vector3(1, 0, -1).normalized(),
		Vector3(-1, 0, 1).normalized(),
		Vector3(-1, 0, -1).normalized()
	]
	
	for i in range(corner_directions.size()):
		var corner_eave = PILLAR_SCENE.instantiate()
		var eave_scale = scale_factor * 0.3
		corner_eave.scale = Vector3(eave_scale, eave_scale * 0.25, eave_scale * 0.4)
		
		var offset = corner_directions[i] * scale_factor * 0.6
		corner_eave.position = offset + Vector3(0, scale_factor * 0.3, 0)
		corner_eave.rotation_degrees = Vector3(-25, 45 + 90 * i, -25)
		
		_apply_roof_material(corner_eave, tier_index)
		parent.add_child(corner_eave)

func _create_corner_pillars(parent: Node3D, scale_factor: float, tier_index: int) -> void:
	"""Create small structural pillars at corners"""
	var corner_positions = [
		Vector3(1, 0, 1) * scale_factor * 0.3,
		Vector3(1, 0, -1) * scale_factor * 0.3,
		Vector3(-1, 0, 1) * scale_factor * 0.3,
		Vector3(-1, 0, -1) * scale_factor * 0.3
	]
	
	for pos in corner_positions:
		var corner_pillar = PILLAR_SCENE.instantiate()
		corner_pillar.scale = Vector3.ONE * scale_factor * 0.15
		corner_pillar.position = pos
		_apply_pillar_material(corner_pillar, tier_index)
		parent.add_child(corner_pillar)

func _create_finial(y_position: float) -> void:
	"""Create the ornamental top spire"""
	var finial_container = Node3D.new()
	finial_container.name = "Finial"
	finial_container.position = Vector3(0, y_position, 0)
	_sim_root.add_child(finial_container)
	
	# Stack progressively smaller pillars for the finial
	var finial_height = 0.0
	for i in range(5):
		var finial_part = PILLAR_SCENE.instantiate()
		var finial_scale = base_scale * 0.15 / pow(_golden_ratio, i * 0.7)
		finial_part.scale = Vector3(finial_scale, finial_scale * 1.5, finial_scale)
		finial_part.position = Vector3(0, finial_height, 0)
		
		_apply_finial_material(finial_part, i)
		finial_container.add_child(finial_part)
		finial_height += finial_scale * 0.8

func _apply_tier_material(node: Node3D, tier_index: int) -> void:
	"""Apply material to the main tier body"""
	var mesh_instances = _find_mesh_instances(node)
	
	for mesh_instance in mesh_instances:
		var material = StandardMaterial3D.new()
		
		# Color gradient from dark wood at base to lighter wood at top
		var t = float(tier_index) / float(num_tiers)
		var base_color = Color(0.4, 0.25, 0.15)  # Dark wood
		var top_color = Color(0.6, 0.45, 0.3)    # Light wood
		material.albedo_color = base_color.lerp(top_color, t)
		
		material.metallic = 0.1
		material.roughness = 0.8
		
		mesh_instance.material_override = material

func _apply_roof_material(node: Node3D, tier_index: int) -> void:
	"""Apply material to roof elements"""
	var mesh_instances = _find_mesh_instances(node)
	
	for mesh_instance in mesh_instances:
		var material = StandardMaterial3D.new()
		
		# Traditional dark roof tiles with slight color variation
		var t = float(tier_index) / float(num_tiers)
		var base_color = Color(0.15, 0.12, 0.1)   # Dark charcoal
		var accent_color = Color(0.25, 0.15, 0.1) # Warm dark
		material.albedo_color = base_color.lerp(accent_color, t * 0.5)
		
		material.metallic = 0.05
		material.roughness = 0.9
		
		mesh_instance.material_override = material

func _apply_pillar_material(node: Node3D, tier_index: int) -> void:
	"""Apply material to structural pillars"""
	var mesh_instances = _find_mesh_instances(node)
	
	for mesh_instance in mesh_instances:
		var material = StandardMaterial3D.new()
		
		# Red lacquered wood (traditional pagoda color)
		var t = float(tier_index) / float(num_tiers)
		material.albedo_color = Color(0.6, 0.15, 0.1).lerp(Color(0.8, 0.2, 0.15), t)
		
		material.metallic = 0.3
		material.roughness = 0.4
		
		mesh_instance.material_override = material

func _apply_finial_material(node: Node3D, level: int) -> void:
	"""Apply material to the finial spire"""
	var mesh_instances = _find_mesh_instances(node)
	
	for mesh_instance in mesh_instances:
		var material = StandardMaterial3D.new()
		
		# Golden/bronze finial
		var t = float(level) / 5.0
		material.albedo_color = Color(0.8, 0.6, 0.2).lerp(Color(1.0, 0.85, 0.4), t)
		
		material.metallic = 0.7
		material.roughness = 0.3
		material.emission_enabled = true
		material.emission = material.albedo_color * 0.2
		
		mesh_instance.material_override = material

func _find_mesh_instances(node: Node) -> Array:
	"""Recursively find all MeshInstance3D nodes"""
	var result = []
	if node is MeshInstance3D:
		result.append(node)
	for child in node.get_children():
		result.append_array(_find_mesh_instances(child))
	return result

func get_tier_count() -> int:
	return _tiers.size()

func get_fibonacci_at(index: int) -> int:
	if index < _fibonacci_sequence.size():
		return _fibonacci_sequence[index]
	return -1

func rebuild_pagoda() -> void:
	"""Clear and rebuild the pagoda"""
	for tier in _tiers:
		tier.queue_free()
	_tiers.clear()
	
	# Clear finial
	var finial = _sim_root.get_node_or_null("Finial")
	if finial:
		finial.queue_free()
	
	_build_pagoda()

func _exit_tree() -> void:
	for child in get_children():
		if not child.owner:
			child.queue_free()


func apply_grid_config(config: Dictionary) -> void:
	for k in config.keys():
		set_meta("config_%s" % str(k), config[k])
	var was: String = profile
	_read_dna()
	if profile != was and _sim_root != null:
		rebuild_pagoda()


# ═══════════════════════════════════════════════════════════════════════════
# profile — everything below is new and nothing above it moved.
# ═══════════════════════════════════════════════════════════════════════════

## Map tokens arrive as config_<key> metadata. An unreadable word keeps the
## golden taper rather than rendering as a law nobody asked for.
func _read_dna() -> void:
	if has_meta("config_profile"):
		var p: String = str(get_meta("config_profile")).strip_edges().to_lower()
		if PROFILES.has(p):
			profile = p
	if has_meta("config_capture_anchor"):
		var a: String = str(get_meta("config_capture_anchor")).strip_edges().to_lower()
		capture_anchor = a == "true" or a == "1" or a == "yes"


## The drawn scale for one tier. "cake" hands back _get_tier_scale(tier_index)
## itself — the same float, from the same untouched function — so the shipped
## pagoda is reproduced exactly. Every other law is normalised against
## _shipped_total() so the stack keeps its height and its quantity of building.
func _profile_scale(tier_index: int) -> float:
	var key: String = str(profile).strip_edges().to_lower()
	if not PROFILES.has(key) or key == "cake":
		return _get_tier_scale(tier_index)

	if key == "flare":
		# The shipped numbers in reverse. Same set, same sum, upside down.
		return _get_tier_scale(num_tiers - 1 - tier_index)

	var raw: float = _profile_raw(key, tier_index)
	var raw_sum: float = 0.0
	for i in range(num_tiers):
		raw_sum += _profile_raw(key, i)
	if raw_sum <= 0.0:
		return _get_tier_scale(tier_index)
	return raw * _shipped_total() / raw_sum


## The unnormalised shape of each law, in the range roughly 0..1.
func _profile_raw(key: String, tier_index: int) -> float:
	var t: float = float(tier_index) / float(maxi(num_tiers - 1, 1))
	match key:
		"ziggurat":
			return lerpf(1.0, ZIGGURAT_NARROW, t)
		"column":
			return 1.0
		"spindle":
			# 1.0 at both ends, SPINDLE_WAIST at the middle.
			return SPINDLE_WAIST + (1.0 - SPINDLE_WAIST) * absf(2.0 * t - 1.0)
	return 1.0


## Sum of the tier scales the shipped law produces. Cached: _get_tier_scale reads
## _fibonacci_sequence when use_golden_ratio is off, so this cannot be computed
## before _generate_fibonacci_sequence has run in _ready.
func _shipped_total() -> float:
	if _shipped_sum >= 0.0:
		return _shipped_sum
	var total: float = 0.0
	for i in range(num_tiers):
		total += _get_tier_scale(i)
	_shipped_sum = total
	return _shipped_sum


## An invisible box over the shipped envelope. Sized from _get_tier_scale and
## the tier-height formula in _create_tier — never from the built scene, because
## a box measured from the scene would be a different box for each profile and
## the five shots would be framed differently, which is the failure it exists to
## prevent. The widest thing on a tier is its corner eave: offset 0.6 * scale
## from the axis plus roughly half of its own 0.3 * scale body.
func _add_capture_anchor() -> void:
	if has_node("CaptureAnchor"):
		return
	var widest: float = 0.0
	var stack_height: float = 0.0
	for i in range(num_tiers):
		var s: float = _get_tier_scale(i)
		widest = maxf(widest, s * 0.85)
		stack_height += tier_height * s / base_scale + 0.3
	# The finial adds five stacked parts on top of the stack.
	var finial_height: float = 0.0
	for i in range(5):
		finial_height += base_scale * 0.15 / pow(_golden_ratio, i * 0.7) * 0.8
	var total_height: float = stack_height + finial_height + base_scale * 0.15

	var anchor := MeshInstance3D.new()
	anchor.name = "CaptureAnchor"
	var bm := BoxMesh.new()
	bm.size = Vector3(widest * 2.0, total_height, widest * 2.0)
	anchor.mesh = bm
	anchor.position = Vector3(0.0, total_height * 0.5, 0.0)
	anchor.layers = 0
	add_child(anchor)
