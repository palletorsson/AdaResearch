extends RefCounted
## Spatial contract between a primitive encounter and a later cover plan.
## Coordinates are local metres on the same ground. This is a chosen clearance
## rule, not plant biology, shade, a growth simulation or a physics contact test.

static func blocked_by(point: Vector2, radius: float, forms: Array, clearance: float, height: Vector2 = Vector2(-INF, INF)) -> String:
	for form in forms:
		# Optional world-local vertical interval. Original footprint studies omit
		# it; lifted banners let shorter cover stand underneath. Same .35 m margin.
		if form.has("vertical"):
			if height.y + clearance < float(form.vertical[0]) - 0.00001 or height.x - clearance > float(form.vertical[1]) + 0.00001:
				continue
		var centre := Vector2(float(form.center[0]), float(form.center[2]))
		var d := point - centre
		var yaw := float(form.get("yaw", 0.0))
		# Inverse of Godot's Y rotation, projected onto x/z.
		var local := Vector2(cos(yaw)*d.x - sin(yaw)*d.y, sin(yaw)*d.x + cos(yaw)*d.y)
		var half := Vector2(float(form.size[0]), float(form.size[2])) * .5
		var outside := Vector2(maxf(absf(local.x)-half.x,0), maxf(absf(local.y)-half.y,0))
		if outside.length() <= radius + clearance:
			return str(form.id)
	return ""

static func footprint(transform: Transform3D, mesh: Mesh) -> Dictionary:
	# A conservative circle around the transformed mesh AABB: the complete card
	# footprint participates, not only its root. This is deliberately visible in
	# the record; later experiments can replace the envelope rule.
	var bounds := transform * mesh.get_aabb()
	var centre := bounds.get_center()
	return {"point": Vector2(centre.x,centre.z), "radius": Vector2(bounds.size.x,bounds.size.z).length()*.5,
		"height": Vector2(bounds.position.y, bounds.end.y)}
