extends Node3D

const Palette = preload("palette.gd")
const Pane = preload("pane.gd")
const Controls = preload("controls.gd")

var filter_mode := true
var opacity := 0.52
var positions: Array[Vector3] = [Vector3(-0.4, 1.25, 0), Vector3(0.4, 1.25, -0.8)]
var turns: Array[float] = [0.0, 45.0]
var palettes: Array = []
var panes: Array[StaticBody3D] = []

func _ready() -> void:
    palettes = [
        Palette.new([Color(0.2, 0.9, 0.9), Color(1, 0.8, 0.15)]),
        Palette.new([Color(0.8, 0.2, 0.6), Color(0.15, 0.55, 0.9)])
    ]
    for i in range(positions.size()):
        var pane := Pane.new()
        pane.position = positions[i]
        pane.rotation_degrees.y = turns[i]
        add_child(pane)
        panes.append(pane)
    add_child(Controls.new())
    apply_colours()

func surface_colour(colour: Color, filtered: bool) -> Color:
    colour.a = clampf(opacity, 0, 1) if filtered else 1.0
    return colour

func apply_colours() -> void:
    for i in range(panes.size()):
        var material: StandardMaterial3D = panes[i].surface
        material.albedo_color = surface_colour(palettes[i].current_colour(), filter_mode)
        material.transparency = BaseMaterial3D.TRANSPARENCY_ALPHA if filter_mode else BaseMaterial3D.TRANSPARENCY_DISABLED

func toggle_filter() -> void:
    filter_mode = not filter_mode
    apply_colours()

func change_first() -> void:
    palettes[0].next_colour()
    apply_colours()
