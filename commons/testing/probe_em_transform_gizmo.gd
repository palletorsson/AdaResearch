extends SceneTree
## Focused proof for the shared perspective/isometric editing hand:
## projected artifact bodies can be selected without colliders, every visible
## axis is hittable, and pixels can be converted back into world metres.
##   godot --headless --path . --script res://commons/testing/probe_em_transform_gizmo.gd

const MuseumScript := preload("res://commons/scenes/endless_museum.gd")
const GizmoScript := preload("res://commons/scenes/em/em_transform_gizmo.gd")

var _failures: PackedStringArray = []


func _initialize() -> void:
	call_deferred("_run")


func _expect(condition: bool, message: String) -> void:
	if not condition:
		_failures.append(message)


func _run() -> void:
	var stage := Node3D.new()
	get_root().add_child(stage)
	var camera := Camera3D.new()
	camera.position = Vector3(5.0, 4.0, 7.0)
	camera.look_at_from_position(camera.position, Vector3.ZERO)
	camera.current = true
	stage.add_child(camera)

	var artifact := MeshInstance3D.new()
	var artifact_mesh := BoxMesh.new()
	artifact_mesh.size = Vector3(2.4, 1.7, 1.2)
	artifact.mesh = artifact_mesh
	stage.add_child(artifact)

	var gizmo: Node3D = GizmoScript.new()
	stage.add_child(gizmo)
	await process_frame
	gizmo.call("place", Vector3.ZERO, camera, true)
	await process_frame
	_expect(gizmo.visible and gizmo.get_child_count() == 7,
		"gizmo draws three bars, three arrowheads, and the turn ring")

	var axes := {
		"x": Vector3.RIGHT,
		"y": Vector3.UP,
		"z": Vector3.BACK,
	}
	for axis in axes:
		var world_hit := gizmo.global_position + (axes[axis] as Vector3) * gizmo.scale.x * 0.72
		var mouse := camera.unproject_position(world_hit)
		_expect(String(gizmo.call("hit_axis", camera, mouse)) == axis,
			"%s axis is a distinct screen hit target" % axis)
		var one_metre: Vector2 = gizmo.call("screen_axis", camera, axis)
		_expect(one_metre.length() > 1.0, "%s axis has a usable pixels-per-metre vector" % axis)

	# No collider: the actual projected mesh extent is still the selection area.
	var museum: Node = MuseumScript.new()
	museum.set("_cam", camera)
	museum.set("_edit_records", [{"token": "probe_body", "node": artifact, "kind": ""}])
	var artifact_mouse := camera.unproject_position(artifact.global_position)
	_expect(int(museum.call("_edit_pick_screen", artifact_mouse)) == 0,
		"projected mesh footprint selects a collider-free artifact")

	# Orthographic is the isometric museum camera; the hand remains readable
	# and selectable there too.
	camera.projection = Camera3D.PROJECTION_ORTHOGONAL
	camera.size = 18.0
	gizmo.call("place", Vector3.ZERO, camera, true)
	_expect(gizmo.scale.x > 1.0, "orthographic gizmo scales with the view")
	var x_mouse := camera.unproject_position(Vector3.RIGHT * gizmo.scale.x * 0.72)
	_expect(String(gizmo.call("hit_axis", camera, x_mouse)) == "x",
		"isometric X handle remains clickable")

	museum.free()
	stage.queue_free()
	if _failures.is_empty():
		print("[probe-transform-gizmo] PASS — projected selection and shared 3D/iso axes")
		quit(0)
	else:
		for failure in _failures:
			push_error("[probe-transform-gizmo] " + failure)
		quit(1)
