from pathlib import Path
r=Path.cwd();o=r/'doc/book/iterations/2026-09-25-forces-review-comments'
changes={
'Vectors_Act1_WhatAVectorIs':[("The point rooms gave us addresses; transformation let us move them. Here we can carry a relation from one place to another.","The point rooms gave us addresses; transformation let us move them. The particles in the last room followed directions. Here we can carry a relation from one place to another.")],
'Vectors_Act4a_KineticForces':[("The same desktop movement command carries you progressively less quickly. XR stick movement uses the same adaptation.","The same movement of the stick carries you progressively less quickly.")],
'Change_Choreography':[("Carry the distinction forward: a parameter can change a pattern, but the permissions of the body still need to be built.","Carry the distinction forward: a parameter can change a pattern, but the permissions of the body still need to be built.\n\nNext, gravity. The place the spring returned to acquires a body of its own. Will the centre remain still when another body answers it?")],
'VFM_07_Gravity':[("The quarter-metre softening keeps close encounters finite by changing the attraction near coincidence.","The quarter-metre softening, called Plummer softening, keeps close encounters finite by changing the attraction near coincidence.[^plummer]")],
'Vectors_Act5_ForceAsPlace':[
("Lift the field off the floor by even a little and the same slider becomes the most powerful control on the console.","Tilt the field away from vertical. YAW begins to turn its horizontal part; as that part grows, the turn becomes easier to see."),
("So the console tells you: while the field is vertical the readout says the yaw is idle and at what bearing it is waiting, and a faint arrow on the stage holds that bearing where you can see it.","The console marks a small neighbourhood around either pole as idle too, even though a slight horizontal part is already there. Its readout gives the waiting bearing, and a faint arrow on the stage holds that bearing where you can see it."),
("The last slider stops at fifteen.","The last slider stops at fifteen metres per second squared."),
("Three glass cubes wait near the machine. Take one and move it slowly. Stop your hand. Its motion arrow should disappear; a body at rest need not invent a direction merely to remain a useful exhibit.","Three glass cubes wait near the machine. Take one and move it slowly. Let your hand settle. The motion arrow disappears when the sampled movement becomes small enough. Even stillness has a threshold in this picture."),
("Ordinary keyboard or stick steering resumes when your feet leave the volume.","Leaving the volume ends this override; the return to ordinary stick steering also needs support under your feet."),
("At the far face, the desktop walker returns horizontal movement to its ordinary input controller and keeps its vertical velocity under ordinary gravity.","At the far face, the carry receiver lets go. In the air, you keep the motion you leave with while ordinary gravity changes it. Once your feet find the floor, the stick can steer again.")]
}
for m,replacements in changes.items():
 p=r/'commons/maps'/m/'final.md';s=p.read_text(encoding='utf-8-sig')
 for a,b in replacements:assert s.count(a)==1,(m,a);s=s.replace(a,b)
 if m=='Vectors_Act5_ForceAsPlace':s='# What carries you across?\n\n'+s
 if m=='VFM_07_Gravity':s=s.rstrip()+'\n\n[^plummer]: The added squared length softens the short-distance interaction. The [galpy Plummer potential documentation](https://docs.galpy.org/en/latest/reference/potentialplummer.html) gives the corresponding potential; this hall uses a softening length of 0.25 metres.\n'
 p.write_text(s,encoding='utf-8')
print('Five chapters receive scoped revisions; all code excerpts retained.')
