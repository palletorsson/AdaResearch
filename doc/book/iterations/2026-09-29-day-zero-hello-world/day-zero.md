# Day Zero — Hello, world

*Part of the preface · preparation before Point Zero*

“Hello, world.”

Two words are often offered as the beginning of programming. Before they can appear, a computer must have somewhere to run the instruction. We need the right program, a project it can open, files it can find, a place to see the result. The sentence is small. The arrangement that lets it happen is not.

We give that arrangement a day of its own. Day Zero is time set aside for downloading, configuring, waiting, asking for help and trying again. Some people will need less time; others will need more. Having the tools ready is work, and the book should not quietly ask the first point to carry it.

By the time we enter Point Zero, we have already accepted a considerable inheritance. Someone made the editor. Someone wrote the renderer, the player controller and the code that follows a hand. We can begin using these things before we can explain their construction. “You arrive late” also means this: even our first successful instruction arrives in a world of instructions already at work.

Borrowing gives us time to investigate something smaller. It also gives that investigation conditions. A supplied camera chooses a view. A player controller decides how movement is received. A pickup system determines what can be held and how it follows a hand. We name these parts so that beginning with them does not make them disappear.

## Get one project running

For the first exercises, use the desktop base supplied with this book. It lets us check a scene without setting up a headset at the same time. The Quest route below belongs to this preparation too; it adds another device to the arrangement.

The test edition uses **Godot 4.6 Standard** and GDScript. Keep the version named by the study while following its examples. The [Godot 4.6 archive](https://godotengine.org/download/archive/4.6-stable/) provides the editor for your operating system; these exercises do not require the .NET edition.

Download and extract the [Day Zero project](/book-review/doc/book/iterations/2026-09-29-day-zero-hello-world/day-zero.zip). Keep the folder somewhere you can find again, and keep a clean copy before experimenting.

There are two files to recognise:

- `project.godot` identifies the project and its settings, including which scene starts.
- `base.tscn` holds the prepared scene: camera, light, floor, environment and greeting. This particular scene contains its own resources, so it can also be copied into an existing project.

A scene is part of a project. The small project download supplies both. If you already have a suitable project, you can also take [base.tscn by itself](/book-review/doc/book/iterations/2026-09-29-day-zero-hello-world/base.tscn).

Open Godot's Project Manager, choose **Import**, and select the extracted `project.godot`. Open the project and let its initial import finish. This is the point at which the editor finds and prepares the project's resources. Godot's [Project Manager guide](https://docs.godotengine.org/en/4.6/tutorials/editor/project_manager.html) covers importing an existing project.

Open `base.tscn`. Run the project with the editor's **Run Project** button, or F5 with the default keyboard shortcuts. The room should show “Hello, world.” The Output panel should receive the same words.

Stop the project. Select **Welcome** in the Scene tree. In the Inspector, change its **Text** to words of your own. Save the scene and run again. Both the displayed greeting and the Output panel should now contain your words. You have changed something in the saved project and seen that change reach the running scene.

For this project, F5 starts `base.tscn` because it is the main scene. **Run Current Scene**, normally F6, starts whichever scene is open. Later studies may have more than one scene. Learn that distinction here, along with stopping and saving, so it can become an ordinary part of working. The Godot [first-script lesson](https://docs.godotengine.org/en/4.6/getting_started/step_by_step/scripting_first_script.html) is a further introduction to the editor and running code.

## Know what has been supplied

The base gives us a lit floor and a fixed view. We have not yet constructed a player. This desktop scene contains no walking, hands or XR add-ons. Point One's study uses the same `base.tscn`, hides the greeting and adds its three point stations. Its scripts can therefore concentrate on what gives a position a visible or physical body.

The full museum supplies much more. In the current course project, `project.godot` enables the bundled **Godot XR Tools 4.5.1** add-on and starts `commons/scenes/vr_staging.tscn`. The player, movement and pickup systems are working material to inherit. Their construction is not an entrance examination for the point.

Godot's OpenXR support connects the application to an XR runtime. XR Tools supplies reusable interaction components above that connection. Installing a toolkit and designing a player's behavior are different pieces of work. When using the course project, keep its supplied add-ons together rather than replacing them individually while learning. The [XR Tools project](https://github.com/GodotVR/godot-xr-tools) documents the library and its version compatibility.

## The Quest route

Putting the work on a headset is another setup task for Day Zero. Use the full XR course project for this route. Exporting the fixed-camera desktop base by itself does not give it tracked eyes or hands.

First establish that the XR scene responds to head movement and that its intended controls work. The scene needs its XR origin, tracked camera and configured input. The [Godot 4.6 XR setup guide](https://docs.godotengine.org/en/4.6/tutorials/xr/setting_up_xr.html) explains their relation and the OpenXR settings. We are learning to recognise and test this supplied arrangement before undertaking its construction.

For standalone Quest deployment, follow the versioned [Android export setup](https://docs.godotengine.org/en/4.6/tutorials/export/exporting_for_android.html): install the matching Godot export templates, Java and the Android SDK, then give Godot their locations. The guide lists the required tool versions. These are tools on the development computer; installing them does not alter the lesson's algorithm.

Then follow the [XR deployment guide](https://docs.godotengine.org/en/4.6/tutorials/xr/deploying_to_android.html) for the Android export preset, OpenXR mode and device connection. Enable the headset's developer access and authorise the connection as its vendor documentation requires. The Godot 4.6 guide treats the OpenXR vendor plug-in as optional but recommended; the course project's selected configuration should be kept together.

A successful export is only one part of this first test. Open the application on the headset, look around, use the intended movement and pick up a supplied test object. Seeing an image proves less than having these relations work. Resolve setup problems here before asking the first hall to explain them.

This chapter provides the setup route; the small download is the desktop base. A standalone Quest starter and a fresh headset deployment have not been verified as part of this edition.

## Leave Day Zero with a place to work

You should now be able to locate your project, open the intended scene, change a value, save, run, stop and return to the saved change. If you are following the Quest route, the supplied player should also respond on your device. Keep that working state.

The later making passages assume these actions. They can begin with a point or a rule, and spend their attention on what is new. If a setup problem returns, come back here.

Hello, world. We have made contact with something we did not make from the beginning.

Now we can arrive in the first room.
