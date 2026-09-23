extends RefCounted
## One local, replaceable pose record. No visit tracking or gesture trajectory.
const FILE := "user://ada_research/assembly_pose.json"
const KEY := "ada_assembly_pose_record"
const PATH_KEY := "ada_assembly_pose_path" # Private probes use a workspace-local file.

static func location(tree: SceneTree) -> String:
	return str(tree.get_meta(PATH_KEY, FILE))

static func read(tree: SceneTree) -> Dictionary:
	if tree.has_meta(KEY): return tree.get_meta(KEY).duplicate(true)
	var path := location(tree)
	if not FileAccess.file_exists(path): return {}
	var file := FileAccess.open(path, FileAccess.READ)
	if file == null or file.get_length() > 65536: return {}
	var parser := JSON.new()
	if parser.parse(file.get_as_text()) != OK: return {}
	var parsed: Variant = parser.data
	if not valid(parsed): return {}
	var record: Dictionary = parsed
	record["persistence"] = "saved locally"
	tree.set_meta(KEY, record)
	return record.duplicate(true)

static func keep(tree: SceneTree, proposal: Dictionary) -> Error:
	if not valid(proposal): return ERR_INVALID_DATA
	var record := proposal.duplicate(true)
	record["saved_unix"] = Time.get_unix_time_from_system()
	record["revision"] = str(Time.get_ticks_usec()) + ":" + str(record.saved_unix)
	record["persistence"] = "this session only"
	tree.set_meta(KEY, record)
	var path := location(tree)
	var error := DirAccess.make_dir_recursive_absolute(ProjectSettings.globalize_path(path.get_base_dir()))
	if error != OK: return error
	var file := FileAccess.open(path + ".tmp", FileAccess.WRITE)
	if file == null: return FileAccess.get_open_error()
	file.store_string(JSON.stringify(record,"\t"))
	file.flush()
	error = file.get_error()
	file.close()
	if error != OK: return error
	error = DirAccess.rename_absolute(ProjectSettings.globalize_path(path+".tmp"),ProjectSettings.globalize_path(path))
	if error == OK:
		record["persistence"] = "saved locally"
		tree.set_meta(KEY,record)
	return error

static func changed(record: Dictionary) -> int:
	var count := 0
	for node in record.get("nodes",[]):
		if vector(node.start).distance_to(vector(node.end)) > .01: count += 1
	return count

static func vector(a: Array) -> Vector3:
	return Vector3(float(a[0]),float(a[1]),float(a[2]))

static func edge_key(edge: Array) -> String:
	var ids: Array = edge.duplicate()
	ids.sort()
	return str(ids[0])+"/"+str(ids[1])

static func changed_connections(record: Dictionary) -> int:
	var baseline: Dictionary = {}
	for edge in record.get("start_edges",record.get("edges",[])): baseline[edge_key(edge)] = true
	var count := 0
	for edge in record.get("edges",[]):
		if not baseline.has(edge_key(edge)): count += 1
	return count

static func components(record: Dictionary) -> int:
	var remaining: Dictionary = {}
	for node in record.get("nodes",[]): remaining[node.id] = true
	var count := 0
	while not remaining.is_empty():
		count += 1
		var todo: Array = [remaining.keys()[0]]
		while not todo.is_empty():
			var id: String = str(todo.pop_back())
			if not remaining.has(id): continue
			remaining.erase(id)
			for edge in record.get("edges",[]):
				if edge[0]==id: todo.append(edge[1])
				elif edge[1]==id: todo.append(edge[0])
	return count

static func valid_edges(edges: Variant, ids: Dictionary) -> bool:
	if not edges is Array or edges.size()!=12: return false
	var seen: Dictionary = {}
	for edge in edges:
		if not edge is Array or edge.size()!=2: return false
		if not edge[0] is String or not edge[1] is String: return false
		if not ids.has(edge[0]) or not ids.has(edge[1]) or edge[0]==edge[1]: return false
		var key := edge_key(edge)
		if seen.has(key): return false
		seen[key] = true
	return true

static func valid(value: Variant) -> bool:
	if not value is Dictionary: return false
	# JSON numbers reload as floats; Array.has() would reject 2.0 against int 2.
	if value.get("schema") != 1 and value.get("schema") != 2: return false
	if value.get("source_map") != "AdvancedLaboratory_Lab_Equipment_Simulation": return false
	if value.get("assembly") != "VRBody": return false
	if not value.get("source_hash",null) is String or value.source_hash.length()!=64: return false
	if not value.get("nodes",null) is Array or value.nodes.size()!=13: return false
	if not value.get("edges",null) is Array or value.edges.size()!=12: return false
	var edits: Variant = value.get("completed_edits",0)
	if not edits is int and not edits is float: return false
	if not is_finite(float(edits)) or float(edits)<0 or float(edits)>1000000000 or float(edits)!=floorf(float(edits)): return false
	if value.has("saved_unix"):
		if not value.saved_unix is float and not value.saved_unix is int: return false
		if not is_finite(float(value.saved_unix)) or float(value.saved_unix)<0: return false
	if value.has("revision") and (not value.revision is String or value.revision.length()>128): return false
	var ids: Dictionary = {}
	for node in value.nodes:
		if not node is Dictionary or not node.get("id",null) is String: return false
		if node.id.is_empty() or node.id.length()>32 or ids.has(node.id): return false
		ids[node.id] = true
		if not node.get("radius",null) is float and not node.get("radius",null) is int: return false
		if not is_finite(float(node.radius)) or node.radius<.01 or node.radius>.4: return false
		for key in ["start","end"]:
			if not node.get(key,null) is Array or node[key].size()!=3: return false
			for x in node[key]:
				if not x is float and not x is int: return false
				if not is_finite(float(x)) or absf(float(x))>3: return false
	if not valid_edges(value.edges,ids): return false
	return value.schema==1 or valid_edges(value.get("start_edges"),ids)
