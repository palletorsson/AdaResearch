extends "res://commons/artifacts/science_screen/science_screen.gd"
## The editable mount adds one parent level. Keep the source's generic monitor
## vocabulary, scoped to this floor; do not invent solver data for other pieces.
func _scan_for_generic() -> void:
	var hall: Node = self
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	if hall == null: return
	var keywords := ["sort","noise","wave","force","fractal","swarm","graph","mesh","boid","flock","particle","field","oscillat","pendulum","spring"]
	for mount in hall.find_children("*","Node3D",true,false):
		if mount == self or not mount.has_meta("artifact_lookup_name"): continue
		var lookup := str(mount.get_meta("artifact_lookup_name"))
		if global_position.distance_to(mount.global_position) > scan_radius: continue
		for word in keywords:
			if not word in lookup.to_lower(): continue
			_tracking_generic = mount
			_generic_mode = true
			_generic_mode_name = word
			_label_name = word.to_upper()+" MONITOR"
			_source_artifact_name = lookup
			return
