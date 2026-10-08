# Day Zero: editions and verification

Moved out of [day-zero.md](day-zero.md) on 8 October 2026 (repair 3 of
[course/VOICE_DECISION.md](course/VOICE_DECISION.md): the page back to one page, its
revision history here). The sentences are kept as they were.

## The current starter (6 October 2026 edition)

Its 15 Primitives lessons now run the same complete programs printed in the book. It supplies another host for those studies, not another lesson order.

The Point Zero lesson uses `point_zero.tscn` and `lessons/Point_Zero/counter.gd`, which reads the engine frame total; the setup check in `studies/hello_world.gd` only confirms that an edit reaches the running world.

## Renderers

The desktop studio uses Forward+. The Android version uses a lighter Compatibility configuration; the starter guide also explains choosing it on a computer.

## The older fixed-camera desktop kit (29 September 2026)

The old fixed-camera exercise is an optional setup alternative. Use the current starter's lesson list for the book; older pilot programs are historical.

For a simpler first editor exercise, the older [Day Zero desktop project](/book-review/doc/book/iterations/2026-09-29-day-zero-hello-world/day-zero.zip) is still available. It contains a fixed camera and greeting, with no player or XR tools. Keep the folder somewhere you can find again, and keep a clean copy before experimenting.

There are two files to recognise:

- `project.godot` identifies the project and its settings, including which scene starts.
- `base.tscn` holds the prepared scene: camera, light, floor, environment and greeting. This particular scene contains its own resources, so it can also be copied into an existing project.

A scene is part of a project. The small project download supplies both. If you already have a suitable project, you can also take [base.tscn by itself](/book-review/doc/book/iterations/2026-09-29-day-zero-hello-world/base.tscn).

Open Godot's Project Manager, choose **Import**, and select the extracted `project.godot`. Open the project and let its initial import finish. This is the point at which the editor finds and prepares the project's resources. Godot's [Project Manager guide](https://docs.godotengine.org/en/4.6/tutorials/editor/project_manager.html) covers importing an existing project.

Open `base.tscn`. Run the project with the editor's **Run Project** button, or F5 with the default keyboard shortcuts. The room should show “Hello, world.” The Output panel should receive the same words.

Stop the project. Select **Welcome** in the Scene tree. In the Inspector, change its **Text** to words of your own. Save the scene and run again. Both the displayed greeting and the Output panel should now contain your words. You have changed something in the saved project and seen that change reach the running scene.

For this project, F5 starts `base.tscn` because it is the main scene. **Run Current Scene**, normally F6, starts whichever scene is open. Later studies may have more than one scene. Learn that distinction here, along with stopping and saving, so it can become an ordinary part of working. The Godot [first-script lesson](https://docs.godotengine.org/en/4.6/getting_started/step_by_step/scripting_first_script.html) is a further introduction to the editor and running code.

The base gives us a lit floor and a fixed view. We have not yet constructed a player. This desktop scene contains no walking, hands or XR add-ons. Point Zero now creates its own display; its local study base omits Day Zero's prepared greeting. The full museum supplies much more.

Exporting the fixed-camera desktop base by itself does not give it tracked eyes or hands.

## What has been verified

The student starter has been checked on desktop and with simulated controller input. Physical head tracking, controller feel and a standalone Quest deployment have not been verified as part of this edition. Its download includes XR Tools and core OpenXR configuration, but no vendor plug-in or built APK.

