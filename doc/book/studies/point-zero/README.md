# Point Zero — Hello, world

A Godot 4.6 Standard study project following Day Zero. Open project.godot. The main scene is hello_world.tscn; hello_world.gd is attached to its Node3D root. Setup and running are assumed; TUTORIAL.md introduces the code.

This ZIP is a desktop study of an Ada encounter. The course builds within a shared Ada XR environment established in Day Zero. The display/counting script is portable and takes no controller input; this download does not include that XR environment. Placing the script in the headset world still needs a separate integration check.

The script creates its own Label3D and keeps its reference in a variable. It has no node-path lookups and needs no named child nodes. Each complete tutorial example also works when attached to an empty Node3D in another prepared 3D scene. Visibility still requires a camera looking at the display, which is placed 1.5 units above its parent.

The tutorial also opens the prepared viewing context: compare the camera at z = 4.7 and z = 3.0, then compare directional light_energy = 1.2 and 0.0. Restore both values afterward. Ambient light is explicitly disabled in this study, so the floor darkens when its directional light is turned off. Label3D is unshaded by default and ignores these light changes.

The camera position exercise is specific to this desktop study. XR head tracking owns the tracked camera pose; it should not be replaced with the fixed desktop camera settings.

The download starts with the running counter. The tutorial first creates a greeting in _ready(), then introduces a retained count and _process(). Moving the increment into _ready() makes the number stay at one; changing the increment changes the sequence.

Supplied context: a floor, camera, light and environment adapted from Day Zero. The old Welcome label and its script have been removed from this study's local base.tscn. No display is stored in either scene file. The shared Day Zero project is unchanged. No plugins, fonts or external assets are needed.

The counter records calls received by this node. The museum panel reads Engine.get_process_frames(), whose count starts with the engine. This study does not reproduce the full museum console.

Fixed-camera desktop study. Code is checked both on a bare Node3D and inside this prepared scene. A beginner reading trial remains separate from execution checks.
