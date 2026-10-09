import json
from build_sources import HERE,ROOT,HALLS,put

# Main code and all local dependencies are printed once. The museum supplies the host.
LESSONS={
'Point_Triangle_Context':('Three positions become a face',
['Three selected array entries','A closed boundary and a face','Clockwise vertex order','A guard for a collapsed triangle'],
'''Your drawing has reached Grid as a sculpture. Here, choose three positions from its original record. The triangle tools in this hall show the difference between connecting corners and giving the space between them a surface. We will make that difference with the point and line classes already used.

The saved record still uses the drawing station's local metres. Grid's rounded copy did not replace it. This lesson reads the original archive and creates three temporary PointBody handles at selected entries. It does not save their later edits back to the drawing.''',
'''Start with CORNERS = Vector3i(0, 1, 2). These are **entry numbers**, not spatial coordinates. If those entries lie on one straight segment of your drawing, lift one handle to make a face, or choose another triple in the record. A trace with fewer than three entries needs another visit to Trace.

Attach lesson.gd to an empty Node3D named TriangleStudy in your working copy of this museum hall. Keep its scale at one; its translation places the study without changing the saved local measurements. The existing museum supplies the player, camera, light and XR pickup functions. This program constructs its own handles, edges, face and label.''',
'''`record[index]` reads one saved position. `PointBody.new()` gives it the same visible, pickable body you already know. The three handles can move independently; their current local positions form a short array.

`Vector3i(0, 1, 2)` tells FaceBody which three entries to visit, in order. Its renderer adds three edges and a triangular surface. The points specify **where**; the triple specifies **how they connect**. This is a face recipe, not another set of positions.

Order matters. Godot treats clockwise vertices, viewed from the front, as a front face. Walk around the triangle: this example keeps normal back-face culling. Reversing the triple to `Vector3i(0, 2, 1)` reverses the front. The outline remains visible from either side.

Three collinear positions enclose no area. FaceBody checks the cross-product magnitude before submitting vertices and clears the previous face when the triangle collapses. The cross product is supplied here as the area-and-normal calculation; vector products return in Forces. The small threshold also rejects nearly collapsed triangles. The helper creates visible geometry, not a physical barrier.''',
'''Choose another three saved entries. Make a valid face, flatten it until it disappears, then restore it. Reverse the order and explain which side is now the front. Keep the original saved drawing unchanged.

Carry forward the position array, its ordered face recipe, and FaceBody. The next hall adds a fourth position and asks whether several faces can enclose a volume.'''),
'Primitives_Polythedra':('Four positions enclose a body',
['Shared vertices','A list of face-index triples','Tetrahedron connectivity','Surface enclosure versus collision'],
'''A tetrahedron is the smallest closed body made entirely of triangular faces. The museum's polyhedra let you encounter a surface from outside and imagine the volume it encloses. Our construction begins with the same three saved entries used for Triangle and adds one point behind their face.

This lesson reloads the original Trace record. Moving a temporary Triangle handle did not change that file. Use the same CORNERS triple you selected there; the number of stored drawing entries determines which indices are available.''',
'''Attach lesson.gd to a unit-scale Node3D named PolyhedronStudy in this hall's working copy. Copy FaceBody, LineSkin and TraceArchive alongside it. All are printed below. No replacement camera, player or room is required.''',
'''`points` holds four positions. `faces` holds four **triples of indices into points**. In `Vector3i(0, 3, 1)`, the renderer reads entries zero, three and one; it does not create three new independent corners.

The fourth position starts at the base triangle's centre and moves DEPTH metres behind its front. Using the base normal means the apex remains off the base plane whichever way the saved triangle faces. A zero-area base cannot define that normal; the guard stops before normalizing it. DEPTH must be positive.

Each of the tetrahedron's six edges belongs to exactly two faces. Adjacent faces traverse their common edge in opposite directions, keeping their fronts outside. The renderer reads the same position again wherever its index occurs. For flat lighting it submits separate render vertices per face, but the construction still has four shared positions.

Change `points[3]`, then call `body.show_faces(points, faces)` again. Three faces move with that one entry. Editing an index changes a connection instead. A closed mesh is still only a visible surface: this program adds no collision shape.''',
'''Replace the selected base with another valid triple, then halve DEPTH. Check that all four faces remain and that the apex is still off the base plane. Explain why a fifth copied point would not automatically become part of the enclosure.

Carry the separation between positions and connectivity into Cube. A longer face list will reuse the same renderer.'''),
'Point_Animatedcube':('Eight corners, twelve triangles',
['A reusable CubeBody class','Shared corner data','Two triangles per square side','Connectivity versus object position'],
'''The cube appears simple enough to arrive ready-made. The diagonal study in this hall exposes a decision hidden by that familiar outline: a square surface is represented here by two triangles. Build one cube, then a second with the other diagonal on its front side.

We keep FaceBody from the preceding halls. CubeBody adds a particular set of eight positions and twelve index triples. It is the cube we can carry into Transformation and Arrays.''',
'''Put the four printed files in one lesson folder and attach lesson.gd to an empty unit-scale Node3D named CubeStudy in the museum hall. CubeBody constructs its visible mesh itself. The placements in lesson.gd leave room between two one-metre cubes; they do not alter their local vertex data.''',
'''CubeBody extends FaceBody, so it inherits the face renderer. Its `_init()` first calls `super()` to attach the parent's surface and edge container, then calls the renderer with this cube's recipe. Each call to `CubeBody.new()` creates a new object with its own position array, face array and mesh.

The corners use x and z values of −0.5 or 0.5 and y values of zero or one. The first two triples cover the positive-z side. `other_diagonal()` changes those two triples, keeping the four corner positions fixed. The black internal line moves to the other diagonal; the square's boundary and area stay the same.

Node position and vertex position do different jobs. `second.position` places the whole cube in the study. `second.points[6] += Vector3(0, 0, 0.25)` changes one local corner; call `second.show_faces(second.points, second.faces)` afterward to redraw it. Every face using entry six changes. A formerly square side can become two angled planes, making the diagonal matter to the surface itself.

These cubes have visible edges and faces, without colliders. The wider prefab collection in the museum remains available for reflection; it is not another construction dependency.''',
'''Make a third CubeBody and place it somewhere else. Change one corner on that instance and redraw it. Verify that the first two cubes keep their shapes. Then explain the difference between moving a body and editing the data from which it is made.

Keep CubeBody. The next hall asks whether a short rule can generate a position list that we have so far written out.'''),
'Primitives_Ignorance':('A rule produces positions',
['Functions and typed return values','Parameters and arguments','Symmetry as a construction rule','Independent generated results'],
'''Among the Platonic solids, the octahedron offers a compact rule: put a position at each end of three perpendicular axes. Six positions replace a long list of coordinates. The geometry courtyard gives the result a place; this lesson makes its construction available to you.

You already have arrays, loops and a face renderer. The new step is to give a repeated construction a name and an input. We supply the eight face triples so that the lesson stays with generating positions.''',
'''Attach lesson.gd to a Node3D named GeneratorStudy in this museum hall. FaceBody and LineSkin are unchanged. The two calls deliberately use different radii and store their results separately.''',
'''`radius` is the function's parameter. The numbers 0.3 and 0.6 are arguments supplied by two calls. `-> Array[Vector3]` names the kind of value returned: a list of positions. The positive-radius assertion states the function's domain.

For each positive axis, the loop appends one position and its opposite. The order is +X, −X, +Y, −Y, +Z, −Z. The supplied face list depends on that order. Rearranging the list without changing the faces would make a different set of connections.

The function builds a fresh `result` on every call and returns it. It does not place a body in the room or draw anything. FaceBody takes the returned data and renders it. This separates generating positions from displaying them without introducing a general-purpose factory.

Changing a returned position changes one result. Changing the rule changes future results. Neither operation makes a claim about which sculpture is better. Radius, geometric relationship and aesthetic judgment are different decisions.''',
'''Call the function with 0.45. Use the returned array to display a third body. Move one entry in that array, redraw only that body, and verify that the other two remain unchanged. Describe the symmetry your edit broke.

Carry the idea of a parameter controlling a construction. In Godot Primitives, return to your original sphere and make two of the engine's construction parameters available while holding it.'''),
'Primitives_Godot':('The held sphere loses resolution',
['Extending PointBody','A mesh resource and its parameters','Held and released states','Elapsed-time steps and lower bounds'],
'''Return to the small white sphere you could pick up in Coordinates and use to draw in Trace. In this hall, holding it changes its visible construction. Rings and radial segments decrease in small timed steps. Release it and the change pauses. Its size and physical boundary remain the same.

The museum's primitive library shows other engine shapes. Our tutorial stays with one familiar body, gaining a new behaviour. This is the object that can acquire further abilities in later sequences.''',
'''Attach lesson.gd to a unit-scale Node3D named ResolutionStudy in the working museum hall. The existing XR Tools hands provide pickup. The two spheres use the same class but own separate resources. Enter—the supplied ui_accept action—resets both in desktop testing. In the museum's input setup, another controller action can call the same reset function; this lesson does not add an undeclared XR binding.

PointBody is a small later edition of the earlier file: `sphere` is now a member variable instead of a local `_init` variable. Its radius, height, collider, material defaults and pickup settings are unchanged. Keep this edition in this lesson folder; earlier tested scripts need no edits.''',
'''ResolutionPoint extends PointBody. `super()` runs the base constructor, which constructs the visible sphere and physical boundary; the added class controls the existing sphere mesh. `sphere.rings` divides the construction along its height; `sphere.radial_segments` divides it around the axis. Neither setting changes its radius.

`advance(delta)` receives elapsed seconds from the hall's `_process`. Its first condition returns immediately while the point is not held. Otherwise it accumulates time. A `while` loop consumes every complete 0.15-second interval, including several intervals during a long frame. Release preserves the remaining fraction, and re-grabbing continues it.

`maxi` stops rings at one and radial segments at four, the valid lower bounds used here. We approach a coarse sphere, not a zero-vertex object. The analytical sphere collider remains round: seeing a faceted mesh does not imply feeling a faceted boundary.

`reset_resolution()` restores the two starting counts and clears the clock. Both calls to `ResolutionPoint.new()` construct their own mesh; changing one must not quietly change its neighbour.''',
'''First hold only the left sphere. Then make a variant that decrements rings but leaves radial segments unchanged; make a second variant that changes only radial segments. Predict and compare the visible results. Release halfway through an interval, wait, and resume: the change should follow held time, not time spent looking at it.

Carry the same body and the distinction between shape, appearance, interaction and construction parameters. Columns next gives a family of forms three separate inputs.'''),
'Primitives_Columns':('One profile, several resolutions',
['A profile as a radius list','Nested loops over rings and sides','Independent height and resolution','Comparing one variable at a time'],
'''The colonnade varies outlines, heights and resolution. Begin with a controlled row: the same profile and height at 4, 6, 8, 12 and 16 sides. Once you can identify what resolution changes, give the columns different silhouettes.

The octahedron lesson generated positions with a function. Here another function generates a stack of rings. Circle sampling and the surface stitcher are supplied below so that the new work stays with the profile, the two loops and their indexing.''',
'''Attach lesson.gd to a Node3D named ColumnStudy in this hall's working copy. Allow roughly five metres for the row. The program creates its own meshes and pale material. Keep positive radii, at least two profile entries, a positive height and at least three sides. For the first variations stay near the displayed dimensions; more samples consume more memory and drawing work.''',
'''PROFILE stores a radius for each height level. Its entries are spaced evenly from the bottom to the full HEIGHT. The outer loop visits a level; the inner loop visits positions around that level's circle. A profile of six entries at eight sides produces 48 positions.

`height * ring / (profile.size() - 1)` places the last ring exactly at the requested height. Circle.make supplies a ring in the x–z plane. Adding `(0, y, 0)` lifts it to the current level. Its cosine and sine are borrowed circle coordinates here; periodic motion returns to their meaning in Waves.

ColumnSurface joins neighbouring rings, closes the last side to the first, and caps both ends. The side order must match at every ring. It connects samples with straight faces, so this small construction has piecewise straight profiles rather than the museum gallery's more elaborate curves. It adds no collision.

Changing sides changes angular sampling. Changing PROFILE changes the silhouette. Changing HEIGHT stretches the spacing between its levels. A higher resolution is not a better proportion or a more interesting sculpture.''',
'''Keep eight sides and make a new positive-radius profile. Then keep that profile and change only its height. Finally use it for all five resolutions. Explain which differences come from your rule and which come from sampling it.

Carry the profile-and-path distinction into the next hall, where the cross-section is borrowed from a letter rather than written as a radius list.'''),
'Primitives_Profiles':('A letter carries its opening',
['A supplied outline with a hole','Cross-section versus route','Sampling placements along a path','Declaring a dependency'],
'''An O can become a short hollow passage. Its interior opening is part of the source outline, not a hole we draw afterward. The museum's glyph gallery explores this relation at architectural scale. Here we use its existing outline-and-sweep builder for one small visible body.

Columns gave a generated cross-section a sequence of placements. Now the font supplies the cross-section, and we choose the placements. Font extraction, triangulation and boundary stitching are explicitly supplied work, not concepts you are expected to reconstruct in this lesson.''',
'''Put lesson.gd, profile_sweep.gd, JetBrainsMono-Medium.ttf and its OFL licence in one folder. The font and licence are in this lesson's downloadable folder; let Godot import the font. Attach lesson.gd to a Node3D named ProfileStudy in the existing museum.

This small example is a visible hollow mesh, without a collider. Its O has a lower sill, so “opening” does not mean a floor-level walk-through doorway. The museum's larger passage uses its own placement and collision setup.''',
'''`Sweep.profile(FONT, "O")` returns a Dictionary: named entries containing the outline positions, cap triangles and boundary edges. You borrow that record intact. Its inner boundary matters as much as its outside edge.

Each Transform3D is a placement for one copy of that cross-section. The supplied expression uses a uniform WIDTH and the position `at`; it leaves all sections parallel. Transformation will examine the basis more closely. The loop creates five placements from fraction zero to one. DEPTH sets their z travel and OFFSET their total sideways travel. This version shears along a straight route; it does not solve arbitrary curved-path orientation.

`Sweep.make(section, frames)` connects corresponding boundary edges between placements and caps the material at the ends. It preserves the O's opening through those caps. The full helper is printed below as a declared dependency. The student-owned decisions are the chosen glyph, size and route—not a claim to have rebuilt font triangulation.''',
'''Set OFFSET to zero; then give it the opposite sign. Keep the O and WIDTH unchanged. Predict the direction of the passage and verify that the opening survives. Next try C and explain why an open contour changes what you would call the resulting space. Some glyphs have disconnected components; one character need not make one connected solid.

Carry the distinction between a rule you write and a structure you borrow. Portals asks how a finite construction can answer a question about an ideal form.'''),
'Primitives_Portals':('Choose a useful limit',
['A closed neighbour loop','Error in a stated unit','A while loop with a stopping rule','A finite work budget'],
'''A circle's perimeter offers a question that a finite polygon can answer approximately. How many sides are enough for a chosen measurement? The hall's encounters with limits give that question a wider setting; our program makes one bounded decision visible.

Reuse Circle.make from Columns and LineSkin from Lines. There is no new shape factory. Add the lengths between neighbouring samples, including the last sample back to the first.''',
'''Attach lesson.gd to a unit-scale Node3D named LimitStudy in this museum hall. The polygon is drawn horizontally at hand height. TOLERANCE is an absolute perimeter error in metres; BUDGET is the maximum number of sides this run may use.''',
'''`(i + 1) % record.size()` wraps the last index to zero. Without that closing edge, the sum would measure an open path. `perimeter` returns one number rather than creating geometry.

The program compares that sum with `TAU * RADIUS`, the floating-point circle circumference used as its numerical reference. Starting with three sides, it doubles the side count, stopping at the budget if a doubling would exceed it. After each new polygon it recomputes error.

There are two honest endings: the requested tolerance is met, or the available work is spent. `met` records which happened. A very small tolerance and a small budget should report false, not run forever or silently claim success. The budget counts samples, not elapsed GPU time.

This does not calculate every digit of pi or prove a limit. Both the circle reference and the sampled coordinates use finite precision. It makes the choice of an adequate approximation inspectable.''',
'''Compare tolerances 0.05 and 0.005 with the same radius and budget. Then request 0.000001 with a budget of twelve. Predict which run will exhaust its budget. Explain what “enough” means in each case and why the last case must still stop.

Carry the ability to name a criterion and a limit. The final Primitives hall gives you room to decide what to make with the constructions already available.'''),
'Primitives_Melencolia':('Arrange what you can already make',
['Composition with known classes','Independent instances','Placement versus construction','Reusing a learned capability'],
'''Dürer's objects gather in the museum's Melencolia hall. Our tutorial closes this sequence with a smaller task: make an arrangement from two instances of your cube and the familiar sphere point. The reflective text can ask what geometry promises; the tutorial gives you enough control to make an arrangement of your own.

There is no new mesh recipe here. Keep CubeBody from Cube and PointBody from the earlier point lessons. These are recognizable constructions, not substitutes downloaded for the closing image.''',
'''Attach lesson.gd to a unit-scale Node3D named ArrangementStudy in this hall's working copy. Place that study at floor level. The cube's local bottom is y = 0; the sphere's centre is one radius above the floor. PointBody retains pickup and frozen release; the cubes remain visible mesh objects without colliders.''',
'''The loop constructs two independent CubeBody instances and assigns positions from places. Reusing a class does not mean sharing one mutable vertex array. Moving an instance should leave its geometry and its neighbour unchanged.

The point is the same white sphere with the same size and interaction settings. It can be picked up and left somewhere else during a run. That temporary placement is not written back into this script. To keep an arrangement across runs, put your chosen coordinates in the source; persistent composition is a later capability.

The program uses constructors, arrays, a loop and positions you have already met. Scale and rotation stay for Transformation. You can still change the relation between bodies through distance, overlap and placement. The resulting arrangement is your decision, not the inevitable output of the cube rule.''',
'''Make a second arrangement by changing only places and the point's initial position. Keep the classes unchanged. Show how a different interval or overlap changes what you notice. You should be able to reconstruct both arrangements from their saved script values.

Carry CubeBody and PointBody into Transformation. A body that you can place is ready to become a body whose position, rotation or scale changes over time.''')}

def main():
    for hall in HALLS:
        title,subjects,encounter,setup,explanation,transfer=LESSONS[hall]
        folder=HERE/hall
        text=f'# {title}\n\n## Learning elements\n\n'+''.join('- '+s+'\n' for s in subjects)
        text+='\n## In the museum\n\n'+encounter+'\n\n## Make this study\n\n'+setup+'\n\n'
        text+='Create the following files together. The complete main program appears once; the remaining listings name every local code dependency. Earlier files return unchanged unless this lesson explicitly identifies a later edition.\n\n'
        for name in ['lesson.gd']+sorted(p.name for p in folder.glob('*.gd') if p.name!='lesson.gd'):
            label='The program' if name=='lesson.gd' else 'Dependency: '+name
            text+='### '+label+'\n\n<!-- student-code:'+name+' -->\n```gdscript\n'+(folder/name).read_text()+'```\n\n'
        text+='## Read the construction\n\n'+explanation+'\n\n## Make it your own\n\n'+transfer+'\n\n'
        text+='## Source and scope\n\nThe runnable study is a small reconstruction in the existing Endless Museum. The hall contains additional artifacts; this lesson does not reproduce their complete runtime. Camera, light, player and XR Tools are declared museum infrastructure. Local geometry is generated by the printed files.\n\n'
        if hall in ['Point_Triangle_Context','Primitives_Polythedra','Point_Animatedcube']:
            text+='Godot documents clockwise front faces and ordered vertex submission in [SurfaceTool](https://docs.godotengine.org/en/4.6/classes/class_surfacetool.html).\n'
        if hall=='Primitives_Godot':text+='Parameter meanings: [Godot 4.6 SphereMesh](https://docs.godotengine.org/en/4.6/classes/class_spheremesh.html). The minimum counts are checked by this lesson’s native tests.\n'
        if hall=='Primitives_Profiles':text+='The supplied sweep is copied from `commons/artifacts/glyph_profile_gallery/profile_sweep.gd`; JetBrains Mono is distributed with its OFL licence. Font geometry uses [Godot TextMesh](https://docs.godotengine.org/en/4.6/classes/class_textmesh.html).\n'
        put(ROOT/'commons/maps'/hall/'tutorial.md',text)
        put(folder/'tutorial.md',text)
    put(HERE/'subjects.json',json.dumps({h:LESSONS[h][1] for h in HALLS},indent=2)+'\n')

if __name__=='__main__':main()
