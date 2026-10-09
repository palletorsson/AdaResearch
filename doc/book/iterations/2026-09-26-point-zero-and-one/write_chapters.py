from pathlib import Path
import hashlib,json,re
r=Path.cwd();o=Path(__file__).resolve().parent
old=(o/'before/commons/maps/Point_One/final.md').read_text(encoding='utf-8')
base=json.loads((o/'baseline.json').read_text())
def write(path,s):
 p=r/path
 if path in base: assert hashlib.sha256(p.read_bytes()).hexdigest()==base[path],path
 p.parent.mkdir(parents=True,exist_ok=True);p.write_bytes(s.encode('utf-8'))
footnotes={line.split(']:',1)[0][2:]:line for line in old.splitlines() if line.startswith('[^')}
zero=old[old.index('… You arrive late.'):old.index('<!-- @the_invisible_point -->')]
zero=zero.replace('… You arrive late.[^1]','''… You arrive late.[^1]

<!-- @arrival_shaft -->

You fall through a dark shaft into a lit room. In front of you, a number is running. Like Alice, you have entered before you know what kind of place you have entered. The floor catches you; the number goes on.''')
zero=zero.replace('We begin with a number that includes something we did not witness.','''We begin with a number that includes something we did not witness.

This room has to be made again while you are in it. Turn your head and another view is drawn. That is the demand of real time here: the program must keep answering a body that has already moved. The counter gives this continuing work a visible trace. It does not count the years it took to make the room possible.

There is another clock outside the room. Software is revised while we are learning to use it. AI makes the feeling of arriving late harder to put aside: before we understand one possibility, another is offered. How much of our time can go into catching up? When do we get time to play?''')
zero=zero.replace('Like Alice after the White Rabbit, we could keep following one opening into another. But we still have a point to find. We carry a question forward; others fold behind us.','''Like Alice after the White Rabbit, we could keep following one opening into another. The desire is real. So is the time it takes from other things. We want to see what happens next, even when we cannot yet judge what we are risking.

We can call that desire progress. We can also ask where it becomes a death drive: an insistence on going further that makes the cost of continuing harder to see. The room can hold the question without settling it. We are here because we wanted to enter.

First light, or the light at the end of a tunnel? The folding frames keep offering a further opening. Light makes a way visible before we know where it leads.''')
zero=zero.replace('Find the black sphere with its pink glow and wireframe cube. Zero has been given a place in this room too.','Find the black sphere with its pink glow and wireframe cube. Its label says “Point zero”. Zero has been given a place in this room too.')
zero='# Point Zero — You arrive late\n\n'+zero.strip()+'''\n\n<!-- @ -->

We have chosen a place to count from. In the next corridor, a label is waiting for something to appear above it.

Point one.

'''+ '\n\n'.join(footnotes[k] for k in ['1','point-one-room-history','point-one-ahmed-reach'])+'\n'
write('commons/maps/Point_Zero/final.md',zero)

opening='''# Point One — A body for a position

<!-- @point_absent -->

The corridor begins with a label: “Point one”. Above it, nothing.

There is somewhere to look because the words have given you a place to look. The name arrives before its object. You can stand in front of it, lean closer, pass your hand through the empty space.

<!-- @point_visible -->

Further along, the same label sits below a small white sphere. Now there is something to look around. Its curved surface holds a highlight; as you move, the highlight moves too.

Walk towards it. The sphere does not stop you. Your view can pass through its surface and come out the other side. You have crossed something you could see.

A mesh supplies the visible shape. Drawing it has not made a boundary for the visitor's body.

<!-- @point_solid -->

The next white sphere has the same size and finish. It says “Point one” too. Try the same approach.

This time a collision body occupies the place the surface describes. Your movement meets a limit. The difference was invisible until you tried to cross it. Two objects can look alike and permit different lives around them.

The program has given the second sphere a `SphereShape3D` inside a `StaticBody3D`. One part tells the renderer what to draw; another tells the physics system where movement meets resistance. We have made those surfaces coincide. They could have been arranged otherwise.

<!-- @point_held -->

At the fourth label the sphere is black. Take hold of it. The place you were looking towards can now leave with your hand.

Its visible size has not changed. Pickup code has added another relation: while held, the body's movement answers to yours. Put it down and look back at the label. “Point one” stays in the corridor; the point has gone elsewhere.

Which part did the name belong to? The position, the sphere, the possibility of taking hold?

A mathematical point specifies a location without extension.[^point-one-euclid] Each sphere occupies space. Each station also has a different address, although its label repeats the same name. A position can be written with three numbers:

```gdscript
var point_position := Vector3(1.0, 0.5, 0.0)
```

`Vector3` holds the components X, Y and Z. Here they name a position relative to an origin. They say nothing about white or black, a radius, a collision, a hand. Those decisions need something beyond the address.

The corridor lets us encounter the decisions separately. In an ordinary object they arrive together, and we can forget that what appears solid has been given a separate reason to resist us.

Keep the black point. There are other ways to approach it in the wider room: arrows meeting at an empty centre, a screen unfolding the code, another point whose surface changes in your hand. We can return to them. For now, carry this one towards the coloured frame.

'''
middle=old[old.index('<!-- @coordinate_readout -->'):old.index('<!-- @ -->')]
middle=middle.replace('The opening between the two areas lets you carry the same point towards the coloured frame. Its guides and the card follow the point you are already holding.','The corridor opens into the coordinate room. Its guides and the card follow the point you are already holding.')
middle=middle.replace(" Remember the case's `FOCUS`: its 1.25 was measured from the case, too.",'')
ending='''<!-- @point_pedestal -->

## The size of a point

Before leaving, you meet a white sphere on a pedestal. It is 1.3 metres across. The text still says “Point one”.

The small sphere travelled in your hand. This one asks you to walk around it. A change in size has changed how much of the room you can see, and where your body can go. Its centre can still be written with three numbers. The same short address leaves a great deal unsaid.

Look from the sphere you carried to the sphere on the pedestal. We have given each a body and called each a point. Neither has to stop being interesting once we know the difference.

The next room brings two points into relation. A line begins.

'''
one=opening+middle+ending+'\n\n'.join(footnotes[k] for k in ['point-one-euclid','point-one-haraway'])+'\n'
write('commons/maps/Point_One/final.md',one)

for m,title,blurb,technical in [
 ('Point_Zero','Late arrival','You fall into a room that has already begun. A number keeps moving; behind the window, frames fold into frames. We find somewhere to count from without finding the first beginning.',
  'The native museum arrival remains governed by gravity and its existing arrival drop. The new open shaft surrounds that route without a cap. At map (7,1) it faces the frame counter at (7,4). Folding Past remains the configured lobby window. The origin at (3,5) owns the Point zero beam label. Engine.get_process_frames counts process frames, not elapsed seconds or software revisions. Software change, inherited work and the death-drive question are distinct historical and critical registers in final.md.'),
 ('Point_One','A body for a position','The same name meets an absence, a white surface, a solid sphere and a black sphere you can carry. The coordinate frame follows the carried body. Before leaving, the point grows larger than your hand.',
  'The opening comparison is point_condition.gd: absent, visible, solid and held share the Point one label; visible, solid and held have radius 0.14 m. Only solid has a fixed SphereShape3D. Held reuses interactive_point_origin.tscn, with a matching sphere collider, black material and coordinate_id point_one_main. Existing WORLD/LOCAL readouts and CoordinateSystem3M adopt that exact ID. The force variant remains a secondary comparison with a different ID. The closing pedestal variant has radius 0.65 m, centre height 1.40 m and pedestal top 0.75 m: the surfaces meet. Native desktop checks do not establish headset comfort or user understanding.')]:
 write(f'commons/maps/{m}/blurb.md',blurb+'\n')
 write(f'commons/maps/{m}/intent.md',f'# {title}\n\n'+blurb+'\n\n'+('First chapter of Primitives, preceding Point_One. Keep the author’s inherited-work paragraph, Alice, folding, risk and available time. Do not collapse the process loop into historical acceleration. The origin is a convention, not a claim to reach the beginning of history.' if m=='Point_Zero' else 'Second chapter of Primitives. Let the reader notice a difference before naming its construction. The body tests whether a visible limit also resists or can be carried. Keep coordinates and tolerance concrete; allow the final sphere to remain a sculpture, not only an explanation.')+'\n')
 write(f'commons/maps/{m}/summary.md',f'# {title}\n\n'+blurb+'\n\n'+technical+'\n')
 # Keep the earlier technical companion as a source record in the baseline.
 write(f'commons/maps/{m}/technical.md',f'# {title} — implementation\n\n'+technical+'\n')
write('commons/maps/Point_Zero/critical.md','''# Arriving inside inherited work

The first light is a first sight for this visitor, not the beginning of the world. The counter includes frames they did not witness. The room borrows code, labour, historical conditions and the visitor’s time. A chosen origin gives them somewhere to count from without settling that inheritance.

The writing can ask whether technical acceleration makes room for play or consumes the time for it. “Death drive” enters as the author’s question about the desire to push past limits, not a diagnosis of AI or a scientific account of a render loop. Alice offers curiosity and risk together. Keep that invitation open.
''')
note_dir='doc/book/iterations/2026-09-25-private-writing-notes/halls/'
write(note_dir+'Point_One.md','''# Point_One

**Desire.** Find out what a point can become without changing its name. Let looking, passing through, being stopped and taking hold supply the questions.

**Route.** Empty place → white surface → white solid → black held sphere → two coordinate reports → a target with tolerance → 1.3 m sphere on a pedestal.

**Explain / linger.** Mesh, collision and pickup are separate decisions, discovered through the repeated corridor. Coordinates need a reference; a target needs a tolerance. Leave room for pleasure in carrying the small sphere and walking around the large one.

**Neighbor.** Point_Zero now carries late arrival, borrowed work, folding, Alice and the chosen origin. Do not repeat the whole opening here. Point_Lines can begin with a relation between two positions.

**Other invitations.** Retain the invisible-point case, code screen, force variant and other secondary works. Their role need not be settled by this first walk.
''')
write(note_dir+'Point_Zero.md','''# Point_Zero

**Desire.** Arrive in time to play, even though the world has already begun.

**Encounter.** A bodily fall opens onto the frame counter. Folding frames tempt a return to the first frame. The origin carries the Point zero label. The removable “you” leaves “are here” behind.

**Clocks.** Keep three registers distinct: process frames, the historical work making the room possible, and the pressure of changing tools and AI. Death drive is an investigative question about desire, cost and risk.

**Handoff.** Choose somewhere to count from; then Point_One asks how a position acquires a body. Preserve the author’s inherited-work paragraph exactly.
''')
print('Chapters written:',len(zero.split()),'and',len(one.split()),'words including code and notes')
