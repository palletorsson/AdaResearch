"""Write the focused plane-to-sphere lesson with complete, named source listings."""
from pathlib import Path
import hashlib, json

ROOT = Path(__file__).resolve().parents[1]
STUDY = ROOT/'doc/book/studies/noneuclid-lineage'
MAP = ROOT/'commons/maps/NonEuclidean_Spaces'
OUT = ROOT/'doc/book/iterations/2026-10-11-noneuclid-what-counts-as-straight'
FILES = ['surface_triangle.gd','surface_study.gd','triangle_record.gd','point_body.gd','line_skin.gd']

OPENING = '''# What counts as straight

## Learning elements

- A surface and its geodesic edges.
- Tangent directions at a corner.
- Comparing angles under two geometric models.
- Keeping a record while changing its interpretation.

**Carry:** Euclid's three-point record, PointBody, LineSkin and triangle construction. **New:** a spherical interpretation, great-circle edge samples and tangent-based angle measurements. **Supplied:** the existing Endless Museum, player, XRTools and push-button scene. We continue inside that project.

## Encounter

At the installed triangle workbench, HOST selects PLANE, SPHERE or DISK. Each setting has its own triangle and edge rule. It is a comparison, not a continuous curvature control for the whole room. The separate slider changes its own surface sketch.

Our coding task is smaller: continue Euclid's three grabbable points through **PLANE → SPHERE**. The existing disk remains a further comparison to visit. We will not mistake a radial warp for a new distance model.

Create a folder beside your Euclid working copy. Keep `triangle_record.gd`, `point_body.gd` and `line_skin.gd` unchanged; their complete listings are at the end. Add the two new files below. Attach `surface_study.gd` to a unit-scale Node3D named SurfaceStudy. The supplied `res://doc/book/studies/noneuclid-lineage/museum.tscn` launcher opens the real hall and mounts the study on clear floor; run that scene with F6 to visit it. To mount your own reconstructed folder, change the launcher's `LESSON` preload to your host script. No replacement camera, light or player is needed.

## Keep three pairs; change their meaning

The new model extends `triangle_record.gd`. It inherits the same `points` array, starting values and reset. PLANE calls the previous measurement unchanged. SPHERE reads each pair `(x,z)` as the direction `(x,1,z)`, normalized to a point on the unit sphere. This chart covers its upper hemisphere. Our hand interface uses only the bounded central patch, where x and z stay between −1 and 1.

Switching models preserves the pairs and point-body instances. It does **not** preserve world positions, lengths or angles. The pairs were planar positions; now they select directions from the sphere's centre. This is a declared correspondence, not an isometry or a saved live object travelling between scene loads.

Between two sphere points, blend their vectors and normalize the result. Every sample lies on the sphere and in the plane through both endpoints and its centre: the shorter great-circle arc. Our upper-hemisphere restriction avoids antipodal endpoints, where the short route would not be unique. The samples are not equally spaced in arc length. The cylinders joining them are a finite drawing of the curve.

At a spherical corner `a`, the surface normal is `a` itself. Remove the part of `b` along that normal: `b - a * a.dot(b)`. Normalize what remains. That is the outgoing tangent toward `b`. Use the two outgoing tangents to measure the corner, with the same cross/dot angle operation as before. The readout uses these analytical tangents, not the angle between rendered cylinder pieces.

Euclid's degeneracy check still matters. In this chart, collinear coordinate pairs map to one great circle. We keep the existing numerical refusal instead of reporting a triangle with an interior. The inherited tolerance is a computational policy.

Save `surface_triangle.gd`:

'''

HOST = '''
## Put the changed path in your hand

We keep PointBody's shape and grab behaviour. LineSkin returns many times: 24 short cylinders approximate each edge. The plane keeps its triangle face. On the sphere, the sphere's own skin replaces that flat face; joining only the three corners with a flat face would cut through the body.

PLANE/P and SPHERE/S change the interpretation only after every point is released. RESET/R restores the pairs and keeps the current model. A mode switch does not recreate the PointBody instances.

For a held point, convert the hand's world position to this study's local frame. On the plane, keep X and Z as before. On the sphere, subtract its centre and divide X and Z by Y to invert our direction chart. Bound the resulting pair to the same workspace. A hand at or below the chart's equator is refused; the last record remains and the readout says so. The small 0.02-metre guard avoids division near zero. On release the sphere point returns to the recorded surface position.

The display sphere has radius 0.75 metres. Scaling a display this way preserves its corner angles. It does not give the museum floor a spherical metric. Neither displayed surface constrains the player physically.

Save `surface_study.gd`:

'''

ENDING = '''
## Predict, then check

Start in PLANE. Move C; keep the three pairs. Release it and select SPHERE. Predict whether the sum will stay, rise or fall before reading it. Switch back: the saved pairs and plane measurements should return exactly within numerical tolerance.

Use `(0,0), (1,0), (0,1)` in a model copy. PLANE gives 90°, 45°, 45°. SPHERE gives approximately 90°, 54.73561°, 54.73561°: sum 199.47122°. Each result must come from the calculated vectors, not a mode label. As a separate tangent check, the sphere's north pole and two equator points a quarter-turn apart give three right angles. Those equator points lie outside this hand chart; test their directions directly, without pretending the interface can reach them.

Check edge endpoints, unit-length spherical samples and tangents perpendicular to their corner normals. Collinear or coincident pairs must withhold the reading and recover when separated. Test the full host too: initialized meshes and labels, mode buttons, transformed local frame, sustained grab input, refused lower-chart input and release over several physics frames. A single rigid-body teleport is not a continuously tracked hand.

Make one variation of your own. State what it should preserve and change before running it. Compare numerical outputs and visible behaviour. The earlier shear is available, but you need not choose it. Do not overwrite a failed prediction to make the record look successful.

## What this comparison establishes

The spherical measurement uses great-circle directions. A chord through the sphere is a different edge. More rendering segments improve the picture; they do not change the analytical angle calculation.

For a suitable geodesic triangle, curvature relates to the difference from 180°. This lesson displays that difference; it does not independently integrate curvature or prove the theorem. [Mark Powell, Gauss–Bonnet, §7.2](https://www.maths.gla.ac.uk/~mpowell/M435-chapter-6-gauss-bonnet.pdf).

Return to DISK on the existing museum bench. The Poincaré model uses boundary-orthogonal arcs or diameters and preserves angles in its drawing. Its apparent flatness does not make its distance rule Euclidean. That model is a supporting encounter here, not code we reconstructed in this exercise. [Cornell, Geometries of Surfaces](https://pi.math.cornell.edu/~mec/Winter2009/Victor/part4.htm).

Carry the habit of stating the rule and checking what it permits into **Russell Paradox**. Next we will ask whether a membership demand can be satisfied. That is a different problem from choosing a geometry.

## Carried files, complete

Copy these three files unchanged from Euclid. `surface_triangle.gd` inherits the first; the host uses the other two. The external scene is `res://commons/interactables/push_button.tscn`; `XRToolsPickable` is supplied by the prepared project. These are declared infrastructure, not missing student code. A blank Godot project will not contain them.

'''

REFLECTION = '''# What counts as straight

<!-- @triangle_curvature_workbench -->

The triangle returns with three points you can still hold. In the previous hall, moving a corner changed its angles while their sum stayed near 180 degrees. Here the familiar result depends on another decision: what path joins the corners?

Start with PLANE at the installed bench, then select SPHERE. The sides follow great circles. At a corner, read the directions along the surface. The total rises. A straight chord would take a shorter route through the sphere's interior, but that route has left the space in which this triangle lives.

The tutorial keeps the same three coordinate pairs and point bodies while changing their interpretation. On the plane the pairs place points; on the sphere they name directions from its centre. This continuity is useful, but it is not sameness in every respect. The positions, distances and angles can change. We have said what travels and what does not.

Lift a point. Its hand-held body may leave the surface, while the recorded corner follows the chart. Release it and the point returns to that record. Move below the chart's equator and the study declines the new position. The sphere continues there; our chosen interface does not. A limit of access can look like a limit of the object until the two are separated.

<!-- @poincare_disk -->

Now choose DISK at the original bench. The picture lies flat, yet its direct paths bend in our view. The Poincaré disk represents a different distance rule while preserving angles. The visible rim is infinitely far away in that metric. A small object on the table can therefore depict a space whose edge cannot be reached by a finite journey. [Cornell, Geometries of Surfaces](https://pi.math.cornell.edu/~mec/Winter2009/Victor/part4.htm).

The bench selects three example triangles. The tutorial compares two interpretations of a retained record. Neither operation bends the museum around you. We can walk from one display to another on the same ordinary floor.

<!-- @hyperbolic_surface -->
<!-- @elliptic_surface -->
<!-- @curvature_slider -->

At the saddle, dome and separate surface slider, appearance asks for another kind of attention. A bend is visible. A metric needs more than that silhouette. The slider changes its own sketch; it does not govern the room. Its gesture is broad enough to suggest an authority the code has never given it.

There is a relation between the curvature enclosed by a geodesic triangle and its angle sum. A measured excess or deficit can direct us towards that relation; one display is not its proof. [Mark Powell, Gauss–Bonnet, §7.2](https://www.maths.gla.ac.uk/~mpowell/M435-chapter-6-gauss-bonnet.pdf).

An operation can remain precise when its result becomes unfamiliar. The changed sum need not be a broken triangle. It may be our first clear view of a condition that used to pass unnoticed. Mathematics allows these models; deciding which describes a physical situation requires further evidence.

Return to PLANE. Its usefulness survives the comparison. Carry the question onward: what has the rule made possible? In Russell's hall, that question will meet a demand that cannot be satisfied as stated.
'''

def block(name):
    return '<!-- student-code:'+name+' -->\n```gdscript\n'+(STUDY/name).read_text(encoding='utf-8').rstrip('\n')+'\n```\n'

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    text = OPENING+block(FILES[0])+HOST+block(FILES[1])+ENDING
    for name in FILES[2:]: text += '\n### '+name+'\n\n'+block(name)
    (MAP/'tutorial.md').write_text(text,encoding='utf-8')
    (MAP/'final.md').write_text(REFLECTION,encoding='utf-8')
    paths = ['commons/maps/curriculum_spine.json','commons/maps/sequences/foundationscrisis.json','commons/data/museum/em_plan.json','commons/maps/NonEuclidean_Spaces/map_data.json','commons/artifacts/triangle_curvature_workbench/triangle_curvature_workbench.gd']
    paths += ['doc/book/studies/euclid-lineage/'+name for name in FILES[2:]]
    baseline=OUT/'preserved.json'
    if not baseline.exists(): baseline.write_text(json.dumps({p:hashlib.sha256((ROOT/p).read_bytes()).hexdigest() for p in paths},indent=2),encoding='utf-8')
    print('Updated NonEuclidean_Spaces: two new scripts, three carried scripts, reflection.')

if __name__=='__main__': main()
