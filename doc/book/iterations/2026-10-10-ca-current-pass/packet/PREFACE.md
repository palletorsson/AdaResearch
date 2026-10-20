# Cellular Automata — a fresh student's reading

You are the imagined student reading a chapter within Endless Museum. Build for the pleasure of finding out; an uncertain result is worth examining. Test the instructions rather than trying to make them look successful.

Read the eight pairs in order.json. tutorial.md gives a complete small construction and its new operation; final.md reflects on installed encounters, which can be larger and have different controls. The latter is not a specification to add hidden functions to the former.

Assumed earlier skills: variables, vectors and local/world coordinates; pickup through the existing XRTools adapter; arrays, loops, functions and small classes; stored traces; meshes/materials and collision as different responsibilities; reproducible comparisons. The immediately preceding Shader chapter ended with an alternating-buffer U/V field shown on several surfaces. Its CPU/GPU implementation is not a dependency here.

Day Zero is the existing Godot 4.6 museum project with XRTools, player, camera and lighting. An empty Node3D named PointStudy hosts one lesson at a time, at unit scale. Each listing constructs all its children. Keep each working lesson in its own folder. The PointBody file is printed every time for completeness; code continuity does not automatically transport live state between halls. Full VR controls belong to the installed encounters; keyboard-only compact controls are named in the tutorial.

The evaluation may create a neutral rendered scene with camera/light and a PointStudy instance, and synthetic hand poses. Those are test fixtures, not new lesson behaviour. The declared XRTools dependency is addons/godot-xr-tools, with its project autoloads. Do not read production museum artifacts, prior CA studies, old probes, old ghost reports or solutions to fill in a missing part.

For each lesson, reconstruct the exact printed code, run it, and choose a small source variation that the text has not already solved. Before running, record a prediction; then write assertions that distinguish the expected behaviour from a plausible wrong implementation. Check state and visible receivers where relevant. Keep originals and variations separately. Account for failures before repairing anything; a faulty prediction or harness is not a book defect.

Report reconstruction barriers, progression, supplied/new/carried boundaries and the different jobs of the two texts. A successful AI test establishes executable evidence for these examples and selected transfers. It does not establish human learning, physical headset usability or every museum interaction.
