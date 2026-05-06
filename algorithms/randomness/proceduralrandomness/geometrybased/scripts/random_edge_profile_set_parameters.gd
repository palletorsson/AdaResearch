# @identity
# essence: f(x) = Σ random_i · basis_i(x) — random coefficients on a fixed geometric basis
# desire: hold a sheet of procedurally generated edge profile, see randomness frozen into geometry
# critical_parameter: profile_height — scales the vertical range of the random edge contour
# triggers: _ready() sets height on child RandomEdgeProfile via set_height()
# emerges: each instance is a unique silhouette — randomness made solid, graspable, architectural
# needs: GrabPaper interactable [has]; child RandomEdgeProfile node [has]
# relationships: feeds random_edge_profile_collection; contrasts with Random_Rotate_Random_XYZ (rotation vs shape)
# truth: A profile is randomness that has been committed to form — the moment noise becomes geometry.

extends Node3D

@export var profile_height: float = 1.0  # Change this value to modify height
@export var label_text: String = ""  # Label text
@onready var profile = $GrabPaper/RandomEdgeProfile  # Get child node
@onready var info = $GrabPaper/id_info_Label3D # Get child node

func _ready() -> void:
	if profile:
		profile.set_height(profile_height)  # Call method to set height

func apply_grid_config(config: Dictionary) -> void:
	pass
