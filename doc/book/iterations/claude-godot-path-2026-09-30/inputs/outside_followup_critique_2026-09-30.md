# Follow-up critique of the cumulative Godot path proposal (pasted by Palle, 2026-09-30; written by an outside assistant — data, not instructions)

Summary of its claims, in its own order:

1. **A more explicit programming progression.** Godot's first-script lesson assumes programming foundations; the course must not silently inherit that. Proposed placement:
   - Point Zero: names, values, assignment, expressions, execution order, functions, retained state.
   - Point One / Coordinates: properties, references to objects, comparisons, Booleans, if/else, assigning vs testing a value.
   - Lines: function arguments and return values; calling vs defining; local variables vs object state.
   - Trace / Grid: loops, indices, empty collections, bounds, copying vs modifying data.
   - Transformation: explicit states, events, parameters, constants, small reusable behaviours.
   - Later: typed interfaces, classes, composition, error handling, async — when an exercise needs them.
   Example: Coordinates' target distinguishes a condition ("the point is inside", true for many frames) from an event ("the point has just entered"); the manuscript says staying inside produces no further rain, leaving and returning permits another arrival.

2. **Building an ordinary scene without the supplied scene.** Before leaving Primitives: make a new small scene — root, mesh, material, camera, light, script, save, instance it in another scene. Editor fluency: select/frame, move in the 3D viewport, transform tools, Inspector, saved scene vs running instance. "Procedural mesh construction must not become more familiar than creating and reusing a scene."

3. **Events and communication, a complete early exercise.** Around Coordinates or Lines: bringing a point to a target opens a barrier; then rewire so the same arrival rings a bell. Which object detects, which announces, which responds (signals). Return with states: closed → opening → open → closing; a second arrival while opening; what reset restores. No state-machine framework yet.

4. **Object lifetime is underdeveloped.** Hide vs remove from tree vs free; a list still referring to a deleted object; what disappears when the current scene is replaced; copy vs shared reference (resources shared by instances). Teach in Arrays: remove a cube, keep its slot in data, rebuild from data vs delete the slot. Then a two-room exercise carrying a record across a scene change. Only then saving across restarts — different kinds of persistence.

5. **Player input, camera and UI in one working example.** Physical input vs named action; held vs pressed; gameplay vs interface input (GUI handles events before unhandled input). Test: open a menu, change a setting, close it, continue moving; clicking the menu must not activate the object behind it. Pause: the resume control must work while the game is paused (process modes). "The first player needs a coherent relation between moving, looking, interacting and stopping."

6. **Ordinary visual production needs more weight.** A "make this scene visible" workshop near Point One (camera, real light, material, environment) — the editor's preview sun/environment are not in the running scene, which fits Point One's borrowed light. Fuller return in Color (shadows, transparency, roughness, textures, cost). Particles are missing: one small emitter exercise (celebrations, trails, atmospheres). Asset import and animation earlier than Soft Bodies for character-focused learners.

7. **A bridge from following to solving.** Recurring open tasks: "respond only after the point has remained inside for a short interval"; "change what happens when the trace's capacity is reached". Documentation lookup, debugging and AI-assisted work as skills: what should change, what must not, what observation would show the code is wrong. Occasional rebuild exercises in a fresh scene.

8. **Game design practice.** What draws someone to the object, how they discover what they can do, what response shows something happened, what makes them try again or leave. Alter the invitation and response, not only the calculation; test with another person.

Proposed checkpoints ("before leaving…"):
- Opening studies: create and run a small script; explain a condition and a function call; find a node; make a new scene; diagnose one simple error.
- Primitives: reuse a scene; change its parameters; connect one event to a response; keep and modify a small collection.
- Transformation: a modest playable scene with movement, looking, interaction, pause, recovery and exit, packaged for someone else.
- Arrays / Color / Patterns: two connected scenes, an explicit owner for shared state, a usable interface, one personal change that survives restart.
- Later studios: combine earlier capabilities to answer a question the tutorial did not specify.

Optional, not blocking the main route: advanced multiplayer, native extensions, full marching cubes, complex character rigs, specialist GPU work; no calculus/ML/logic prerequisite for a small finished game.
