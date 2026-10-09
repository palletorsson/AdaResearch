# A local acceleration and three receivers

Start with vector_machine, force_cube, then force_field_zone. Compare the preserved plank with entry into the field. The machine exposes pitch [-pi/2,pi/2], yaw [0,2pi], magnitude [0,15] m/s². Yaw zero points world +Z. Opening acceleration (0,-9.8,0); for an initial up/forward trial choose pitch about 45 degrees, yaw zero, magnitude about 7.5. These values invite a crossing attempt, not a guaranteed landing for every incoming velocity.

The lesson is opted in by #lesson:force_as_place on the machine, zone and three probes. The machine locates the shared em_map ancestor and updates only opted-in zones there, including zones loaded after its controls. Legacy machines skip these scoped zones.

Released RigidBody3D receivers in the real Area3D save gravity_scale, replace it with zero, then add field_vector * delta directly to linear_velocity. This is acceleration, independent of mass. Godot retains body damping/contact. Leaving the area, becoming frozen, or removing the field restores saved gravity. There is no claim that this overrides every other force.

Desktop locomotion samples incoming velocity before its ordinary update, then asks the opted-in containing field for its retained post-collision velocity plus a*dt. The final handoff happens before move_and_slide; collision output is recorded for the next step. While inside, this replaces keyboard steering/jump output. Exit clears field history, ordinary horizontal input takes over, and the vertical state returns to normal gravity. First containing field owns a visitor if volumes overlap.

The XRTools provider runs at order 95, respects earlier exclusive providers, uses move_player and returns exclusive ownership inside. It installs for both existing and late XRTools player bodies without duplicates. This changes software locomotion, not tracked physical movement. Headset comfort and embodied testing remain pending.

Field dimensions: five metres, centred in X/Z and extending from local y=0 to 5. Visitor feet use strict X/Z interior and y in [-0.02,5]; physical cubes use area overlap. On entry, velocity is retained. Zero field acceleration does not stop motion. The carry receiver has no added damping; the loose probes retain linear_damp 0.3 plus project defaults.

ForceCube displays sampled velocity * 0.5, capped at 2.6 m, decomposed in body-local axes. This lesson removes the legacy seeded rest arrow; stationary means zero. Its readout declares the visual scale/cap instead of calling the arrow force. Recovery below four metres from its home height restores the initial transform and freezes; basin floor contact can prevent reaching that threshold.

The map is reversed in Z across all layers to place the machine before the field in museum travel. All eight artifact placements and six identities remain. Original walls, five-row pit and two-cell plank are preserved. Field geometry is an Area and drawing, not a wall; its opt-in placement must not erase the plank from the museum walk graph.
