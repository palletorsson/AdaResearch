extends Node3D

var readout: Label3D
var slider: Node
var play_button: Node
var replay_button: Node
var panel: Node3D

func label(text: String, at: Vector3, size: int = 30) -> Label3D:
    var item := Label3D.new()
    item.text = text
    item.position = at
    item.font_size = size
    item.pixel_size = 0.006
    item.modulate = Color(0.92, 0.92, 0.86)
    item.outline_modulate = Color(0.06, 0.07, 0.09)
    item.outline_size = 8
    add_child(item)
    return item

func _ready() -> void:
    var Rack = load("res://commons/audio/rack_templates/RackTemplates.gd")
    panel = Rack.create_panel("SET ANGLE", [
        [{"type":"slider_h", "label":"0 — TAU", "default":0}],
        [{"type":"button", "label":"RUN / PAUSE"}, {"type":"button", "label":"REPLAY"}]
    ])
    panel.position = Vector3(0, -0.6, 1.0)
    panel.scale = Vector3.ONE * 1.5
    panel.set_meta("em_local_instrument", true)
    add_child(panel)
    slider = panel.find_child("Param_0", true, false)
    slider.slider_moved.connect(func(_value): get_parent().scrub_angle(slider.get_normalized_value() * TAU))
    play_button = panel.find_child("Btn_0", true, false).get_node("InteractableAreaButton")
    replay_button = panel.find_child("Btn_1", true, false).get_node("InteractableAreaButton")
    play_button.button_pressed.connect(func(_button): get_parent().running = not get_parent().running)
    replay_button.button_pressed.connect(func(_button): get_parent().replay_graph())
    readout = label("", Vector3(0, 1.6, 0.1), 27)
    label("ANGLE →    one turn = TAU radians", Vector3(7.8, -1.3, 0.3), 29)
    for i in range(5):
        label(["0", "PI", "TAU", "3 PI", "2 TAU"][i], Vector3(1.8 + i * 3, -1.05, 0.4), 24)
    refresh()

func refresh() -> void:
    if readout == null: return
    var source = get_parent()
    readout.text = "angle %.2f rad\nx %+.2f m    y %+.2f m\ncos %.2f    sin %.2f" % [source.angle, cos(source.angle)*source.radius, sin(source.angle)*source.radius, cos(source.angle), sin(source.angle)]
