# The tape: one student, the first two weeks

1 October 2026. This is a playback, not a record. Nobody has taken this course. I read every lesson of the short track in order, as the student would meet it, and wrote down what happens at the desk minute by minute.

Three kinds of statement are kept apart:

- **The page.** What the lesson says and what the kit shows when it runs. The kits were run in Godot 4.6; the pages were read on 1 October.
- **Measured.** Word counts, code blocks, download sizes, indentation: counted from the files.
- **Imagined.** Everything the student does, thinks and gets wrong, and every clock time. These are my estimates.

## Who, where

Juno is a second-year art student. They have used Blender a little and have never programmed. Their own Windows laptop. English is their second language. The class is twelve people and one teacher, 10:00 to 12:00 and 13:00 to 15:30: four and a half hours a day.

Two things the tape has to assume, because the course does not yet provide them:

- **The pages reach the students.** Today the course is served from one machine, at localhost:3003. The tape assumes the class can open it.
- **Someone walks the hall.** Each lesson begins "in its hall", and the four Point lessons before Trace mention the museum or the hall 19 times. A study kit has no hall in it. The tape assumes the teacher walks the hall on the projector for ten minutes before each lesson.

## What each stop costs

| stop | words | code blocks | marked "not watched" | my estimate |
|---|---|---|---|---|
| Day Zero | 1175 | 0 | 0 | 60 min |
| Point Zero | 661 | 3 | 0 | 40 min |
| Point One | 804 | 5 | 0 | 50 min |
| Point Coordinates | 715 | 4 | 0 | 40 min |
| Point Lines | 664 | 2 | 0 | 40 min |
| Point Trace | 3111 | 19 | 7 | 180 min, two sessions |
| Break it on purpose | 2400 | 28 | 13 | 110 min |
| Checkpoint | 1385 | 0 | 4 | 120 min |
| Plane | 4131 | 21 | 5 | 200 min |
| Cube | 4190 | 17 | 7 | 210 min, with the export |
| Decide, and keep a field note | 488 | 1 | 0 | 30 min |
| Organism | 3626 | 20 | 5 | 180 min |
| A body of parts | 3943 | 14 | 5 | 180 min |

Words and blocks are measured. "Not watched" counts the steps a page marks *(editor)*: 46 in all, each one a click in Godot's own windows that was described and never seen. The minutes are imagined.

## Day 1, in real time

**10:00.** Day Zero is on the projector and on Juno's screen. The first 246 words are about what it means to arrive late in a world of instructions. Juno reads them. Two people at the next table have already started the download.

**10:04.** "Get one project running." Juno follows the link to the Godot archive, takes Standard for Windows, and unzips it. The folder holds two programs, one with "console" in its name. The page does not say which. Juno opens the other one. It is the right one.

**10:11.** The Day Zero project: a zip of 5.5 KB. Juno extracts it and, as the page asks, makes a clean copy beside it.

**10:15.** Project Manager, Import, `project.godot`. The editor opens on an empty grey view. The page says "Open `base.tscn`". Juno looks for it for a minute, finds the file list at the lower left, and double-clicks.

**10:19.** F5. A window: a lit floor, and above it "Hello, world." The page says the Output panel shows the same words. The panel is at the bottom of the editor, behind the new window. Juno finds it.

**10:23.** Juno stops the project, selects Welcome, changes its Text to "hej, golv", saves, runs. The floor says "hej, golv". This is the first thing Juno has changed that reached the running scene, 23 minutes in.

**10:24.** The rest of the page: 167 words on what was supplied, then 278 words on putting the work on a Quest. Juno reads about Android export templates and has no headset.

**10:32.** Juno is done. Three people are still importing. One has opened the zip without extracting it. The room is through at 10:50.

**10:50.** The teacher walks Point Zero's hall on the projector. A panel on a wall counts frames.

**11:00.** Point Zero. It is a new project: a second download (9 KB), a second import. Nothing on the page says that every stop is its own project. Juno works it out.

**11:05.** `hello_world.gd` is open and holds the finished counter. "Replace its contents with the short greeting below." The teacher has asked the class to type and not paste. Juno types four lines.

**11:08.** A red line. Juno wrote `func _ready()` with no colon. The page has no word for this: Day Zero and the four Point lessons before Trace never mention an error. The teacher points at the end of the line. Two minutes.

**11:11.** F5. "Hello, world." above the floor. Juno changes the words and runs again.

**11:15.** The counter. A number races under the greeting. The neighbour's number races faster. Juno asks why. The answer is on the page for day 2: a count per frame measures the machine.

**11:24.** "Once, or repeatedly?" Juno moves two lines from `_process` into `_ready`. The number is 1 and stays 1. Juno thinks it is broken, then reads: "The engine continues running; our counting instruction now happens only when this node becomes ready." This is where the lesson lands.

**11:31.** "Whose beginning?" The museum's panel counts the engine's frames, not ours. Juno saw that panel forty minutes ago, on the projector. Without the hall walk this paragraph is about something Juno has never seen.

**11:36.** Done: 36 minutes.

**11:40 to 12:00, 13:00 to 13:40.** Point One. Three stations, three scripts. At the first, Juno changes 1.12 to 1.7 and nothing appears: the page meant that. At the third, `sphere_shape.radius = 0.35`, and the pink feeler stops in empty air a hand's width from the sphere. Juno says "oh". A surface and a boundary are two things.

**13:50 to 14:35.** Point Coordinates. The page opens with 253 words on holding the point in a headset. Juno skips to the desk study. Changing the root's X to 2.0 moves everything and the picture looks the same; the two printed lines, local and world, are the only place the change shows.

**14:35.** Four stops. An hour is left. The plan gives day 1 two stops.

## Days 2 to 5: the moments

**Day 2, 10:30. Lines.** "While running in the editor, use the Remote scene tree to change B's position." Nobody has shown Juno the Remote tree. The teacher shows the room. Where to click is described in the checkpoint, a day later.

**Day 2, 11:15. Trace, first session.** 19 code blocks and 18 runs. This is where the course first shows an error: `trace.append("here")`, on purpose, about five hours of work in. Then the swapped `or`, and the game pauses on a line for the first time. The kit's scripts are indented with tabs from here on; the three kits before used spaces (measured). The page explains the message for mixed indentation.

**Day 3. Break it on purpose, then the checkpoint.** Seven times the page asks: predict, which line will the message name? Then the lessons close and Juno records the trace of a pink feeler from Point One with the recorder from Trace. There is no reference answer.

**Day 4, 11:20. Plane: the prediction.** Juno has walked a loop, closed it, filled it. The page says: write your prediction before you render. Four values of `side`; which two will look most alike from above, and which will be missing? Juno writes: "0 and 1, both clockwise. 3 missing?" Then looks. The closest pair is 0 and 3. Value 2 is the missing one. 0 and 1 cover the same pixels, one white, one grey. Juno was wrong on both counts, and after the table can say why.

**Day 4, 11:40.** At value 2, seen from above, the marble rests in the air inside a pink outline. The eye and the body disagree, and Juno made both.

**Day 4, 14:10. "In your room", first time.** One sentence holds four editor moves: New Inherited Scene, clear the root's script, attach a new one, save as `room.tscn`. All four are marked not watched. This is the likeliest place in week 1 for half the room to stop.

**Day 5. Cube.** Juno writes one face, hands five to a drafter with three lines of instruction, and checks what comes back. Most of its faults give no message. Then the first export: Godot asks for export templates, a large download, on the class network, twelve at once. Then the room moves: "Copy `room.tscn`, `room.gd` and `my_plane.tres` from your Plane folder into this one." From here on the room is carried by hand, three files at a time, at every stop.

**Day 5, 15:00. Decide, and keep a field note.** Juno goes back to the plane's prediction and writes the first note. Decision: follow. Reason: "3 had no shadow and I do not know why."

## Week 2: two moments

**Organism.** The axis is where the pivot sits. "Become it" asks Juno to attach the limb to their hand and cut a passage through a lattice. At a desk the hand is the point B, moved with the keys.

**A body of parts.** The lesson opens "Find the family in the hall" and then says that its hall shows no family: three works with a declared axis, each standing once. Later it asks Juno to get a part from a classmate, with the scripts it names, and copy the files into their own folder. It is the first time something made by another person enters Juno's room.

## Where the tape stops

Each line: what stops the student, and whether a page covers it.

1. **The pages live on one machine.** Not covered. Nothing in the course says how a class gets the pages and the kit downloads.
2. **The hall.** Not covered. Every lesson leans on a hall the kit does not contain. Someone has to walk it for the class, or the hall readings have to carry pictures.
3. **The first red line comes on day 1; reading an error is taught on day 2 and day 3.** Not covered. Point Zero needs two sentences about the red line and the colon.
4. **Every stop is a new project.** Said once, in the course intro. Thirteen kits, thirteen imports.
5. **The room is carried by hand.** Covered, as three files to copy at each stop. If one copy goes wrong the room is gone, and no page says how to get it back.
6. **Editor moves nobody showed.** The Output panel, the Remote tree, New Inherited Scene. 46 steps are marked not watched. They need one page of pictures, made by someone looking at the editor.
7. **Spaces, then tabs.** The kits change between Coordinates and Lines. Explained in Trace, after the change.
8. **Headset passages at a desk.** Day Zero's Quest route and the opening of Coordinates: 531 words a desk student reads and cannot do. The intro says so; the pages do not mark them.
9. **The sheet needs a terminal.** The comparison stills are made by a command with the Godot program's path in it. The page gives the measured table, so the student can go on without it.
10. **Export templates on day 5.** One line in the Cube page. The teacher should fetch them before class.

## Does it fit?

By these estimates, yes, but not as the plan lays it out. The plan gives days 1 to 3 two stops each. That leaves day 1 with an hour and forty minutes of work, and leaves the error workshop, the checkpoint and the field note with no day at all.

A packing that holds, with ten minutes of hall before each hall stop:

| day | stops | minutes of 270 |
|---|---|---|
| 1 | Day Zero, Point Zero, Point One, Coordinates | 220 |
| 2 | Lines, Trace (both sessions) | 240 |
| 3 | Break it on purpose, Checkpoint | 230 |
| 4 | Plane; the scanning session has an hour, not an afternoon | 270 |
| 5 | Cube with the export, the field note | 250 |
| 6 to 10 | Organism, Body of parts, Chessboard, Family, Collage, one a day | about 190 each |

Day 4 has no slack. Week 2 has about eighty minutes a day for the room.

## What the tape changed

One thing, on 1 October. The stop list had the error workshop and the checkpoint after the cube. Both pages say "after Point Trace", the checkpoint asks only for the studies up to Trace, and the cube speaks of the workshop as past. The order is now Trace, Break it on purpose, Checkpoint, Plane, Cube, the field note. The checkpoint's last line, which announced a room called `my_room` that no longer exists, was rewritten.

Everything else on the list above is open.
