extends RefCounted
## Development exports only. Game scenes and their imported models stay in res://.

static func root_directory() -> String:
	var configured := OS.get_environment("ADA_GENERATED_ROOT")
	if configured.is_empty():
		configured = "D:/AdaGenerated/AdaResearch_46" if OS.get_name()=="Windows" else OS.get_user_data_dir().path_join("generated-models")
	return configured.replace("\\","/").simplify_path()

static func project_directory() -> String:
	var source := OS.get_environment("ADA_SOURCE_PROJECT")
	return (ProjectSettings.globalize_path("res://") if source.is_empty() else source).replace("\\","/").simplify_path().trim_suffix("/")

static func export_directory(relative: String) -> String:
	return root_directory().path_join("exports").path_join(relative)

static func public_directory(relative: String) -> String:
	return root_directory().path_join("public").path_join(relative)

static func output_directory(requested: String) -> String:
	var absolute := ProjectSettings.globalize_path(requested).replace("\\","/").simplify_path().trim_suffix("/")
	var project := project_directory()
	# An isolated test project uses junctions to source but is not an export root.
	var runtime := ProjectSettings.globalize_path("res://").replace("\\","/").simplify_path().trim_suffix("/")
	if absolute.to_lower().begins_with(runtime.to_lower()+"/"):
		absolute=project.path_join(absolute.substr(runtime.length()+1))
	if absolute.to_lower().begins_with(project.to_lower()+"/"):
		absolute=root_directory().path_join("project").path_join(absolute.substr(project.length()+1))
	elif absolute.to_lower()==project.to_lower():
		absolute=root_directory().path_join("project")
	return absolute

static func write_gltf(document: GLTFDocument, state: GLTFState, requested: String) -> Error:
	var path := output_directory(requested)
	var source := project_directory().to_lower()
	# Fail closed if a caller misconfigures ADA_GENERATED_ROOT into res://.
	if path.to_lower()==source or path.to_lower().begins_with(source+"/"):
		push_error("Generated GLB output must be outside the Godot project: "+path)
		return ERR_INVALID_PARAMETER
	var error := DirAccess.make_dir_recursive_absolute(path.get_base_dir())
	if error!=OK:return error
	return document.write_to_filesystem(state,path)
