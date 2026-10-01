# The contract: one course candidate (2026-09-30 auto-research)

Palle: "try to find a good middle ground that has a logical progression relating to the spine but not forced by it". Every candidate is a whole course in this shape, so candidates can be scored and bred side by side. Read BRIEF.md, APPLICATION.md, QUEER3D.md (all in this folder) first.

## Who it is for
- Art and design students who have never programmed (Konstfack), and the teachers who run the course.
- Two tracks: SHORT (three weeks, ending in a mini project shown to the class; prerequisites it skips are supplied and named) and LONG (about a year; like Palle's one-year programming course for professional artists).
- Godot 4.6. VR is the project's primary medium: desktop first is allowed, but the headset route must be reachable (the desktop body can later be swapped for the XR body).

## Every chapter braids four strands and three layers
Strands: CODE (one programming idea first met, named from the vocabulary below; returns allowed) - BODY (a body the student builds in code) - ARGUMENT (a family of that body: one axis, 3-5 values, a PREDICTION written before rendering - which two will look most alike and why - and a one-sentence CLAIM the comparison image supports; the axis must be visible in a still) - PLACE (where a body meets it: stand on it, walk through it, carry it, become it).
Layers (Palle's Queer 3D World intro): FOUNDATION (the lab: how it works), DEBT (the uncanny and algorithmic debt: what the approximation owes or hides - pseudo-randomness, the blob aesthetic of noise, recursion that must be stopped, polycount against smooth deformation, bias), ONTOLOGY (the body leaves the lab: hybrid or impossible space). Foundation is the chapter itself; DEBT and PLACE/ontology must be filled.
Lesson rhythm: predict, run, investigate, modify, make (PRIMM), plus the prediction and the comparison image, plus one planted bug whose message the student reads.

## Relation to the spine (related, not forced)
- Every chapter names the spine sequence(s) it draws on ('spine') and the halls that carry it or are visited ('halls', role carrier / field trip / encounter). Halls must exist (spine.json in this folder lists all 25 sequences and 204 halls).
- The chapter ORDER may depart from the spine. Each departure carries a 'departure' note saying why a student needs it earlier or later (or that it is a deliberate return). Silent reordering is a fault.
- Not every hall needs a chapter; encounters stay encounters. The standing rulings hold where a chapter uses those halls (doc/book/TUTORIAL_LINEAGE.md: list before append; condition before a distance threshold; distance belongs to Point Lines; pickup belongs to Point Coordinates; grids are not prerequisites for the first line; reflect halls need no compulsory code). The existing /course opening (Day Zero -> Point Zero -> Point One -> Point Coordinates -> Point Lines -> Point Trace, runnable kits in doc/book/studies/) and the runnable random-definition kit are assets a candidate may use in any position.

## Code vocabulary (use these ids in code_new / code_returns; 'other:<short>' only if nothing fits)
statements, output, errors, variables, types, expressions, calling, properties, methods, functions, parameters, return, lifecycle, delta, conditions, booleans, loops, nested_loops, arrays, packed_arrays, dictionaries, strings, vectors, transforms, basis, trig, interpolation, random, seeds, noise, classes, inheritance, composition, export, setters, tool_scripts, signals, input, await, timers, instancing, groups, lifetime, recursion, stacks, queues, state_machines, buffers, meshes, surface_tool, normals, uv, materials, shaders, uniforms, multimesh, physics_bodies, collision, areas, raycasts, forces, integration, camera, player, ui, audio, particles, navigation, graphs, search, sorting, resources, files, json, save_load, profiling, threads, debugging, testing, export_build, xr, import_assets, ai_assist
(ai_assist = directing and checking generated code: what should change, what must not, what observation would show it is wrong.)
LADDER: never return an idea before the chapter whose code_new introduces it.

## The JSON (return it; also write it to the file your task names)
{ "id", "anchor" (the reference course/tradition it grew from), "title", "thesis" (one paragraph for the student: why this order),
  "parts": [{"id","title","promise"}],
  "tracks": [{"id":"short","title","length","chapters":[ids],"mini_project"}, {"id":"long", ...}],
  "chapters": [{"id","n","part","title","spine":[sequence names],"halls":[{"map","role"}],"code_new":[ids],"code_returns":[ids],
     "body","argument":{"axis","values":[..],"predict","claim"},"debt","place","godot":[..],
     "lineage":{"processing","noc","application_wp","klee","reference"},"departure" (string or null),"project_step","tracks":[..]}],
  "learned_from": [what this candidate takes from comparable courses] }

## How candidates are scored
Mechanical (computed by the workflow from the JSON): ladder violations; unknown code ids; order agreement with the spine (fraction of chapter pairs in spine order; a band around 0.6-0.95 scores best = related, not forced) and whether departures are declared; spine coverage (sequences touched / 25); halls that exist; load (chapters with more than 3 new code ideas); coverage of the 2023 application's algorithms; coverage of what a small complete game needs (player, input, camera, ui, save_load, audio, export_build, physics, instancing, signals); every chapter has debt and place; a short track with a mini project; xr, import_assets and ai_assist present.
Judged (independent agents, 1-10): student logic; Ada intent (bodies, visual argument, critical depth, the three layers, the queer lens); teachability (a teacher can run it; supplied parts named; both tracks work); Godot competence (breadth to make and ship).
