extends RefCounted
## An append-only index of individual KEEP files. Never evict a kept form.
const SCHEMA="prefab-hybrid-gallery/1"
var paths: Array[String]=[]
var index_path: String=""
var error: String=""
var writable:=true

func bind(pointer_path: String) -> void:
	var target:=pointer_path.get_basename()+"-gallery.json"
	if target==index_path: return
	index_path=target;paths.clear();error="";writable=true
	if not FileAccess.file_exists(index_path):
		# Bring forward the previous single saved selection, not every test file.
		var pointer=read_json(pointer_path,10000)
		if pointer is Dictionary and valid_path(pointer.get("path")): paths.append(pointer.path)
		return
	load_index()

func load_index() -> bool:
	var record=read_json(index_path,2000000)
	if not record is Dictionary or record.get("schema")!=SCHEMA or not record.get("paths") is Array:
		fail_load();return false
	var seen: Dictionary={}
	for path in record.paths:
		if not valid_path(path) or seen.has(path): fail_load();return false
		seen[path]=true
	paths.clear()
	for path in record.paths: paths.append(path)
	return true

func fail_load() -> void:
	paths.clear();writable=false;error="Gallery index unreadable; existing saves retained."

func add(path: String) -> bool:
	if not writable or not valid_path(path): return false
	# Another open preview may have kept an entry since this scene last browsed.
	if FileAccess.file_exists(index_path) and not load_index(): return false
	var next: Array[String]=paths.duplicate()
	if not next.has(path): next.append(path)
	var temporary:=index_path+".tmp"
	var file:=FileAccess.open(temporary,FileAccess.WRITE)
	if file==null: error="Could not write gallery index.";return false
	file.store_string(JSON.stringify({"schema":SCHEMA,"paths":next},"\t"));file.flush()
	var code:=file.get_error();file.close()
	if code!=OK: error="Gallery index write incomplete.";return false
	code=DirAccess.rename_absolute(ProjectSettings.globalize_path(temporary),ProjectSettings.globalize_path(index_path))
	if code!=OK: error="Could not replace gallery index; earlier entries retained.";return false
	paths=next;error="";return true

static func valid_path(value: Variant) -> bool:
	return value is String and value.begins_with("user://prefab-disorder-") and value.ends_with(".json") and not value.contains("..") and not value.trim_prefix("user://").contains("/") and not value.contains("\\")

static func read_json(path: String, maximum: int=1000000) -> Variant:
	var file:=FileAccess.open(path,FileAccess.READ)
	if file==null or file.get_length()>maximum: return null
	var parser:=JSON.new()
	var code:=parser.parse(file.get_as_text());file.close()
	return parser.data if code==OK else null
