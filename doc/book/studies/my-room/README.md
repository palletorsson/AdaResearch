# My room

This project is yours. It is a floor under a pink sky with forty numbered places on it, and a walker, which is you. Every chapter of the course ends by handing the room one body, a *guest*. The room stands each guest on the next free place, and you walk to it.

Import `project.godot` in the Project Manager of Godot 4.6 once, and open it from there every time after. Press Play (F5): `room.tscn` is the main scene. You stand in front of place 1, where the example guest is, a lime box.

## Adding a guest

A guest is a folder. The chapter's kit has it at `guests/<name>/`.

1. Copy the folder `guests/<name>/` from the kit into this project's `guests/` folder. Copy the whole folder, with everything in it, and do not rename it.
2. Open `room.gd`. Near the top is the one list you edit:

```gdscript
const GUESTS: Array[String] = [
	"res://guests/example/example.tscn",
]
```

Add one line for the new guest, under the last one, with the comma at its end:

```gdscript
const GUESTS: Array[String] = [
	"res://guests/example/example.tscn",
	"res://guests/trial/trial.tscn",
]
```

3. Run the room. The Output panel, at the bottom of the editor, says where everybody stands:

```
My room: place 1 is res://guests/example/example.tscn
My room: place 2 is res://guests/trial/trial.tscn
```

The first line of the list stands at place 1, the second at place 2. Places 1 to 8 are the front row, left to right; 9 to 16 the row behind it. Walk to your guest.

If a line is wrong, the room does not stop. It prints one line and goes on without that guest:

```
My room: no scene at res://guests/trail/trail.tscn. Check the line in GUESTS against the folder in guests/. The room goes on without it
```

Reading that line and mending the path is ordinary. The guests after it move up one place.

You may take the example guest out of the list when your own first guest is in.

## The keys

| key | what it does |
| --- | --- |
| W A S D, or the arrows | walk: forward, left, backward, right |
| the right mouse button, or V, held | move the mouse to look around; let go and the mouse is free again |
| J | jump |
| C | change between your eyes and the camera above the room |
| M | drop a marble one metre in front of you |

The marble tells you what a guest is for a body. It rests on a guest that has a collider and falls through one that has only a mesh. You are a body too: a guest with a collider stops you, a low one you step onto (up to 0.35 m), and one with only a mesh you walk through.

If you walk off the floor you fall, and after ten metres you are put back where you started.

## What a guest must be

The room does not check these; the kit that made the guest does.

- A folder `guests/<name>/` with the scene `<name>.tscn` in it, and everything the scene needs in the same folder. It names nothing outside its folder.
- It stands on the ground at its own origin: its lowest point at height 0, its middle over the middle of the place.
- It fits in a box 1.6 m wide and deep, the dark square of a place. It may be as high as it likes.
- Its first node is a `Node3D`, or a kind of one.
- It declares no `class_name`. Two guests that declare the same name do not load together.

## The room's look

`room_look.gd` holds the room's colours and its light: `SKY`, `GROUND`, `SHADE` for the squares, `INK` for the numbers. It is yours to change. It starts as a copy of `supplied/look.gd`, the look of every kit. The walker and the marble keep the kit's look, and a guest brings its own colours.

The room runs in the look with its filter: a sky that goes from violet (`SKY_TOP`) down to a pink horizon (`SKY`), a faintly tinted ambient light, a weak second light from the other side and a soft shadow. All of it is in `room_look.gd`: change `SKY_TOP` and `SKY` and the whole sky follows.

One thing to know before you change the light: in this renderer a sun that casts shadows lights a face about three times as brightly as its energy says. That is why `SUN_ENERGY` is 0.28. Raise it much and the colours turn to white.

## What is in the folder

- `room.tscn`, `room.gd`: the room. `GUESTS` is the only thing you need to edit.
- `room_look.gd`: the room's look.
- `guests/`: one folder for each guest. `guests/example/` is the example.
- `supplied/`: the parts every kit has, the same files as in every kit. Leave them as they are.
- `verify.gd`: the room's own checks. `guest_trial.gd`: a test of one guest.
- `export_presets.cfg`: the preset `Windows Desktop`, for **Project > Export…**.

## If the room is gone

The room is this folder and nothing else. If it breaks, take a fresh copy of `my-room` from the course, copy your own `guests/` folder into it, and add your lines to `GUESTS` again. Your guests are in their folders; the list is all that has to be written again. If you changed `room_look.gd`, copy that file too.

## For whoever checks the room

From this folder; `godot` stands for the Godot 4.6 program.

```
godot --headless --path . --xr-mode off --script res://verify.gd
godot --headless --path . --xr-mode off --script res://guest_trial.gd -- <name>
godot --headless --path . --export-debug "Windows Desktop" <folder>/my-room.exe
```

`verify.gd` runs 23 checks on the room as it is shipped and writes `verification.json`; its exit code is the number that failed. A fresh copy with no `.godot/` passed 23 of 23, with no import step, in about nine seconds, and in under one with `--fixed-fps 60`. It checks: the project and its nine actions; the 15 files of `supplied/`; that `room_look.gd` starts as the kit's look and that `paint(BODY)` gives that colour; that the environment's background is SKY and the floor GROUND; the list; the example at place 1; the 40 places, 2 m apart in a row and the rows 4 m apart; the walker 4 m in front of place 1, looking through its eyes; C; M; the walker's autopilot sent to place 1 and stopped by the example guest's collider, 0.55 m from the middle of the place; the same walk to an empty place, which arrives; more than 180 frames with no error; a second copy of the example, which stands at place 2; a path with no scene, which prints its line, logs no error and leaves the room running, with the next guest at the next free place; a scene whose first node is a `Control` and a scene file that is broken, a line each; 42 guests for 40 places, 40 placed and one line. With guests of your own in the list, or a look of your own, some of these checks fail: they describe the room as shipped.

`guest_trial.gd` is the test a kit's builder runs once: with the guest's folder copied in and its line added, it runs the room 180 frames, finds the guest, walks the walker to it by the aisles and says how the walk ended. It writes `guest_trial.json`.

The export was run on the machine that made this, from a scratch copy: it took three seconds and wrote `my-room.exe` (100,557,824 bytes, the engine), `my-room.pck` (66,896 bytes, 48 files, the project) and `my-room.console.exe`. The build was started with a window and without one, ran 300 frames each time, printed `My room: place 1 is res://guests/example/example.tscn` and no error. `my-room.exe` copied alone to another folder exits with code 1 and `Couldn't load project data … Is the .pck file missing?`: the two files travel together. No build is shipped here.

Two things differ from the first plan of the room. The rows are 4 m apart and not 2: a guest may be 1.6 m deep, the walker is 0.6 m wide, and rows 2 m apart would leave 0.4 m to walk in. And there are 40 places, not 24, because the course has more chapters than 24.

Not checked: nobody has walked the room with their hands on the keys; the walker was walked by its autopilot and by actions pressed from the script. Nothing was run in a headset. No build was copied to another computer. The editor's Export window was not watched.
