A bowl on your left, a dome on your right, and a flat plate between them that no longer looks like the default.

The previous room let you stand inside an assumption until it stopped feeling like one. This room puts the assumption on a dial. There is a slider here with a number on it, and the number is the curvature of space — negative to the left, zero in the middle, positive to the right. Flatness is the detent at zero. It is not the centre because it is correct; it is the centre because it is zero.

## One number, and it is not a metaphor

<!-- @curvature_slider -->

```gdscript
# curvature_slider.gd:10
# critical_parameter: curvature — the ONE number that determines the entire geometry
```

Gaussian curvature, K, running from −1 to +1. That single scalar decides whether parallel lines diverge, stay apart, or converge; whether a triangle's angles sum to less than, exactly, or more than 180°; whether the shortest path between two points looks straight to you from outside. Not three geometries with three rulebooks. One rulebook with one free parameter.

This is the nineteenth century's actual discovery, and it is more unsettling than "there are other geometries." Gauss, Bolyai and Lobachevsky did not find a strange new space next door to the real one. They found that the space we were in had a setting, and that nothing in mathematics specifies which value it should take. Euclid's fifth postulate turns out to be the statement *K = 0* — not an axiom about parallels, a choice about curvature, wearing a sentence about lines.

## Where the wire is missing

<!-- @poincare_disk -->

```gdscript
# curvature_slider.gd:110
curvature_changed.emit(curvature)

# poincare_disk.gd:19 — and the only other place this signal name appears
signal curvature_changed(value: float)
```

Here is the room's own honest gap, and it is worth knowing before you turn anything.

The slider emits. Its registry entry says so plainly — *emits curvature_changed signal for linked surfaces* — and line 110 does exactly that, every time you move it. Search the rest of the project for anything that connects to it and you find one hit: the Poincaré disk, which declares the identical signal and emits it too. Two objects broadcasting the same message into a room where nothing is subscribed.

So the four surfaces standing around you — the saddle, the dome, the disk, the sphere — do not move when you turn the dial. Each one says so in its own header, in the same four words: *VR controls [missing]*. They are four fixed illustrations of four values of a parameter that is, in this room, unconnected to them.

Do not file that as a defect and move on. Notice what it makes the room into. You have a control that publishes a number, and a set of worlds that were each built at one value of it and cannot hear. That is a fairly exact picture of the situation the chapter is describing: the parameter is real, the consistency of each setting is real, and the passage between them is the thing nobody has built.

## The one that listens to itself

<!-- @triangle_curvature_workbench -->

```gdscript
# triangle_curvature_workbench.gd:7
# critical_parameter: K — discrete in {-2, -1, -0.5, 0, +0.5, +1, +2}. Drives surface
#   choice, edge geodesic type, angle measurement, and the excess/deficit readout
```

At the far corner, one bench does work. It carries its own slider — seven detents rather than a continuum — and when you turn it the surface underneath the triangle changes, the edges are rebuilt as geodesics *on that surface*, and the angle sum is measured and printed.

Measured. This is the payoff for the room you just left, where the angle sum was a hard-coded string reading `"60° + 60° + 60° = 180°"`. Here the number comes out of the geometry, and at K = 0 it lands on 180 not because anyone typed it but because that is what the flat case computes to. The same claim, arrived at two different ways, one room apart — and only one of them could ever have come out differently.

What it is showing you is the Gauss–Bonnet theorem: the amount by which a triangle's angles overshoot or fall short of 180° is exactly the curvature enclosed. Angle sum is not a fact about triangles. It is a measurement of the space the triangle is lying in, which is what the artifact's own header says: *the triangle doesn't know it's "in 3D"; it only knows its host*.

## Both neighbours of zero

<!-- @hyperbolic_surface -->

```gdscript
# hyperbolic_surface.gd:9
# essence: y = K(x² - z²) — saddle surface with negative Gaussian curvature K < 0
```

The saddle. Space curving outward, so that two geodesics starting parallel drift apart, and a triangle's angles fall short. Its header says something quietly good: *"straight" on a saddle looks curved from outside*. Straightness is not a property of the line. It is a relationship between the line and the surface it is confined to, and there is no outside vantage from which the surface is wrong.

<!-- @elliptic_surface -->

```gdscript
# elliptic_surface.gd:13
# emerges: the realization that on a positively curved surface there are NO parallel lines at all
```

The dome, and the opposite. Geodesics that begin parallel converge and cross, and the angle sum overshoots. On a sphere, the fifth postulate is not merely false — the thing it asserts cannot happen at all, because every pair of great circles meets. Twice.

Stand between the two and the point of the chapter is available without argument. These are not deformations of a correct space. Each is internally consistent, each has been formalised, each has physical realisations, and neither can be reached from the other by fixing an error. Flatness is the one in the middle. That is a fact about the number line, not about the world.

## The finite that holds the infinite

<!-- @riemann_sphere -->

```gdscript
# riemann_sphere.gd:10
# desire: see the infinite complex plane folded onto a finite sphere — the north pole IS infinity
```

Two objects here do the same trick from different directions and it is worth catching. The Poincaré disk compresses an entire infinite hyperbolic plane inside a finite circle: geodesics are arcs meeting the rim at right angles, and the rim is not an edge, it is infinity, which is why the tiles crowd and never arrive. The Riemann sphere does the mirror of it — the whole complex plane wrapped onto a ball by stereographic projection, with infinity as a single point you can walk around and look at from behind.

Both are saying that "infinite" and "unbounded" are not the same word, and that where you put the boundary is a modelling decision rather than a discovery. Which is the same sentence as the slider, one level up.

## What the dial cannot decide

Geometry was chosen, not found. That is settled by the time you leave this room, and it is settled without anyone having to be wrong.

But notice the shape of what just happened, because the next room breaks it. Every question here was answered by picking a value: what is the angle sum, do parallels meet, is the space finite — each one becomes answerable the moment K is fixed. The crisis so far is only that *we* pick K, and nothing outside picks it for us.

The next question does not have that form. It is not about which setting to choose. It is what happens to a rule that includes itself in the range of things it applies to — and there is no value of any parameter that makes that come out.

Flatness is a special case. The ground itself is a variable.
