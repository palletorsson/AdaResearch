## probe_pbr_box.gd — is PbrKit.box watertight at a plinth's proportions?
##
## THE QUESTION. A twelve-artifact batch turned exhibit_furniture's solid plinths into
## hollow shells: through the front face you could see the inside of the back wall. The
## symptom is MISSING FRONT FACES, not transparency, which points at the chamfered box
## rather than at any material. But PbrKit.box is used by fourteen artifacts that render
## correctly today, so if it is at fault the fault must be conditional on proportions.
##
## Rather than reason about winding order, build the boxes and COUNT. For a closed convex
## mesh every edge is shared by exactly two triangles; a hole shows up as edges used once.
## That is a fact about the geometry and needs no camera, no lighting and no eye.
##
## The sizes are the ones the batch actually used, taken from exhibit_furniture's kinds.
##
## Usage:
##   godot --headless --path . --xr-mode off \
##     --script res://commons/testing/probe_pbr_box.gd
extends SceneTree

const PBR := preload("res://commons/render/pbr_kit.gd")

const CASES: Array = [
	{"name": "plinth m body", "size": Vector3(0.55, 0.95, 0.55), "bevel": -1.0},
	{"name": "plinth s body", "size": Vector3(0.40, 1.15, 0.40), "bevel": -1.0},
	{"name": "plinth cap", "size": Vector3(0.60, 0.04, 0.60), "bevel": -1.0},
	{"name": "platform xl", "size": Vector3(3.40, 0.28, 3.40), "bevel": -1.0},
	{"name": "floating wall", "size": Vector3(4.00, 2.60, 0.10), "bevel": -1.0},
	{"name": "THIN PANEL 4mm", "size": Vector3(0.60, 0.004, 0.60), "bevel": -1.0},
	{"name": "explicit big bevel", "size": Vector3(0.55, 0.95, 0.55), "bevel": 0.30},
	{"name": "bevel == half min", "size": Vector3(0.50, 0.50, 0.50), "bevel": 0.25},
	{"name": "bevel > half min", "size": Vector3(0.50, 0.50, 0.50), "bevel": 0.40},
	{"name": "cube 1m default", "size": Vector3(1.0, 1.0, 1.0), "bevel": -1.0},
]


func _initialize() -> void:
	var mat := StandardMaterial3D.new()
	var bad := 0
	print("%-22s %8s %8s %9s %9s  %s" % ["case", "verts", "tris", "open", "dup", "verdict"])
	print("-".repeat(76))
	for c in CASES:
		var mi: MeshInstance3D = PBR.box(Vector3.ZERO, c["size"], mat, c["bevel"], 0.0)
		if mi == null or mi.mesh == null:
			print("%-22s  NO MESH" % c["name"])
			bad += 1
			continue
		# UNTYPED on purpose: ARRAY_INDEX is null for an unindexed surface, and a typed
		# PackedInt32Array assignment from null is a runtime error that kills the script
		# before it can report anything. The first run of this probe died exactly there
		# and the watchdog reported only "no result", which says nothing about the mesh.
		var arrays: Array = mi.mesh.surface_get_arrays(0)
		if arrays.is_empty():
			print("%-22s  NO SURFACE ARRAYS" % c["name"])
			bad += 1
			mi.free()
			continue
		var verts = arrays[Mesh.ARRAY_VERTEX]
		var idx = arrays[Mesh.ARRAY_INDEX]
		if verts == null:
			print("%-22s  NO VERTICES" % c["name"])
			bad += 1
			mi.free()
			continue
		var n_idx: int = 0
		if idx != null:
			n_idx = idx.size()
		var tris: int = int((n_idx if n_idx > 0 else verts.size()) / 3)

		# Edge census on WELDED positions: an index buffer can split a vertex for normals
		# or UVs while the surface is still closed, so counting raw indices would report a
		# hole in a watertight mesh. Quantise to 0.1 mm and key the edge by position pair.
		var key := {}
		var edges := {}
		for i in range(0, (n_idx if n_idx > 0 else verts.size()), 3):
			var t: Array = []
			for k in range(3):
				var vi: int = (idx[i + k] if n_idx > 0 else (i + k))
				var v: Vector3 = verts[vi]
				var q := "%d_%d_%d" % [roundi(v.x * 10000.0), roundi(v.y * 10000.0), roundi(v.z * 10000.0)]
				if not key.has(q):
					key[q] = key.size()
				t.append(key[q])
			for k in range(3):
				var a: int = t[k]
				var b: int = t[(k + 1) % 3]
				var e := "%d-%d" % [mini(a, b), maxi(a, b)]
				edges[e] = int(edges.get(e, 0)) + 1
		var open_edges := 0
		var dup_edges := 0
		for e in edges:
			var n: int = edges[e]
			if n == 1:
				open_edges += 1
			elif n > 2:
				dup_edges += 1
		var verdict := "watertight"
		if open_edges > 0:
			verdict = "OPEN - %d edges used once" % open_edges
			bad += 1
		elif dup_edges > 0:
			verdict = "NON-MANIFOLD - %d edges used 3+" % dup_edges
			bad += 1
		print("%-22s %8d %8d %9d %9d  %s" % [c["name"], key.size(), tris, open_edges, dup_edges, verdict])
		mi.free()
	print("-".repeat(76))
	print("%d of %d cases FAILED" % [bad, CASES.size()])
	var f := FileAccess.open("res://ada_run/probe_pbr_box.txt", FileAccess.WRITE)
	if f:
		f.store_string("failed=%d of %d\n" % [bad, CASES.size()])
		f.close()
	quit(1 if bad > 0 else 0)
