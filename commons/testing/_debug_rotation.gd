extends SceneTree
const BigPipe = preload("res://algorithms/wavefunctions/big_pipe_system/big_pipe_system.gd")
func _initialize() -> void:
	var pipe = BigPipe.new()
	pipe.auto_build = false
	pipe.pipe_radius = 0.8
	pipe.segment_length = 2.0
	root.add_child(pipe)
	await process_frame
	print("DBG start: pos=%s forward=%s" % [pipe.cursor_pos, pipe.cursor_forward])
	pipe.generate_from_code("f")
	print("DBG after f: pos=%s forward=%s" % [pipe.cursor_pos, pipe.cursor_forward])
	pipe.generate_from_code("l")
	print("DBG after l: pos=%s forward=%s" % [pipe.cursor_pos, pipe.cursor_forward])
	pipe.generate_from_code("f")
	print("DBG after f2: pos=%s forward=%s" % [pipe.cursor_pos, pipe.cursor_forward])
	quit(0)
