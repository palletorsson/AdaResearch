class_name FoldMaterialProfile
extends Resource
## Surface response to folding — how creases look, how wrinkles form.

@export_range(0.0, 1.0) var shell_ratio: float = 0.0
@export_range(0.0, 1.0) var membrane_ratio: float = 0.0
@export_range(0.0, 1.0) var flesh_ratio: float = 0.0
@export_range(0.0, 1.0) var crease_visibility: float = 0.5
@export_range(0.0, 1.0) var wrinkle_response: float = 0.3
