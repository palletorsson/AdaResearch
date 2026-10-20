extends SceneTree
const DIR="res://doc/book/iterations/2026-10-16-book-image-study/"
const Motion=preload("res://commons/artifacts/random_touch/motion_record.gd")
var stage: Node3D
var camera: Camera3D
var receipts: Array=[]
func _initialize() -> void:run.call_deferred()
func photo(id: String, eye: Vector3, target: Vector3, height: float) -> void:
	camera.position=eye;camera.look_at(target);camera.size=height
	for frame in 4:await process_frame
	for layer in root.find_children("*","CanvasLayer",true,false):layer.visible=false
	await RenderingServer.frame_post_draw
	var err:=root.get_texture().get_image().save_png(DIR+id+"-source.png")
	assert(err==OK)
	receipts.append({"image":id,"eye":[eye.x,eye.y,eye.z],"target":[target.x,target.y,target.z],"orthographic_height":height})
func run() -> void:
	root.size=Vector2i(1600,1200)
	stage=Node3D.new();stage.set_meta("hall_seed_scope",true);root.add_child(stage)
	var env:=WorldEnvironment.new();env.environment=Environment.new();env.environment.background_mode=Environment.BG_COLOR;env.environment.background_color=Color("f3f0e7");env.environment.ambient_light_source=Environment.AMBIENT_SOURCE_COLOR;env.environment.ambient_light_color=Color.WHITE;env.environment.ambient_light_energy=0.7;stage.add_child(env)
	var sun:=DirectionalLight3D.new();stage.add_child(sun);sun.rotation_degrees=Vector3(-35,-40,0);sun.light_energy=0.6
	camera=Camera3D.new();camera.projection=Camera3D.PROJECTION_ORTHOGONAL;stage.add_child(camera);camera.current=true
	var abacus: Node3D=load("res://commons/artifacts/random_touch/random_touch.tscn").instantiate();abacus.set_meta("config_hall_seed","435");stage.add_child(abacus)
	for frame in 5:await process_frame
	abacus.set_physics_process(false);abacus.paused=true
	for lane in 5:
		var seconds: float=10.35/float(Motion.RATES[lane]);abacus.times[lane]=seconds;abacus.offsets[lane]=Motion.offset(abacus.record,lane,seconds);abacus.ink.record_span(abacus.record,lane,0,seconds)
	abacus._update_pose()
	FileAccess.open(DIR+"abacus-state.json",FileAccess.WRITE).store_string(JSON.stringify(abacus.capture(),"  "))
	await photo("abacus",Vector3(0.70,1.55,5),Vector3(0,1.10,0),2.55)
	for label in abacus.find_children("*","Label3D",true,false):label.hide()
	await photo("abacus-detail",Vector3(0.30,1.47,5),Vector3(0,1.41,0),1.10)
	abacus.hide()
	var book: Node3D=load("res://algorithms/randomness/randomnumbergeneration/scenes/random_number_book_page_1955.tscn").instantiate();book.set_meta("config_hall_seed","435");book.row_stream=true;book.cascade_speed=0.4;book.set_process(false);stage.add_child(book)
	for frame in 5:await process_frame
	book.set_process(false)
	book._apply_hall_seed(435,{}) # Discard any automatic tick before staging arrivals.
	# Complete a controlled set of row arrivals, hold one real populated cell, continue.
	for step in 10:book._cascade_step();book._advance_stream(10.0)
	book._on_cell_touched(null,4,4)
	for step in 5:book._cascade_step();book._advance_stream(10.0)
	var digits: Array=[]
	for row in book._cells:
		var values: Array=[]
		for cell in row:values.append(cell.text)
		digits.append(values)
	FileAccess.open(DIR+"page-state.json",FileAccess.WRITE).store_string(JSON.stringify({"seed":435,"page_number":book.page_number,"procedure":"First five fractional digits of each randf(); same stream as colour-window baseline; folio consumes no draw.","arrivals":15,"held_cell":[4,4],"digits":digits,"frozen":book._frozen},"  "))
	# Remove the screen-legibility halo for a print capture; digits/state stay intact.
	for label in book.find_children("*","Label3D",true,false):label.outline_size=0
	await photo("page",Vector3(1.2,0.3,-8),Vector3(0,0,0),6.8)
	await photo("page-detail",Vector3(0.3,1.1,-8),Vector3(0,1.0,0),2.35)
	book.hide()
	var geiger: Node3D=load("res://commons/artifacts/geiger_counter/geiger_counter.tscn").instantiate();geiger.set_meta("config_hall_seed","435");stage.add_child(geiger)
	for frame in 5:await process_frame
	geiger.set_process(false);geiger._audio.stop();geiger._progress=0;geiger._refresh_text()
	FileAccess.open(DIR+"geiger-state.json",FileAccess.WRITE).store_string(JSON.stringify(geiger.current,"  "))
	await photo("geiger",Vector3(1.5,2.1,7),Vector3(0,1.5,0),3.7)
	for label in geiger.find_children("*","Label3D",true,false):label.hide()
	await photo("geiger-detail",Vector3(0.35,2.25,7),Vector3(0,2.05,0),1.55)
	FileAccess.open(DIR+"capture-receipt.json",FileAccess.WRITE).store_string(JSON.stringify({"scope":"Current artifact scenes isolated from museum architecture. Authored orthographic views; deterministic staged states, no claimed visitor observation.","captures":receipts,"abacus":"All five rows have advanced 10.35 steps; equal step counts, not simultaneous touch. Each row retains 124 phase samples.","page":"15 row arrivals, with row 4 column 4 held after arrival 10.","geiger":"Initial 435 record; 96 simulated detections; playback paused."},"  "))
	print("BOOK IMAGE CAPTURE ",receipts.size()," views written")
	for frame in 6:await process_frame
	quit(0)
