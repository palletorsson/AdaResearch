# probe_biome_cost.gd — the axis the look-loop never measured.
#
# Every biome look-research pass judged a specimen by its PNG. Cost was invisible
# to it, so a body that looked 5/5 but took 283ms to build was a latent map-load
# freeze that only surfaced later, reactively (build_budget, four tier caps). This
# probe measures BUILD COST — the same thing those perf commits measured by hand —
# and writes it where the research ledger can fold it in, so "the biome is fast"
# becomes a tracked property, not a thing rediscovered per body.
#
# Times each SDF morphology (the expensive substrates; the non-SDF ones measured
# 1-10ms and need no watch) at the biome-spawn LOD, averaged over N runs, and
# writes doc/reports/biome_cost.json { slug: {build_ms, verts, lod} }.
#
# Run:  <godot> --headless --path . --xr-mode off --script res://commons/testing/probe_biome_cost.gd

extends SceneTree

const CreatureSdf = preload("res://algorithms/nature_system/morphology/creature_sdf_morphology.gd")
const FungusSdf = preload("res://algorithms/nature_system/morphology/fungus_sdf_morphology.gd")
const FloraSdf = preload("res://algorithms/nature_system/morphology/flora_sdf_morphology.gd")
const DNA = preload("res://algorithms/nature_system/dna/critter_dna.gd")
const TraitMapper = preload("res://algorithms/nature_system/dna/critter_trait_mapper.gd")

const RUNS := 3
const BIOME_LOD := 1   # the dispatcher caps all SDF at lod 1 (BIOME_SDF_MAX_LOD_*)
const OUT := "res://doc/reports/biome_cost.json"


func _init() -> void:
	var mapper: CritterTraitMapper = TraitMapper.new()
	var results: Dictionary = {}

	print("── probe_biome_cost (%d runs, lod %d) ──" % [RUNS, BIOME_LOD])
	# gallery slug -> (morphology, DNA). DNA mirrors the dispatcher's biome recipe.
	results["fauna_grub"] = _time("fauna_grub", CreatureSdf, _grub(), mapper)
	results["fungus_sdf"] = _time("fungus_sdf", FungusSdf, _shroom(), mapper)
	results["flora_sdf_tree"] = _time("flora_sdf_tree", FloraSdf, _tree(), mapper)

	var f := FileAccess.open(OUT, FileAccess.WRITE)
	if f:
		f.store_string(JSON.stringify({"lod": BIOME_LOD, "runs": RUNS, "specimens": results}, "\t"))
		f.close()
		print("wrote %s" % OUT)
	quit(0)


func _time(slug: String, cls, dna: CritterDNA, mapper: CritterTraitMapper) -> Dictionary:
	var total_us: int = 0
	var verts: int = 0
	for r in range(RUNS):
		var holder := Node3D.new()
		root.add_child(holder)
		var t0: int = Time.get_ticks_usec()
		var built: Node3D = cls.build(dna, holder, mapper, BIOME_LOD)
		total_us += Time.get_ticks_usec() - t0
		if r == 0:
			verts = _count_verts(built if built != null else holder)
		holder.free()
	var ms: float = float(total_us) / float(RUNS) / 1000.0
	print("  %-16s %7.1f ms   %d verts" % [slug, ms, verts])
	return {"build_ms": round(ms * 10.0) / 10.0, "verts": verts, "lod": BIOME_LOD}


func _count_verts(n: Node) -> int:
	var v: int = 0
	if n is MeshInstance3D and (n as MeshInstance3D).mesh is ArrayMesh:
		var m: ArrayMesh = (n as MeshInstance3D).mesh
		if m.get_surface_count() > 0:
			v += (m.surface_get_arrays(0)[Mesh.ARRAY_VERTEX] as PackedVector3Array).size()
	for c in n.get_children():
		v += _count_verts(c)
	return v


func _grub() -> CritterDNA:
	var d: CritterDNA = DNA.new()
	d.body_type = 1.0; d.segments = 5.5; d.scale = 0.9
	d.part_length = 0.39; d.part_width = 0.94; d.part_curve = 0.35; d.part_taper = 0.8
	d.symmetry = 3.0; d.mobility = 0.9; d.branch_angle = 30.0
	d.primary_color = Color(0.7, 0.5, 0.4); d.iridescence = 0.2; d.roughness = 0.6
	return d


func _shroom() -> CritterDNA:
	var d: CritterDNA = DNA.new()
	d.body_type = 3.0; d.scale = 1.0
	d.part_length = 0.9; d.part_width = 0.9; d.part_curve = 0.7; d.part_taper = 0.5
	d.primary_color = Color.from_hsv(0.09, 0.35, 0.85); d.roughness = 0.6
	return d


func _tree() -> CritterDNA:
	var d: CritterDNA = DNA.new()
	d.body_type = 0.0; d.segments = 5.0; d.scale = 1.0
	d.part_length = 0.9; d.part_width = 0.8; d.branch_angle = 35.0; d.part_curve = 0.4
	d.primary_color = Color(0.4, 0.28, 0.18); d.secondary_color = Color(0.2, 0.5, 0.2)
	return d
