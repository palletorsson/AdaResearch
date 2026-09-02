Rotation is the transformation that happens in time: the same small angular rule, repeated, accrues into a twist you can walk through and a spectacle you cannot stop watching.

The last hall taught that order matters. This one teaches that speed and direction compound. It is a long hall, a procession, with a tunnel along one wall and a carousel at the far end, and everything in it is one rule applied again and again until the rule has become architecture.

```gdscript
func attach_ring(frame: Node3D, count: int, radius: float) -> void:
    for i in count:
        var angle: float = i * TAU / count
        var obj := MeshInstance3D.new()
        obj.mesh = BoxMesh.new()
        obj.position = Vector3(cos(angle), 0, sin(angle)) * radius
        frame.add_child(obj)
```

Eight objects at even angles round a circle, hung from one frame. Turn the frame and the whole ring sweeps. Stack frames, give each its own speed, and the stack diverges and realigns over time. That is the whole machinery of this hall: a parent that turns, and children that inherit the turn.

## Still things first

<!-- @righttriangle -->

A right triangle, on its own by the entrance. Move it anywhere, turn it any way, and the ninety degrees between its two short sides is still ninety. It is here as a diagnostic: with everything in this hall turning, you need one thing whose angle you can trust.

<!-- @dark_sphere -->

The dark sphere, still, as it has been in every hall. The spectacle needs a witness that does not spin.

<!-- @ -->

## The rule, accrued

<!-- @boolean_tunnel -->

Along the east wall, a corridor built from eighteen hollowed cubes, three metres apart, and every one of them turned ten degrees more than the one before. Ten degrees is nothing. Eighteen times ten is a half turn, and over fifty-one metres it is a twist you walk through with your whole body leaning into it. Nobody designed the twist. A local rule about one segment and its neighbour was repeated, and the repetition became a building. This is rotation as navigable structure, and it is the argument of the hall in one object.

<!-- @baggage_grammar -->

A baggage carousel, and one suitcase going round it forever. On the straights it translates. At the corners it rotates. Through the customs arch it is scaled down, and on the far side it is restored, nothing to declare. Twelve seconds a lap. All three rigid motions, one after another, on one object, in a loop: the grammar of the chapter, spoken by a suitcase.

<!-- @two_cakes -->

Two cakes of three tiers each, assembled from the same tiers. One was turned and then slid, the other slid and then turned, and the candles stand at two different addresses. It is the last hall's lesson baked: the product changes when the factors change sides.

<!-- @pick_up_cube -->

A cube to carry through the procession, so that something in the hall moves because you moved it.

<!-- @carousel_cake -->

At the end, the carousel itself: eight circular layers stacked into a cake, and every layer obeys one rule, turn a fifth faster than the layer below. The bottom layer turns slowly. The top turns three and a half times as fast, and between them the layers slide past each other in patterns that repeat and interfere and repeat. The rule is the same at every level. Only the multiplier compounds, and it compounds until the object reads as rhythm rather than as a spin. Stand close. Watch the layers turn, and forget which way you were going.

<!-- @ -->

## Perpetual return

Translation goes somewhere and stops. Rotation goes round and comes back, and if you let it run it never has to stop, which is why a carousel is a spectacle and a walkway is not. What this hall adds to the chapter is time. A rule repeated in space gave you a twisted tunnel; a rule repeated in time gives you a cake that never settles. Both are the same ten degrees, and the difference between a building and a performance is only whether the repetition has finished.

Next: the last of the three moves, and the one that changes you.
