# perfect_shot_framer.gd
# Shared scene measurement helper used by artifact presentation and capture tools.

class_name PerfectShotFramer
extends RefCounted


## Compute the combined local-space AABB of a Node3D and its visible 3D children.
static func get_combined_aabb(node: Node3D) -> AABB:
	var result := AABB()
	var first := true

	for child in node.get_children():
		var child_aabb := AABB()
		var has_aabb := false

		if child is MeshInstance3D:
			var mesh: Mesh = (child as MeshInstance3D).mesh
			if mesh:
				child_aabb = child.transform * mesh.get_aabb()
				has_aabb = true
		elif child is MultiMeshInstance3D:
			var multimesh: MultiMesh = (child as MultiMeshInstance3D).multimesh
			if multimesh and multimesh.instance_count > 0:
				child_aabb = child.transform * multimesh.get_aabb()
				has_aabb = true
		elif child is CSGShape3D:
			var child_meshes: Array = (child as CSGShape3D).get_meshes()
			if child_meshes.size() >= 2 and child_meshes[1] is Mesh:
				child_aabb = child.transform * (child_meshes[1] as Mesh).get_aabb()
				has_aabb = true
		elif child is GPUParticles3D:
			child_aabb = child.transform * (child as GPUParticles3D).visibility_aabb
			has_aabb = true

		if has_aabb and child_aabb.size.length() > 0.0:
			if first:
				result = child_aabb
				first = false
			else:
				result = result.merge(child_aabb)

		if child is Node3D:
			var sub_aabb: AABB = get_combined_aabb(child as Node3D)
			if sub_aabb.size.length() > 0.0:
				if first:
					result = sub_aabb
					first = false
				else:
					result = result.merge(sub_aabb)

	return result


# ═══════════════════════════════════════════════════════════════
# SIZE-AWARE FRAMING — measure an artifact, classify it, and produce orbit + angle
# presets so any artifact (a 5 cm bead or a 20 m structure) frames well. Consumed by
# ArtifactCatalogDesktop3D, ArtifactScenePresenter and the capture tools.
# ═══════════════════════════════════════════════════════════════

enum SizeClass { TINY, SMALL, MEDIUM, LARGE, HUGE, FLAT }

const SIZE_NAMES := ["TINY", "SMALL", "MEDIUM", "LARGE", "HUGE", "FLAT"]
# upper bounds on max dimension (m): < 0.5 TINY · < 1.5 SMALL · < 4 MEDIUM · < 10 LARGE · else HUGE
const SIZE_THRESHOLDS := [0.5, 1.5, 4.0, 10.0]

# Standard hero + 3 framing angles (yaw, pitch in radians) — number keys 1-4.
const ANGLES_STANDARD := [
	{"name": "hero",  "yaw": 0.6,    "pitch": -0.35},
	{"name": "front", "yaw": 0.0,    "pitch": -0.22},
	{"name": "side",  "yaw": 1.5708, "pitch": -0.30},
	{"name": "top",   "yaw": 0.6,    "pitch": -1.05},
]

# Wide establishing orbits for LARGE / HUGE artifacts — flagged environment=true.
const ANGLES_ENVIRONMENT := [
	{"name": "establishing", "yaw": 0.6, "pitch_factor": 0.45, "environment": true},
	{"name": "low_sweep",    "yaw": 2.2, "pitch_factor": 0.20, "environment": true},
	{"name": "high_survey",  "yaw": 0.6, "pitch_factor": 0.75, "environment": true},
]


static func classify(max_dim: float) -> int:
	if max_dim < SIZE_THRESHOLDS[0]: return SizeClass.TINY
	if max_dim < SIZE_THRESHOLDS[1]: return SizeClass.SMALL
	if max_dim < SIZE_THRESHOLDS[2]: return SizeClass.MEDIUM
	if max_dim < SIZE_THRESHOLDS[3]: return SizeClass.LARGE
	return SizeClass.HUGE


## Measure + classify a Node3D. Returns aabb, size_class/name, max_dimension, the
## orbit_distance + orbit_focus to frame it, and the angle presets for its size.
static func analyze(node: Node3D) -> Dictionary:
	var aabb := get_combined_aabb(node)
	var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	var size_class := classify(max_dim)
	# Flat artifacts (floors, panels, plates) — thin in one axis — get their own class.
	var min_dim: float = minf(aabb.size.x, minf(aabb.size.y, aabb.size.z))
	if max_dim > 0.4 and min_dim / maxf(max_dim, 0.001) < 0.18:
		size_class = SizeClass.FLAT
	# Catalog repositions so X/Z centre at origin, bottom at y=0 → focus at mid-height.
	var orbit_focus := Vector3(0.0, aabb.size.y * 0.5, 0.0)
	var orbit_distance: float = maxf(max_dim * 1.8 + 0.5, 1.2)
	# Only genuinely big (not flat) artifacts get the wide environment orbits.
	var big: bool = size_class == SizeClass.LARGE or size_class == SizeClass.HUGE
	var angles: Array = (ANGLES_ENVIRONMENT + ANGLES_STANDARD) if big else ANGLES_STANDARD.duplicate(true)
	return {
		"aabb": aabb,
		"size_class": size_class,
		"size_name": SIZE_NAMES[size_class],
		"max_dimension": max_dim,
		"orbit_distance": orbit_distance,
		"orbit_focus": orbit_focus,
		"angles": angles,
	}


## Ground plane size (Vector2) — scales with footprint + a size-class margin.
static func get_ground_size(aabb: AABB, size_class: int) -> Vector2:
	var foot: float = maxf(aabb.size.x, aabb.size.z)
	var pad: float = lerpf(2.0, 8.0, clampf(float(size_class) / float(SizeClass.HUGE), 0.0, 1.0))
	var s: float = maxf(foot * 3.0, foot + pad)
	return Vector2(s, s)


static func is_environment_angle(angle: Dictionary) -> bool:
	return bool(angle.get("environment", false))


static func get_environment_orbit_radius(aabb: AABB) -> float:
	var max_dim: float = maxf(aabb.size.x, maxf(aabb.size.y, aabb.size.z))
	return maxf(max_dim * 1.4, 4.0)


static func get_environment_orbit_height(aabb: AABB) -> float:
	return maxf(aabb.size.y * 0.9, 2.0)


## Camera position for a wide environment shot: orbit `focus` at `yaw`, lifted by
## `pitch_factor` of `height`, at `radius` out.
static func compute_environment_orbit_position(focus: Vector3, yaw: float, pitch_factor: float, radius: float, height: float) -> Vector3:
	return focus + Vector3(sin(yaw) * radius, height * (0.4 + pitch_factor), cos(yaw) * radius)


## Standard spherical orbit position: `distance` from `focus` at `yaw` around Y,
## `pitch` tilting up/down (negative pitch lifts the camera above the focus).
static func compute_orbit_position(focus: Vector3, yaw: float, pitch: float, distance: float) -> Vector3:
	var horiz: float = distance * cos(pitch)
	return focus + Vector3(sin(yaw) * horiz, -sin(pitch) * distance, cos(yaw) * horiz)
