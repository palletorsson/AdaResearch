"""Preserve the pre-pass sources and update the Forces journal."""
from pathlib import Path
import hashlib, json, shutil
ROOT = Path(__file__).resolve().parents[1]
OUT = ROOT/'doc/book/iterations/2026-10-08-formfinding-build-and-investigate'
NAMES = ['Descent','Catenary','Relaxation','Equilibrium','Annealing','Forge']

def main():
    OUT.mkdir(parents=True, exist_ok=True)
    files = [ROOT/f'commons/maps/FormFinding_{n}/{f}' for n in NAMES for f in ['map_data.json','tutorial.md','final.md']]
    files += [ROOT/'commons/maps/sequences/formfinding.json', ROOT/'doc/book/course/execution-plan/plan.json']
    blog = ROOT.parent/'ada_encyclopedia/src/content/blog/2026-10-08-everything-worked-and-this-happened.md'
    files.append(blog)
    manifest = {}
    for p in files:
        relative = p.relative_to(ROOT) if p.is_relative_to(ROOT) else Path('encyclopedia-blog')/p.name
        dest = OUT/'before'/relative
        dest.parent.mkdir(parents=True,exist_ok=True)
        if not dest.exists(): shutil.copy2(p,dest)
        manifest[str(relative)] = hashlib.sha256(dest.read_bytes()).hexdigest()
    (OUT/'before-sources.json').write_text(json.dumps(manifest,indent=2),encoding='utf8')
    text = blog.read_text(encoding='utf8')
    text = text.replace('We have recorded proposed tutorial carriers and checks, while the full Forces tutorial rewrite remains ahead.', 'The eleven-hall tutorial draft now follows that point through complete runnable studies. The next task is to test what a learner can build from those studies and bring each reflection into contact with the current room.')
    text = text.replace('They do not yet tell us whether every encounter feels good in a headset or whether a student can reconstruct it from the book. The next pass needs both kinds of experience.', 'They do not establish whether every encounter feels good in a headset. We have now begun a separate test of reconstruction from the book, starting with Motion.')
    addition = '''
## A student who has to make something

On 8 October, Motion became the first test of a stricter lesson: build the example, then make another experiment from it. Three equal-sized points receive the same one-second push. Their masses are one, two and four kilograms. The command ends; the motion continues. The tutorial gives the complete script and states which earlier classes and museum controls it uses.

The independent task asks for two points and two clocks. Give the one-kilogram point one second of force and the two-kilogram point two seconds. Predict their final speeds and the distances they travel before running it. Equal final speeds do not mean equal journeys. This small construction asks the student to carry a relation into a new arrangement.

We then gave a fresh AI ghost student only the lesson, its declared prerequisites and the supplied helper code. It had no access to our worked answer. It wrote predictions and scripts before execution, including its own three-kilogram, three-second experiment. Its unchanged submission passed 43 native Godot checks and 21 checks inside the actual Motion hall. These are 64 bounded claims about this submission. They are not 64 measures of human understanding.

![The ghost student's two-point comparison running inside the actual Motion hall.](/book-review/doc/book/iterations/2026-10-08-motion-ghost-student-fresh/museum/student.png)

*Two clocks, the same final speed, different distances. This is the submitted construction running in the museum, not an illustration of a proposed lesson.*

The test also found a mistake in our examiner. We first required an entire caption to stay unchanged after the pulse. The student had reasonably kept a saved result beside a live reading. We corrected the check to inspect the saved result; the student's code stayed unchanged. A test can narrow a lesson wrongly just as a summary can. Its assertions need an argument too.

The ghost identified smaller teaching edges: a two-decimal display conceals the exact 0.125 result for an eight-kilogram variation; “starting position” needs to say whether it means the beginning of the scene or another button press; two independent stopping events demand more than copying a loop. Those observations remain visible in the [fresh-student report](/book-review/doc/book/iterations/2026-10-08-motion-ghost-student-fresh/index.html).

The reflection changed with the encounter. It follows the current points, their one-second command, the space available for coasting and the recent history retained by the trail. Strong sentences survived; references to an older cube-and-ramp arrangement moved into the archive. The tutorial and reflection now ask different questions of the same situation.

This is the method we take into Form Finding: identify one operation in the real hall, provide enough code to reconstruct it, ask for a new construction, and test the claim made by the result. The student must also decide what the construction leaves out. An AI that already knows programming can expose missing dependencies and faulty checks; a human learner and a person wearing the headset are still needed to test the pace and the encounter.

'''
    if '## A student who has to make something' not in text:
        text = text.replace('\nWhat we have made is a much richer set', '\n'+addition+'What we have made is a much richer set')
    text = text.replace('covering the Forces investigations and builds of 6–7 October. All eleven images', 'updated with the Motion reconstruction test of 8 October, following the Forces investigations and builds of 6–7 October. All images')
    blog.write_text(text,encoding='utf8')
    print(blog)

if __name__=='__main__': main()
