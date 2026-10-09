# Spray cans and a shared image — current implementation

Color_Paint places `ball_painting_demo:0:0.5#automated:true#tools:spray`. The stable lookup and scene remain; the new token selects thirty cans and spray feedback. Placements without `tools:spray` retain pigment balls and the legacy brush calls.

`spray_can.gd` builds a coloured cylinder, metal rims, paper label, nozzle and collision capsule. It extends the project's pickable cube base. XRTools action press/release drives the nozzle after pickup. The museum's desktop hand uses `on_desktop_grab` and `on_desktop_drop` because desktop carrying does not call XRTools.pick_up; its existing left-button action routing supplies the same trigger. Drop stops emission and restores the individual saved tray transform. A tracked trigger's scalar value sets pressure; desktop uses full pressure.

## Hit, distance and coverage

A ray from the nozzle's local negative z direction must hit a drawing area first. The visible surface plane is then intersected exactly, avoiding the thickness of the Area collider. Back-facing and near-grazing incidence, targets behind blockers and targets beyond three metres do not deposit. The hit surface owns the receiver; no global first-canvas lookup is used.

```gdscript
last_radius_m = 0.012 + distance * tan(deg_to_rad(7.0))
var density := clampf(pow(0.09 / last_radius_m, 2.0), 0.06, 4.0)
var opacity := 1.0 - exp(-8.0 * pressure * density * minf(delta, 0.05))
```

The footprint's minor axis follows the canvas tangent; its major axis stretches by inverse incidence. Both are transformed into texture pixels using the actual rectangular surface and world transform. Coverage is an approximation: it is not a fluid, aerosol or spectral pigment model.

## Deposition and feedback

`spray_stamp.gdshader` renders a soft radial falloff with seeded pixel grain. Alpha compositing lets repeated deposits build coverage. BrushLayer queues up to 64 stamps per rendered frame and reuses a bounded pool of Polygon2D quads. Queues and transient commands clear after use. Small nozzle particles show the active spray, but they do not determine paint hits.

Each surface duplicates its feedback material. Spray mode settles the grain with less diffusion and flow than the older wet brush. It fades toward its selected priming colour. Fade and flow use elapsed frame time, capped at 50 ms per update to bound stalls. Stochastic rounding prevents small fade increments from becoming stuck in the compatibility renderer's 8-bit buffer. The image still has finite colour precision and finite spatial/temporal sampling; the time scaling is not a guarantee of identical output at every frame rate.

Canvas initialization and reset explicitly lay the selected ground in the feedback shader for two rendered frames. This fixes a black initial surface exposed by clearing the old transient reset splat. The shared legacy splat path now also clears stale draw commands when input stops.

The automatic can follows the existing UV oscillations. At most thirty updates per second deposit a six-centimetre-radius patch on its own surface using `draw_spray`. Manual nozzles deposit at physics steps. Both feed one image; no input history or undo stack is retained.

## Evidence

Current native museum report and interior images: `doc/book/iterations/2026-09-28-paint-spray-cans/`. Supplied pickup/trigger input checks actual rays, rectangular UV, range, obstruction, trigger release, dock return and the rendered pigment. The real desktop carry hooks/action dispatcher and an ordinary walking approach are also exercised. Tracked-controller reach and headset comfort remain untested. Previous ball evidence is preserved in the dated 10 and 23 September records and in this review's before-state.
