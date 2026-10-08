extends Node3D
## Preserve the source fields while fitting their large source units to museum bays.
var study := "caves"
var ready_for_display := false

func apply_grid_config(config: Dictionary) -> void:
	study = str(config.get("study", study))

func _ready() -> void:
	study = str(get_meta("config_study", study))
	_bind.call_deferred()

func _bind() -> void:
	var hall: Node = get_parent()
	while hall != null and not hall.has_meta("em_map"): hall = hall.get_parent()
	if hall == null: return
	var em: Node = hall
	while em != null and not "_edit_records" in em: em = em.get_parent()
	if em == null: return
	var targets: Array = ["marchingcave", "marchingcubes_cave"] if study == "caves" else ["mc_base", "animated_noise_explorer"]
	var found: Dictionary = {}
	for attempt in 100:
		for rec: Dictionary in em.get("_edit_records"):
			var n = rec.get("node")
			if is_instance_valid(n) and hall.is_ancestor_of(n) and rec.token in targets: found[rec.token] = n
		if found.size() == targets.size(): break
		await get_tree().create_timer(0.1).timeout
	for token in found:
		var n: Node3D = found[token]
		# Token scales below 0.05 are clamped by the generic parser. These
		# three large-domain sources use the same explicit 0.02 display scale.
		if token != "animated_noise_explorer": n.scale = Vector3.ONE * 0.02
		for camera in n.find_children("*", "Camera3D", true, false): camera.current = false
		for old_label in n.find_children("*", "Label3D", true, false): old_label.hide()
		for ui in n.find_children("*", "CanvasLayer", true, false): ui.hide()
	ready_for_display = found.size() == targets.size()
	if not ready_for_display: push_error("Isosurface specimen stage is missing a source: " + study)
