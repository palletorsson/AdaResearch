# Point Zero — Hello, world

A Godot 4.6 Standard project following Day Zero. The main scene is hello_world.tscn and the learner script is hello_world.gd. Setup and running are assumed; TUTORIAL.md introduces the code.

The download starts with the completed running counter. The tutorial first reduces it to a greeting in _ready(), then introduces a retained count and _process(). Moving the update into _ready() makes the number stay at one; changing the increment changes the sequence.

Supplied parts: an unchanged Day Zero base.tscn, a Greeting Label3D and a Counter Label3D. The inherited Welcome label is hidden. The script assigns the text of the two displays. No plugins, fonts or external assets are needed.

This counter records calls received by this node. The museum's frame_counter_display defaults to Engine.get_process_frames(), whose count starts with the engine. It has a different starting reference. This study does not reproduce the full museum console or its other display modes.

Fixed-camera desktop study; no walking or headset setup. Actual tutorial code and variations are verified natively. A beginner learner trial remains distinct from execution checks.
