# Next: my_room, a scene from nothing

*Workshop W02 · desktop · **planned, not yet written***

This page says what comes after the checkpoint. The lesson itself does not exist yet, and none of it has been run.

Until now every study has handed us a prepared scene: a floor, a light, a camera, an environment. In W02 we make our own project, from an empty one, and bring in what the opening made.

## What the workshop plans to do

- Create a new project called `my_room` in the Project Manager, with the Compatibility renderer, as the study kits use.
- Make two folders: `rooms/` for scenes and `shared/` for parts we reuse.
- Build `rooms/room.tscn` from an empty `Node3D` root: a floor that can be seen and stood on, and one `DirectionalLight3D`.
- Copy the camera node from a kit's `base.tscn`. The camera stays borrowed; cameras become the subject later, at Melencolia.
- Rebuild the point as `shared/point.tscn`, with its collider sized apart from its surface as in Point One, but without a kit. Drag it into `room.tscn` twice.
- Set `room.tscn` as the main scene, then carry over your segment variant and your recorder as scripts.

## What it will check

The run should show the floor lit by your own light, and the recorder should work as it did in the kit.

The plan also names a contrast, still to be confirmed at the first real run: delete the light, and the editor's view may still look lit while the running game does not, because the editor adds a preview light of its own. If that holds, it is the first time the course separates what the editor shows from what the game shows.

## What it carries

A project you made, a rule for where files go, a saved scene with instances of your own part, and one light you placed. From here on, the making happens in `my_room`.
