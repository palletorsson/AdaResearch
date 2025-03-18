extends Node3D

class_name AlgorithmBase

# Core metadata properties
var algorithm_id: String = ""
var algorithm_name: String = ""
var algorithm_description: String = ""
var algorithm_category: String = ""

# Extended metadata properties
var algorithm_metadata: Dictionary = {}

# Signal for algorithm-specific events
signal algorithm_event(event_name, data)
var interaction_prompt

func _ready():
	# Base setup
	# Set default interaction prompt to algorithm name if it exists
	if algorithm_name and algorithm_name != "":
		interaction_prompt = "Interact with %s" % algorithm_name

# Set algorithm metadata from the registry
func set_algorithm_metadata(metadata: Dictionary) -> void:
	algorithm_metadata = metadata
	
	# Set primary properties
	algorithm_id = metadata.get("id", "")
	algorithm_name = metadata.get("name", "Unknown Algorithm")
	algorithm_description = metadata.get("description", "")
	algorithm_category = metadata.get("category", "")
	
	# Update interaction prompt
	interaction_prompt = "Interact with %s" % algorithm_name
	
	# Custom initialization based on metadata
	_on_metadata_set(metadata)

# Override this in derived classes to handle specific metadata
func _on_metadata_set(metadata: Dictionary) -> void:
	pass

# Override the base interact method
func _do_interaction(player = null, data = null) -> void:
	# Base implementation
	print("Algorithm activated: %s" % algorithm_name)
	
	# Custom algorithm-specific interaction
	_on_algorithm_interact(player, data)
	
	# Emit the algorithm event
	emit_signal("algorithm_event", "activated", {
		"id": algorithm_id,
		"name": algorithm_name
	})

# Override this in derived classes to implement algorithm-specific interaction
func _on_algorithm_interact(player = null, data = null) -> void:
	pass

# Get a human-readable info card for this algorithm
func get_info_card() -> String:
	var info = """
	# %s
	
	%s
	
	**Category:** %s
	""" % [algorithm_name, algorithm_description, algorithm_category]
	
	# Add year and inventor if available
	if algorithm_metadata.has("year_invented") and algorithm_metadata.has("inventor"):
		info += "\n**Invented:** %s by %s" % [algorithm_metadata.get("year_invented"), algorithm_metadata.get("inventor")]
	
	# Add complexity if available
	if algorithm_metadata.has("complexity"):
		info += "\n**Complexity:** %s" % algorithm_metadata.get("complexity")
	
	# Add history if available
	if algorithm_metadata.has("history"):
		info += "\n\n## History\n%s" % algorithm_metadata.get("history")
	
	# Add references if available
	if algorithm_metadata.has("references") and algorithm_metadata.get("references") is Array:
		info += "\n\n## References\n"
		var references = algorithm_metadata.get("references")
		for ref in references:
			info += "- %s\n" % ref
	
	return info

# Get a property value from metadata
func get_property(property_name: String, default_value = null):
	if algorithm_metadata.has("properties") and algorithm_metadata.get("properties") is Dictionary:
		var properties = algorithm_metadata.get("properties")
		if properties.has(property_name):
			return properties.get(property_name)
	return default_value

# Get related algorithm IDs
func get_related_algorithm_ids() -> Array:
	if algorithm_metadata.has("related_algorithms") and algorithm_metadata.get("related_algorithms") is Array:
		return algorithm_metadata.get("related_algorithms")
	return []
