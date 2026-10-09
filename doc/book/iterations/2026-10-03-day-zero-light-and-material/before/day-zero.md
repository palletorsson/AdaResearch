# Day Zero — Hello, world

*Part of the preface · preparation before Point Zero*

“Hello, world.”

Two words are often offered as the beginning of programming. Before they can appear, a computer must have somewhere to run the instruction. We need the right program, a project it can open, files it can find, a place to see the result. The sentence is small. The arrangement that lets it happen is not.

We give that arrangement a day of its own. Day Zero is time set aside for downloading, configuring, waiting, asking for help and trying again. Some people will need less time; others will need more. Having the tools ready is work, and the book should not quietly ask the first point to carry it.

By the time we enter Point Zero, we have already accepted a considerable inheritance. Someone made the editor. Someone wrote the renderer, the player controller and the code that follows a hand. We can begin using these things before we can explain their construction. “You arrive late” also means this: even our first successful instruction arrives in a world of instructions already at work.

Borrowing gives us time to investigate something smaller. It also gives that investigation conditions. A supplied camera chooses a view. A player controller decides how movement is received. A pickup system determines what can be held and how it follows a hand. We name these parts so that beginning with them does not make them disappear.

## One world to work in

The course builds a collection of works within Ada. We begin with a prepared world, then make things we can place in it: a point, a line, a trace, a body that changes. Each study should be small enough to inspect and change, and able to return to the room that gave it a question.

Day Zero establishes the shared environment, including XR Tools and the headset route. Later tutorials assume it is working. A study may also have a small desktop version for testing without a headset. The lesson states which environment it needs and what has already been supplied.

The [student starter](/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) supplies this working room, including the chosen XR Tools add-on and a desktop route. The full museum and the smaller desktop studies remain available. The [course-world agreement](course/COURSE_WORLD.md) explains how they fit together.

## Get one project running

Use the student starter for the shared course world. For the XR route, establish its player and device connection during Day Zero too. Both routes support the same learning progression; a lesson that depends on hands or bodily movement names that requirement.

The test edition uses **Godot 4.6 Standard** and GDScript. Keep the version named by the study while following its examples. The [Godot 4.6 archive](https://godotengine.org/download/archive/4.6-stable/) provides the editor for your operating system; these exercises do not require the .NET edition.

Download and extract the [student starter](/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip). Import its `project.godot` in Godot's Project Manager and let the first import finish. Open `main.tscn` and run the project. It starts on desktop by default. Click to look, use WASD to walk, and approach the pink cube. Aim at it and press E to pick it up; press E again to let go. R returns it to the plinth. Esc releases the mouse.

Open `studies/hello_world.gd`. Change `count += 1` to `count += 2`, save and run again. The counter now takes steps of two. Restore the original line. Point Zero will explain this script; here we are checking that an edit reaches the running world. The [starter guide](studies/ada-xr-starter/README.md) identifies the supplied room and player, the study, and the headset controls.

## The small desktop check

For a simpler first editor exercise, the older [Day Zero desktop project](/book-review/doc/book/iterations/2026-09-29-day-zero-hello-world/day-zero.zip) is still available. It contains a fixed camera and greeting, with no player or XR tools. Keep the folder somewhere you can find again, and keep a clean copy before experimenting.

There are two files to recognise:

- `project.godot` identifies the project and its settings, including which scene starts.
- `base.tscn` holds the prepared scene: camera, light, floor, environment and greeting. This particular scene contains its own resources, so it can also be copied into an existing project.

A scene is part of a project. The small project download supplies both. If you already have a suitable project, you can also take [base.tscn by itself](/book-review/doc/book/iterations/2026-09-29-day-zero-hello-world/base.tscn).

Open Godot's Project Manager, choose **Import**, and select the extracted `project.godot`. Open the project and let its initial import finish. This is the point at which the editor finds and prepares the project's resources. Godot's [Project Manager guide](https://docs.godotengine.org/en/4.6/tutorials/editor/project_manager.html) covers importing an existing project.

Open `base.tscn`. Run the project with the editor's **Run Project** button, or F5 with the default keyboard shortcuts. The room should show “Hello, world.” The Output panel should receive the same words.

Stop the project. Select **Welcome** in the Scene tree. In the Inspector, change its **Text** to words of your own. Save the scene and run again. Both the displayed greeting and the Output panel should now contain your words. You have changed something in the saved project and seen that change reach the running scene.

For this project, F5 starts `base.tscn` because it is the main scene. **Run Current Scene**, normally F6, starts whichever scene is open. Later studies may have more than one scene. Learn that distinction here, along with stopping and saving, so it can become an ordinary part of working. The Godot [first-script lesson](https://docs.godotengine.org/en/4.6/getting_started/step_by_step/scripting_first_script.html) is a further introduction to the editor and running code.

## Know what has been supplied

The base gives us a lit floor and a fixed view. We have not yet constructed a player. This desktop scene contains no walking, hands or XR add-ons. The later studies create their lesson objects in code, with the camera, room and player context identified separately. Point Zero now creates its own display; its local study base omits Day Zero's prepared greeting.

The full museum supplies much more. In the current course project, `project.godot` enables the bundled **Godot XR Tools 4.5.1** add-on and starts `commons/scenes/vr_staging.tscn`. The player, movement and pickup systems are working material to inherit. Their construction is not an entrance examination for the point.

Godot's OpenXR support connects the application to an XR runtime. XR Tools supplies reusable interaction components above that connection. Installing a toolkit and designing a player's behavior are different pieces of work. When using the course project, keep its supplied add-ons together rather than replacing them individually while learning. The [XR Tools project](https://github.com/GodotVR/godot-xr-tools) documents the library and its version compatibility.

## The Quest route

Putting the work on a headset is another setup task for Day Zero. Use the student XR starter or the full Ada project for this route. Exporting the fixed-camera desktop base by itself does not give it tracked eyes or hands.

First establish that the XR scene responds to head movement and that its intended controls work. The scene needs its XR origin, tracked camera and configured input. The [Godot 4.6 XR setup guide](https://docs.godotengine.org/en/4.6/tutorials/xr/setting_up_xr.html) explains their relation and the OpenXR settings. We are learning to recognise and test this supplied arrangement before undertaking its construction.

For a connected computer headset, the student starter's guide explains enabling OpenXR in Project Settings. Do that once the runtime and headset are available. The Android version already has an override enabling OpenXR. Both use the same room and study.

For standalone Quest deployment, follow the versioned [Android export setup](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html): install the matching Godot export templates, Java and the Android SDK, then give Godot their locations. The guide lists the required tool versions. These are tools on the development computer; installing them does not alter the lesson's algorithm.

Then follow the [XR deployment guide](https://docs.godotengine.org/en/4.6/tutorials/xr/deploying_to_android.html) for the Android export preset, OpenXR mode and device connection. Enable the headset's developer access and authorise the connection as its vendor documentation requires. The Godot 4.6 guide treats the OpenXR vendor plug-in as optional but recommended; the course project's selected configuration should be kept together.

A successful export is only one part of this first test. Open the application on the headset, look around, use the intended movement and pick up a supplied test object. Seeing an image proves less than having these relations work. Resolve setup problems here before asking the first hall to explain them.

The student starter has been checked on desktop and with simulated controller input. Physical head tracking, controller feel and a standalone Quest deployment have not been verified as part of this edition. Its download includes XR Tools and core OpenXR configuration, but no vendor plug-in or built APK.

## Leave Day Zero with a place to work

You should now be able to locate your project, open the intended scene, change a value, save, run, stop and return to the saved change. If you are following the Quest route, the supplied player should also respond on your device. Keep that working state.

The later making passages assume these actions. They can begin with a point or a rule, and spend their attention on what is new. If a setup problem returns, come back here.

Hello, world. We have made contact with something we did not make from the beginning.

Now we can arrive in the first room.
