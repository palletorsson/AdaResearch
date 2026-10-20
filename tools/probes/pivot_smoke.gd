extends SceneTree
func _initialize() -> void:run.call_deferred()
func run() -> void:
	var work=load("res://algorithms/randomness/proceduralrandomness/geometrybased/omoss/omoss.tscn").instantiate()
	root.add_child(work)
	await process_frame
	print("CREATURE ",work.creature.skeleton.get_bone_count()," / ",work.creature.vertices.size())
	work.queue_free()
	await process_frame
	quit()
