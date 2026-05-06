# SubstrateTrajectory.gd — A named path through substrate space
#
# A trajectory is an ordered sequence of waypoints (artifact → vector pairs)
# that captures how substrate dimensions change along a conceptual path.
#
# Example: "cube_freedom" trajectory
#   static_reference_cube → rotating_cube_demo → oscillation_controlled_cube → jelly_cube
#   Shows rigidity dissolving: physics goes none → none → none → soft_body
#
# Usage:
#   var traj := SubstrateTrajectory.new()
#   traj.name = "specimen_in_jar"
#   traj.add_waypoint("dna_specimen", dna_vector)
#   traj.add_waypoint("boids_aquarium", boids_vector)
#   var midpoint := traj.interpolate(0.5)

extends RefCounted
class_name SubstrateTrajectory

var name: String = ""
var description: String = ""

## Array of {artifact_name: String, vector: SubstrateVector}
var waypoints: Array[Dictionary] = []


# ── Construction ─────────────────────────────────────────────

func add_waypoint(artifact_name: String, vector: SubstrateVector) -> void:
	waypoints.append({
		"artifact_name": artifact_name,
		"vector": vector,
	})


func get_waypoint_count() -> int:
	return waypoints.size()


func get_waypoint_names() -> Array[String]:
	var result: Array[String] = []
	for wp in waypoints:
		result.append(wp["artifact_name"])
	return result


func get_waypoint_vector(index: int) -> SubstrateVector:
	if index < 0 or index >= waypoints.size():
		return SubstrateVector.zero()
	return waypoints[index]["vector"]


# ── Dimension Arc ────────────────────────────────────────────

## How a single dimension changes along the trajectory.
## Returns Array of {artifact_name, dominant_value, weights}
func get_dimension_arc(dimension: String) -> Array[Dictionary]:
	var result: Array[Dictionary] = []
	for wp in waypoints:
		var vec: SubstrateVector = wp["vector"]
		var dim_weights: Dictionary = vec.get_dimension(dimension)
		result.append({
			"artifact_name": wp["artifact_name"],
			"dominant_value": vec.get_dominant(dimension),
			"dominant_weight": vec.get_dominant_weight(dimension),
			"weights": dim_weights.duplicate(),
		})
	return result


# ── Interpolation ────────────────────────────────────────────

## Interpolate along the trajectory at position t (0.0 = first, 1.0 = last).
## Blends between adjacent waypoints.
func interpolate(t: float) -> SubstrateVector:
	if waypoints.is_empty():
		return SubstrateVector.zero()
	if waypoints.size() == 1:
		return waypoints[0]["vector"]

	t = clampf(t, 0.0, 1.0)

	# Map t to segment space
	var segment_count := waypoints.size() - 1
	var segment_float := t * segment_count
	var segment_index := int(segment_float)
	var segment_t := segment_float - float(segment_index)

	# Clamp to last segment
	if segment_index >= segment_count:
		segment_index = segment_count - 1
		segment_t = 1.0

	var vec_a: SubstrateVector = waypoints[segment_index]["vector"]
	var vec_b: SubstrateVector = waypoints[segment_index + 1]["vector"]
	return vec_a.blend(vec_b, segment_t)


# ── Arc Description ──────────────────────────────────────────

## Human-readable description of what changes along this trajectory.
func describe_arc() -> String:
	if waypoints.size() < 2:
		return "Trajectory '%s': insufficient waypoints" % name

	var lines: Array[String] = []
	lines.append("Trajectory: %s" % name)
	if description != "":
		lines.append("  %s" % description)
	lines.append("  Path: %s" % " → ".join(get_waypoint_names()))
	lines.append("")

	# For each dimension, describe how it changes
	for dim_name in SubstrateVector.DIMENSIONS:
		var arc := get_dimension_arc(dim_name)
		var dominants: Array[String] = []
		var has_change := false
		var prev_dom := ""
		for entry in arc:
			var dom: String = entry["dominant_value"]
			if dom == "":
				dom = "∅"
			dominants.append(dom)
			if prev_dom != "" and dom != prev_dom:
				has_change = true
			prev_dom = dom

		if has_change:
			lines.append("  %s: %s" % [dim_name, " → ".join(dominants)])

	return "\n".join(lines)


# ── Similarity Between Trajectories ──────────────────────────

## Compute how similar two trajectories are by sampling both at regular
## intervals and comparing the substrate vectors at each sample point.
func trajectory_similarity(other: SubstrateTrajectory, samples: int = 10) -> float:
	if waypoints.size() < 2 or other.waypoints.size() < 2:
		return 0.0

	var total := 0.0
	for i in samples:
		var t := float(i) / float(samples - 1)
		var vec_a := interpolate(t)
		var vec_b := other.interpolate(t)
		total += vec_a.cosine_similarity(vec_b)
	return total / float(samples)


# ── Total Arc Length ─────────────────────────────────────────

## Sum of distances between consecutive waypoints.
func arc_length() -> float:
	if waypoints.size() < 2:
		return 0.0
	var total := 0.0
	for i in range(1, waypoints.size()):
		var a: SubstrateVector = waypoints[i - 1]["vector"]
		var b: SubstrateVector = waypoints[i]["vector"]
		total += a.distance(b)
	return total


# ── Serialization ────────────────────────────────────────────

func to_dict() -> Dictionary:
	var wps: Array[Dictionary] = []
	for wp in waypoints:
		wps.append({
			"artifact_name": wp["artifact_name"],
			"vector": wp["vector"].to_dict(),
		})
	return {
		"name": name,
		"description": description,
		"waypoints": wps,
	}


static func from_dict(d: Dictionary) -> SubstrateTrajectory:
	var traj := SubstrateTrajectory.new()
	traj.name = d.get("name", "")
	traj.description = d.get("description", "")
	var wps: Array = d.get("waypoints", [])
	for wp in wps:
		var vec := SubstrateVector.from_dict(wp.get("vector", {}))
		traj.add_waypoint(wp.get("artifact_name", ""), vec)
	return traj
