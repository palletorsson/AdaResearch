extends Node3D

var count := 0

func _ready():
    $Greeting.text = "Hello, world."

func _process(_delta):
    count += 1
    $Counter.text = str(count)
