# PerfectShotFramer.gd — Size classification, angle selection, and AABB measurement
#
# The "brain" of the Perfect Shot system. Stateless and reusable.
# Consolidates the three existing _get_combined_aabb() copies into one
# canonical version that handles all mesh types.
#
# Given an AABB, classifies the scene into a size class and returns
# optimal camera angles — small objects get "tabletop" treatment,
# large scenes get bird's-eye perspectives.
#
# Usage:
#   var aabb: AABB = PerfectShotFramer.get_combined_aabb(scene_root)
#   var size_class: int = PerfectShotFramer.classify(aabb)
#   var angles: Array[Dictionary] = PerfectShotFramer.get_angles(size_class)
#   var distance: float = PerfectShotFramer.get_orbit_distance(aabb, size_class)

class_name PerfectShotFramer
extends RefCounted


# ─────────────────────────────────────────────────────────────
#  Size classes
# ─────────────────────────────────────────────────────────────

enum SizeClass {
	TINY,     ## < 0.3 units — jewelry, small procedural pieces
	SMALL,    ## < 1.0 — typical grid artifacts
	MEDIUM,   ## < 3.0 — standard artifacts, single critters
	LARGE,    ## < 10.0 — multi-artifact setups, small maps
	HUGE,     ## >= 10.0 — full maps, environments
	FLAT,     ## One axis < 10% of the others — 2D panels, boards
}

## Human-readable names for size classes.
const SIZE_NAMES: Array[String] = ["tiny", "small", "medium", "large", "huge", "flat"]

## Size thresholds (max AABB dimension).
const THRESHOLD_TINY: float = 0.3
const THRESHOLD_SMALL: float = 1.0
const THRESHOLD_MEDIUM: float = 3.0
const THRESHOLD_LARGE: float = 10.0

## Orbit distance multipliers per size class.
## Applied to max AABB dimension to get camera distance.
## Aggressive zoom — object fills the frame, minimal empty space.
const DISTANCE_MULTIPLIERS: Array[float] = [
	2.0,   # TINY — tight on small details
	1.6,   # SMALL
	1.4,   # MEDIUM
	1.2,   # LARGE
	1.0,   # HUGE
	1.5,   # FLAT
]

## Minimum orbit distance (prevents camera clipping into object).
const MIN_DISTANCE: float = 0.3

## Flatness threshold — only truly planar objects (floors, panels).
## Both non-dominant axes must be small relative to the dominant one.
const FLATNESS_RATIO: float = 0.05


# ─────────────────────────────────────────────────────────────
#  Angle presets per size class
# ─────────────────────────────────────────────────────────────

## TINY/SMALL: "Tabletop" — looking down at a specimen on a table.
## Higher pitch = more above, gentler angles for small details.
const ANGLES_TABLETOP: Array[Dictionary] = [
	{ "name": "hero",  "yaw": 0.3,  "pitch": 0.6  },  # Above-front, looking down ~35°
	{ "name": "side",  "yaw": 1.8,  "pitch": 0.5  },  # Side, above
	{ "name": "back",  "yaw": 3.4,  "pitch": 0.5  },  # Back, above
]

## MEDIUM: Standard 3/4 hero + sides.
const ANGLES_STANDARD: Array[Dictionary] = [
	{ "name": "hero",     "yaw": 0.4,    "pitch": 0.5    },  # 3/4 hero shot, looking down ~30°
	{ "name": "side_a",   "yaw": 1.97,   "pitch": 0.45   },  # 90° left, above
	{ "name": "side_b",   "yaw": -1.17,  "pitch": 0.45   },  # 90° right, above
	{ "name": "overview", "yaw": 0.001,  "pitch": 1.5607 },  # Top-down
]

## LARGE/HUGE: Bird's-eye + ground-level.
## Uses pitch_factor approach from MAP_ANGLES (0.0=horizontal, 1.0=top-down).
const ANGLES_ENVIRONMENT: Array[Dictionary] = [
	{ "name": "hero",     "yaw": 0.0,         "pitch_factor": 0.35 },  # 3/4 front-down
	{ "name": "overview", "yaw": 0.0,         "pitch_factor": 0.95 },  # Near top-down
	{ "name": "side_a",   "yaw": PI * 0.5,    "pitch_factor": 0.35 },  # Left side
	{ "name": "side_b",   "yaw": PI * -0.5,   "pitch_factor": 0.35 },  # Right side
]

## FLAT: Front-on + slight angle for panels and boards.
const ANGLES_FLAT: Array[Dictionary] = [
	{ "name": "hero",   "yaw": 0.0, "pitch": 0.0 },  # Dead-on front
	{ "name": "angled", "yaw": 0.3, "pitch": 0.2 },  # Slight perspective
]


# ═══════════════════════════════════════════════════════════════
# CLASSIFICATION
# ═══════════════════════════════════════════════════════════════

## Classify an AABB into a size class.
static func classify(aabb: AABB) -> int:
	if aabb.size.length() < 0.001:
		return SizeClass.TINY

	var sx: float = aabb.size.x
	var sy: float = aabb.size.y
	var sz: float = aabb.size.z
	var max_dim: float = maxf(sx, maxf(sy, sz))

	# Check for flatness — truly planar objects like floor tiles and panels.
	# Must have one axis nearly zero (< 2% of max) to qualify.
	if max_dim > 0.01:
		var min_dim: float = minf(sx, minf(sy, sz))
		if min_dim / max_dim < 0.02:
			return SizeClass.FLAT

	# Size-based classification
	if max_dim < THRESHOLD_TINY:
		return SizeClass.TINY
	elif max_dim < THRESHOLD_SMALL:
		return SizeClass.SMALL
	elif max_dim < THRESHOLD_MEDIUM:
		return SizeClass.MEDIUM
	elif max_dim < THRESHOLD_LARGE:
		return SizeClass.LARGE
	else:
		return SizeClass.HUGE


## Get the human-readable name for a size class.
static func get_size_name(size_class: int) -> String:
	if size_class >= 0 and size_class < SIZE_NAMES.size():
		return SIZE_NAMES[size_class]
	return "unknown"


# ═══════════════════════════════════════════════════════════════
# ANGLE SELECTION
# ═══════════════════════════════════════════════════════════════

## Get the angle presets for a size class.
## Returns Array of { name, yaw, pitch } or { name, yaw, pitch_factor }.
static func get_angles(size_class: int) -> Array[Dictionary]:
	match size_class:
		SizeClass.TINY, SizeClass.SMALL:
			return ANGLES_TABLETOP
		SizeClass.MEDIUM:
			return ANGLES_STANDARD
		SizeClass.LARGE, SizeClass.HUGE:
			return ANGLES_ENVIRONMENT
		SizeClass.FLAT:
			return ANGLES_FLAT
		_:
			return ANGLES_STANDARD


## Check if an angle uses pitch_factor (environment mode) vs direct pitch.
static func is_environment_angle(angle: Dictionary) -> bool:
	return "pitch_factor" in angle


# ═══════════════════════════════════════════════════════════════
# ORBIT CALCULATION
# ═══════════════════════════════════════════════════════════════

## Calculate the optimal orbit distance for a size class and AABB.
## Tall-and-thin objects get extra distance so the full height fits in frame.
static func get_orbit_distance(aabb: AABB, size_class: int) -> float:
	var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	if max_dim < 0.01:
		max_dim = 1.0

	var multiplier: float = DISTANCE_MULTIPLIERS[clampi(size_class, 0, DISTANCE_MULTIPLIERS.size() - 1)]
	var distance: float = max_dim * multiplier

	# Tall-and-thin boost: if height is much larger than width, pull back more
	var width: float = maxf(aabb.size.x, aabb.size.z)
	if width > 0.01 and aabb.size.y / width > 2.0:
		distance *= 1.3  # 30% extra distance for tall objects

	return maxf(distance, MIN_DISTANCE)


## Calculate the orbit focus point.
## After center_instance(), the instance sits with bottom at y=0.
## Tall objects (height >> width) get a higher focus to keep the top in frame.
static func get_orbit_focus(aabb: AABB, size_class: int) -> Vector3:
	var height: float = aabb.size.y
	var width: float = maxf(aabb.size.x, aabb.size.z)

	# Tall-and-thin (flowers, poles): focus at 65% height
	# Wide-and-short (fungi colonies): focus at 50%
	# Normal proportions: 55%
	var height_ratio: float = 0.55
	if width > 0.01:
		var aspect: float = height / width
		if aspect > 2.0:
			height_ratio = 0.65  # Very tall — focus near top
		elif aspect > 1.2:
			height_ratio = 0.6   # Moderately tall
		elif aspect < 0.5:
			height_ratio = 0.45  # Very wide/flat

	return Vector3(0.0, height * height_ratio, 0.0)


## Compute camera position from orbit parameters (spherical coordinates).
## This is the standard orbit formula used by ArtifactCatalogDesktop3D.
static func compute_orbit_position(
	focus: Vector3,
	yaw: float,
	pitch: float,
	distance: float
) -> Vector3:
	var offset := Vector3(
		sin(yaw) * cos(pitch),
		sin(pitch),
		cos(yaw) * cos(pitch)
	) * distance
	return focus + offset


## Compute camera position for environment angles (pitch_factor approach).
## pitch_factor: 0.0 = horizontal, 1.0 = directly overhead.
## Used for LARGE/HUGE maps where the orbit formula from MAP_ANGLES applies.
static func compute_environment_orbit_position(
	focus: Vector3,
	yaw: float,
	pitch_factor: float,
	orbit_radius: float,
	orbit_height: float
) -> Vector3:
	var elevation: float = orbit_height * pitch_factor
	var horizontal_dist: float = orbit_radius * (1.0 - pitch_factor * 0.5)
	return Vector3(
		focus.x + sin(yaw) * horizontal_dist,
		focus.y + elevation,
		focus.z + cos(yaw) * horizontal_dist
	)


## Get the orbit height for environment mode (based on AABB).
static func get_environment_orbit_height(aabb: AABB) -> float:
	var max_horizontal: float = maxf(aabb.size.x, aabb.size.z)
	return maxf(max_horizontal * 0.8, 3.0)


## Get the orbit radius for environment mode (based on AABB).
static func get_environment_orbit_radius(aabb: AABB) -> float:
	var max_horizontal: float = maxf(aabb.size.x, aabb.size.z)
	return maxf(max_horizontal * 0.7, 3.0)


# ═══════════════════════════════════════════════════════════════
# GROUND PLANE SIZING
# ═══════════════════════════════════════════════════════════════

## Get the ground plane size for a size class and AABB.
static func get_ground_size(aabb: AABB, size_class: int) -> Vector2:
	var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	match size_class:
		SizeClass.TINY, SizeClass.SMALL:
			return Vector2(maxf(max_dim * 6.0, 2.0), maxf(max_dim * 6.0, 2.0))
		SizeClass.MEDIUM:
			return Vector2(maxf(max_dim * 4.0, 4.0), maxf(max_dim * 4.0, 4.0))
		SizeClass.LARGE:
			return Vector2(maxf(max_dim * 2.0, 20.0), maxf(max_dim * 2.0, 20.0))
		SizeClass.HUGE:
			return Vector2(maxf(max_dim * 1.5, 80.0), maxf(max_dim * 1.5, 80.0))
		SizeClass.FLAT:
			return Vector2(maxf(max_dim * 3.0, 2.0), maxf(max_dim * 3.0, 2.0))
		_:
			return Vector2(20.0, 20.0)


# ═══════════════════════════════════════════════════════════════
# AABB MEASUREMENT — Canonical implementation
# ═══════════════════════════════════════════════════════════════

## Compute the combined AABB of a node and all its mesh children.
## Handles MeshInstance3D, MultiMeshInstance3D, CSGShape3D, GPUParticles3D.
## This is the single canonical version — consolidates three existing copies.
static func get_combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true

	for child in node.get_children():
		var child_aabb := AABB()
		var has_aabb := false

		if child is MeshInstance3D:
			var mesh = (child as MeshInstance3D).mesh
			if mesh:
				child_aabb = child.transform * mesh.get_aabb()
				has_aabb = true
		elif child is MultiMeshInstance3D:
			var mm = child.multimesh
			if mm and mm.instance_count > 0:
				child_aabb = child.transform * mm.get_aabb()
				has_aabb = true
		elif child is CSGShape3D:
			var child_meshes: Array = child.get_meshes()
			if child_meshes.size() >= 2:
				var m = child_meshes[1]
				if m is Mesh:
					child_aabb = child.transform * m.get_aabb()
					has_aabb = true
		elif child is GPUParticles3D:
			child_aabb = child.transform * child.visibility_aabb
			has_aabb = true

		if has_aabb and child_aabb.size.length() > 0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)

		# Recurse into children
		if child is Node3D:
			var sub_aabb: AABB = get_combined_aabb(child)
			if sub_aabb.size.length() > 0:
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)

	return result


## Convenience: measure + classify + return everything needed for framing.
static func analyze(node: Node3D) -> Dictionary:
	var aabb: AABB = get_combined_aabb(node)
	var size_class: int = classify(aabb)
	return {
		"aabb": aabb,
		"size_class": size_class,
		"size_name": get_size_name(size_class),
		"max_dimension": maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z)),
		"orbit_distance": get_orbit_distance(aabb, size_class),
		"orbit_focus": get_orbit_focus(aabb, size_class),
		"angles": get_angles(size_class),
		"ground_size": get_ground_size(aabb, size_class),
	}
