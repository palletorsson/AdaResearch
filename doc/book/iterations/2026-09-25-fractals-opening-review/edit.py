from pathlib import Path
import hashlib,json
r=Path.cwd();o=Path(__file__).resolve().parent;base=json.loads((o/'baseline.json').read_text())
changed=[]
def save(rel,text):
 p=r/rel
 assert hashlib.sha256(p.read_bytes()).hexdigest()==base[rel], 'Concurrent change: '+rel
 raw=p.read_bytes();newline='\r\n' if b'\r\n' in raw else '\n'
 p.write_bytes(text.replace('\r\n','\n').replace('\n',newline).encode('utf-8'))
 changed.append(rel)
def load(m,name='final.md'):return (r/'commons/maps'/m/name).read_text(encoding='utf-8')
m='Fractal_Recursion';text=load(m)
old=next(p for p in text.split('\n\n') if p.startswith('Seven levels produce'))
new='''Seven levels produce seven squares. One call makes one further call. Each square repeats the shape of the one around it at a smaller size. That resemblance gives us a way towards fractals, but it is not enough to define one. A straight line is also made of smaller lines; looking closer brings no new structure. In the exact fractal constructions ahead, smaller parts repeat the whole and fine structure continues however far we zoom.[^1] Here we reach a last square. The room has stopped where a rule could go on.

We could also write this particular descent as a loop. Seeing a square inside another square does not tell us which program made it. We had to look behind the image.'''
assert old.endswith('We had to look behind the image.')
text=text.replace(old,new)
text=text.replace('Here is the self-call from the artifact:', 'Here is the self-call from the artifact:[^noc]')
oldnote=next(p for p in text.split('\n\n') if p.startswith('[^1]:'))
text=text.replace(oldnote,'''[^1]: Benoît Mandelbrot coined *fractal* in 1975. The distinction here between self-similarity and fine structure follows Daniel Shiffman's introductory discussion in [“What Is a Fractal?”, *The Nature of Code*](https://natureofcode.com/fractals/#what-is-a-fractal). It is a way into the examples, not a complete mathematical definition.

[^noc]: The square and ring source files credit Daniel Shiffman's *The Nature of Code*, Examples 8.2 and 8.3, adapted from Processing into GDScript for VR. The compact desks and their LAYOUT, COLLAPSE and PACKING comparisons are additions in this project. The example numbers follow the source-file headers.''')
save(f'commons/maps/{m}/final.md',text)
m='Fractal_RecursiveTrees';text=load(m)
old=next(p for p in text.split('\n\n') if p.startswith('RESET returns'))
text=text.replace(old,'''RESET returns to the trunk and the original settings. This specimen uses no random variation. Repeat the same choices and the same branches return. Now press GROW once more and watch where the new branches appear. Every unfinished tip advances in the same press. The desk holds those tips in a queue and works through one generation at a time.

We could instead follow one branch all the way to its last twig before returning for its siblings. A self-call can take that route. With the same fixed angles and lengths, the completed tree could look the same; watching it being made would be a different encounter. Here the next generation waits for your hand. The surrounding museum continues.''')
old=next(p for p in text.split('\n\n') if p.startswith('Three trees in this hall'))
text=text.replace(old,'''The small tree further in begins with a sentence. A short string is rewritten four times, then read as steps and turns. Its angle control changes how those turns are drawn. The letters can stay while the branches move.

Look back at the two trees near the entrance: the growing tree keeps its proportions; the red tree repeats a seeded draw. Beside them, the little grammar tree gives instructions letters we will learn to read in a later hall. Which one most readily becomes a tree in your eyes? That recognition arrives before any of them has met soil, light or wind.''')
save(f'commons/maps/{m}/final.md',text)
intents={
'Fractal_Recursion':'''# Where does “again” spend itself?

First hall of Fractals, following CA_EdgeOfChaos and leading to Fractal_RecursiveTrees. The previous hall compared neighbouring exchanges; this one inspects instructions that ask for another call. A finite recursive construction is the starting encounter, not evidence that the room contains an infinite fractal.

Four primary works carry different questions. The nested squares separate a depth allowance, a minimum size and what an eye can resolve. The rings make four descendants per call, so another level has another cost. Subdivision spends the same twelve splits by DRILL, SPREAD or LOTS; selection distributes the detail. The chair keeps and discards cells, then transforms and adds parts through five authored stages. Its name does not make those stages self-calls.

The critical opening lies in allocation and recognition: where does the next operation go, what becomes hard to distinguish, and which chosen arrangement becomes a chair? Keep the supporting collection available for other readings. The dark sphere is a secondary remnant, not the chapter's organizing work. Object count is not an entropy measurement; resemblance does not establish topology or implementation.

Continue by giving branches positions, directions and lengths. A future bodily enlargement could make the stopping condition or allocation felt at room scale; the current desks should not be described as walkable or climbable structures. The earlier intent is preserved in the opening-review baseline, rather than treated as a report of installed behavior.
''',
'Fractal_RecursiveTrees':'''# Where will the next branch go?

Second hall of Fractals, between Fractal_Recursion and Fractal_CantorSet. Give the previous hall's repeated calls a position, direction and inherited length. Start with an unfinished trunk and let the visitor anticipate a fork before seeing it.

The growing tree uses fixed angles and ratios in this hall. GROW evaluates a whole generation from its queue; ANGLE and LENGTH change the placement of existing branches; FORKS changes their number. The red block tree uses a fixed seed within a bounded construction rule. STRATA, REACH and ENDS expose the same built tree. Further in, the small grammar tree rewrites a string and draws its instructions. These are particular implementations to compare, not exclusive categories of tree making.

The critical question begins when these constructions become trees in our eyes. None responds to soil, light or shade. A seed repeats one permitted arrangement without enlarging what the rule permits. Branches in the growing specimen have no colliders: an opening in their outline does not yet offer shelter or a climbing route. Keep that material limit as a possible development lead, not a reason to erase the desire for another body.

All twelve authored works remain. Inverted trees, the small Möbius specimen, living paper and subdivision objects support other investigations; a Möbius surface is not proof of “topological recursion.” The dark sphere remains secondary. Lead onward through Cantor's removal rule: another generation can be made by taking something away.

The old parameter-explorer wish is partly met by the existing six-control desk. Headset reach and the larger shelter encounter remain separate questions. The earlier intent is preserved in the opening-review baseline.
'''}
for m,text in intents.items():save(f'commons/maps/{m}/intent.md',text)
(o/'changed-files.json').write_bytes((json.dumps(changed,indent=2)+'\n').encode())
print('Updated',len(changed),'canonical files; original line endings preserved')
