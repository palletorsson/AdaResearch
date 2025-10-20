@tool
extends Node3D
class_name SpaceColonizationPresets

## Space Colonization - Advanced Organic Forms

@export_group("Preset Patterns")
@export_enum("Veins", "Coral", "Lightning", "Roots", "Neural", "Custom") var pattern_preset: int = 0:
    set(value):
        pattern_preset = value
        apply_preset()

@export_group("Multiple Targets")
@export var use_multiple_cubes: bool = false
@export var cube_count: int = 3
@export var cube_spacing: float = 6.0

@export var base_colonization: Node3D

func _ready():
    setup_colonization()

func apply_preset():
    if not base_colonization:
        return
    
    match pattern_preset:
        0: # Veins
            base_colonization.distribution_type = 0  # Shell
            base_colonization.distribution_thickness = 1.0
            base_colonization.influence_distance = 1.5
            base_colonization.segment_length = 0.15
            base_colonization.branch_thickness = 0.1
            base_colonization.branch_color = Color(0.8, 0.2, 0.2)
        
        1: # Coral
            base_colonization.distribution_type = 1  # Volume
            base_colonization.distribution_thickness = 3.0
            base_colonization.influence_distance = 2.5
            base_colonization.segment_length = 0.25
            base_colonization.branch_thickness = 0.2
            base_colonization.branch_color = Color(1.0, 0.5, 0.3)
        
        2: # Lightning
            base_colonization.distribution_type = 2  # Surface
            base_colonization.distribution_thickness = 0.5
            base_colonization.influence_distance = 3.0
            base_colonization.segment_length = 0.4
            base_colonization.branch_thickness = 0.08
            base_colonization.branch_color = Color(0.7, 0.9, 1.0)
        
        3: # Roots
            base_colonization.distribution_type = 1  # Volume
            base_colonization.distribution_thickness = 2.0
            base_colonization.influence_distance = 2.0
            base_colonization.segment_length = 0.2
            base_colonization.branch_thickness = 0.25
            base_colonization.branch_color = Color(0.5, 0.3, 0.2)
            base_colonization.origin_type = 2  # Ring
        
        4: # Neural
            base_colonization.distribution_type = 3  # Corners
            base_colonization.distribution_thickness = 2.5
            base_colonization.influence_distance = 1.8
            base_colonization.segment_length = 0.12
            base_colonization.branch_thickness = 0.06
            base_colonization.branch_color = Color(0.9, 0.9, 0.5)
            base_colonization.origin_type = 3  # Base

func setup_colonization():
    if not base_colonization:
        base_colonization = get_node_or_null("SpaceColonization")
    
    if not base_colonization:
        # Create colonization node
        base_colonization = Node3D.new()
        base_colonization.name = "SpaceColonization"
        add_child(base_colonization)
        
        # You would attach the main script here
        # base_colonization.set_script(...)
    
    apply_preset()
