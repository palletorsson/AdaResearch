"""Scoped catalog repairs. Run only between museum probes; preserve unrelated entries."""
from pathlib import Path
import json
import re
import sys

HERE = Path(__file__).resolve().parent
ROOT = HERE.parents[3]

def replace_entry(relative, key, update):
    path = ROOT / relative
    text = path.read_text(encoding='utf-8')
    match = re.search(r'(?m)^([ \t]*)' + re.escape(json.dumps(key)) + r'\s*:\s*', text)
    assert match, (relative, key)
    value, length = json.JSONDecoder().raw_decode(text[match.end():])
    update(value)
    rendered = json.dumps(value, ensure_ascii=False, indent=2).replace('\n', '\n' + match.group(1))
    path.write_text(text[:match.end()] + rendered + text[match.end()+length:], encoding='utf-8', newline='\n')

def patch(file, key, **changes):
    replace_entry('commons/artifacts/registry/' + file + '.json', key, lambda v: v.update(changes))

if __name__ == '__main__':
    if '--recover' in sys.argv:
        for token in ['laundry_line_cathedral', 'impossible_end_table']:
            patch('primitives', token, lookup_name=token, map_ready=True, include_in_map_data=True)
    else:
        patch('formfinding', 'settling_tremble', description='A static comparison between a sampled analytic catenary and seeded vertical offsets within +/- epsilon. The inset magnifies fixed differences eight times. It asks when a remainder counts as settled; it runs no relaxation solver and measures no residual motion.')
        patch('machinelearning', 'gradient_descent', description='A marker takes finite-difference descent steps on seeded Perlin terrain, retaining a trail. Step size, small-gradient threshold and step budget control the local search. This is a numerical visualization, not a freely rolling rigid body or a trained network.', qfep_connection='A local update can reach different accepted states depending on landscape, start and stopping rule. Compare the retained-state marble and controlled objective lab in Descent; visual similarity does not make their update laws identical.')
        patch('soft_bodies', 'descent_marble_toy', description='A small bowl with a marker carrying position and velocity. Its local update combines slope, damping and periodic programmed kicks; the bowl also sways. A comparison for the momentum-free objective search, not proof that every form-finding process is the same descent.')
        patch('wavefunctions', 'cable_builder', description='Move four grabbable control beads to redraw a cable. Per-span Bezier handles add a chosen downward sag; the curve is drafted from those controls rather than found by a physical chain solver.')
        patch('primitives', 'laundry_line_cathedral', description='Three sampled cosh washing lines with shirts and towels, supported by end crossbars, and mirrored ghost arches above. The analytic curves and inversion make a structural analogy visible; the artifact does not solve loaded ropes or masonry equilibrium.')
        patch('parametric', 'catenoid', description='A sampled parametric catenoid generated from cosh and circular sections. A grabbable model of a minimal surface, not a live soap-film simulation or a guarantee of globally least area for arbitrary ring separation.', qfep_connection='Compare a boundary-conditioned analytic construction with a drafted cable. An elegant form can make a model convincing; its formula and rendering do not establish that material has performed an optimization in this room.')
        patch('parametric', 'helicoid', description='A sampled parametric helicoid with straight ruling lines and screw symmetry, presented as a grabbable model. Its mathematical relation to a catenoid can be discussed, but this artifact performs no continuous deformation between the two.', qfep_connection='A different parameterization opens a different surface while keeping the construction inspectable. The small model is a comparison of forms, not a staircase for the visitor or a measured least-area experiment.')
        patch('vectors_demos', 'calder_mobile', description='A static tree of painted discs and rods. Nominal disc masses use area, thickness and aluminium density; massless arms place each pivot so left mass times distance equals right mass times distance. Nameplates expose the arithmetic. No dynamic rigid-body balance, rod mass, wire mass or wind response is simulated.', qfep_connection='The balance is encoded in a chosen mass model and geometry. Inspect what the recursive calculation includes and what it leaves out before treating the hanging image as a physical test.')
        patch('primitives', 'tensegrity_triangle', description='Three rendered struts and joints with a prescribed sinusoidal scale pulse. It depicts a triangle but has no member-force, hinge or load solver and no tension cables; the legacy identifier does not make it a tensegrity demonstration.', qfep_connection='A convincing pulse invites the question of what was actually tested. Compare the authored animation with the constraint needed to establish rigidity; the current sculpture poses that experiment rather than performing it.')
        patch('fractals', 'fractal_truss_tower', name='Fractal Truss Tower (recursive storeys)', description='A tower recursively divided into shorter braced storeys, with smaller corner members overlapping earlier ones and prescribed sway. This constructs a visual hierarchy; it performs no material, strength or buckling analysis.')
        patch('soft_bodies', 'mass_spring_bench', description='A connected lattice relaxed for a fixed number of initialization steps, then displayed with prescribed rocking. The frozen geometry preserves a finite computational history; the display does not keep solving spring dynamics.')
        patch('soft_bodies', 'verlet_workbench', description='A cloth uses current and previous positions plus iterated distance constraints. In the Form Finding comparison, PASSES selects 1/4/8/12 corrections per fixed step; RESET repeats the initial condition and WIND switches the continuous lateral drive. Mean and worst relative spring errors expose different readings of the result. Legacy placements retain their ambient dial.')
        patch('soft_bodies', 'max_q_basin_room', description='A constructed comparison of a static cube in a deep well and a driven soft lattice in a shallow basin. The two bodies receive different rules; depth is not a measured common objective. Form Finding starts with DEEP/SHALLOW labels and reveals the Q proposition on INTERPRET. The installation asks which responsiveness the author values; it does not measure a universal life/death boundary.')
        patch('algorithms_misc', 'simulated_annealing', description='A Rastrigin search with random neighbouring proposals and temperature-dependent acceptance of uphill changes. Recent acceptance adapts the cooling schedule. Stagnation or HOP invokes a separate unconditional relocation and reheating rule. START T sets a future reset temperature and participates in proposal scaling; it does not directly set the running temperature.', qfep_connection='Changing which moves are admitted can make another basin accessible. The separate hop and cooling policies expose authored escape mechanisms; no run guarantees a global optimum or measures a biological Q quantity.')
        patch('soft_bodies', 'frozen_glass_vessel', description='A transparent mesh formed by a pinned ring, a radial inflation pulse, gravity and a fixed number of Verlet constraint steps at initialization. The resulting pose is retained as a vessel. Source parameters vary the process; this mesh has no collision shell to make it a walkable interior.')
        patch('soft_bodies', 'gradient_descent_optimizer', description='A point follows a finite-difference downhill update on an authored scalar surface, with a retained trail, energy readout and repeated starts. It distinguishes SMALL SLOPE from a BOUNDARY that prevents a significant feasible step. No neural network, training data or soft-body mechanics are present.')
        patch('soft_bodies', 'self_shaping_forge', description='A staged transformation interpolates raw vertices toward authored target shapes, with a prescribed progress/Q display. Retained as a sculpture about becoming; it does not optimize a measured Q objective or discover its targets through physics.')
        patch('primitives', 'impossible_end_table', description='An authored mesh arrangement of separated table parts, drawn cables and an unbothered teacup. No contact, cable-tension or rigid-body balance solver tests the pose. Its visual stillness is a question to investigate, not evidence that the displayed force system balances.')
    print('Form Finding metadata updated:', ' '.join(sys.argv[1:]) or 'source descriptions')
