extends "res://tools/probes/transformation_encounters.gd"

func panel_bounds(demo: Node3D) -> AABB:
	var cube = demo._columns[0].cubes[0]
	var bounds: AABB = cube.get_aabb()
	bounds.position += cube.position
	for cell in demo._columns[0].cubes:
		var part: AABB = cell.get_aabb()
		part.position += cell.position
		bounds = bounds.merge(part)
	return bounds

func landing_checks() -> void:
	museum.call("flush_stamps")
	await create_timer(0.5).timeout
	var demo := find_scene("/seed_replay_demo.gd")
	check("seed example installed", demo != null)
	if demo == null: return
	check("installed starting grids are four by four", demo.grid_cols == 4 and demo.grid_rows == 4)
	check("two actual panels each contain sixteen cubes", demo.column_count() == 2 and demo.column_colors(0).size() == 16 and demo.column_colors(1).size() == 16)
	check("opening label counts forty-eight draws", demo.draws_per_grid() == 48 and "48 draws" in demo._seed_label.text)
	demo.restore_museum_state({"seed":42,"extra_on":false,"side":4})
	var first: PackedColorArray = demo.column_colors(0)
	check("same requests produce identical grids", first == demo.column_colors(1))
	demo.replay()
	check("replay recovers every colour", first == demo.column_colors(0) and first == demo.column_colors(1))
	var bounds := panel_bounds(demo)
	check("fewer cells keep the original 1.225m wall panels", is_equal_approx(bounds.size.x, 1.225) and is_equal_approx(bounds.size.y, 1.225))
	await snapshot("seed-before", demo.to_global(Vector3(0,2,4.4)), demo.to_global(Vector3(0,1.9,0)), 53)
	demo.toggle_extra_draw()
	check("extra draw changes only the right grid", demo.column_colors(0) == first and demo.column_colors(1) != first)
	var rng := RandomNumberGenerator.new()
	rng.seed = 42
	rng.randf()
	var independently_shifted := PackedColorArray()
	for i in range(16):
		independently_shifted.append(Color(rng.randf(),rng.randf(),rng.randf()))
	check("all sixteen right colours match the shifted stream", demo.column_colors(1) == independently_shifted)
	check("right procedure consumes forty-nine draws", demo._rng.state == rng.state)
	await snapshot("seed-after", demo.to_global(Vector3(0,2,4.4)), demo.to_global(Vector3(0,1.9,0)), 53)
	var slider = demo.find_child("Param_1", true, false)
	check("MATRIX slider still available", slider != null)
	if slider == null: return
	var knob = slider.get("_slider")
	var identity: int = slider.get_instance_id()
	knob.move_slider(knob.slider_limit_max)
	await tick()
	check("physical slider still selects sixteen by sixteen", demo.grid_cols == 16 and demo.column_colors(0).size() == 256)
	var larger := panel_bounds(demo)
	# Cube depth changes with cell size; the panel's x/y footprint stays fixed.
	observations["panel_at_four"] = {"position":xyz(bounds.position), "size":xyz(bounds.size)}
	observations["panel_at_sixteen"] = {"position":xyz(larger.position), "size":xyz(larger.size)}
	check("resizing retains panel footprint and seed", is_equal_approx(bounds.position.x,larger.position.x) and is_equal_approx(bounds.position.y,larger.position.y) and is_equal_approx(bounds.size.x,larger.size.x) and is_equal_approx(bounds.size.y,larger.size.y) and demo.current_seed() == 42)
	check("resizing retains stream prefix and discard", demo.column_colors(0).slice(0,16) == first and demo.extra_on())
	knob.move_slider(knob.slider_limit_max*2.0/14.0)
	await tick()
	check("returning slider to four restores the two pictures", demo.grid_cols == 4 and demo.column_colors(0) == first and demo.column_colors(1) == independently_shifted)
	check("slider node survives rebuild", slider.get_instance_id() == identity)
	var state: Dictionary = demo.capture_museum_state()
	demo.set_grid_side(2)
	demo.restore_museum_state(state)
	check("saved visits retain chosen size and colours", demo.grid_cols == 4 and demo.column_colors(1) == independently_shifted)
	observations["scope"] = "Current museum installation and live MATRIX slider. Screenshots use default-size comparison. No physical headset test."
