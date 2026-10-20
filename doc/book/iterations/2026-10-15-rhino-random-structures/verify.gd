extends SceneTree
const DIR:="res://doc/book/iterations/2026-10-15-rhino-random-structures/"
const SOURCE:="res://commons/artifacts/random_structure_studies/"
var checks: Array=[]
var failures: Array=[]
var observations: Dictionary={}
var preview: Node3D
var study: Node3D
func _initialize() -> void: run.call_deferred()
func check(label: String,passed: bool) -> void:
	checks.append({"name":label,"passed":passed})
	if not passed: failures.append(label);print("FAIL ",label)
func press(key: String) -> void:
	var area: Node=study.buttons[key].get_node("InteractableAreaButton")
	area.button_pressed.emit(area)
func shot(kind: String) -> void:
	if DisplayServer.get_name()=="headless": return
	for frame in 3: await process_frame
	await RenderingServer.frame_post_draw
	root.get_texture().get_image().save_png(DIR+kind+".png")
func run() -> void:
	if DisplayServer.get_name()=="headless":
		push_error("This suite checks MultiMesh readback: run run.py with the real renderer, not --headless.")
		quit(2)
		return
	root.size=Vector2i(1600,1100)
	preview=load(SOURCE+"preview.tscn").instantiate();root.add_child(preview)
	study=preview.variant;study.pointer_prefix="user://structure-test-latest-"
	for frame in 4: await process_frame
	var registry: Dictionary=JSON.parse_string(FileAccess.get_file_as_string("res://commons/artifacts/registry/random_structures.json")).artifacts
	for kind in ["columns","spheres","lattice","tree"]:
		preview.select(kind);study.study_seed=435;study.model.reseed(435)
		study.variation=1;study.column_target=2;study.link_probability=0.4;study.redraw()
		var original: Dictionary=study.geometry.duplicate(true)
		var values: Array=study.model.values.duplicate()
		check(kind+": baseline retains the same draws",preview.baseline.model.values==values and preview.baseline.variation==0)
		check(kind+": zero and full range differ",preview.baseline.geometry!=original)
		preview.range_slider.value=0.5
		check(kind+": slider changes mapping without new draws",study.variation==0.5 and study.model.values==values and study.geometry!=original)
		preview.range_slider.value=1
		check(kind+": range return restores exact geometry",study.geometry==original)
		await shot(kind)
		press("KEEP");var path: String=study.last_saved_path
		check(kind+": KEEP writes file",FileAccess.file_exists(path))
		press("SEED +1");check(kind+": seed changes structure",study.geometry!=original and study.study_seed==436)
		press("REPLAY")
		check(kind+": saved record restores geometry and values exactly",study.geometry==original and study.model.values==values and study.study_seed==435)
		var record=JSON.parse_string(FileAccess.get_file_as_string(path))
		var registered: Dictionary=registry["random_structure_"+kind]
		var fresh=load(registered.scene).instantiate();root.add_child(fresh)
		check(kind+": registered standalone scene can restore record",fresh.restore(record) and fresh.geometry==original)
		fresh.queue_free()
		var bad: Dictionary=record.duplicate(true);bad.draws[0]=INF
		check(kind+": invalid retained value rejected without change",not study.restore(bad) and study.geometry==original)
		bad=record.duplicate(true);bad.draws.resize(2)
		check(kind+": wrong sample count rejected",not study.restore(bad))
		bad=record.duplicate(true);bad.seed="9223372036854775808"
		check(kind+": overflowing seed rejected",not study.restore(bad))
		var count := 0
		for i in study.geometry.rods.size():
			var rod: Dictionary=study.geometry.rods[i]
			var t: Transform3D=study.view.rods.multimesh.get_instance_transform(i)
			if (t*Vector3(0,-0.5,0)).is_equal_approx(rod.a) and (t*Vector3(0,0.5,0)).is_equal_approx(rod.b): count+=1
		check(kind+": every rendered rod joins its declared endpoints",count==study.geometry.rods.size())
		observations[kind]={"rods":original.rods.size(),"balls":original.balls.size(),"points":original.points.size(),"seed":435,"saved_file":path}
		if kind=="columns": columns()
		elif kind=="spheres": spheres()
		elif kind=="lattice": lattice()
		else: tree()
	preview.select("columns");study.column_target=2;study.variation=1;study.redraw()
	await process_frame
	var report:={"checks":checks,"failures":failures,"observations":observations,"passed":failures.is_empty(),"scope":"Godot native preview and real button callbacks; no headset, structural engineering, mesh-union or human-learning claim."}
	FileAccess.open(DIR+"verification.json",FileAccess.WRITE).store_string(JSON.stringify(report,"  "))
	print("RANDOM STRUCTURES ",checks.size()," checks, failures=",failures)
	quit(0 if failures.is_empty() else 1)
func columns() -> void:
	check("columns: exactly 100 across ten distinct rows",study.geometry.rods.size()==100 and study.geometry.rods[0].a.z!=study.geometry.rods[10].a.z)
	var valid:=true
	for rod in study.geometry.rods:
		valid=valid and rod.a.y==0 and rod.r>=0.012 and rod.r<=0.047 and rod.b.y>=0.06 and rod.b.y<=0.82
	check("columns: fixed bases, positive radii and bounded heights",valid)
	study.column_target=0;study.redraw();valid=true
	for rod in study.geometry.rods: valid=valid and is_equal_approx(rod.r,0.032)
	check("columns: height-only leaves every radius fixed",valid)
	study.column_target=1;study.redraw();valid=true
	for rod in study.geometry.rods: valid=valid and is_equal_approx(rod.b.y,0.32)
	check("columns: radius-only leaves every height fixed",valid)
func spheres() -> void:
	var valid: bool=study.geometry.balls.size()==100
	for i in study.geometry.balls.size():
		var ball: Dictionary=study.geometry.balls[i]
		var baseline: Dictionary=preview.baseline.geometry.balls[i]
		valid=valid and ball.p.x==baseline.p.x and ball.p.z==baseline.p.z and ball.r==0.07 and ball.p.y>=0.07 and ball.p.y<=0.67
	check("spheres: fixed horizontal grid and radius; only height changes",valid)
func lattice() -> void:
	var valid: bool=study.geometry.points.size()==196
	var seen: Dictionary={}
	for edge: Vector2i in study.geometry.edges:
		var a:=edge.x;var b:=edge.y
		valid=valid and b/49==a/49+1 and absi(a%7-b%7)<=1 and absi((a%49)/7-(b%49)/7)<=1 and not seen.has(edge)
		seen[edge]=true
	check("lattice: valid unique neighbours, no boundary wrapping",valid)
	var points: Array=study.geometry.points.duplicate()
	study.link_probability=0;study.redraw()
	check("lattice: zero probability keeps 147 direct posts",study.geometry.edges.size()==147 and study.geometry.points==points)
	study.link_probability=1;study.redraw()
	check("lattice: all 936 legal diagonal candidates plus 147 posts",study.geometry.edges.size()==1083 and study.geometry.points==points)
	study.link_probability=0.4;study.redraw()
func tree() -> void:
	check("tree: 41 nodes, 40 branches, 27 tips",study.geometry.points.size()==41 and study.geometry.edges.size()==40 and study.geometry.balls.size()==27)
	var valid:=true
	for edge: Vector2i in study.geometry.edges:
		valid=valid and edge.x<edge.y and study.geometry.points[edge.y].y>study.geometry.points[edge.x].y
	check("tree: parent before child and every branch rises",valid)
