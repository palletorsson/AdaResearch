# How to follow the opening

This is the beginning of a Godot course through Ada Research. It runs from Day Zero, where we get a project to run, to a checkpoint after Point Trace, where we show what we can do. The step after the checkpoint is shown as a preview. The course uses Godot 4.6 Standard and GDScript.

The halls come in museum order. Each one gives us one new thing to make, and each start keeps what the previous one made: a script that runs, a point with a body, two named positions, a line between them, a trace of where one went.

## Two working places

**The study kits, now.** Each stop with a kit has a small Godot project under `doc/book/studies/`. Open its `project.godot` in the Project Manager. Work in your own copy and keep a clean one beside it, as Day Zero says. If something breaks badly, the clean copy is where you start again.

**The Ada course project, for the xr route.** Held and walked encounters happen in this repository's own project, with its XR player already set up. It needs the XR Tools add-on on disk, which a fresh clone does not include.

**my_room, from W02.** After the checkpoint we leave the kits. We make an empty project of our own, called `my_room`, and carry our point, segment and recorder into it. From then on the making happens there.

## Borrowed parts, and three depths

Every study lends us parts we did not make: a camera, a floor, a light, a drawing helper, a pickup system. The page names each one and says how far we go with it:

- **use**: we can operate it;
- **understand**: we have opened it and can explain it;
- **change**: we can change it or replace it ourselves.

The same three words describe what we learn. A stop may introduce something at "use" that a later stop takes to "understand". Nothing needs to be understood before it is used.

## Desktop and xr

Most stops are desktop only. Two have a headset part:

- **Day Zero** sets up the Quest route: export the course project to the headset, look around, move, pick up a test object. This route has not been verified in this edition.
- **Point Coordinates** starts by holding a point in the course project, then giving a second point the same capability. Its page says where the desktop route begins.

A group without headsets can skip those parts. No desktop step depends on them. That group does not meet the project's main medium, and its teacher should say so.

## Using this page

Each stop shows:

- **notes for this page**, where a lesson needs one: something the lesson does not say, or says in a way we found could mislead, with what we saw when we ran it;
- **the lesson**: the text to read and follow, with the code in it;
- **did it work?**: what we should see if it worked, and one contrasting case;
- **the kit**: the files to open, and the main scene that runs.

The **teacher view** adds why the stop sits where it does, which capabilities are new or return (with their depth), what is borrowed, what the stop carries forward, a prompt for the learner's own work, and the state of the stop's files and checks.

Point Trace is two sessions; its lesson marks where the first one ends.

Each stop also has a status. **Runnable** means the kit opens and runs in Godot 4.6 and the lesson can be followed in it. **Draft** means the page exists but has not passed its checks. **Planned** means it is not written yet. A stop that runs has still not been tried with a beginner or in a headset unless it says so.
