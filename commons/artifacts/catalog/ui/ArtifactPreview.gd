class_name ArtifactPreview
extends Control

## Preview panel showing artifact details and spawn button

signal spawn_requested(lookup_name: String)

@onready var _name_label: Label = $VBoxContainer/NameLabel
@onready var _description_label: RichTextLabel = $VBoxContainer/ScrollContainer/DescriptionLabel
@onready var _metadata_label: Label = $VBoxContainer/MetadataLabel
@onready var _lock_status_label: Label = $VBoxContainer/LockStatusLabel
@onready var _spawn_button: Button = $VBoxContainer/SpawnButton

var _current_lookup_name: String = ""


func _ready():
	_spawn_button.pressed.connect(_on_spawn_pressed)
	_show_empty_state()


## Display artifact details
func show_artifact(lookup_name: String):
	_current_lookup_name = lookup_name

	var artifact = ArtifactCatalogDataProvider.get_artifact_by_lookup_name(lookup_name)
	if artifact.is_empty():
		_show_empty_state()
		return

	# Name
	_name_label.text = artifact.get("name", "Unknown Artifact")
	_name_label.visible = true

	# Description
	var description = artifact.get("description", "No description available.")
	_description_label.text = description
	_description_label.visible = true

	# Metadata (themes, complexity, tags)
	var metadata_text = _build_metadata_text(artifact)
	_metadata_label.text = metadata_text
	_metadata_label.visible = metadata_text != ""

	# Lock status
	var is_unlocked = ArtifactCatalogDataProvider.is_artifact_unlocked(lookup_name)
	if is_unlocked:
		_lock_status_label.visible = false
		_spawn_button.disabled = false
		_spawn_button.text = "Spawn Artifact"
	else:
		_lock_status_label.text = "🔒 Locked - Complete sequences to unlock this artifact"
		_lock_status_label.visible = true
		_spawn_button.disabled = true
		_spawn_button.text = "Locked"


func _build_metadata_text(artifact: Dictionary) -> String:
	var parts = []

	# Themes
	var themes = artifact.get("dev_themes", [])
	if not themes.is_empty():
		var theme_str = "Themes: " + ", ".join(themes)
		parts.append(theme_str)

	# Complexity
	var complexity = artifact.get("complexity", "")
	if complexity != "":
		parts.append("Complexity: " + complexity.capitalize())

	# Category
	var category = artifact.get("dev_category", "")
	if category != "":
		parts.append("Category: " + category.replace("_", " ").capitalize())

	# Tags
	var tags = artifact.get("tags", [])
	if not tags.is_empty():
		var tags_str = "Tags: " + ", ".join(tags)
		parts.append(tags_str)

	return "\n".join(parts)


func _show_empty_state():
	_name_label.text = "Select an artifact to view details"
	_name_label.visible = true
	_description_label.text = ""
	_description_label.visible = false
	_metadata_label.text = ""
	_metadata_label.visible = false
	_lock_status_label.visible = false
	_spawn_button.disabled = true
	_spawn_button.text = "Spawn Artifact"


func _on_spawn_pressed():
	if _current_lookup_name != "":
		spawn_requested.emit(_current_lookup_name)


## Clear preview
func clear_preview():
	_current_lookup_name = ""
	_show_empty_state()
