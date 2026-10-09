# Shared field experiment

The primary `flow_field_painter` is mounted at y=1.05 with scale 2.5. Its opt-in `shared_field` lesson aligns the backing canvas with the XZ trails, uses 80 particles and seed 43, and starts with field evolution held.

## Two clocks and one sampler

ARROWS reveals 24 glyphs. Both glyphs and particle updates call `field_direction`. Arrow geometry refreshes at 10 Hz; particles update every rendered frame. A nearby arrow samples its own address and has its own refresh schedule: it is a representation of the field, not the source steering the particle.

FIELD TIME toggles only the field clock, holding its current time on pause. Particles continue. In lesson mode SCALE affects the noise frequency once; legacy instances retain their existing sampling behaviour. Existing SCALE and SPEED controls remain.

The field takes a noise value, turns it into an angle and constructs a unit direction with cosine and sine. It does not calculate the gradient of the noise. The two short code blocks in final.md are teaching sketches of the angle conversion and the position update, with the coordinate mapping and renderer omitted.

## What the controls retain

RESET scatters new particle positions and clears their trails without selecting a new seed. SEED changes the seed and resets those particles. Neither rewinds every clock. Changes to speed or scale leave existing trail positions present until new samples replace them; they therefore temporarily show the history of more than one setting.

The fixed sample capacity limits each trail's memory; it is not a fixed duration. Increasing speed changes the distance travelled between samples at a given update interval. Different display timing can change the sampling and numerical trajectory. Finite updates hold a sampled direction for a whole step before looking up another.

## The return seam

Opposite edges wrap the particle coordinates. The renderer joins consecutive stored positions, including across a wrap, so a long visible segment can cross an interior the particle did not traverse. The noise itself is not periodic: wrapping position does not ensure that directions agree at opposite edges.

## Which body this makes

This is prescribed motion through a direction field, not a force, gradient or fluid model. The update stores no inertial velocity, mass or particle-to-particle collision negotiation. Neighbours can change the aggregate picture without changing one another's movement. The standalone `vector_field_visualizer`, `vector_field_grid` and other supporting artifacts are independent examples; their arrows do not steer this painter.

The revised final.md follows a single particle, the held field, a changing field, and the edge's return before introducing the missing interaction. An immersive field affecting the visitor would require a separate receiver and a verified movement connection. That remains development material, not a capability added by this prose pass.

Full previous prose: [before this revision](../../../doc/book/iterations/2026-09-24-change-reading/before/commons/maps/Flow_Field/final.md). This companion records existing implementation, inspected again on 24 September 2026; no new runtime or headset test was made for the reading revision.
