extends SceneTree
var OUT:="res://doc/book/iterations/2026-09-19-tiling-review/relations/overlay-before/"
func _initialize() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):OUT=arg.trim_prefix("--out=")
	run.call_deferred()
func run() -> void:
	var parent:=Node3D.new();parent.position=Vector3(10,2,-7);root.add_child(parent)
	var gallery:Node3D=load("res://commons/artifacts/wall_pattern_gallery/wall_pattern_gallery.gd").new()
	gallery.position=Vector3(3,1,4);parent.add_child(gallery)
	var world:=Vector3(20,6,-5);var size:=2.0
	gallery.call("_add_overlay",world,size,ShaderMaterial.new(),Vector3i(5,2,-3))
	var offsets:=[Vector3(0,0,1.02),Vector3(0,0,-1.02),Vector3(-1.02,0,0),Vector3(1.02,0,0),Vector3(0,1.02,0)]
	var failures:Array[String]=[];var positions:Array=[]
	if gallery.get_child_count()!=5:failures.append("expected five overlays")
	for i in mini(5,gallery.get_child_count()):
		var node:Node3D=gallery.get_child(i);var wanted:Vector3=world+offsets[i]
		var pass_position:=node.global_position.is_equal_approx(wanted)
		positions.append({"face":i,"actual":[node.global_position.x,node.global_position.y,node.global_position.z],"expected":[wanted.x,wanted.y,wanted.z],"matches":pass_position})
		if not pass_position:failures.append("face %d world position"%i)
	var start_children:=gallery.get_child_count()
	gallery.call("_build_ceiling",world,[Vector3i(-1,1,0),Vector3i(1,1,0)],[0],{},size,size)
	if gallery.get_child_count()-start_children!=4:failures.append("expected three ceiling cubes and one floor cube")
	var expected_ceiling:=[world+Vector3(-2,4,0),world+Vector3(0,4,0),world+Vector3(2,4,0),world]
	for i in mini(4,gallery.get_child_count()-start_children):
		var node:Node3D=gallery.get_child(start_children+i);var wanted:Vector3=expected_ceiling[i]
		var pass_position:=node.global_position.is_equal_approx(wanted)
		positions.append({"ceiling_or_floor":i,"actual":[node.global_position.x,node.global_position.y,node.global_position.z],"expected":[wanted.x,wanted.y,wanted.z],"matches":pass_position})
		if not pass_position:failures.append("ceiling/floor %d world position"%i)
	var f:=FileAccess.open(OUT+"probe_overlay_positions.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":11,"failures":failures,"translated_parent":[13,3,-3],"positions":positions},"  "));f.close()
	print("OVERLAY_POSITIONS ",failures)
	quit(0 if failures.is_empty() else 1)
