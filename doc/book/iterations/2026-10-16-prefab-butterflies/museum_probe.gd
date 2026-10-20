extends "res://tools/probes/transformation_encounters.gd"
func landing_checks() -> void:
	root.size=Vector2i(1600,1100)
	var bench:=find_scene("/prefab_disorder.gd")
	check("prefab installation is present",bench!=null)
	if bench==null:return
	var flock: Node3D=bench.butterflies
	check("map config installs local butterfly flock",flock!=null)
	if flock==null:return
	check("sixteen butterflies visible at arrival",flock.birds.size()==16 and flock.visible)
	check("old aisle swarm no longer placed",find_scene("/randombutterflies/butterflies.gd")==null)
	flock.set_physics_process(false)
	var saved: Dictionary=bench.capture()
	var upright:=true
	var confined:=true
	for i in 600:
		flock.advance(0.1)
		for b in flock.birds:
			var body: Node3D=b.node
			confined=confined and flock.center_bounds().grow(0.0001).has_point(bench.to_local(body.global_position))
			upright=upright and body.global_basis.y.normalized().dot(Vector3.UP)>0.94
	check("all sixteen remain in installation after a minute",confined)
	check("all sixteen remain upright in the installed hall",upright)
	check("flight leaves hybrid experiment unchanged",bench.capture()==saved)
	observations["position"]=xyz(bench.global_position)
	observations["habitat_local"]={"min":xyz(flock.HABITAT.position),"max":xyz(flock.HABITAT.end)}
	await snapshot("flock-in-hall",bench.to_global(Vector3(-3.6,3.1,1.3)),bench.to_global(Vector3(0,1.55,0)),65)
	bench.set_disorder(1)
	await snapshot("flock-and-hybrids",bench.to_global(Vector3(-3.1,2.8,1.3)),bench.to_global(Vector3(0,1.55,-0.15)),68)
	var body: Node3D=flock.birds[0].node
	# Oblique dorsal view verifies head-forward texture and upright wing beats.
	await snapshot("butterfly-detail",body.global_position+Vector3(0.3,0.45,0.4),body.global_position,48)
	bench.show_gallery(true)
	check("gallery hides and pauses butterflies",not flock.visible and not flock.can_process())
	bench.show_gallery(false)
	check("return to experiment brings back same sixteen",flock.visible and flock.birds.size()==16)
	check("hybrid state restores after change",bench.restore(saved) and bench.capture()==saved)
	observations.scope="Native render and scripted local-volume/orientation checks; no physical headset comfort claim. Flock is visual staging, excluded from hybrid save records."

func finish() -> void:
	var f:=FileAccess.open(folder+"report.json",FileAccess.WRITE)
	f.store_string(JSON.stringify({"checks":checks,"failures":failures,"observations":observations},"\t"));f.close()
	quit(0 if failures.is_empty() else 1)
