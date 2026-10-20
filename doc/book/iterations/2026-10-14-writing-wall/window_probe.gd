extends "res://tools/probes/transformation_encounters.gd"

func landing_checks() -> void:
	var window := find_scene("/seed_replay_demo.gd")
	var ride := find_scene("/random_return.gd")
	check("colour window and carrying sphere installed",window!=null and ride!=null)
	if window==null or ride==null: return
	check("mapping comparison opted in",window.mapping_study)
	var seed_value: int = window.current_seed()
	var prefix: PackedFloat32Array = window.raw_prefix(1,48)
	var baseline: PackedColorArray = window.column_colors(0)
	check("two equal baseline windows",_same(baseline,window.column_colors(1)))
	var ride_seed: int = ride.route_seed
	var ride_state: int = ride.rng.state
	var ride_trip: int = ride.trip
	var receipt: Dictionary = window._source_receipt.duplicate(true)
	var map_button: Node = window.find_child("Btn_4",true,false).get_node("InteractableAreaButton")
	var range_button: Node = window.find_child("Btn_5",true,false).get_node("InteractableAreaButton")
	var reset_button: Node = window.find_child("Btn_6",true,false).get_node("InteractableAreaButton")
	map_button.button_pressed.emit(map_button)
	check("real map control chooses red only",window.mapping_mode==1)
	var red: PackedColorArray = window.column_colors(1)
	var correct := red.size()==baseline.size()
	for i in range(red.size()): correct = correct and is_equal_approx(red[i].r,baseline[i].r) and is_equal_approx(red[i].g,0.5) and is_equal_approx(red[i].b,0.5)
	check("red is sampled; green and blue stay fixed",correct)
	check("assignment preserves baseline and all 48 raw draws",_same(baseline,window.column_colors(0)) and prefix==window.raw_prefix(1,48) and window.draws_per_grid()==48)
	range_button.button_pressed.emit(range_button)
	check("real range control selects narrow bounds",window.mapping_narrow)
	var narrowed: PackedColorArray = window.column_colors(1)
	correct=true
	for i in range(narrowed.size()): correct = correct and is_equal_approx(narrowed[i].r,0.2+0.6*baseline[i].r) and is_equal_approx(narrowed[i].g,0.5) and is_equal_approx(narrowed[i].b,0.5)
	check("narrowing uses the same values with explicit bounds",correct)
	check("mapping changes do not reset or advance the ride",ride.route_seed==ride_seed and ride.rng.state==ride_state and ride.trip==ride_trip)
	check("mapping changes retain source and seed",window.current_seed()==seed_value and window._source_receipt==receipt)
	map_button.button_pressed.emit(map_button)
	check("second press swaps R and B",window.mapping_mode==2)
	var swapped: PackedColorArray = window.column_colors(1)
	correct=true
	for i in range(swapped.size()): correct = correct and is_equal_approx(swapped[i].r,0.2+0.6*baseline[i].b) and is_equal_approx(swapped[i].g,0.2+0.6*baseline[i].g) and is_equal_approx(swapped[i].b,0.2+0.6*baseline[i].r)
	check("swap mapping matches independent arithmetic",correct)
	var saved: Dictionary = window.capture_museum_state()
	reset_button.button_pressed.emit(reset_button)
	check("reset map recovers matching windows",window.mapping_mode==0 and not window.mapping_narrow and _same(baseline,window.column_colors(1)))
	window.restore_museum_state(JSON.parse_string(JSON.stringify(saved,"",true,true)))
	check("visit restore retains mapping and exact colours",window.mapping_mode==2 and window.mapping_narrow and _same(swapped,window.column_colors(1)))
	window.replay()
	check("replay retains chosen mapping",_same(swapped,window.column_colors(1)))
	window.toggle_extra_draw()
	check("draw offset remains a separate intervention",window.extra_on() and not _same(swapped,window.column_colors(1)))
	window.reset_mapping()
	check("reset map does not hide an active draw offset",window.extra_on() and not _same(baseline,window.column_colors(1)))
	window.toggle_extra_draw()
	check("reset and remove offset recover baseline",_same(baseline,window.column_colors(1)))
	window.cycle_mapping();window.toggle_mapping_range()
	observations["mapping"]={"seed":seed_value,"draws":48,"mode":window.mapping_description(),"baseline_first":str(baseline[0]),"changed_first":str(window.column_colors(1)[0])}
	await snapshot("window-range",window.to_global(Vector3(0,2.2,4.5)),window.to_global(Vector3(0,2.0,0)),58)
	window.reset_mapping()

func _same(a: PackedColorArray,b: PackedColorArray) -> bool:
	if a.size()!=b.size(): return false
	for i in range(a.size()):
		if not a[i].is_equal_approx(b[i]): return false
	return true
