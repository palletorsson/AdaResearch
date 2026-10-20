# A school within reach

72 stylized fish beside the Boids observation balcony. A new encounter using the existing `Boid.gd` neighbour calculation and the carried PointBody from `particle_swarm_walk`. The original 100-prism flock, aquarium, controls and balcony remain.

Hold the black sphere to gather nearby fish. Hold its action (VR trigger; desktop left mouse button while carrying) to scatter them. Release the action to gather again. Release the sphere to remove its influence; it returns to the stand after 1.5 seconds. Desktop pickup/drop uses the museum's existing right-click interaction.

The cyan/pink rings show the eight-metre influence radius. A gold ring identifies one fish; its arrow shows the additional steering from the sphere. Separation, alignment, cohesion and boundary turning still apply. Fish have no solid collision bodies. Their appearance is an artistic representation, not an empirically validated model of fish biology.

## Construction

- `fish_school.gd`: population, seeded starting positions, shared meshes, sphere, hand term and readout.
- `fish.gd`: existing Boid subclass without the original long prism trails.
- `Boid.gd`: optional `boundary_frame` and `steering_source`; original scenes leave both unset.
- Boundary: 11 × 4 × 10 m, centred beside the stand. Soft turning, not a glass box.
- Integration: existing sequential Boid physics updates. This is separate from the small tutorial's simultaneous snapshot model.
- The stand has floor collision. `get_museum_occupied_cells()` reports that footprint only; decorative range rings do not block navigation.

## Verification

`tools/probes/fish_school_checks.gd` runs the real Boid integrator with synthetic pickup and action signals. `tools/probes/fish_school_museum.gd` exercises the encounter inside the real museum, checks hand height and a standing capsule's approach, measures gather/scatter, and captures eye-level and overhead images.

Physical headset comfort, controller reach and Quest frame rate still need a headset session. No changes to the tested tutorial, reflective text, or hall order are implied by this encounter.
