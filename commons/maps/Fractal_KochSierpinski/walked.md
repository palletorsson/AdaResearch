# Fractal_KochSierpinski — walked

> R-021/R-028: considered critical tutorial, ghost-drafted from the working map;
> Palle rules the voice. The walk (tutorial) woven with the turn (critical).

## The cast

fractal_koch_curve · koch_curve_3d · sierpinski_triangle · sierpinski_pyramid · box_counting_dimension

## The walk

Cantor removed; Koch replaces. Take every straight edge and swap its middle third for a spike — two sides of an equilateral triangle — then do it to every edge the swap created. The `fractal_koch_curve` runs the rule, and the arithmetic is the tutorial: each iteration multiplies the length by 4/3, so after *n* passes the length is (4/3)ⁿ, growing without bound — while the curve stays inside the same finite patch of floor. Infinite length, finite area, D = log 4/log 3 ≈ 1.262. The `sierpinski_triangle` shows the sibling operation — remove the middle triangle, recurse on the three that remain, D = log 3/log 2 ≈ 1.585 — and together they complete your toolkit: *remove* and *replace*, the two fundamental fractal moves. Then use the instrument. The `box_counting_dimension` station lays grids of shrinking cells over a shape and counts the boxes it touches; the slope of that count against scale *is* the dimension. Measure the Koch curve at several ruler-lengths and watch the answer refuse to settle — the shorter your ruler, the longer the coastline.

## The turn (critical)

When Helge von Koch published his curve in 1904, mathematics filed it under **pathology** — a "monster," continuous everywhere and smooth nowhere, cooked up to embarrass the calculus. The map's turn is that the diagnosis ran exactly backwards. Coastlines, mountain ridges, lungs, river networks, cloud edges: measured honestly, the world is Koch-like almost everywhere, and it is the smooth Euclidean curve that is the laboratory artifact, the idealization that exists mainly in textbooks. Richardson found it empirically before the theory existed — the measured length of Britain's coast depends on the ruler, with no true value waiting at the bottom. That is worth saying politically: *the norm was the special case.* The instrument beside the curve makes the point structural. Box-counting is measurement done in good faith — patient, systematic, reproducible — and what it faithfully reports is a number between the categories: 1.262, 1.585. Dimension, the deepest classification geometry owns, the very axis of point/line/plane/solid, turns out to be a spectrum the moment you measure anything real. The monsters were never deviant. They were the population; the classifier just hadn't been outdoors.

## Room for improvement

*(Palle: "the norm was the special case — smoothness is the laboratory artifact"
is the turn. Note whether box-counting reads as an activity (slope you extract)
or a readout, and whether the Koch coastline-ruler gap still wants an artifact.)*
