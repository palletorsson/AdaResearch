extends "res://commons/testing/render_soft_body.gd"
## Reuse the gallery's exact builders and solver; only serialize their results.
const OUTPUT := "res://commons/artifacts/soft_snapshot_gallery/gallery_samples.json"
const IDS := ["sb01_cloth_drape_corners", "sb06_jelly_grid_settle", "sb_ls01_plant_skeleton", "sb_ca02_life_without_death_cloth", "gm03_box_in_cube_mould", "gm04_pressed_onto_sphere"]
func _initialize() -> void: bake.call_deferred()
func vectors(values: PackedVector3Array) -> Array:
	var result: Array = []
	for v in values: result.append([v.x,v.y,v.z])
	return result
func settle(cfg: Dictionary):
	var sim = _build_sim(cfg)
	for i in int(cfg.get("steps",240)):
		sim.step(float(cfg.get("dt",.0166667)))
		if cfg.has("mould"): _apply_mould_clamp(sim,cfg.mould)
	return sim
func bake() -> void:
	var library: Dictionary = JSON.parse_string(FileAccess.get_file_as_string("res://commons/soft_body/research_configs.json"))
	var samples: Array = []
	for id in IDS:
		var cfg: Dictionary = library.configs.filter(func(c):return c.id==id)[0]
		var start = _build_sim(cfg)
		var sim = settle(cfg)
		var repeat = settle(cfg)
		assert(sim.positions == repeat.positions, "Non-repeatable sample: " + id)
		assert(sim.positions != start.positions, "No change: " + id)
		var indices: Array = []
		if cfg.topology == "cloth_grid":
			for r in int(cfg.rows)-1:
				for c in int(cfg.cols)-1:
					var a: int = r*int(cfg.cols)+c
					indices.append_array([a,a+1,a+int(cfg.cols)+1,a,a+int(cfg.cols)+1,a+int(cfg.cols)])
		if cfg.topology == "glass_blow":
			for r in int(cfg.rings):
				for c in int(cfg.segments):
					var a: int = r*int(cfg.segments)+c
					var b: int = r*int(cfg.segments)+(c+1)%int(cfg.segments)
					indices.append_array([a,a+int(cfg.segments),b+int(cfg.segments),a,b+int(cfg.segments),b])
		for v in sim.positions: assert(v.is_finite())
		samples.append({"id":id,"config":cfg,"initial":vectors(start.positions),"kept":vectors(sim.positions),"springs":sim.springs,"indices":indices,"pinned":sim.pinned})
		print("GALLERY BAKE PASS ",id," / ",sim.positions.size()," particles / repeat identical")
	var f := FileAccess.open(OUTPUT,FileAccess.WRITE)
	f.store_string(JSON.stringify({"samples":samples,"source":"commons/testing/render_soft_body.gd","scope":"Saved geometry and spring connectivity; not a resumable simulation."}))
	f.close()
	quit(0)
