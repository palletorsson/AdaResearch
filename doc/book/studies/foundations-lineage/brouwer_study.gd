extends "bench.gd"
const Witness = preload("witness.gd")
var model := Witness.new()
var rows: Array = [[0,0,1,1],[1,0,1,0],[0,1,1,0],[1,1,0,1]]
var show_diagonal := false

func _ready() -> void:
    start("BROUWER / PRODUCE THE WITNESS", ["0", "1", "DIAGONAL", "RESET"],
        [choose.bind(0),choose.bind(1),diagonal,reset])
    refresh()

func choose(bit: int) -> void:
    if point.held(): return
    show_diagonal = false
    model.append_bit(bit)
    refresh()

func diagonal() -> void:
    if point.held(): return
    show_diagonal = not show_diagonal
    refresh()

func reset() -> void:
    if point.held(): return
    model.terms.clear()
    refresh()

func bit_at(bit: int, at: Vector3, marked: bool = false) -> void:
    block(drawing,at,Vector3(0.18,0.045,0.13),Color("d29d55") if bit else Color("618da9"))
    label(drawing,str(bit),at+Vector3.UP*0.09,19)
    if marked: block(drawing,at+Vector3(0,-0.015,0),Vector3(0.23,0.01,0.18),Color("ffda88"))

func refresh() -> void:
    clear_drawing()
    if show_diagonal:
        var d: Array = model.diagonal(rows).bits
        for y in rows.size():
            for x in rows[y].size():
                bit_at(rows[y][x],Vector3(-0.75+x*0.3,1.04,-0.48+y*0.21),x==y)
        for i in d.size(): bit_at(d[i],Vector3(-0.75+i*0.3,1.04,0.45))
        point_home=Vector3(0.95,1.18,0.45)
        readout.text="A finite diagonal witness\nNew row: %s\nRow i differs at position i."%str(d)
    else:
        for i in model.terms.size(): bit_at(model.terms[i],Vector3(-1.05+i*0.3,1.05,0))
        point_home=Vector3(-1.05+mini(model.terms.size(),7)*0.3,1.27,0)
        var report := model.inspect_prefix()
        readout.text="%d / %d stored; no automatic next bit\nFinite prefix has 1: %s; index %d\nContinuation: %s"%[
            model.terms.size(),model.CAPACITY,str(report.finite_contains_one),report.witness_index,report.future_claim]
