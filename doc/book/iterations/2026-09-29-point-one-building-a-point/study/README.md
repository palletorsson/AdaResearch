# Point One — building a point

A small Godot 4.6 project accompanying Point One. Import project.godot, open study.tscn, and run with F6 (or run the project with F5).

The camera, lights, floor and labels are supplied in study.tscn. The three scripts add only the point:

- position.gd: keep a local position; nothing is drawn.
- visible.gd: keep that position and give it a visible sphere.
- solid.gd: keep both, then add a matching fixed physics body.

Each script is complete. Read them in order; the later scripts retain the earlier lines. Edit a script and rerun to see the result. The positions of the three stations are set separately in study.tscn.

The accompanying tutorial is TUTORIAL.md in this folder (also canonical at commons/maps/Point_One/tutorial.md in AdaResearch). The reduction comes from commons/primitives/point/point_condition.gd: 0.14 m radius and local centre (0, 1.12, 0). Labels, finish, resolution choices and condition branches are omitted from the study scripts.

This is a fixed-camera construction exercise. It has no walking or pickup controls. The black held point and the coordinate frame remain encounters in the full museum, which supplies those systems. Physics collision is present in the right sphere and can be shown using Godot's Debug > Visible Collision Shapes.

Tested engine behavior is recorded in the accompanying review. A beginner's ability to use and understand this kit still needs a learner trial.
