# Drawn, evaluated, settled

What has already been decided when a curve seems to find itself?

The last hall let you follow a search taking steps. Here, first take a curve in your hand. Then compare it with one whose coordinates come from a formula. The hanging chain and the soap film are the physical references: under specified supports, loads and material assumptions, a settled chain or film can make a difficult calculation visible. But these objects in the museum arrive by different routes. Watch for the difference between drawing an answer, evaluating an answer, and letting a system settle toward one.

## The chain

<!-- @cable_builder -->

Four cyan beads, and a four-metre cable glowing magenta into blue slung through them. Take a bead and move it. The whole curve recomputes and re-skins in your hands, every frame. Hold the ends in mind while you move an interior point: what have you asked the curve to obey?

Read it carefully, because it is the room's honest object. The cable is not a chain solving its own equation. It is a spline whose sag is two Bezier handles per span, each pulled down by a fixed fraction of that span's length, so the depth is drafted rather than found. It resembles a hanging cable because its maker supplied a rule for sag. Your hand changes the constraints of that drawing. No weight has been measured and no rope length conserved.

<!-- @laundry_line_cathedral -->

Three washing lines pegged with towels and shirts, supported at their ends by crossbars. These curves are sampled from `cosh`. Their sag comes from three chosen parameters; the washing adds colour and an association with weight, but it adds no load to the calculation. Then look up. Above each line hangs its ghost: the same curve mirrored upward as a pale arch. The cathedral is implied.

Gaudí used hanging models to study structural form. Inverting a suitable tension model can suggest a compression structure under corresponding loads and supports; it is not a guarantee that any inverted curve will stand. Here the two poses let you see that reversal, while the plaque names the limit: an analytic drawing, not a gravity solver. The washing and the cathedral share a curve. They do not yet share a test.[^hanging-model]

<!-- @ -->

## The film

<!-- @catenoid -->

The chain, revolved into a surface. A soap film can form a catenoid between two coaxial rings, but the rings do not guarantee one enduring answer: stability depends on their separation, and a film can collapse into separate discs. “Minimal” does not promise a globally smallest surface for every boundary.[^film]

Here it lies low and wide, a cyan wireframe hourglass about a metre and a fifth across and a little over a third of a metre tall. Lift the model and turn it. The opening travels with it; the sampled mesh retains its shape. The same `cosh` appears again, now drawn around an axis. You can inspect the result in your hand, but you cannot stretch its rings or watch a film settle between them.

```gdscript
@export var c: float = 0.5      # waist radius

var r: float = c * cosh(u / c)
var x: float = r * cos(v)
var y: float = r * sin(v)
var z: float = u
```

The same `cosh` appears in a catenary and in the radial profile of a catenoid. Here `c` sets the waist radius; the chosen range of `u` decides how much surface we keep. The formula does not choose its own boundary. Somebody has already chosen the numbers from which it will begin.

<!-- @helicoid -->

In a slot between two pillars, the other one, and you may step over it before you notice it: a green wireframe corkscrew twenty centimetres across, about thirty-eight centimetres high, six thousand triangles in a thing the size of a mug. Lift this one too. A straight line rotates as it rises; the display gains about nineteen centimetres in each full turn.

A helicoid is ruled: straight lines lie along its surface. A catenoid is a surface of revolution. Suitable patches of these surfaces belong to an isometric family: they can be continuously related while preserving their intrinsic distances. That does not make these two differently bounded meshes the same object, and nothing in the room performs the deformation.[^surfaces]

<!-- @science_screen -->

The screen has no compatible live measurement from these objects. Its scanner needs more than a nearby shape or a suggestive name: it needs data in a form it recognises. The surfaces are visible; their mathematical relation has not become a signal the screen can read. There is still work between having an object and having an instrument for it.

<!-- @ -->

## Matter as the solver

A real chain can move, overshoot and settle after an end is displaced. A film has a history too. The equilibrium equation describes a possible settled condition; it does not erase the time needed to reach it. In this room that time is absent for another reason: the laundry curves and surface meshes are constructed from chosen formulas.

This is still a powerful way to make form. The boundary, the formula, the sampling and the drawing each decide something. The calculus of variations asks what makes a shape stationary under allowed changes. Our objects let us approach that question, and also ask which changes their code has allowed us to make.

Next: what happens when the solving has to be done in steps after all, by a machine with a frame budget.

[^hanging-model]: Santiago Huerta, [“Structural design in the work of Gaudí”](https://oa.upm.es/703/) (2006), on hanging models, graphical methods and equilibrium design. The inversion is conditional on loads and supports; the laundry artifact evaluates and mirrors a formula.

[^film]: Gareth P. Alexander and Thomas Machon, [“A Björling Representation for Jacobi Fields on Minimal Surfaces and Soap Film Instabilities”](https://arxiv.org/abs/1912.13009) (2020). Instability and the transition to separated films are not implemented in this model.

[^surfaces]: Danny Calegari, [*Minimal Surfaces*, §1.4](https://math.uchicago.edu/~dannyc/courses/minimal_surfaces_2014/minimal_surfaces_notes.pdf), on the conjugate family and isometric deformation. The local relation does not identify arbitrary finite meshes or their boundaries.
