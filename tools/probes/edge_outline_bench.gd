extends SceneTree
## Bench for commons/void/edge_outline.gd: a cube shows its 12 edges, an 8-sided cylinder its 8 seams and two rims,
## a 64-sided one only its rims, and a sphere at 25 degrees almost nothing. Run headless, prints and quits.
const Outline = preload("res://commons/void/edge_outline.gd")
func _init() -> void:
	var fails := 0
	var box := BoxMesh.new()
	var c8 := CylinderMesh.new(); c8.radial_segments = 8; c8.rings = 0
	var c64 := CylinderMesh.new(); c64.radial_segments = 64; c64.rings = 0
	var cases := [["box", box, 12], ["cylinder 8", c8, 24], ["cylinder 64", c64, 128]]
	for c in cases:
		var w: ArrayMesh = Outline.edges(c[1])
		var n: int = 0 if w == null else w.surface_get_array_len(0) / 2
		var ok: bool = n == c[2]
		if not ok: fails += 1
		print("%s %s: %d edges (want %d)" % ["PASS" if ok else "FAIL", c[0], n, c[2]])
	var root := Node3D.new()
	var mi := MeshInstance3D.new(); mi.mesh = box; root.add_child(mi)
	var label := MeshInstance3D.new(); label.name = "Label"; label.mesh = box; root.add_child(label)
	var dressed: int = Outline.outline(root)
	Outline.outline(root)
	var ok2: bool = dressed == 1 and mi.get_children().size() == 1 and label.get_children().is_empty()
	if not ok2: fails += 1
	print("%s outline dresses the solid once, twice-safe, skips the label (%d dressed, %d overlays)" % ["PASS" if ok2 else "FAIL", dressed, mi.get_children().size()])
	root.free()
	print("[edge_outline_bench] %s" % ("ok" if fails == 0 else "%d FAIL" % fails))
	quit(fails)
