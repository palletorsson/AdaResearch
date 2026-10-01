extends RefCounted
## Supplied check of a guest: does the folder stand on its own?
##   const CheckGuest := preload("res://supplied/check_guest.gd")
##   var needs: Array[String] = CheckGuest.outside("res://guests/trial/")
## A guest is a folder guests/<name>/ with the scene <name>.tscn in it. It is
## copied alone into another project, the room, so it may name nothing that is
## not in the folder. Contract:
##   outside(folder)       the list of what the guest needs from outside its
##                         folder. Empty: the guest stands on its own. It reads
##                         every .tscn, .gd, .tres, .gdshader and .gdshaderinc of
##                         the folder AS TEXT and lists each res:// path that is
##                         not inside the folder, a comment's too; and the script
##                         of each named class (class_name) from outside that a
##                         .gd of the folder uses. It also loads the scene: a
##                         scene that is missing or does not load is listed as
##                         one line that begins "no scene" or "does not load".
##   class_names(folder)   the names the folder itself declares with class_name.
##                         A room holds many guests: two that declare one name
##                         do not load together, so a guest should declare none.
## This reads the project's files as they are written, so it is for a kit's
## verify.gd, not for an exported build.

const READ := ["tscn", "gd", "tres", "gdshader", "gdshaderinc"]

static func outside(folder: String) -> Array[String]:
	if not folder.ends_with("/"):
		folder += "/"
	var found: Array[String] = []
	var scene := folder + folder.trim_suffix("/").get_file() + ".tscn"
	if not FileAccess.file_exists(scene):
		found.append("no scene at " + scene)
	else:
		var packed: Resource = load(scene)
		if not packed is PackedScene or not packed.can_instantiate():
			found.append("does not load: " + scene)
	var path_finder := RegEx.create_from_string("res://[^\"'\\s)\\],]*")
	for file: String in _files(folder):
		var text := FileAccess.get_file_as_string(file)
		for hit: RegExMatch in path_finder.search_all(text):
			var path := hit.get_string().simplify_path()
			if not (path + "/").begins_with(folder) and not found.has(path):
				found.append(path)
		if file.get_extension() != "gd":
			continue
		var code := _code_only(text)
		for entry: Dictionary in ProjectSettings.get_global_class_list():
			var declared: String = entry["path"]
			if declared.begins_with(folder) or found.has(declared):
				continue
			if RegEx.create_from_string("\\b%s\\b" % entry["class"]).search(code) != null:
				found.append(declared)
	return found

static func class_names(folder: String) -> Array[String]:
	if not folder.ends_with("/"):
		folder += "/"
	var names: Array[String] = []
	var finder := RegEx.create_from_string("(?m)^\\s*class_name\\s+(\\w+)")
	for file: String in _files(folder):
		if file.get_extension() == "gd":
			for hit: RegExMatch in finder.search_all(_code_only(FileAccess.get_file_as_string(file))):
				names.append(hit.get_string(1))
	return names

## Every file of the folder, and of the folders in it, that is read as text.
static func _files(folder: String) -> Array[String]:
	var out: Array[String] = []
	if not DirAccess.dir_exists_absolute(folder):
		return out
	for file in DirAccess.get_files_at(folder):
		if READ.has(file.get_extension()):
			out.append(folder + file)
	for inner in DirAccess.get_directories_at(folder):
		out.append_array(_files(folder + inner + "/"))
	return out

## A script without its comments and without what stands between quotes.
static func _code_only(text: String) -> String:
	var out := ""
	for line in text.split("\n"):
		var quote := ""
		for i in line.length():
			var c := line[i]
			if quote != "":
				if c == quote and line[i - 1] != "\\":
					quote = ""
			elif c == "\"" or c == "'":
				quote = c
			elif c == "#":
				break
			else:
				out += c
		out += "\n"
	return out
