extends SceneTree
var checks := []
func _initialize() -> void: run.call_deferred()
func check(name: String, passed: bool) -> void: checks.append({"name":name,"passed":passed})
func run() -> void:
	var study: Node3D = load("res://line.tscn").instantiate()
	root.add_child(study)
	await process_frame
	var a: Node3D = study.get_node("A")
	var b: Node3D = study.get_node("B")
	var line: MeshInstance3D = study.get_node("Segment")
	for endpoint in [Vector3(0.75,1.12,0),Vector3(0.25,1.12,0),Vector3(-0.75,2.62,0),Vector3(-0.75,-0.38,0),Vector3(0.75,1.12,0.8)]:
		b.position=endpoint
		study._process(0)
		var delta: Vector3 = b.position-a.position
		check("length "+str(endpoint),is_equal_approx(line.mesh.height,delta.length()))
		check("midpoint "+str(endpoint),line.position.is_equal_approx((a.position+b.position)*0.5))
		check("axis "+str(endpoint),line.basis.y.dot(delta.normalized())>0.999)
		check("readout "+str(endpoint),study.get_node("Readout").text=="%.2f m"%delta.length())
	b.position=a.position;study._process(0)
	check("coincident endpoints hide segment",not line.visible and study.get_node("Readout").text=="0.00 m")
	b.position+=Vector3.RIGHT;study._process(0)
	check("moving apart restores segment",line.visible)
	var passed := checks.all(func(c):return c.passed)
	FileAccess.open("res://verification.json",FileAccess.WRITE).store_string(JSON.stringify({"passed":passed,"checks":checks},"  "))
	print("Line study: ",checks.size()," checks; passed=",passed)
	quit(0 if passed else 1)
