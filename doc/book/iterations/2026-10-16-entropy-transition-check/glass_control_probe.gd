extends "res://doc/book/iterations/2026-10-16-entropy-transition-check/visual_probe.gd"
## One installed pane, same chair/camera/record; only its blur uniform changes in memory.
func types_views() -> void:
	var glass=comparison(5)
	check("installed colour-record pane available",glass!=null and glass.versions.size()==5)
	if glass==null:return
	var version=glass.versions[2]
	var initial=version.frost.get_shader_parameter("obscurity")
	var record: int=version.setting
	var identity: int=version.selected
	for value in [0.4,0.78]:
		version.frost.set_shader_parameter("obscurity",value)
		await snapshot("same-pane-"+str(value),version.to_global(Vector3(0,1.55,2.8)),version.to_global(Vector3(0,0.83,0.6)),48)
		check("same chair and record at blur "+str(value),version.setting==record and version.selected==identity)
	version.frost.set_shader_parameter("obscurity",initial)
	observations["controlled_change"]="In-memory obscurity 0.4 to 0.78 on installed pane C; fixed chair identity 3, record channel 1, geometry and camera. Hall backgrounds are not moved. Decorative time-based effects remain live. Production materials unchanged."
