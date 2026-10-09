extends Node3D

var display := Label3D.new()
var count := 0

func _ready():
    display.position.y = 1.5
    display.text = str(count)
    add_child(display)

func _process(_delta):
    count += 1
    display.text = str(count)
