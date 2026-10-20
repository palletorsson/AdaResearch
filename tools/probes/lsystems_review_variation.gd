extends SceneTree
const DIR := "res://doc/book/iterations/2026-10-09-lsystems-feedback/"
var checks: Array = []
var failures: Array = []
var cases := 0

func _initialize() -> void:
	run.call_deferred()

func check(title: String, ok: bool) -> void:
	checks.append({"name": title, "passed": ok})
	if not ok: failures.append(title)
	print("REVIEW ", "PASS " if ok else "FAIL ", title)

func same(a: Array, b: Array) -> bool:
	if a.size() != b.size(): return false
	for i in a.size():
		if not a[i].is_equal_approx(b[i]): return false
	return true

func reflected(a: Array, b: Array) -> bool:
	if a.size() != b.size(): return false
	for i in a.size():
		# Independent geometric oracle for origin zero, initial heading +Y, XY plane.
		if not Vector3(-a[i].x, a[i].y, a[i].z).is_equal_approx(b[i]): return false
	return true

func segment_lengths(a: Array, b: Array) -> bool:
	if a.size() != b.size(): return false
	for i in range(0,a.size(),2):
		if not is_equal_approx(a[i].distance_to(a[i+1]),b[i].distance_to(b[i+1])): return false
	return true

func chain(a: Array, b: Array) -> bool:
	if a.size() != b.size(): return false
	for i in range(2,a.size(),2):
		if a[i].is_equal_approx(a[i-1]) != b[i].is_equal_approx(b[i-1]): return false
	return true

func run() -> void:
	var original=load(DIR+"printed/grammar.gd").new()
	var reversed=load(DIR+"turns-reversed/grammar.gd").new()
	var rule := {"F":"F+F-F-F+F"}
	var sentence := "F"
	for generation in 5:
		var reflects := true
		var lengths := true
		var joins := true
		for angle in [30.0,60.0,90.0,120.0]:
			var a:Array=original.read(sentence,angle)
			var b:Array=reversed.read(sentence,angle)
			reflects=reflects and reflected(a,b)
			lengths=lengths and segment_lengths(a,b) and a.size()==2*int(pow(5,generation))
			joins=joins and chain(a,b)
			cases+=1
		check("Generation %d: four angles reflect every endpoint across local Y"%generation,reflects)
		check("Generation %d: ordered segment lengths and drawing counts retained"%generation,lengths)
		check("Generation %d: segment joins retained"%generation,joins)
		var first:Dictionary=original.rewrite(sentence,rule)
		var second:Dictionary=reversed.rewrite(sentence,rule)
		check("Generation %d: rewriting is unchanged"%generation,first==second)
		if generation<4: sentence=first.text
	var a:Array=original.read("F+F",90)
	var b:Array=reversed.read("F+F",90)
	check("Asymmetric witness: the second endpoint changes right to left",a[-1].is_equal_approx(Vector3(1,1,0)) and b[-1].is_equal_approx(Vector3(-1,1,0)))
	check("The straight seed alone cannot distinguish the readers",same(original.read("F",90),reversed.read("F",90)))
	check("Forward and non-drawing advances retain their jobs",reflected(original.read("F+f-G",60),reversed.read("F+f-G",60)))
	check("An unchanged reader fails the reflection oracle on the asymmetric witness",not reflected(a,a))
	check("A segment-count check alone would accept that wrong reader",segment_lengths(a,a))
	# Run both complete printed programs, not only the isolated model.
	var host := Node3D.new()
	host.position=Vector3(7,0,-4);host.rotation.y=.6;root.add_child(host)
	var live=load(DIR+"printed/sentence.gd").new()
	var altered=load(DIR+"turns-reversed/sentence.gd").new()
	host.add_child(live);host.add_child(altered)
	await process_frame
	live.advance();altered.advance();live.keep();altered.keep()
	var saved:Dictionary=altered.held.duplicate(true)
	check("Both complete hosts construct ten finite rods after one generation",live.drawing.get_child_count()==10 and altered.drawing.get_child_count()==10 and altered.drawing.get_children().all(func(n):return n.transform.is_finite()))
	check("Complete hosts share sentence, angle and command counts",live.sentence==altered.sentence and live.angle==altered.angle and live.model.read(live.sentence,live.angle).size()==altered.model.read(altered.sentence,altered.angle).size())
	var visual_mirror := true
	for i in live.drawing.get_child_count():
		var left:Node3D=live.drawing.get_child(i)
		var right:Node3D=altered.drawing.get_child(i)
		var origin_x := -.85 if i<5 else .85
		visual_mirror=visual_mirror and right.position.is_equal_approx(Vector3(2*origin_x-left.position.x,left.position.y,left.position.z)) and is_equal_approx(left.mesh.height,right.mesh.height)
	check("Actual fitted rod positions reflect around each display's own origin",visual_mirror)
	altered.choose(3);altered.advance()
	check("Edited host retains held sentence and angle after live changes",altered.held==saved and altered.angle==120 and altered.generation==2)
	check("Original host remains independent",live.angle==90 and live.generation==1 and live.sentence==saved.text)
	var receipt={"passed":failures.is_empty(),"checks":checks,"failures":failures,"model_cases":cases,
		"scope":"Authoring AI executed the proposed turn-reversal edit with exact printed base files and complete hosts. Planar unbranched reader, +Y initial heading, local origin. No physical headset, independent learner or new eight-hall runtime test."}
	FileAccess.open(DIR+"variation-checks.json",FileAccess.WRITE).store_string(JSON.stringify(receipt,"  "))
	host.queue_free()
	await process_frame
	quit(0 if failures.is_empty() else 1)
