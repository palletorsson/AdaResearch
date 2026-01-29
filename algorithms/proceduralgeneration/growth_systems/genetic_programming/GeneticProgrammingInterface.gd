@tool
extends Control
class_name GeneticProgrammingInterface

## Interactive Evolution Interface

@export var evolution_engine: NodePath

var engine: Node3D
var selected_genome_index: int = -1

func _ready():
    if evolution_engine:
        engine = get_node(evolution_engine)
    
    setup_ui()

func setup_ui():
    # Create UI for interactive selection
    var vbox = VBoxContainer.new()
    add_child(vbox)
    
    var title = Label.new()
    title.text = "Interactive Evolution"
    title.add_theme_font_size_override("font_size", 24)
    vbox.add_child(title)
    
    var info = Label.new()
    info.text = "Click on forms to select favorites"
    vbox.add_child(info)
    
    var evolve_btn = Button.new()
    evolve_btn.text = "Evolve Selected"
    evolve_btn.pressed.connect(_on_evolve_selected)
    vbox.add_child(evolve_btn)
    
    var random_btn = Button.new()
    random_btn.text = "Random Evolution"
    random_btn.pressed.connect(_on_random_evolution)
    vbox.add_child(random_btn)
    
    var stats = Label.new()
    stats.name = "Stats"
    vbox.add_child(stats)

func _on_evolve_selected():
    if engine and selected_genome_index >= 0:
        # Breed from selected genome
        print("Evolving from selected genome")

func _on_random_evolution():
    if engine:
        engine.evolve_one_generation = true

func _input(event):
    if event is InputEventMouseButton and event.pressed:
        # Raycast to select genome
        pass
