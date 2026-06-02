extends SceneTree

# Headless smoke test: instantiate each instrument scene, let one frame pass so
# _ready/_build runs, then report mesh/label counts + combined world AABB.
# Usage: godot --path . --xr-mode off --no-window --script res://commons/testing/instrument_smoke.gd -- a,b,c

var _list: Array = []
var _insts: Array = []
var _done := false

func _initialize() -> void:
	for a in OS.get_cmdline_user_args():
		for t in a.split(","):
			if t.strip_edges() != "":
				_list.append(t.strip_edges())
	if _list.is_empty():
		_list = ["half_life_manometer"]
	for t in _list:
		var path := "res://commons/instruments/%s.tscn" % t
		if not ResourceLoader.exists(path):
			print("FAIL  %-26s no scene" % t); _insts.append(null); continue
		var ps = load(path)
		if ps == null:
			print("FAIL  %-26s load null (parse error)" % t); _insts.append(null); continue
		var inst = ps.instantiate()
		root.add_child(inst)
		_insts.append(inst)

func _process(_delta: float) -> bool:
	if _done:
		return true
	_done = true
	var ok := 0
	for i in _list.size():
		var inst = _insts[i]
		if inst == null:
			continue
		var meshes: Array = []
		var labels: Array = []
		_collect(inst, meshes, labels)
		var combined := AABB()
		var first := true
		for mi in meshes:
			var a: AABB = (mi as MeshInstance3D).get_aabb()
			var gt: Transform3D = (mi as MeshInstance3D).global_transform
			for c in 8:
				var p: Vector3 = gt * a.get_endpoint(c)
				if first:
					combined = AABB(p, Vector3.ZERO); first = false
				else:
					combined = combined.expand(p)
		var status := "OK  " if meshes.size() > 0 else "EMPTY"
		if meshes.size() > 0:
			ok += 1
		print("%s  %-26s meshes=%2d labels=%2d  size=(%.1f,%.1f,%.1f)" % [
			status, _list[i], meshes.size(), labels.size(),
			combined.size.x, combined.size.y, combined.size.z])
	print("---- %d/%d built geometry ----" % [ok, _list.size()])
	return true

func _collect(n: Node, meshes: Array, labels: Array) -> void:
	for c in n.get_children():
		if c is MeshInstance3D:
			meshes.append(c)
		elif c is Label3D:
			labels.append(c)
		_collect(c, meshes, labels)
