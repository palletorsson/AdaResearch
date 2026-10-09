extends Node3D

var label: Label3D

func _ready() -> void:
    label = Label3D.new()
    label.text = "0"
    label.font_size = 96
    label.pixel_size = 0.005
    add_child(label)
    label.text = str(Engine.get_process_frames())
