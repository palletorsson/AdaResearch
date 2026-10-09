# Point One — construction reference

Read TUTORIAL.md for the lesson. The complete runnable scripts are position.gd, visible.gd and solid.gd; their code is also shown there. This reference names the parts we borrow and the distinction each part makes.

| Part | What it supplies | What the learner changes |
| --- | --- | --- |
| base.tscn | Floor, light, fixed camera and an inherited Welcome label, hidden by study.tscn | Nothing in this lesson |
| study.tscn | Three station nodes and their Point one labels | Each attached script is identified in the tutorial |
| point_position | A Vector3 location inside a station | The supplied height; detailed component reading follows in Coordinates |
| SphereMesh | A surface description with radius and height | Visible radius while keeping the centre |
| marker / MeshInstance3D | The node displaying that surface | Its position is assigned from point_position |
| StaticBody3D and CollisionShape3D | A fixed body participating in physics and its attached shape | Its sphere radius, independently of the visible radius |
| contact_probe.gd | Small moving CharacterBody3D feelers and contact reports | Borrowed comparison equipment; pause with Space and repeat with R |

The probe uses move_and_collide; a collision returned by the physics engine stops it. Its labels report that result. The helper does not decide whether a station is solid by its name or by the visible sphere's radius. Its fixed height is 1.12 m and its feeler has a small width, so the stopping position includes that width and the physics margin. It is a contact comparison, not a ruler for the sphere's radius.

The three stations are placed separately by study.tscn. The same point_position value is relative to each station, so the spheres appear side by side. The next chapter makes reference frames explicit.

The position in position.gd is a local value inside _ready(); with no constructed child it draws nothing. In the later scripts, _ready() constructs nodes and attaches them to the station; those nodes remain in the scene after the function ends.

Neither declaring a grabbable group nor connecting unexplained signals creates an XR pickup here. Point Coordinates identifies the supplied museum pickable and keeps the missing portable XR starter explicit. Distance thresholds belong to Lines; proximity is not object identity.
