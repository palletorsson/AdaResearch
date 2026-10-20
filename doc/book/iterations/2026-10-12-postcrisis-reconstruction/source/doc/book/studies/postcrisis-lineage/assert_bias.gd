extends "assertions.gd"
const Model = preload("distinctions.gd")
func run() -> void:
    var model := Model.new()
    var opening := model.layout(0)
    var middle := model.layout(.5)
    var end := model.layout(1)
    expect("six identities retained",opening.size()==6 and Model.WORDS.size()==6)
    expect("warm midpoint .32",is_equal_approx(middle[0].distance_to(middle[1]),.32))
    expect("grey midpoint .66",is_equal_approx(middle[3].distance_to(middle[4]),.66))
    expect("compression reduces warm gap",end[0].distance_to(end[1])<opening[0].distance_to(opening[1]))
    expect("fresh arrays leave earlier arrangement intact",is_equal_approx(opening[0].x,-.52))
    expect("range clamps at upper end",model.layout(3)==end)
    expect("range clamps at lower end",model.layout(-1)==opening)
