# Point One — give the point a body

Current study, 30 September 2026. Open this folder's project.godot; the main scene is study.tscn. Day Zero setup and Point Zero's _ready(), _process() and named values are assumed.

Start with TUTORIAL.md. PointStudy inherits the supplied base.tscn and contains three stations: Position uses position.gd; Visible uses visible.gd; Solid uses solid.gd. These are complete learner scripts. point_position is a Vector3 value; marker is the node displaying a surface at that position.

The supplied contact_probe.gd moves three pink feelers through the stations using actual physics collision. The empty and visible-only stations let them cross; the solid station stops one. The sweep repeats. Space pauses/resumes; R repeats. Changing the collision radius moves the stopping place independently of the visible sphere. The probe stays at the supplied height of 1.12 m; restore the height after the first experiment before comparing boundaries.

CONSTRUCTION.md names the borrowed parts and their roles. The fixed-camera study needs no XR add-on or player. The museum's sun switch, pedestal sphere and bodily traversal remain encounters there. Point Coordinates owns pickup, X/Y/Z and local/world references; its desktop study is supplied separately.

The current download contains only this lesson's scripts, scene, base, project settings and documentation. Older coordinates.tscn, points.gd, DAY_ZERO.md and POINT_ZERO.md remain in the repository as historical copies; they are not this study's starting instructions or part of the new download.
