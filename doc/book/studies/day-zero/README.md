# Day Zero — Hello, world

Open this project's project.godot in Godot 4.6 Standard. The main scene is base.tscn. The Day Zero chapter explains this setup once, before the museum chapters.

The scene contains its own camera, light, environment, floor, floor collider and a greeting. It uses only built-in resources and an embedded script; base.tscn can also be copied into an existing Godot 4.6 project.

Run the project: “Hello, world.” appears in the 3D view and the Output panel. Stop, select Welcome in the Scene tree, change its Text in the Inspector, save, and run again. Both the view and output should contain the changed words. The supplied label script prints its text when it becomes ready.

This is a fixed-camera desktop construction base. No player controller, XR Tools, headset setup or Android export is included. Those belong to the separately documented museum/Quest route. Do not infer headset support from the name base.tscn.

Point One's study inherits this same base and hides its greeting. Keep a clean starter copy and use another copy for your own work. The examples use GDScript; the .NET edition is unnecessary for them.

Canonical chapter: doc/book/day-zero.md in AdaResearch.
