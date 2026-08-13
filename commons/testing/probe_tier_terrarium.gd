extends SceneTree

## Does `tier` change what tier_terrarium builds?
##
## The sweep returned five BYTE-IDENTICAL frames per channel, which means either the
## axis does nothing in code or the value never reached the node. This asks the artifact
## directly, the way capture_config_sweep does it — set the export BEFORE add_child and
## let _ready build — and then measures the subtree instead of trusting the picture.
##
## Runs in a SubViewport with its own world and yields frames, because an artifact
## parented straight to the tree root in a --script run may fail to build at all (see
## probe_sorting_hall_work.gd for the shader case that cost an hour).
##
##   godot --path . --xr-mode off --no-window --script res://commons/testing/probe_tier_terrarium.gd

const SCENE := preload("res://commons/artifacts/tier_terrarium/tier_terrarium.tscn")


func _initialize() -> void:
	_run()


func _run() -> void:
	var vp := SubViewport.new()
	vp.own_world_3d = true
	vp.size = Vector2i(64, 64)
	root.add_child(vp)
	await process_frame

	print("\nPROBE  %-8s %-8s %8s %10s %10s" % ["channel", "tier", "meshes", "height", "widest"])
	for channel in ["body", "grain"]:
		for tier in ["1", "2", "3", "4", "5"]:
			var a: Node3D = SCENE.instantiate()
			# EXACTLY the sweep's contract: set the export, then add, then let _ready build.
			a.set("channel", channel)
			a.set("tier", tier)
			vp.add_child(a)
			await process_frame
			await process_frame

			var meshes: int = 0
			var box := AABB()
			var first := true
			var stack: Array[Node] = [a]
			while not stack.is_empty():
				var n: Node = stack.pop_front()
				if n is MeshInstance3D:
					meshes += 1
					var mi := n as MeshInstance3D
					var m: Mesh = mi.mesh
					if m != null:
						var b: AABB = mi.global_transform * m.get_aabb()
						box = b if first else box.merge(b)
						first = false
				for c in n.get_children():
					stack.append(c)

			# read back what the artifact thinks it is, not what we set
			var got: String = str(a.get("tier"))
			print("PROBE  %-8s %-8s %8d %10.4f %10.4f%s" % [
				channel, tier, meshes, box.size.y, box.size.x,
				"" if got == tier else "   !! artifact reports tier=" + got])

			vp.remove_child(a)
			a.queue_free()
			await process_frame
	quit(0)
