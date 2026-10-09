extends Node3D
## Supplied annotation: stage, time and two height ticks. No animation state is changed.

var title := Label3D.new()
var values := Label3D.new()

func _init():
    title.position = Vector3(0, 2.25, 0)
    title.font_size = 29
    title.pixel_size = 0.0025
    title.outline_size = 0
    title.modulate = Color("ddadbe")
    add_child(title)
    values.position = Vector3(0, 0.57, 0)
    values.font_size = 22
    values.pixel_size = 0.003
    values.outline_size = 0
    add_child(values)

func configure(centre: Vector3, travel: float):
    for height in [centre.y - travel, centre.y + travel]:
        var tick := Label3D.new()
        tick.position = Vector3(-0.86, height, 0)
        tick.text = "%.2f  ─" % height
        tick.font_size = 20
        tick.pixel_size = 0.0025
        tick.outline_size = 0
        tick.modulate = Color("c8c0c4")
        add_child(tick)

func show_values(stage: int, elapsed: float, t: float, height: float):
    title.text = ["0 / STILL", "1 / RISE AND FALL", "2 / ADD A TURN", "3 / ADD A CHANGE IN SIZE"][stage]
    values.text = "%.2f seconds    t = %.2f\ncentre height = %.2f m" % [elapsed, t, height]
