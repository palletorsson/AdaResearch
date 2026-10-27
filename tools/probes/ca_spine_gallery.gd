extends "res://tools/probes/ca_spine_active.gd"
## Final native views and measured fit. Interaction receipts are separate.
var measured_rows: Array = []
func run() -> void:
	for arg in OS.get_cmdline_user_args():
		if arg.begins_with("--out="):out = arg.trim_prefix("--out=")
	take_photos = true
	await start(false)
	for floor in selected_floors:
		level = floor;game.place_player(game.spawn_for(level));await frames(90)
		var y: float = game.building.spec.levels[level]
		check(str(level)+" safe main-floor arrival",game.body.is_on_floor() and absf(game.body.global_position.y-y)<.2)
		for entry in game.building.content.data.floors[level].artifacts:
			var node: Node3D = station(entry.id);var boxes: Array = [];geometry(node,boxes)
			check(str(level)+"/"+entry.id+" actual geometry",not boxes.is_empty())
			var b: AABB = boxes[0]
			for box: AABB in boxes:b = b.merge(box)
			b.position.y -= y
			measured_rows.append({"floor":level,"id":entry.id,"artifact":entry.artifact,"min":[b.position.x,b.position.y,b.position.z],"max":[b.end.x,b.end.y,b.end.z]})
			check(str(level)+"/"+entry.id+" fits tower XZ",b.position.x>=-21.05 and b.end.x<=21.05 and b.position.z>=-9.05 and b.end.z<=9.05)
		await photo("ca-%d-overview"%level,Vector3(0,y+2.6,8.7),Vector3(0,y+1.2,-1))
		if floor==103:
			await photo("ca-103-neighbourhood",Vector3(-.3,y+1.85,5.2),Vector3(-3.5,y+1.4,1.8))
		if floor==105:
			await photo("ca-105-laboratory",Vector3(-12.8,y+2.2,7.5),Vector3(-16.2,y+1.7,0))
		if floor==108:
			await photo("ca-108-exchange",Vector3(-4.5,y+2.2,7.5),Vector3(0,y+1.4,1))
		if floor==110:
			await photo("ca-110-infection",Vector3(12.8,y+2.3,6.5),Vector3(16,y+2.3,0))
		FileAccess.open(out.path_join("final-bounds.json"),FileAccess.WRITE).store_string(JSON.stringify(measured_rows,"  "))
	FileAccess.open(out.path_join("gallery-checks.json"),FileAccess.WRITE).store_string(JSON.stringify({"checks":checks,"failed":failed,"passed":failed.is_empty()},"  "))
	print("CA_BASELINE_RESULT ",checks.size()," gallery/fit checks; failures ",failed);quit(0 if failed.is_empty() else 1)
func photo(filename: String, at: Vector3, target: Vector3) -> void:
	var visible_charge: bool = game.charge_display.visible
	game.charge_display.hide()
	await super.photo(filename,at,target)
	game.charge_display.visible = visible_charge
