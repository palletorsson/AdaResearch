extends SceneTree
const STUDY := "res://doc/book/studies/randomness-shelf/"
const PRINTED := "res://doc/book/iterations/2026-10-15-randomness-tutorial-shelf/printed/direct_randomness.gd"
var failures: Array[String] = []
var checks := 0
func check(ok: bool, why: String) -> void:
	checks += 1
	if not ok: failures.append(why); push_error(why)
func _initialize() -> void: call_deferred("run")
func build():
	var shelf = load(STUDY+"shelf.tscn").instantiate()
	shelf.set_script(load(PRINTED))
	root.add_child(shelf)
	return shelf
func run() -> void:
	var shelf = build()
	check(shelf.values.size()==8 and shelf.cursor==0,"Printed program starts with eight retained values and the first visible sample")
	var original: Array = shelf.values.duplicate()
	var other = build()
	check(shelf.values==other.values,"A fresh shelf repeats the seed-435 procedure")
	shelf.get_node("Controls/NEXT").pressed.emit()
	check(shelf.cursor==1 and shelf.values==original,"NEXT reads a retained value without another draw")
	shelf.get_node("Controls/REPLAY").pressed.emit()
	check(shelf.cursor==0 and shelf.values==original,"REPLAY returns to the first retained value")
	for i in 8: shelf.next_sample()
	check(shelf.cursor==0,"The finite eight-value sequence wraps deliberately")
	shelf.values.assign([0.0,0.25,0.5,0.75,1.0,0.2,0.4,0.6])
	for i in range(5):
		shelf.cursor=i
		shelf.show_sample()
		var u: float=shelf.values[i]
		check(is_equal_approx(shelf.get_node("Move/Point").position.x,-0.4+0.8*u),"Stored fraction maps to bounded X")
		check(shelf.get_node("Scale/Point").scale.is_equal_approx(Vector3.ONE*(0.5+u)),"The same fraction maps to uniform scale")
		check(is_equal_approx(shelf.get_node("Rotate/Cube").rotation.y,u*TAU),"The same fraction maps to a full-turn angle")
		check(shelf.colour.albedo_color.is_equal_approx(Color.from_hsv(u,0.8,0.9)),"The same fraction maps to hue with saturation and brightness held")
	var other_colour: Color=other.colour.albedo_color
	shelf.cursor=1; shelf.show_sample()
	check(other.colour.albedo_color==other_colour,"Each shelf owns its colour material")
	var scale_before: Vector3=shelf.get_node("Scale/Point").scale
	var angle_before: Vector3=shelf.get_node("Rotate/Cube").rotation
	var colour_before: Color=shelf.colour.albedo_color
	shelf.x_extent=0.2; shelf.show_sample()
	check(is_equal_approx(shelf.get_node("Move/Point").position.x,-0.1),"Reducing the range changes this sample's X")
	check(shelf.get_node("Scale/Point").scale==scale_before and shelf.get_node("Rotate/Cube").rotation==angle_before and shelf.colour.albedo_color==colour_before,"A range intervention leaves the three other assignments unchanged")
	shelf.values.assign(original); shelf.x_extent=0.4; shelf.replay(); shelf.next_sample()
	var notebook=shelf.get_node("Notebook")
	notebook.observation="Scripted comparison; no felt response inferred."
	notebook.next_change="Try half the X range with the same draws."
	var baseline: Dictionary=notebook.capture()
	shelf.get_node("Controls/KEEP").pressed.emit()
	var baseline_path: String=notebook.load_path
	check(FileAccess.file_exists(baseline_path),"Actual KEEP control writes a file")
	shelf.x_extent=0.2; shelf.show_sample()
	var changed_path: String=notebook.save_trial()
	check(changed_path!=baseline_path and FileAccess.file_exists(baseline_path),"Keeping a comparison preserves the baseline file")
	shelf.free()
	shelf=build(); notebook=shelf.get_node("Notebook")
	notebook.load_path=baseline_path
	shelf.get_node("Controls/LOAD").pressed.emit()
	check(notebook.capture()==baseline,"A fresh printed-code instance reopens exact values, cursor and range")
	check(notebook.observation=="Scripted comparison; no felt response inferred.","Observation travels with the saved record")
	check(is_equal_approx(shelf.get_node("Move/Point").position.x,lerpf(-0.4,0.4,baseline.values[baseline.cursor])),"Loaded state updates the visible assignment")
	shelf.replay(); shelf.next_sample()
	check(notebook.capture()==baseline,"Replay and one NEXT reconstruct the saved moment")
	var invalid=baseline.duplicate(true); invalid.values[0]=2.0
	check(not notebook.restore(invalid) and notebook.capture()==baseline,"An invalid value is rejected without changing the current experiment")
	invalid=baseline.duplicate(true); invalid.x_extent=-1.0
	check(not notebook.restore(invalid) and notebook.capture()==baseline,"An invalid range is rejected without changing current state")
	invalid=baseline.duplicate(true); invalid.mapping="other"
	check(not notebook.restore(invalid),"An incompatible mapping recipe is not silently loaded")
	shelf.free(); other.free()
	DirAccess.remove_absolute(baseline_path); DirAccess.remove_absolute(changed_path)
	var preview=load(STUDY+"preview.tscn").instantiate(); root.add_child(preview)
	preview.get_node("UI/Bar/Next").pressed.emit()
	check(preview.get_node("Shelf").cursor==1,"Desktop preview's NEXT is connected to the same lesson")
	preview.get_node("UI/Bar/Replay").pressed.emit()
	check(preview.get_node("Shelf").cursor==0,"Desktop preview's REPLAY is connected")
	preview.free()
	await process_frame
	print("RANDOMNESS TUTORIAL SHELF: ","PASS" if failures.is_empty() else "FAIL"," (",checks," checks)")
	quit(0 if failures.is_empty() else 1)
