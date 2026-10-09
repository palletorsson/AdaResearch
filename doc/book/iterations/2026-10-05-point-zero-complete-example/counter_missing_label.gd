extends Node3D

var label: Label3D

func _ready() -> void:
    label.text = "0"
    label.font_size = 96
    label.pixel_size = 0.005
    add_child(label)

func _process(_delta: float) -> void:
    label.text = str(Engine.get_process_frames())
