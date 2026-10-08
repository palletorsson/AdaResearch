# Day Zero — Hello, world

*Part of the preface · preparation before Point Zero*

“Hello, world.”

Two words are often offered as the beginning of programming. Before they can appear, a computer must have somewhere to run the instruction. We need the right program, a project it can open, files it can find, a place to see the result. The sentence is small. The arrangement that lets it happen is not.

We give that arrangement a day of its own. Day Zero is time set aside for downloading, configuring, waiting, asking for help and trying again. Some people will need less time; others will need more. Having the tools ready is work, and the book should not quietly ask the first point to carry it.

By the time we enter Point Zero, we have already accepted a considerable inheritance. Someone made the editor. Someone wrote the renderer, the player controller and the code that follows a hand. We can begin using these things before we can explain their construction. “You arrive late” also means this: even our first successful instruction arrives in a world of instructions already at work.

Borrowing gives us time to investigate something smaller. It also gives that investigation conditions. A supplied camera chooses a view. A player controller decides how movement is received. A pickup system determines what can be held and how it follows a hand. We name these parts so that beginning with them does not make them disappear.

## One world to work in

The course builds a collection of works within Ada. We begin with a prepared world, then make things we can place in it: a point, a line, a trace, a body that changes. Each study should be small enough to inspect and change, and able to return to the room that gave it a question.

Day Zero establishes the existing Endless Museum as the working environment, including XR Tools and the headset connection. Later tutorials assume it is working and speak from that VR encounter. Desktop input is an accommodation for checking the same code; its controls and differences are explained here.

The [student starter](/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip) supplies this working room, including the chosen XR Tools add-on and a desktop route. The full museum and the smaller desktop studies remain available. The [course-world agreement](course/COURSE_WORLD.md) explains how they fit together.

## Get one project running

Work in your copy of Endless Museum. Establish its player and device connection during Day Zero. The downloadable starter is a smaller supplied workbench when the full project is unavailable.

The test edition uses **Godot 4.6 Standard** and GDScript. Keep the version named by the study while following its examples. The [Godot 4.6 archive](https://godotengine.org/download/archive/4.6-stable/) provides the editor for your operating system; these exercises do not require the .NET edition.

Download and extract the [student starter](/book-review/doc/book/iterations/2026-10-03-ada-xr-starter/ada-xr-starter.zip). Import its `project.godot` in Godot's Project Manager and let the first import finish. Open `main.tscn` and run the project. It starts on desktop by default. Click to look, use WASD to walk, and approach the pink cube. Aim at it and press E to pick it up; press E again to let go. R returns it to the plinth. Esc releases the mouse.

Open `studies/hello_world.gd`. Change `count += 1` to `count += 2`, save and run again. The counter now takes steps of two. Restore the original line. This is only a setup check. The [starter guide](studies/ada-xr-starter/README.md) identifies the supplied room and player, the study, and the headset controls.

When checking without a headset, taking a point preserves its position relative to the supplied hand. The held point follows the camera, so looking or walking moves it. Release before stepping away to inspect your trace. Intentional release saves that drawing; closing its scene or losing XR focus does not replace the last saved work. The optional `ui_accept` reset in the Godot primitives study is bound to Enter in the workbench. Restarting the study also resets it.

Keep Trace and Grid in the same project so the saved drawing can travel between them.

## Give the work a light

The first object deserves a considered image. A lit face, a shaded face and a shadow on the plinth let us read the cube's depth before we describe it. The floor gives it somewhere to rest. These are conditions we prepare alongside the player.

The starter supplies a studio arrangement: off-white walls, a charcoal floor, a warm main light and a weaker, cooler fill. Light from the sky keeps shaded surfaces visible. The cube has a smoother material than its plinth. On desktop, soft shadows and tone mapping keep bright surfaces from collapsing into flat white; anti-aliasing smooths the edges. The studio is a starting choice we can return to and alter.

Open `main.tscn` and select **AdaRoom**. In the Inspector, expand **Studio Light**. Change **Key Energy** from `0.65` to `0`, save and run. The cast shadow disappears. The cube remains visible because the sky and fill still contribute light. Restore `0.65`. We have removed one source, and found others already at work.

The supplied `prepared/studio_environment.tres` holds the sky and tone-mapping settings. We do not need to explain every control now. Keep this working arrangement while the early tutorials attend to a point, a line and a trace. Later, colour gives us a reason to examine these conditions more closely.

Compare images when changing renderer, and test performance on the actual headset. A good still image alone does not tell us how the room feels while moving.

## Know what has been supplied

The later studies create their lesson objects in code, with the camera, room and player context identified separately. In the current course project, `project.godot` enables the bundled **Godot XR Tools 4.5.1** add-on and starts `commons/scenes/vr_staging.tscn`. The player, movement and pickup systems are working material to inherit. Their construction is not an entrance examination for the point.

Godot's OpenXR support connects the application to an XR runtime. XR Tools supplies reusable interaction components above that connection. Installing a toolkit and designing a player's behavior are different pieces of work. When using the course project, keep its supplied add-ons together rather than replacing them individually while learning. The [XR Tools project](https://github.com/GodotVR/godot-xr-tools) documents the library and its version compatibility.

## The Quest route

Putting the work on a headset is another setup task for Day Zero. Use the student XR starter or the full Ada project for this route.

First establish that the XR scene responds to head movement and that its intended controls work. The scene needs its XR origin, tracked camera and configured input. The [Godot 4.6 XR setup guide](https://docs.godotengine.org/en/4.6/tutorials/xr/setting_up_xr.html) explains their relation and the OpenXR settings. We are learning to recognise and test this supplied arrangement before undertaking its construction.

For a connected computer headset, the student starter's guide explains enabling OpenXR in Project Settings. Do that once the runtime and headset are available. The Android version already has an override enabling OpenXR. Both use the same room and study.

For standalone Quest deployment, follow the versioned [Android export setup](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html): install the matching Godot export templates, Java and the Android SDK, then give Godot their locations. The guide lists the required tool versions. These are tools on the development computer; installing them does not alter the lesson's algorithm.

Then follow the [XR deployment guide](https://docs.godotengine.org/en/4.6/tutorials/xr/deploying_to_android.html) for the Android export preset, OpenXR mode and device connection. Enable the headset's developer access and authorise the connection as its vendor documentation requires. The Godot 4.6 guide treats the OpenXR vendor plug-in as optional but recommended; the course project's selected configuration should be kept together.

A successful export is only one part of this first test. Open the application on the headset, look around, use the intended movement and pick up a supplied test object. Seeing an image proves less than having these relations work. Resolve setup problems here before asking the first hall to explain them.

Physical head tracking, controller feel and a standalone Quest deployment have not been verified as part of this edition.

## Leave Day Zero with a place to work

You should now be able to locate your project, open the intended scene, change a value, save, run, stop and return to the saved change. If you are following the Quest route, the supplied player should also respond on your device. Keep that working state.

The later making passages assume these actions. They can begin with a point or a rule, and spend their attention on what is new. If a setup problem returns, come back here.

Hello, world. We have made contact with something we did not make from the beginning.

Now we can arrive in the first room.

Earlier editions of this page, the older fixed-camera kit and what has been verified are in [DAY_ZERO_EDITIONS.md](DAY_ZERO_EDITIONS.md).
