# capture_tone.gd
# Compare two print filters on one saved native abacus state. Never adds blur.
extends SceneTree
const Capture = preload("res://commons/book/installation_capture.gd")
const DIR := "res://doc/book/iterations/2026-10-16-tone-and-trace/captures/"
const BASE := "res://doc/book/iterations/2026-10-16-before-and-after/captures/"
var checks := 0
var failures: Array[String] = []
var images: Array = []
func _initialize() -> void: run.call_deferred()
func check(ok: bool, message: String) -> void:
	checks += 1
	if not ok: failures.append(message); push_error(message)
func vec(a: Array) -> Vector3: return Vector3(a[0],a[1],a[2])
func run() -> void:
	var archive: Dictionary = JSON.parse_string(FileAccess.get_file_as_string(BASE+"capture.json"))
	var source_record: Dictionary
	for item in archive.images:
		if item.id=="abacus-after": source_record=item
	var hall := Node3D.new(); hall.set_meta("em_map","Random_Definition");root.add_child(hall)
	var source: Node3D = load("res://commons/artifacts/random_touch/random_touch.tscn").instantiate()
	hall.add_child(source);source.set_process(false);source.set_physics_process(false)
	var pose: Array = source_record.source_transform
	source.global_transform=Transform3D(Basis(vec(pose[0]),vec(pose[1]),vec(pose[2])),vec(pose[3]))
	check(source.restore(source_record.state),"Recorded marks and targets restore")
	for frame in 3: await process_frame
	var state: Dictionary = source.capture()
	check(state.distribution=="uniform","Uniform target distribution is unchanged")
	for row in state.ink: check(row.size()==576,"576 saved marks remain")
	for treatment in [0,4]:
		var choice: Dictionary = source_record.choice.duplicate(true)
		choice.id="abacus-outline" if treatment==0 else "abacus-tone"
		choice.filter.treatment=treatment
		if treatment==4: choice.filter.merge({"tone_white":0.94,"tone_black":0.06})
		var camera := Capture.new();root.add_child(camera)
		camera.freeze(source,choice)
		camera.receipt.method="Restored native abacus marks; fixed camera and lighting. Compare contour to continuous luminance on the same geometry. No convolution, fitted bell curve or added marks."
		camera.receipt.source_record=BASE+"capture.json"
		var result: Dictionary = await camera.render(DIR)
		check(result.ok,"Render saved: "+str(choice.id))
		if result.ok: images.append(result.receipt)
		check(source.capture()==state,"Rendering changes no artifact state")
		camera.queue_free()
		for frame in 3: await process_frame
	var old_source := Image.load_from_file(BASE+"abacus-after-source.png")
	var new_source := Image.load_from_file(DIR+"abacus-tone-source.png")
	check(old_source.get_data()==new_source.get_data(),"Raw native capture remains pixel-identical")
	check(Image.load_from_file(BASE+"abacus-after.png").get_data()==Image.load_from_file(DIR+"abacus-outline.png").get_data(),"Existing contour treatment unchanged")
	check(Image.load_from_file(DIR+"abacus-outline-source.png").get_data()==new_source.get_data(),"Both treatments receive identical input pixels")
	FileAccess.open(DIR+"capture.json",FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failures":failures,"images":images,"scope":"Filter comparison of the same stored native state; not a human movement trial or Gaussian-source experiment."},"  ",true,true))
	print("TONE STUDY: ",checks," checks; failures=",failures)
	quit.call_deferred(0 if failures.is_empty() else 1)
