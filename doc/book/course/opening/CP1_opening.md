# Checkpoint: the opening studies

*Its own session, after "Break it on purpose" · desktop, with one step on the xr route*

This session has no new lesson. We show what the opening gave us, with the lesson pages closed, and then do one task that nobody has solved for us. Bring your copies of the studies: Day Zero, Point Zero, Point One, Point Coordinates, Point Lines and Point Trace.

For the teacher: keep the lessons closed too. Where the learner is stuck, wait before helping, and write down each place you had to fill a gap. That record matters as much as the learner's work. It tells us where a lesson did not teach.

Some items use the editor's windows. The lessons name those steps without always showing the clicks, so the clicks are given here. They are marked *(editor)*: they describe the Godot 4.6 editor, and were not watched for this page.

## Show it

Each item is something you can show on screen or say aloud.

1. **A script that runs once, and again.** In a fresh copy of the point-zero study, clear `hello_world.gd` and write a script yourself that sets one display's text once and changes the other's every frame. Run it. Point to the line that runs once and the line that runs again, and say why each runs when it does.
2. **A condition and two functions.** In your Trace copy, explain the condition in `keep()`: what `trace.is_empty() or` protects against, and what went wrong at Break it on purpose when it was taken away. Then explain the two functions you wrote. For `keep(p)`, say what goes in and under which name it arrives, and what the function changes instead of giving anything back. For `route_length()`, say what comes back, and what comes back for an empty list and for a list of one position.
3. **Named input.** In your Trace copy, move the point with its named actions. Open **Project > Project Settings > Input Map** and show the actions. Name the file where they are stored: `project.godot`, under `[input]`.
4. **A node, two ways.** Find a node by its path in a script, such as `$Readout`. Then run the study from the editor, and find the same node in the running game: at the top of the Scene dock, click **Remote**, open the tree under `root`, and select the node; the Inspector now shows its values in the running game *(editor)*. Change one of them there, such as B's **Position**, and watch the study follow. Click **Local** to return to the saved scene.
5. **An error from its message.** Someone plants one fault in a copy of one of your studies. Find it from the message alone, without comparing files. Then find one method in the class reference that the lessons did not use, and use it.
6. **xr route.** In the Ada course project, hold the point, then give a second point the same capability, as in Point Coordinates. A desktop-only group skips this item and says so.
7. **Follow, vary, carry.** This is the check the lineage asks for. Follow the Trace exercise as it is written. Make one deliberate variation: change what happens when the recorder's capacity is reached, and say what your choice loses. The third step is the open task below.

## The open task

Record the trace of a different moving object, in another study, using the recorder you already have and no new helper.

In Trace we moved the recorder from B to A in the same scene. Here it leaves that scene. The candidate is a feeler from Point One's study: the pink feelers move through the stations by themselves. You can choose another moving thing instead. There is no reference answer.

Some things you need that the lessons did not show step by step:

- **Where to work.** In a fresh copy of the point-one study, not in your Trace copy. Copy `trace_strip.gd` from your Trace copy into it.
- **Adding a node.** Select the root, `PointStudy`, in the Scene dock and press Ctrl+A, or the **+** at the top of the dock. Search for the type, such as `MeshInstance3D`, and click **Create**. Rename it by double-clicking its name *(editor)*. The recorder needs a `MeshInstance3D` for the strip and a `Label3D` for the record.
- **Attaching a script.** Drag a `.gd` file from the FileSystem dock onto a node in the Scene dock. For a new script, select the node and click the scroll with a green **+** at the top of the Scene dock *(editor)*.
- **Finding the feeler.** The feelers are made by `contact_probe.gd` while the study runs, so they are not in the editor's Scene tree. Run the study and look in the Remote tree, under `ContactProbe`.

The recorder you already have is your `trace.gd`: the list, the gate, the capacity, `keep()`, the two lengths, and the lines that call the strip and fill the label. A script on the root made from those parts counts. Leave out the lines about A, B, the segment and the readout, which Point One does not have. A new helper would be a function your recorder did not have before. If you find you need one, stop and say what it would have to do. That is a result too.

When the trace works, say what it keeps and what it loses. The solid station's feeler stops against the sphere and waits, then the sweep starts again: does your trace show the wait? What does the start of the next sweep draw?

## Evidence

Version control arrives at W03. Until then the record is a copy.

- **A dated copy of your study folders.** Make one folder named with today's date, such as `opening-2026-10-07`, and copy your study folders into it. Leave out each project's `.godot` folder: Godot rebuilds it when the project is opened. Keep this copy unchanged.
- **The teacher's session record.** Where the learner was confused, how long each item took, and each place the teacher had to fill a gap.

## Self-check

The depth each capability should have reached by now, taken from the lessons as they are written. **Use**: you can operate it. **Understand**: you have opened it and can explain it. The opening does not yet ask for **change** anywhere.

**Day Zero**

- [ ] Open, import and save a Godot project: *understand*
- [ ] The Scene tree and the Inspector: *use*
- [ ] Run, stop, and read the Output panel: *understand* (after W01)

**Point Zero**

- [ ] Variables, and member values that last between calls: *understand* (after Point Trace)
- [ ] `_ready()` and `_process()`: when code runs: *use*
- [ ] Text, `str()` and number formatting (`%.2f`, `%d`): *understand* (after Point Trace)
- [ ] Finding a node by its path (`$Name`): *use*

**Point One**

- [ ] Nodes and resources: *use*
- [ ] Primitive meshes (`SphereMesh`, `CylinderMesh`): *understand*
- [ ] Physics bodies (`StaticBody3D`): *use*
- [ ] Collision shapes: *use*

**Point Coordinates**

- [ ] `Vector3`: positions, and changing one component: *use*
- [ ] Local and global position: *use*
- [ ] Holding a thing in XR (xr route only): *use*

**Point Lines**

- [ ] A displacement, `b - a`, and its length: *understand*
- [ ] Changing a value in the running game through the Remote tree: *use*

**Point Trace**

- [ ] Named input actions: *use*
- [ ] `@export`: changing a value in the Inspector: *use*
- [ ] Arrays: an ordered list of values, `append`, `size`, indexes from 0 and from the end: *use*
- [ ] Conditions (`if`, `or`, `!=`): *use*
- [ ] Loops that do a job: *use*
- [ ] Your own functions: one that takes a value in (`keep(p)`), one that gives a value back (`route_length()`): *use*
- [ ] Static types: *understand* (after W01)

**Break it on purpose**

- [ ] Reading Godot's error messages: `SCRIPT ERROR`, `ERROR`, warnings, the backtrace: *use*
- [ ] The debugger and `print()`: *use*
- [ ] Looking things up in the class reference: *use*

## What comes next

After this session we leave the kits. In W02 we start `my_room`, an empty project of our own, and carry our point, segment and recorder into it.
