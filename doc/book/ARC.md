# The Tutorial Arc — Ada Research, NOC for Godot 3D

> R-025. All 22 chapters as one pedagogical spine. Each chapter *builds on* the
> vocabulary of the ones before it — a plain, sound tutorial — then the critical
> voltage (the thinker with QFEP) turns it into Ada. The beat roles are the skeleton;
> casting (role → real artifact) and voltage live in `doc/book/baselines/<seq>.json`,
> read together at `/composition`.

## 1. primitives
*builds on:* — (the foundation)

the vocabulary of space itself — point, line, plane, solid, coordinate frame

**Beats:** arrive → meet the point → the point moves → two points → measure the line → lines repeat → three points → planes close → build one yourself → prove it

## 2. transformation
*builds on:* primitives

move a thing without changing what it IS — translate, rotate, scale; dot/cross products; matrices compose motion; the invariant under motion

**Beats:** arrive in transformed space → translate a solid → rotate it → scale it → the dot product → the cross product → compose transforms → the invariant → compose a transform yourself → prove it

## 3. array_tutorial
*builds on:* primitives, transformation

the grid as an addressable structure — index to position, repetition as a first-class move

**Beats:** the grid appears → one cell, addressed → fill a row → fill 2D → the tile repeats → mirror and symmetry on the grid → edit the grid live → a pattern from a rule → prove it

## 4. color
*builds on:* primitives, array_tutorial

color as a system — hue, value, saturation — and how color becomes composition

**Beats:** a single hue → value and saturation → the palette → contrast → color the grid → a color rule → the artists' systems → compose a palette yourself → prove it

## 5. change
*builds on:* primitives, transformation

the calculus substrate — derivative as instantaneous rate, integral as accumulation, vector field as flow; the vocabulary forces/waves/randomness/noise all use

**Beats:** the slope at a point → the derivative pair → velocity as the derivative of position → the integral as area → accumulation → the vector field → partial derivative → the FTC bridge → prove it

## 6. isosurfaces
*builds on:* change, array_tutorial, primitives

implicit field to explicit surface — marching cubes as the bridge from continuous to mesh

**Beats:** the scalar field → the isovalue → sample on a grid → one cube's cases → the surface emerges → sculpt the field → resolution → build a surface yourself → prove it

## 7. boolean_surfaces
*builds on:* isosurfaces, primitives

CSG — union, intersection, difference as composition logic on solids

**Beats:** two solids → union → intersection → difference → compose a boolean tree yourself

## 8. forces
*builds on:* change, transformation, primitives

Newton — vectors become physics; force, mass, acceleration, friction, attraction

**Beats:** a vector → apply a force → mass → gravity → friction and drag → the attractor → many attractors → bounded space → build a force field yourself → prove it

## 9. wavefunctions
*builds on:* forces, change

oscillation — force and energy exchange; sine creates curves; amplitude, frequency, phase

**Beats:** the oscillator → amplitude → frequency → phase → sine as circular motion → the spring → waves add → standing waves → compose a waveform yourself → prove it

## 10. randomness
*builds on:* primitives, array_tutorial

disorder as creative force — distributions, entropy, the seed

**Beats:** the coin flip → the random walk → distributions → the Gaussian → entropy → the seed → random versus pseudo-random → paint with randomness → prove it

## 11. noise
*builds on:* randomness, change, forces

structured randomness — Perlin, octaves, flow fields

**Beats:** white noise → smooth it → Perlin → octaves → noise as terrain → the flow field → steer with the field → sculpt with noise → prove it

## 12. cellularautomata
*builds on:* array_tutorial, randomness

simple rules to complex behavior — Rule 110 is Turing complete, the edge of chaos

**Beats:** the cell → the neighborhood → one rule, one step → iterate → the edge of chaos → Rule 110 → seed and watch → design a rule yourself → prove it

## 13. fractals
*builds on:* transformation, primitives

self-similarity, recursion, infinite detail

**Beats:** recursion → self-similarity → the recursion depth → IFS → the Mandelbrot → dimension → build a fractal yourself → prove it

## 14. lsystems
*builds on:* fractals, transformation

generative grammars — symbols rewritten into structure

**Beats:** the alphabet → a rule → the turtle → iterate the grammar → branching → stochastic rules → design a grammar yourself → prove it

## 15. proceduralgeneration
*builds on:* array_tutorial, cellularautomata, randomness

emergence from constraint — WFC, Markov, adjacency

**Beats:** the tile set → adjacency rules → constraint propagation → wave function collapse → Markov → seeds and variation → generate a world yourself → prove it

## 16. swarmintelligence
*builds on:* forces, noise, change

collective behavior — steering, the three boid rules, stigmergy

**Beats:** one agent → steering → separation → alignment → cohesion → stigmergy → tune the swarm yourself → prove it

## 17. softbodies
*builds on:* forces, wavefunctions, change

deformable matter — springs, cloth, damping, energy descent, morphogenesis

**Beats:** two masses and a spring → a chain → the cloth → gravity and pinning → damping → collision → morphogenesis → build a soft body yourself → prove it

## 18. machinelearning
*builds on:* forces, change, randomness

learning systems — the neuron, loss, gradient descent as a force downhill

**Beats:** the data → the neuron → the loss → gradient descent → the network → training → overfitting → train one yourself → prove it

## 19. graphtheory
*builds on:* array_tutorial, primitives

connections define structure — the substrate under every map

**Beats:** nodes and edges → adjacency → traversal → shortest path → the graph under the maps → build a graph yourself → prove it

## 20. foundationscrisis
*builds on:* graphtheory, machinelearning, cellularautomata

the limits of formal systems — Russell, Gödel, Turing's halting problem

**Beats:** the axioms → the paradox → self-reference → Gödel → the halting problem → the limit made walkable → sit with the incompleteness → prove it

## 21. qfeplaboratory
*builds on:* foundationscrisis

the complete QFEP formula embodied — Question, Field, Entropy, Potential

**Beats:** Question → Field → Entropy → Potential → the formula assembled → the lab → run the QFEP loop yourself → prove it

## 22. postfoundationscrisis
*builds on:* foundationscrisis, qfeplaboratory

practice after the crisis — bias, rhizomes, molecular design, the self-made archive

**Beats:** bias → the rhizome → molecular design → the archive → practice after the crisis → the closing
