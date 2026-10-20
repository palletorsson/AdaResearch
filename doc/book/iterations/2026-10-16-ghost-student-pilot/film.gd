extends SceneTree
## Fixed-step capture of the actual rehearsal, without accelerating its gestures.
var preview: Node3D
func _initialize() -> void: run.call_deferred()
func run() -> void:
	root.size=Vector2i(1280,840)
	preview=load("res://commons/artifacts/prefab_disorder/preview.tscn").instantiate();root.add_child(preview)
	var ghost: Node3D=preview.bench.ghost;ghost.auto_enabled=false
	for node in preview.get_children():
		if node is CanvasLayer: node.visible=false
	var camera: Camera3D=preview.get_node("Camera")
	camera.position=Vector3(3.8,2.85,4.9);camera.look_at(Vector3(0,1.42,0.8));camera.fov=50
	for i in 30: await process_frame
	ghost.start()
	for i in 1900:
		await process_frame
		if not ghost.active: break
	for i in 45: await process_frame
	preview.queue_free()
	for i in 5: await process_frame
	quit()
