extends "study_base.gd"
const Model = preload("distinctions.gd")
var model := Model.new()
var positions: Array[Vector3] = []

func _ready() -> void:
    start("DISTINGUISH / SAME WORDS",["OPEN","HALF","COMPRESS"],[set_amount.bind(0.0),set_amount.bind(.5),set_amount.bind(1.0)])
    refresh()

func set_amount(value: float) -> void:
    if point.held(): return
    model.amount = value
    refresh()

func drag(at: Vector3) -> void:
    model.amount = clampf((at.x+.8)/1.6,0,1)
    refresh()

func refresh() -> void:
    positions = model.layout(model.amount)
    point_home = Vector3(-.8+model.amount*1.6,1.17,.58)
    clear_drawing()
    for i in 6:
        dot(positions[i],Color("e4a98d") if i<3 else Color("b7c1c5"))
        label(drawing,Model.WORDS[i],positions[i]+Vector3.UP*.13,16)
    readout.text = "Compression %.2f / authored positions
Warm gap %.2fm; grey gap %.2fm" % [model.amount,positions[0].distance_to(positions[1]),positions[3].distance_to(positions[4])]
