extends Node3D

# Label utility that displays artifact name from the artifact registry
# Usage: la:keyid (e.g., "la:menu", "la:point", "la:line")

@onready var label_node: Label3D = $StaticBody3D/Label3DName
 
# Artifact data
var artifacts_data: Dictionary = {}
var keyid: String = ""
var artifact_name: String = "unknown"

# Path to artifact registries
const REGISTRY_DIR_PATH = "res://commons/artifacts/registry/"

func _ready():
	# Load artifact data on ready
	_load_artifacts_data()

	# Update label if keyid was set before ready
	if not keyid.is_empty():
		_update_label_text()
	else:
		# Set default text if no keyid provided
		if label_node:
			label_node.text = "no keyid"

# Called by GridUtilitiesComponent with the keyid parameter
func set_keyid(id: String):
	keyid = id

	# If artifacts data is already loaded, update immediately
	if not artifacts_data.is_empty():
		_update_label_text()
	else:
		_load_artifacts_data()
		_update_label_text()

# Load artifacts data from registry/*.json files
func _load_artifacts_data():
	var dir = DirAccess.open(REGISTRY_DIR_PATH)
	if not dir:
		push_error("InfoLabel: Registry directory not found at %s" % REGISTRY_DIR_PATH)
		return

	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if not dir.current_is_dir() and file_name.ends_with(".json"):
			var full_path = REGISTRY_DIR_PATH + file_name
			var file = FileAccess.open(full_path, FileAccess.READ)
			if file:
				var json = JSON.new()
				if json.parse(file.get_as_text()) == OK:
					var data = json.get_data()
					if data is Dictionary:
						var arts = data.get("artifacts", {})
						if arts is Dictionary:
							for key in arts:
								if arts[key] is Dictionary:
									artifacts_data[key] = arts[key]
				file.close()
		file_name = dir.get_next()
	dir.list_dir_end()
	print("InfoLabel: Loaded %d artifacts from registry" % artifacts_data.size())

# Update the label text based on keyid
func _update_label_text():
	# Make sure label_node exists
	if not label_node:
		push_error("InfoLabel: Label3D node not found!")
		return

	if keyid.is_empty():
		label_node.text = "no keyid"
		return

	# Look up the artifact by keyid (lookup_name)
	var artifact = _find_artifact_by_keyid(keyid)

	if artifact.is_empty():
		label_node.text = "unknown: %s" % keyid
		print("InfoLabel: Artifact not found for keyid '%s'" % keyid)
	else:
		artifact_name = artifact.get("name", keyid)
		label_node.text = "(x) " + artifact_name
		print("InfoLabel: Displaying '%s' with hint for keyid '%s'" % [label_node.text, keyid])

# Find artifact by lookup_name (keyid)
func _find_artifact_by_keyid(id: String) -> Dictionary:
	# Direct lookup by key
	if artifacts_data.has(id):
		var artifact = artifacts_data[id]
		if typeof(artifact) == TYPE_DICTIONARY:
			return artifact

	# Search for matching lookup_name
	for artifact_key in artifacts_data.keys():
		var artifact = artifacts_data[artifact_key]
		if typeof(artifact) == TYPE_DICTIONARY:
			if artifact.get("lookup_name", "") == id:
				return artifact

	return {}

# Debug function to list all available artifacts
func list_available_artifacts():
	print("InfoLabel: Available artifacts:")
	for key in artifacts_data.keys():
		var artifact = artifacts_data[key]
		if typeof(artifact) == TYPE_DICTIONARY:
			var lookup = artifact.get("lookup_name", "N/A")
			var name = artifact.get("name", "N/A")
			print("  %s -> lookup_name: %s, name: %s" % [key, lookup, name])
