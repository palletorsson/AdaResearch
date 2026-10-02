# What the student already has

For chapter 13, Rules in Time (cellular automata). Everything below was taught in chapters 1 to 12.

## Types introduced earlier (the course's hard taxonomy)

### Chapter 1
- **supplied** (supplied, supplied part, supplied parts): Made for you, to use before it is taught. [1.1]
- **node** (node, nodes): One thing Godot keeps and runs. [1.1]
- **scene** (scene, scenes): Nodes that Godot runs together. [1.1]
- **editor** (editor): Godot's window, where you build a scene. [1.1]
- **scene_tree** (scene tree): The list of a scene's nodes, in the editor. [1.1]
- **base_scene** (base scene, course look, base.tscn) (supplied): Floor, sky, sun, camera and one node to place. [supplied:1.1]
- **script** (script, scripts): Text on a node, which the node runs as code. [1.1]
- **play** (Play): The editor's button that runs the scene. [1.1]
- **extends** (extends): Names the kind of node a script is for. [1.1]
- **Node3D** (Node3D): A node with a position. [1.1]
- **func** (func): Starts a named block of code. [1.1]
- **_ready** (_ready): Runs once, when the scene starts. [1.1]
- **indent** (indent, indents, indented): One tab in, which sets a line of code under the one above. [1.1]
- **$** ($): `$Name` reaches the node named Name. [1.1]
- **=** (=): Sets the left side to the value on the right. [1.1]
- **Vector3** (Vector3): Three numbers held as one value. [1.1]
- **position** (position, positions): Where a node stands, as a `Vector3`. [1.1]
- **origin** (origin): Where counting starts, at zero, zero, zero. [1.2]
- **metre** (metre, metres): The length of a count of one. [1.2]
- **axis** (axis, axes): A straight way out from the origin, counted in metres. [1.2]
- **x** (x): How far right, along the x axis. [1.2]
- **y** (y): How far up, along the y axis. [1.2]
- **z** (z): How far toward you, along the z axis. [1.2]
- **coordinate** (coordinate, coordinates): One count from the origin, along x, y or z. [1.2]
- **point** (point, points): A place given by three coordinates, with no size. [1.2]
- **mesh** (mesh, meshes): What is seen. [1.3]
- **shape** (shape, shapes): What is touched. [1.3]
- **body** (body, bodies): A node you place, with a position. [1.3]
- **MeshInstance3D** (MeshInstance3D): A node that shows a mesh. [1.3]
- **SphereMesh** (SphereMesh): A round mesh. [1.3]
- **StaticBody3D** (StaticBody3D): A body that stays put and stops things. [1.3]
- **CollisionShape3D** (CollisionShape3D): A node that holds a shape. [1.3]
- **SphereShape3D** (SphereShape3D): A round shape. [1.3]
- **feeler** (feeler, feelers, contact_probe.gd) (supplied): A cyan rod that moves and stops at a shape. [supplied:1.3]
- **Inspector** (Inspector): The editor's panel of a node's numbers. [1.3]
- **primitive** (primitive, primitives): A mesh Godot makes for you from a few numbers. [1.4]
- **BoxMesh** (BoxMesh): A box primitive. [1.4]
- **CylinderMesh** (CylinderMesh): A cylinder primitive. [1.4]
- **PrismMesh** (PrismMesh): A prism primitive. [1.4]
- **TorusMesh** (TorusMesh): A ring primitive. [1.4]
- **top_radius** (top_radius): The radius of a `CylinderMesh` at its top. [1.4]
- **segment** (segment, segments): One slice around a round mesh. [1.4]
- **radial_segments** (radial_segments): How many segments go around. [1.4]
- **line** (line, lines): The straight piece between two points. [1.5]
- **face** (face, faces): The flat piece filled between three points. [1.5]
- **call** (call, calls, called, calling): Asks a supplied part, or Godot, to do its work. [1.5]
- **line()** (line, line(a, b)) (supplied): Draws a line between two points. [supplied:1.5]
- **triangle()** (triangle, triangle(a, b, c)) (supplied): Fills a face between three points. [supplied:1.5]
- **frame** (frame, frames): One picture Godot draws before it draws the next. [1.6]
- **_process** (_process): Runs again every frame. [1.6]
- **Engine** (Engine): Godot itself, as something you can ask. [1.6]
- **get_process_frames** (get_process_frames): How many frames have run so far. [1.6]
- **Label3D** (Label3D): A node that shows words in the room. [1.6]
- **text** (text): The words a `Label3D` shows. [1.6]
- **str** (str): Turns a number into words. [1.6]
- **counter_panel** (counter panel) (supplied): A `Label3D` on a stand, named Counter. [supplied:1.6]
- **mouse_point()** (mouse_point, mouse_point()) (supplied): The point on the floor under the mouse. [supplied:1.7]
- **copy** (copy, copies, copied): A new node made from another, the same in all. [1.7]
- **duplicate** (duplicate): Makes a copy of a node. [1.7]
- **add_child** (add_child): Puts a new node into the scene. [1.7]
- **variable** (variable, variables): A name for a value. [1.8]
- **var** (var): Makes a variable. [1.8]
- **:=** (:=): Gives a new variable its first value. [1.8]
- **+=** (+=): Adds to what a variable holds. [1.8]
- **-** (-): Takes away, or turns a number the other way. [1.8]
- **/** (/): Divides. [1.8]
- **height** (height): How tall a mesh is, in metres. [1.8]

### Chapter 2
- ***** (*): Multiplies. [2.1]
- **delta** (delta): The seconds since the last frame. [2.1]
- **frame_rate** (frame rate, frame rates): How many frames Godot draws in a second. [2.1]
- **rider_code** (rider code, _translate_rider) (supplied): Carries whoever stands on a moving cube. [supplied:2.1]
- **rotate_y** (rotate_y): Turns a body around its own y axis. [2.2]
- **rotation** (rotation, rotations, rotate): A turn around an axis. [2.2]
- **scale** (scale, scaled): How many times its size a body is drawn. [2.2]
- **transform** (transform, transforms): A move, turn or growth given to a body. [2.2]
- **conditional** (conditional, conditionals): Code that runs only when a test is true. [2.3]
- **if** (if): Runs its block only when the test is true. [2.3]
- **comparison** (comparison, comparisons): A test of two values: less, more, equal, not equal. [2.3]
- **<** (<): Is less than. [2.3]
- **>** (>): Is more than. [2.3]
- **==** (==): Is equal to. [2.3]
- **!=** (!=): Is not equal to. [2.3]
- **true** (true): The value of a test that passes. [2.3]
- **false** (false): The value of a test that fails. [2.3]
- **else** (else): Runs its block when the test before it failed. [2.4]
- **elif** (elif): Asks again when the test before it failed. [2.4]
- **bool** (bool, bools, boolean, booleans): A value that is `true` or `false`. [2.4]
- **length** (length): How long a `Vector3` is: the distance it spans. [2.5]
- **queue_free** (queue_free): Takes a node out of the scene. [2.5]
- **walker** (walker, walkers, walker.tscn) (supplied): The cyan capsule you steer with WASD: the visitor. [supplied:2.5]
- **and** (and): True when both tests are true. [2.6]
- **or** (or): True when either test is true. [2.6]
- **not** (not): Turns true into false, and false into true. [2.6]
- **Input** (Input): Godot's keyboard, mouse and controller, as something you ask. [2.6]
- **is_action_pressed** (is_action_pressed, Input.is_action_pressed): Is this key held down at this moment? [2.6]
- **ui_accept** (ui_accept): The action that Space and Enter set off. [2.6]
- **lerp** (lerp) (supplied): A value part way between two ends. [supplied:2.6]
- **pingpong** (pingpong) (supplied): A value that runs to an end and back, repeating. [supplied:2.6]
- **parent** (parent, parents): The node that holds another in the scene tree. [2.7]
- **child** (child, children): A node held by another: it follows that node. [2.7]
- **$/** ($/): Reaches a child of a node by a path of names. [2.7]
- **translate** (translate): Moves a body along its own axes. [2.8]

### Chapter 3
- **loop** (loop, loops): Code that runs its block again and again. [3.1]
- **while** (while): Repeats its block as long as its test is true. [3.1]
- **preload** (preload): Loads a scene file once, when the script is read. [3.1]
- **PackedScene** (PackedScene): A saved scene, ready to make copies of. [3.1]
- **instantiate** (instantiate, PackedScene.instantiate): Makes a new node, with its children, from a `PackedScene`. [3.1]
- **collection_record** (collection record) (supplied): Per cube, 1 until it is taken, then 0. [supplied:3.2]
- **for** (for): Runs its block once for each value in turn. [3.2]
- **in** (in): Names what a `for` goes through. [3.2]
- **loop_variable** (loop variable, loop variables): The variable a `for` sets anew each time round. [3.2]
- **address** (address, addresses): Where a copy sits in a grid: its counts. [3.3]
- **grid** (grid, grids): Copies laid out in rows and columns. [3.3]
- **nested_loop** (nested loop, nested loops): A loop inside a loop: every pair of counts. [3.3]
- **lattice** (lattice, lattices): A grid that also climbs in y. [3.4]
- **flight_region** (flight region) (supplied): Lets the walker fly inside the lattice. [supplied:3.4]
- **+** (+): Adds. [3.5]
- **%** (%): The remainder after dividing. [3.5]
- **remainder** (remainder, remainders): What is left when one count divides another. [3.5]
- **reflection** (reflection, reflections, mirror, mirrors, mirrored, mirroring): A copy flipped, as a mirror shows it. [3.6]
- **diagonal_tile** (diagonal tile, diagonal tiles) (supplied): A half-black square, made with `triangle(a, b, c)`. [supplied:3.6]
- **cell_at()** (cell_at, cell_at(x, z)) (supplied): Finds a floor tile by its address. [supplied:3.6]
- **phase** (phase, phases): How far through its repeat a repeating thing has got. [3.8]

### Chapter 4
- **local_variable** (local variable, local variables): A variable that lives only inside its function. [4.0]
- **Color** (Color, Color(r, g, b)): A colour as three numbers from 0 to 1. [4.1]
- **rgb** (RGB, red, green and blue): A colour mixed from red, green and blue light. [4.1]
- **material** (material, materials): What a mesh wears: its colour and how it shines. [4.1]
- **albedo_color** (albedo_color): A material's own colour. [4.1]
- **function** (function, functions): A named block of code that takes values and answers. [4.2]
- **parameter** (parameter, parameters): A value a function is given when it is called. [4.2]
- **return** (return): Ends a function and hands its answer back. [4.2]
- **->** (->): Says what kind of value a function answers with. [4.2]
- **by_height** (by_height): Your function: a colour for a height. [4.2]
- **SpotLight3D** (SpotLight3D): A node that shines a cone of light. [4.3]
- **light_color** (light_color): The colour of a light. [4.3]
- **lamp** (lamp you can carry) (supplied): A pickup with a `SpotLight3D` inside. [supplied:4.3]
- **colour_from** (colour_from): Your function: a colour for a point in a box. [4.4]
- **from_hsv** (from_hsv, Color.from_hsv): Makes a `Color` from hue, saturation and value. [4.5]
- **hsv** (HSV): A colour as hue, saturation and value. [4.5]
- **hue** (hue, hues): Where a colour sits on the colour circle. [4.5]
- **saturation** (saturation): How strong a colour is, from grey to full. [4.5]
- **hue_for** (hue_for): Your function: a hue for one band of many. [4.5]
- **colour_at** (colour_at): Your function: a colour for any point. [4.5]
- **band_mesh** (band mesh) (supplied): The rainbow's arch of bands; you write the colours. [supplied:4.5]
- **ink** (ink): Your function: one of four colours for an address. [4.6]
- **class** (class, classes): A kind of thing you write: data and behaviour. [4.7]
- **object** (object, objects): One thing made from a class. [4.7]
- **method** (method, methods): A function that belongs to a class. [4.7]
- **class_name** (class_name): Names a class so other scripts can use it. [4.7]
- **@export** (@export): Shows a variable in the Inspector, to set per object. [4.7]
- **SprayCan** (SprayCan): Your class: a can with a colour that sprays. [4.7]
- **spray** (spray): SprayCan's method: paints its colour onto the canvas. [4.7]
- **paint_call** (paint-into-image call) (supplied): Paints a colour into the canvas picture. [supplied:4.7]
- **point_on_canvas()** (point_on_canvas, point_on_canvas(ray)) (supplied): The point on the canvas the nozzle aims at. [supplied:4.7]
- **new** (new): Makes an object from a class. [4.8]
- **Pane** (Pane): Your class: a see-through pane of one colour. [4.8]

### Chapter 5
- **size** (size): How many values an array holds. [5.0]
- **append** (append): Adds a value to the end of an array. [5.0]
- **array** (array, arrays, Array): Values kept in order, one after another. [5.1]
- **item** (item, items): One value kept in an array. [5.1]
- **cell** (cell, cells): One place of a grid, holding a state. [5.1]
- **index** (index, indices, indexes): An item's place in an array, counted from 0. [5.1]
- **[]** ([]): Makes an array, or reads one item by its index. [5.1]
- **note_per_track** (note per track) (supplied): The sound behind each step of the sequencer. [supplied:5.1]
- **AudioStreamPlayer** (AudioStreamPlayer) (supplied): A node that plays a sound. [supplied:5.1]
- **array_of_arrays** (array of arrays, arrays of arrays): An array whose items are arrays: a grid by rows. [5.3]
- **wrap** (wrap, wraps, wrapping, wrapped): Running off one end, coming back at the other. [5.4]
- **pick()** (pick, pick()) (supplied): The floor square under the pointer or the controller. [supplied:5.5]
- **Image** (Image): A picture held in memory, that code can write into. [5.6]
- **set_pixel** (set_pixel, Image.set_pixel): Sets the colour at one place of an `Image`. [5.6]
- **ImageTexture** (ImageTexture): An `Image` made ready for a material to wear. [5.6]
- **texture** (texture, textures): A picture a material wears on a mesh. [5.6]
- **wallpaper_group** (wallpaper group, wallpaper groups, wallpaper, wallpapers, P1, PM, PG, P4, P2): One way to repeat a tile: P1, PM, PG, P4. [5.7]
- **catwalk_path** (catwalk path) (supplied): The path your figures walk along. [supplied:5.8]
- **uv_repeat** (UV repeat) (supplied): How the hall repeats the pattern on the skirt. [supplied:5.8]

### Chapter 6
- **velocity** (velocity, velocities): How far a body moves in a second: a `Vector3`. [6.1]
- **acceleration** (acceleration, accelerations): How much the velocity changes in a second. [6.2]
- **gravity** (gravity): The pull down: an acceleration every body shares. [6.2]
- **fixed_step** (fixed step, step size): A step of time that does not change between frames. [6.2]
- **_physics_process** (_physics_process): Runs at a fixed step, the same on every machine. [6.2]
- **rate** (rate, rates): A rise divided by the gap it rose over. [6.3]
- **f()** (f, f(x)) (supplied): The Change_Intro curve: one height for each x. [supplied:6.3]
- **secant** (secant, secants): A line through two points of a curve. [6.3]
- **tangent** (tangent, tangents): The line a curve runs along at one point. [6.3]
- **accumulation** (accumulation): A total built by adding many small parts. [6.4]
- **field** (field, fields): A rule that gives every place its own value. [6.5]
- **flow_field** (flow field, flow fields, flow-field): A field whose value at each place is a direction. [6.5]
- **particle** (particle, particles): A body that is only a point that moves. [6.5]
- **field_direction()** (field_direction, field_direction(p)) (supplied): The flow field's direction at a place. [supplied:6.5]
- **trail()** (trail, trail(points, n)) (supplied): Keeps the last n places of a moving body. [supplied:6.5]
- **fposmod** (fposmod): A remainder that is never negative: it wraps. [6.6]

### Chapter 7
- **RigidBody3D** (RigidBody3D): A body Godot moves for you, by forces and contact. [7.0]
- **apply_central_force** (apply_central_force): Pushes a `RigidBody3D` with a force through its centre. [7.0]
- **vector** (vector, vectors): A move: a length and a direction, end minus start. [7.1]
- **unit_vector** (unit vector, unit vectors, unit direction, unit directions): A vector of length one: a pure direction. [7.1]
- **normalized** (normalized): The unit vector in the same direction. [7.1]
- **draw_arrow()** (draw_arrow, draw_arrow(from, to, colour)) (supplied): Draws a vector as a rod and a cone. [supplied:7.1]
- **dot** (dot product, dot products, dot): How much two directions agree: large along, zero across. [7.3]
- **projection** (projection, projections): The part of one vector that runs along another. [7.3]
- **mass** (mass, masses): How much a body resists a change of velocity. [7.4]
- **force** (force, forces): A push that changes velocity: acceleration times mass. [7.4]
- **apply_force** (apply_force): Your method: adds a force into this step's acceleration. [7.4]
- **drag** (drag): A force against the velocity: -c times velocity. [7.6]
- **spring** (spring, springs): A force back toward rest: -k times the stretch. [7.6]
- **attraction** (attraction, attractor, attractors): A pull between two bodies that weakens with distance. [7.7]
- **centre_of_mass** (centre of mass): The point a body balances on. [7.8]
- **support_outline** (support outline, support outlines): The outline round where a body touches the ground. [7.8]
- **Geometry2D** (Geometry2D): Godot's tools for flat geometry. [7.8]
- **convex_hull** (convex_hull, Geometry2D.convex_hull): The tightest outline round a set of points. [7.8]
- **Area3D** (Area3D): A region that notices bodies and can change gravity. [7.9]
- **body_entered** (body_entered): The signal an `Area3D` sends when a body comes in. [7.9]
- **body_exited** (body_exited): The signal an `Area3D` sends when a body leaves. [7.9]

### Chapter 8
- **slope** (slope, slopes): How steep a curve is at a place: its rate. [8.1]
- **gradient** (gradient, gradients): The slope in each direction: which way is uphill. [8.1]
- **sample** (sample, samples, sampled, sampling): One value read from a rule at one place. [8.1]
- **central_difference** (central difference, central differences): A slope from two samples, one on each side. [8.1]
- **gradient_descent** (gradient descent): Stepping against the gradient, again and again, to go downhill. [8.1]
- **-=** (-=): Takes away from what a variable holds. [8.1]
- **cost_function** (cost function, cost functions, cost surface, cost): A height to make small: lower is better. [8.1]
- **landscape()** (landscape, landscape(x, z)) (supplied): The halls' cost functions: hills and valleys. [supplied:8.1]
- **stopping_rule** (stopping rule, stopping rules): The test that says a search is done. [8.2]
- **cosh** (cosh): The curve a hanging chain makes. [8.3]
- **Curve3D** (Curve3D): A smooth path through points you give. [8.3]
- **verlet** (Verlet, Verlet integration): Next place from this place and the last one. [8.4]
- **Particle** (Particle): Your class: a particle that remembers where it was. [8.4]
- **pin** (pin, pins, pinned): A point held still while the rest moves. [8.4]
- **rest_length** (rest length, rest lengths): The length a link has when nothing pulls it. [8.5]
- **constraint** (constraint, constraints): A rule two points must keep, like a rest length. [8.5]
- **relax** (relax, relaxed, relaxing, relaxation): Pulling every constraint back toward true, pass after pass. [8.5]
- **lever_law** (lever law, lever): Balance: mass times distance is equal on both sides. [8.6]
- **calder_builder** (Calder mobile's builder) (supplied): Hangs arms from arms by calling itself. [supplied:8.6]
- **simulated_annealing** (simulated annealing, annealing, annealer): A search that accepts worse steps less as it cools. [8.7]
- **exp** (exp): e raised to a power: fast growth, or fast fading. [8.7]
- **chance()** (chance, chance(p)) (supplied): True with a likelihood p. [supplied:8.7]
- **sleeping** (sleeping): True while a `RigidBody3D` has come to rest. [8.8]

### Chapter 9
- **TAU** (TAU): One full turn, about 6.28. [9.1]
- **radian** (radian, radians): The angle unit Godot uses: a full turn is `TAU`. [9.1]
- **sin** (sin): The height of a point going round a circle. [9.1]
- **cos** (cos): The sideways place of a point going round a circle. [9.1]
- **polar_coordinates** (polar coordinates, polar): A place as a distance and an angle. [9.1]
- **sine** (sine, sines, sine wave, sine waves): The rise and fall of `sin` over time. [9.2]
- **amplitude** (amplitude, amplitudes): How far a repeating thing swings from its middle. [9.2]
- **period** (period, periods): How long one repeat takes. [9.2]
- **frequency** (frequency, frequencies): How many repeats happen in a second. [9.2]
- **angular_velocity** (angular velocity): How fast an angle changes. [9.3]
- **angular_acceleration** (angular acceleration): How fast the angular velocity changes. [9.3]
- **push_front** (push_front): Puts an item at the start of an array. [9.4]
- **resize** (resize): Makes an array exactly n items long. [9.4]
- **surface** (surface, surfaces): A thin sheet bent through space. [9.5]
- **oscillation** (oscillation, oscillations, oscillate, oscillates, oscillating): A motion that repeats about a middle. [9.6]
- **wave** (wave, waves): The same oscillation, later the farther from the source. [9.6]
- **AudioStreamWAV** (AudioStreamWAV): A sound made from numbers you write. [9.7]
- **PackedByteArray** (PackedByteArray): A compact array of small numbers, from 0 to 255. [9.7]
- **encode_s16** (encode_s16, PackedByteArray.encode_s16): Writes one sound sample into a `PackedByteArray`. [9.7]
- **ValueMapper3D** (ValueMapper3D) (supplied): A cage: where you hold a ball becomes three numbers. [supplied:9.7]

### Chapter 10
- **random** (random, randomness, randomly): Not chosen by you, and not known before it comes. [10.1]
- **RandomNumberGenerator** (RandomNumberGenerator): An object that draws random numbers for you. [10.1]
- **randf** (randf): A random number from 0 to 1. [10.1]
- **seed** (seed, seeds, seeded): The start number that makes the same random draws again. [10.2]
- **histogram** (histogram, histograms): Bars that count how often each value came up. [10.3]
- **distribution** (distribution, distributions): How often each value comes up, over many draws. [10.3]
- **uniform_distribution** (uniform distribution): A distribution where every value is equally likely. [10.3]
- **randi_range** (randi_range): A random number with no fractional part, between two ends. [10.4]
- **ten_print** (10 PRINT): A maze drawn by one random choice per square. [10.4]
- **random_walk** (random walk, random walks): A path made of random steps. [10.6]
- **Wanderer** (wanderer, wanderers, Wanderer): Your class: a position taking a random step each frame. [10.6]
- **trace()** (trace, trace(points)) (supplied): Draws a line through an array of positions. [supplied:10.6]
- **probability** (probability, probabilities): How likely something is, from 0 (never) to 1 (always). [10.7]
- **normal_distribution** (normal distribution, bell curve): The bell: values near the middle, few far out. [10.7]
- **randfn** (randfn): A random number from the normal distribution. [10.7]
- **drawn_wait** (drawn wait, drawn waits): A pause whose length is a random draw. [10.8]
- **await** (await) (supplied): Pauses a function until something happens. [supplied:10.8]
- **get_tree** (get_tree) (supplied): The scene tree that runs, as something you ask. [supplied:10.8]
- **create_timer** (create_timer, timeout) (supplied): A timer that sends `timeout` after some seconds. [supplied:10.8]
- **create_tween** (tween, tweens, create_tween) (supplied): Slides a value smoothly from one end to the other. [supplied:10.8]

### Chapter 11
- **noise** (noise, noises): Random values whose neighbours are related. [11.1]
- **FastNoiseLite** (FastNoiseLite): Godot's noise maker. [11.1]
- **get_noise_1d** (get_noise_1d): The noise at a place on a line. [11.1]
- **get_noise_2d** (get_noise_2d): The noise at a place on a plane. [11.1]
- **get_noise_3d** (get_noise_3d): The noise at a place in space. [11.1]
- **white_noise** (white noise): Random values with no relation between neighbours. [11.1]
- **perlin** (Perlin, Perlin noise): Ken Perlin's noise: smooth hills of related values. [11.1]
- **vertex** (vertex, vertices): A corner point of a mesh. [11.3]
- **normal** (normal, normals): The direction straight out of a surface at a point. [11.3]
- **map_range** (mapping a range): Turning a value from one range into another. [11.3]
- **displace()** (displace, displace(mesh, f)) (supplied): Moves each vertex along its normal by a function. [supplied:11.3]
- **grid_mesh()** (grid_mesh, grid_mesh(heights, cells, size)) (supplied): A surface and its shape, built from heights. [supplied:11.3]
- **threshold** (threshold, thresholds): The value that splits above from below. [11.4]
- **voxel** (voxel, voxels): One cube of a 3D grid, there or not there. [11.4]
- **octave** (octave, octaves): Noise again at double frequency and half strength. [11.5]
- **fractal_sum** (fractal sum, fBm): Noise added to itself over several octaves. [11.5]
- **lacunarity** (lacunarity): How fast frequency grows from octave to octave. [11.5]
- **gain** (gain): How fast strength shrinks from octave to octave. [11.5]
- **domain_warp** (domain warp, warp, warped, warping): Noise asked at an address another noise has moved. [11.6]
- **heightfield** (heightfield, heightfields, height field, height fields): A grid of heights: one height per place. [11.7]
- **ArrayMesh** (ArrayMesh): A mesh you build from your own points. [11.7]
- **SurfaceTool** (SurfaceTool): Collects points, three to a face, and makes an `ArrayMesh`. [11.7]
- **begin** (begin): Starts a `SurfaceTool` on one kind of piece. [11.7]
- **Mesh** (Mesh): Godot's name for every kind of mesh. [11.7]
- **PRIMITIVE_TRIANGLES** (PRIMITIVE_TRIANGLES): Every three points make one face. [11.7]
- **add_vertex** (add_vertex): Adds one vertex to a `SurfaceTool`. [11.7]
- **generate_normals** (generate_normals): Works out the normal at every vertex, for the light. [11.7]
- **commit** (commit): Hands back the `ArrayMesh` a `SurfaceTool` built. [11.7]
- **create_trimesh_shape** (create_trimesh_shape): Makes a shape that matches a mesh exactly. [11.7]

### Chapter 12
- **gpu** (GPU, graphics card): The part of the computer that draws. [12.1]
- **pixel** (pixel, pixels): One dot of the picture on the screen. [12.1]
- **shader** (shader, shaders): A program the GPU runs for every pixel at once. [12.1]
- **shading_language** (shading language): The language shaders are written in. [12.1]
- **shader_type** (shader_type): The first line of a shader: what it shades. [12.1]
- **spatial** (spatial): The shader type for 3D meshes. [12.1]
- **fragment** (fragment): The shader function run for every pixel. [12.1]
- **UV** (UV, UVs): Where a pixel sits on its mesh, 0 to 1. [12.1]
- **ALBEDO** (ALBEDO): The colour a fragment answers with. [12.1]
- **shaping_function** (shaping function, shaping functions, shaping): A function that bends values from 0 to 1. [12.2]
- **step** (step): 0 below an edge, 1 above it. [12.2]
- **smoothstep** (smoothstep): A step with eased sides. [12.2]
- **mix** (mix): A value part way between two others, in a shader. [12.2]
- **uniform** (uniform, uniforms): A number your script hands a shader. [12.3]
- **set_shader_parameter** (set_shader_parameter): Hands a uniform its value from a script. [12.3]
- **TIME** (TIME): The seconds since start, handed to every shader. [12.3]
- **fract** (fract): Keeps only the fractional part: 2.7 becomes 0.7. [12.4]
- **floor** (floor): Drops the fractional part: 2.7 becomes 2. [12.4]
- **hash()** (hash, hash(p)) (supplied): Turns a tile's address into a number that seems random. [supplied:12.4]
- **truchet** (Truchet): Tiles of quarter arcs, each turned by a coin. [12.4]
- **NORMAL** (NORMAL): The normal at a pixel, in a shader. [12.5]
- **VIEW** (VIEW): The direction from a pixel toward your eye. [12.5]
- **rim** (rim): Where a surface turns away from your eye. [12.5]
- **EMISSION** (EMISSION): Light a surface gives off by itself. [12.5]
- **value_noise** (value noise): Noise made by blending random values at grid corners. [12.6]
- **vertex()** (vertex): The shader function run for every vertex. [12.7]
- **buffer** (buffer, buffers): A picture kept so the next frame can read it. [12.8]
- **SubViewport** (viewport, viewports, SubViewports, SubViewport): A node that draws its own picture, off screen. [12.8]
- **ping_pong_rig** (ping-pong rig) (supplied): Two viewports that swap their pictures every frame. [supplied:12.8]

### Everyday words, no teaching needed
line_of_code, pointing, facing, printed, stacked, means, floating, degrees, camera, lined_up, forced, graphics, select, russell

## The chapters before this one, as the course sketch has them

### 1 Points Build Bodies: Three numbers place a body; a script makes it stay, move and follow you.
You make: A court of your own shapes, built from Godot's primitive meshes at chosen coordinates, with a point that follows your mouse and draws.
- 1.1 Press Play: A script is text on a node: the lines in func _ready() run once, when you press Play.
- 1.2 Somewhere to count from: Every place in a 3D world is three numbers, x, y and z, counted from zero.
- 1.3 A position needs a body: A position stays invisible until you give it a mesh, and a mesh lets things pass until you give it a collider.
- 1.4 Godot's own shapes: Box, sphere, cylinder, prism and torus are shapes you set with a few numbers.
- 1.5 Two points, three points: Give the supplied helper two points and it draws a line; give it three and it fills a face.
- 1.6 Every frame: _process runs again every frame, so a number can count while the program runs.
- 1.7 Follow the mouse: Read the mouse in _process and the point goes there; leave a copy behind each frame with duplicate() and add_child(), and you are drawing.
- 1.8 Name a number: A variable is a name for a value you can read, change and use again: keep the court's sizes in variables.

### 2 Bodies That Change: Bodies move, turn and grow every frame, and an if decides when.
You make: A pickup cube that bobs, turns and pulses, a carrier that waits at each bank, a wall that opens as you come, and a room you can scale small.
- 2.1 A little every frame: Add a small step to position in every _process and the body travels; multiply the step by delta and the speed holds at any frame rate.
- 2.2 Turn and grow: rotate_y() turns a body around its own axis, and scale multiplies its size; both keep its shape.
- 2.3 If it passes the line: An if asks a question that is true or false: if the cube is above the top, reverse its speed.
- 2.4 Wait, then go back: A bool remembers whether the body is moving or waiting, and else says what happens otherwise.
- 2.5 Close enough: Measure the distance to the visitor with length(); under the reach, open the slat, shrink the block or collect the cube with queue_free().
- 2.6 Keys decide: Input.is_action_pressed() asks about a key, and and, or and not join several questions into one.
- 2.7 Children follow: A child moves, turns and grows with its parent: scale the room and everything in it follows.
- 2.8 Order matters: translate() moves along the body's own axes, so turning then moving is not the same as moving then turning.

### 3 Many From One: A loop makes a row, a grid, a lattice and a floor with a rule.
You make: A hall of copies: a row, a 4 x 4 grid, a 4 x 4 x 4 lattice you can fly through, and an off-white and near-black floor whose rule changes with the beat.
- 3.1 Again, while it holds: while repeats its block as long as its test is true: instantiate() a cube while there are fewer than four.
- 3.2 for counts for you: for i in 4 runs its block four times with i = 0, 1, 2, 3, and i times the spacing places each copy.
- 3.3 A loop inside a loop: Put a loop for z inside a loop for x and you get a grid; each cube knows its address, x and z.
- 3.4 The third index: A third loop for y makes a lattice, and the spacing decides whether a body fits between the cubes.
- 3.5 A rule at every address: (x + z) % 2 is 0 or 1, so each tile asks it once and the floor becomes a checker.
- 3.6 Turn the tile by its address: One diagonal tile, turned by (x + z) % 4 quarter turns, mirrored or shifted by address, gives six floors.
- 3.7 Stand it up: Swap z for y and the same loops build a wall; one if keeps one tile different.
- 3.8 A floor with a clock: Add a phase that grows each beat, and (x + z + phase) % 2 makes the floor blink.

### 4 Colour by Function: Write functions that answer with a colour, then a class whose objects each carry their own.
You make: A colour hall of your own: stacks coloured by four functions, a rainbow, a field of pillars, and spray cans and glass panes that are objects of your own classes.
- 4.1 A colour is three numbers: Color(1, 0.55, 0.1) is red, green and blue from 0 to 1; give it to a material and the body wears it.
- 4.2 A function answers: func by_height(level) -> Color takes a number and returns a colour: one stack, four functions, four columns.
- 4.3 Light has a colour: A SpotLight3D has a light_color, and where a red pool meets a green one you see yellow.
- 4.4 Where you hold it: colour_from(p) turns a point in a box into red, green and blue; move the point and the nails change.
- 4.5 Around the hue circle: Color.from_hsv() walks around the colour circle: hue_for(i, count) shares it among bands, and colour_at(p) spreads it over a field.
- 4.6 A rule over the floor: ink(x, z) returns one of four colours from (x + z) % 4, and a colour you paint by hand stays until the rule runs again.
- 4.7 A class of your own: class_name SprayCan, with an @export colour and a spray() method: thirty cans from one class, each in its own colour.
- 4.8 Objects in a room: Twelve Pane objects, each with its own colour, width and turn, make an office you can see through.

### 5 A Source, Many Copies: Keep a 4 x 4 source in an array and copy it by symmetry.
You make: A patterned room: a 4 x 4 source you paint, copied over floor and walls by P1, PM, PG and P4, and a row of your figures wearing it.
- 5.1 A list of steps: var steps := [true, false, false, true] keeps values in order; steps[i] reads one, and the playhead reads them in turn.
- 5.2 A palette is a list: palette[value] turns a 0 or 1 into a colour; swap the palette and every square changes while the values stay.
- 5.3 A tile is rows: source[y][x] holds sixteen colours in four rows of four, and two loops draw it as cells.
- 5.4 Copy by rule: Every cell of a big field reads source[y % 4][x % 4]; read x backwards in odd columns and the copies mirror.
- 5.5 Write into the source: Painting a cell writes a colour into the array and every copy changes at once; FLIP X rebuilds each row from its far end.
- 5.6 Wrap a room: Write the field into an Image and the floor and walls wear it; % brings every address back into the source.
- 5.7 What counts as the same: P1, PM, PG and P4 are four ways to read one array: translate, mirror, glide, turn.
- 5.8 A list of bodies: An array can hold objects: keep your figures in a list, dress each in the pattern, and send them down the catwalk in turn.

### 6 A Curve of Steps: A rate is a rise over a gap; motion is a sum of small steps.
You make: A ball you launch with two lines of your own (velocity += gravity * delta; position += velocity * delta), and a canvas of particles that ask a field for their next step.
- 6.1 Velocity is a rate in time: Velocity is how far you move in a second, so every frame you add velocity times delta to the position.
- 6.2 A curve made of steps: Add gravity to the velocity, then the velocity to the position, every step, and a throw draws its own arc.
- 6.3 Two readings, one rate: Read a curve at two places and divide the rise by the gap: that is a rate, and a smaller gap reads closer.
- 6.4 One height for a width: Let one height stand for a whole strip and add the strips: you get an area, and more strips give a closer total.
- 6.5 Ask the field: A particle asks for a direction where it stands, takes a small step, and asks again, so the path draws itself.
- 6.6 The edge returns you: When a particle leaves one side of the canvas, put it back on the other.

### 7 Arrows That Push: A vector is a move; a force is a vector that changes velocity, divided by mass.
You make: A Mover class of your own (position, velocity, acceleration, mass, apply_force) that wind, drag, a spring and an attractor push around, and a corner of your room with its own gravity.
- 7.1 The arrow between two points: A vector is end minus start: a move you can carry anywhere, with a length and a direction.
- 7.2 Add two moves: Adding joins two moves into one: walk the first, then the second, and you have arrived by their sum.
- 7.3 How much two directions agree: The dot product says how much two directions agree: large when they point the same way, zero at a right angle.
- 7.4 A push that ends: A force changes velocity, a heavier body changes less, and when the push stops the velocity stays.
- 7.5 One field, two receivers: Read the field of 6.5 as the velocity and a body stops where the field is zero; add it to the velocity and the body overshoots.
- 7.6 Forces that answer the body: Drag pushes against the velocity and a spring pulls back toward rest; each force is a function that returns a vector.
- 7.7 Bodies that pull: Attraction points from one body to the other and weakens with distance; a sideways velocity turns the fall into an orbit.
- 7.8 Contact holds you up: A body stands while its centre of mass is above the outline of its feet.
- 7.9 A room with its own gravity: An Area3D can replace gravity for whatever enters it, so a law becomes a place.

### 8 Finding the Form: Let a rule settle: downhill steps, relaxed links and balanced arms find shapes nobody drew.
You make: A net that relaxes into a hanging form you turn over into a vault, and a point that walks downhill to the bottom of a landscape you wrote.
- 8.1 Downhill, one step: Read the slope on both sides of where you stand and step against it: p -= rate * gradient.
- 8.2 Where it stops: The start picks the valley, a step that is too large jumps out of it, and you decide when it is done.
- 8.3 The hanging chain: A chain hangs in a cosh curve, and drawing a sag by hand is not the same as finding it.
- 8.4 The past is the velocity: A Particle keeps where it is and where it was, so its next place is now + (now - before) + gravity * dt * dt.
- 8.5 Relax, pass after pass: Pull every link back toward its rest length, many times a step, and a net settles into a form nobody drew.
- 8.6 Where forces cancel: A lever balances when mass times distance is equal on both sides; hang arms from arms and a mobile balances itself.
- 8.7 Willing to get worse: Accept an uphill step with a chance that shrinks as you cool, and the search can climb out of a small valley.
- 8.8 A shape that counts: Release a stack and let the engine decide: it counts only if it stands tall and stays still.

### 9 What Returns: Turn a circle sideways and it is a sine: pendulums, waves, stairs and tones.
You make: A point that goes round, a pendulum whose swing you can walk beside, and a bar that rings with a tone you computed sample by sample.
- 9.1 A point goes round: Add a little to an angle every frame and place the point at (cos, sin) times the radius: it goes round.
- 9.2 Amplitude, period, phase: Laid out in time, the point's height is a sine, and its amplitude, period and phase are three numbers.
- 9.3 The pendulum: Gravity pulls the bob back by the sine of its angle, and the angle together with the angular velocity says what comes next.
- 9.4 A swing laid into space: Keep each sample with its time and push older ones farther away: a duration becomes a length you can walk beside.
- 9.5 A sine you stand on: Feed a sine a position instead of a time and it becomes a surface, a twisted column or a stair.
- 9.6 A wave travels: Give every point the same oscillation, a little later the farther it is from the source, and a ripple moves while nothing travels.
- 9.7 A wave you hear: Write a sine into an AudioStreamWAV, 44 100 numbers a second, let it fade with exp(), and a bar rings.
- 9.8 Adding waves: Two close tones add into a slow beat.

### 10 Chance Enters the Grid: Draw a number, keep its seed, and let it turn, choose, walk and wait.
You make: You end with a seeded floor of disturbed cubes, a 10 PRINT maze you can walk into, a random wanderer in a glass box, and three stones that sink after random waits.
- 10.1 A number you didn't choose: randf() hands you a number between 0 and 1, and three of them make a colour.
- 10.2 The seed brings it back: Set the seed and the same numbers come back in the same order.
- 10.3 Count the throws: Throw a die 600 times and count each face in an array: the six bars come out nearly level.
- 10.4 One of two: 10 PRINT: randi_range(0, 1) leans each wall left or right, and a maze appears that you can walk into.
- 10.5 Chance against order: Turn each cube of a grid by a draw, more with every column.
- 10.6 A random wander: A Wanderer object keeps a position and adds a random step every frame.
- 10.7 The middle wins: Add two dice and seven comes up six times as often as twelve.
- 10.8 Wait for it: A stone stays up for a random wait and then sinks.

### 11 Chance That Remembers: Noise gives neighbours related values: a path, a body, and ground you can walk.
You make: You end with a walkable noise terrain, reached by way of a breathing column, a voxel body cut by a threshold and a warped sphere.
- 11.1 Randomness with a memory: randf() gives each column its own height, while noise gives neighbours related heights, and a landscape appears.
- 11.2 Noise in time: Sample noise at t, a little further each frame, and a value wanders smoothly without ever making the sine's return.
- 11.3 What a value becomes: Noise answers between -1 and 1: you decide whether that becomes a colour, a height or a push.
- 11.4 The line that decides: Ask 3D noise at every cell of a 12 x 12 x 12 grid and put a cube wherever the value passes a threshold.
- 11.5 Octaves add detail: Add the noise to itself at double the frequency and half the strength, a few times over, and detail grows inside the big shapes.
- 11.6 Borrow an address: Move where you ask before you ask: noise sampled at p plus another noise folds the field like marble.
- 11.7 Ground you can walk: Build a mesh from a grid of heights, give it a collider, and walk across what you made.

### 12 Every Pixel at Once: The noise moves onto the graphics card: a skin made for every pixel.
You make: You end with a sphere wearing a computed skin (stripes, grain and a rim that follows your eye), a pool of water driven by the clock, and a shader that remembers its last frame.
- 12.1 A rule for every pixel: A shader is one function the graphics card runs for every pixel at once.
- 12.2 Shaping functions: step() cuts, smoothstep() eases and sin() repeats: three ways to decide where value goes across a square.
- 12.3 Numbers from outside: A uniform is a number your script hands the shader, and TIME is the one Godot hands it every frame.
- 12.4 Fold space: fract() throws away the whole number, so every pixel thinks it is in the one tile.
- 12.5 The skin answers your eye: dot(NORMAL, VIEW) is small where the surface turns away from you.
- 12.6 Noise on the GPU: The octaves of the last chapter, written as a shader function, cloud a skin at every pixel on every frame.
- 12.7 Water from the clock: vertex() lifts every vertex by sines and noise of its position and TIME.
- 12.8 A rule with a past: A shader remembers nothing until you hand it its last frame.

