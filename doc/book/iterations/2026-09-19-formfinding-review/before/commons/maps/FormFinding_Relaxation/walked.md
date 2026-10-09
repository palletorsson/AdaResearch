# FormFinding_Relaxation — walked

> R-021/R-028: considered critical tutorial, ghost-drafted from the working map;
> Palle rules the voice. The walk (tutorial) woven with the turn (critical).

## The cast

mass_spring_bench · verlet_workbench · frozen_glass_vessel

## The walk

Release a mesh and watch it settle. The `mass_spring_bench` is a grid of masses joined by springs, and when you let it go each spring hauls toward its own rest length while gravity pulls the whole thing down — and after a few seconds of jostling it stops, having found the configuration that costs the least. That settling is *relaxation*, the algorithm every fabric, every membrane, every cooling sheet of glass obeys. The `verlet_workbench` shows the machinery a game engine actually uses — integrate the positions forward, then run constraint passes that nudge each mass back toward where its springs want it, over and over until the motion dies. Turn the constraint dial and feel the cloth go from floppy to taut. Then look at the `frozen_glass_vessel`: a walkable glass shape that was never modelled by hand — it was a sphere, pinned at the top, dropped, and left to sag under physics until it froze into *this*. Its form is a recording of the forces that made it.

## The turn (critical)

The vessel is D'Arcy Thompson made of glass, and the map's turn is his hundred-year-old thesis stated where you can walk inside it: **a form is a fossil of the forces that made it.** In *On Growth and Form* Thompson argued against the assumption that every shape in biology is a design, a purpose, a thing selected for — and insisted instead that most of it is *physics*: the hexagon of the honeycomb is packing, the spiral of the shell is growth at a fixed rate, the branching of the lung is flow finding least resistance. Beauty in nature is very often the calculus of variations wearing flesh — not chosen, computed, the same relaxation you just watched the spring mesh perform, run for millions of years. This map is where the chapter turns from physics toward biology, and it does so exactly as softbodies did with the radiolarian: the intricate form nobody designed, matter organizing itself under simple rules until structure crystallizes out. The turn worth holding is the one Thompson fought for and mostly lost to the gene-centred century that followed: before you ask what a shape is *for*, ask what forces it is the *residue of* — because the vessel's shape has no purpose at all, and it is still exactly what it had to be.

## Room for improvement

*(Palle: "a form is a fossil of the forces that made it — D'Arcy Thompson in glass"
is the turn, the pivot toward biology. Note whether watching the spring mesh settle
makes relaxation felt, and whether the vessel reads as physics-not-design when you
walk into it.)*
