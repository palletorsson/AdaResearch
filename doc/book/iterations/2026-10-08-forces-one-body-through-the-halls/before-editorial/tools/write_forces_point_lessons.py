"""One authored Forces revision. --write installs prose/code; default renders saved tutorials."""
from pathlib import Path
import json, html, shutil, sys, re
import markdown

ROOT=Path(__file__).resolve().parents[1]
OUT=ROOT/'doc/book/iterations/2026-10-08-forces-one-body-through-the-halls'
CODE=ROOT/'doc/book/studies/forces-point-lineage'
BEFORE=OUT/'before/commons/maps'

# These are editorial choices, not summaries inferred from artifact names.
ROWS=[
dict(map='Vectors_Act1_WhatAVectorIs',file='01_vectors.gd',title='The relation between two points',subjects=['Displacement','Magnitude','Zero and normalization','Vector addition','Signed projection'],
 encounter='Take the two familiar points. Move one, then move both by the same amount. The cylinder follows the gap. Its length changes only when their relation changes. In the other stations, two moves become one arrival, and a rail keeps one component of a movement.',
 learn='Keep the point class from Lines. This small study returns to two endpoints before adding a force. First read the displacement and its length. Then read direction. Finally inspect the X projection and the remainder in `relation()`; together they reconstruct the same displacement.',
 explain='`b.position - a.position` uses the study’s local frame. Dividing by length keeps direction while giving it unit length. The condition avoids inventing a direction at zero. `dot(Vector3.RIGHT)` keeps a signed X component: a negative result points left. Adding `along_x` and `remainder` returns the original vector. In the addition station, the same addition joins two chosen displacements. None of these arrows pushes a body.',
 tryit='Place the endpoints three metres apart along X and four along Y. Predict a five-metre gap. Translate both together; the result should stay unchanged. Then bring them together: the cylinder disappears and direction becomes zero.',
 onward='A displacement can begin elsewhere. In Launch, a vector will acquire units of metres per second and become an initial velocity.',
 keep='Keep the earlier distinction between an address and a difference, and between display scale and measured length. Replace descriptions of removed wall consoles with the current hand-held points.',
 retained='This is a description of displacement, not a force controller.'),
dict(map='VFM_05_Launch',file='02_launch.gd',title='Give the point a beginning',subjects=['Initial velocity','Constant acceleration','Position as a function of time','Model limits'],
 encounter='Stand between the two flight lanes. Press FIRE before revealing PATH. The point rises and returns to its departure height. PAIR gives the same launch speed to a second angle. Equal range can take a different amount of time.',
 learn='Continue the sphere as a visible marker. For this experiment it is frozen, not pickable and has no collision. We calculate its position from an initial velocity and elapsed time. This is the small version of Launch Arc, with one lane and a fixed launch vector.',
 explain='`initial_velocity * t` is displacement in metres. The acceleration contribution grows with time squared. Here acceleration is constant, vertical and negative, launch velocity has a positive Y component, and landing means returning to START.y. Under those conditions `duration()` gives the positive return time. The clamp stops at that time; it does not resolve an impact. The smaller code uses (3, 4, 0) m/s so both contributions are easy to follow. The museum chamber supplies angle/speed controls around the same calculation.',
 tryit='Keep the vertical component at 4 m/s and double the horizontal component from 3 to 6. Flight time remains 0.8 seconds; horizontal range doubles from 2.4 to 4.8 metres. Predict this before editing.',
 onward='Keep initial velocity and acceleration distinct. The next hall lets the engine retain velocity while a force acts for a limited time.',
 keep='Keep the analytical flight, complementary-angle comparison and explicit landing boundary. Remove placement bookkeeping from the student’s opening.',
 retained='Landing freezes the pre-impact state, without collision resolution.'),
dict(map='VFM_03_Motion',file='03_mass.gd',title='When the push ends',subjects=['Force','Mass','Physics updates','Retained velocity'],
 encounter='Three equally sized black points wait in separate lanes. Their masses are 1, 2 and 4 kilograms. Press PUSH 1 s. The push ends; the points keep travelling. The new readouts place their speeds beside the expected velocity change.',
 learn='Use three instances of the same PointBody. They differ in mass, not visible size. The new free_point.gd subclass allows physical release and removes inherited gravity and damping for this controlled comparison. A single button applies one newton for one second.',
 explain='`apply_central_force` asks the physics engine to change motion; it does not assign position. Godot integrates the force each physics step and accounts for mass. We scale only the final partial step by `interval / delta` so the pulse lasts exactly one second. We do not multiply a continuing force by delta a second time. After the pulse, no code erases velocity. The expected changes are 1, 0.5 and 0.25 m/s before contacts or another intervention. Another press adds to the current state; restart the study for a matched trial.',
 tryit='Change the third mass to 8 kg. The same pulse should add 0.125 m/s. Predict the result, then compare it with the readout. Keep your hands off during this measurement; a grab or collision is another influence.',
 onward='A force can end while its consequence continues. The field will choose the next acceleration from the point’s current address.',
 keep='Retain the title and the core distinction between ending a command and erasing velocity. Replace the old cube chamber, brake controls and obsolete pulse strength.',
 retained='The command lasts one second. The cube keeps going.'),
dict(map='Vectors_Act3_FieldsAndMotion',file='04_field.gd',title='Ask the field where you are',subjects=['Position-dependent acceleration','Sampling','Force and acceleration','Receiving a vector'],
 encounter='The vortex begins with one point, so its path can be followed through the arrows. ONE / MANY restores the circulating cargo. The same field meets more receivers; their contacts add another source of change.',
 learn='Keep the moving point and its velocity. Replace the fixed force with a function of position. The function returns acceleration: an inward part and a sideways part. Multiply by mass before handing it to the rigid body.',
 explain='`sample()` works in the station’s local X–Z frame. Its result is transformed into world direction by `global_basis`. The tangent is perpendicular to the radius; near the centre the function deliberately returns zero. `mass * acceleration` makes the commanded acceleration independent of mass. The engine still handles contacts. This small reconstruction removes the museum vortex’s additional damping to isolate the field term. The retained VectorFieldFlow comparison shows another choice: assign the sample as velocity instead of accumulating its effect as acceleration. Those are different receivers.',
 tryit='Set the point’s mass to 4 kg. With the same start and no contact, the path should stay the same because the requested force grows with mass. Then set the tangential coefficient to zero; predict the loss of the sideways contribution.',
 onward='The next force will read velocity rather than position. Carry the distinction between sampling a value and deciding how a body receives it.',
 keep='Keep the strong assignment-versus-accumulation comparison as a secondary reading. It explains why an arrow alone does not name a force.',
 retained='The field extends across the room, but it has not settled how either body will receive it.'),
dict(map='Vectors_Act4a_KineticForces',file='05_drag.gd',title='Let motion meet resistance',subjects=['Quadratic drag','Region membership','Opposing velocity','A bounded physics step'],
 encounter='Drop the same point into the three large coloured regions. Begin with DRAG ONLY. The nearby BUOYANCY button adds an upward contribution after the first comparison. RESET and DROP give each trial a shared beginning. The basin ramps nearby ask a separate question about contact friction and rolling.',
 learn='Rebuild one falling point and one region. Keep the familiar sphere; enable ordinary gravity and apply resistance only while its centre is between zero and two metres in this small study. The museum extends that membership test across three visible volumes.',
 explain='The minus sign opposes velocity. `velocity.length() * velocity` makes force magnitude proportional to speed squared. With this convention the coefficient has units kg/m. Doubling speed makes four times the drag before the numerical cap. `limit_length` prevents this drag contribution alone from reversing velocity during a large step. Gravity still acts separately. No fluid solver is hidden here, and the player’s walking adapter uses a different resistance mapping. Put the starting position on the point before adding it to the scene: a frozen kinematic teleport can otherwise manufacture velocity.',
 tryit='Increase coefficient from 0.6 to 3.0 and restart. At the same downward speed the opposing force is five times larger until capped; the falling body should settle to a lower speed. Keep buoyancy out of this first comparison.',
 onward='Resistance opposes an existing movement. A spring adds a different demand: return toward a rest length.',
 keep='Keep the distinction between an object’s force and a visitor’s controller mapping. Replace the earlier linear-drag coefficients and FIRE interface with the current quadratic region model.',
 retained='One visible medium contains two implementations. The fact that both seem slower is a beginning for comparison, not proof that they share a mechanism.'),
dict(map='Vectors_Act4b_Oscillation',file='06_spring.gd',title='Release the point; keep the attachment',subjects=['Rest length','Hooke’s law','Damping','Equilibrium','Force versus constraint'],
 encounter='One central point hangs from the frame. Pull its rose grip and release. The force-transmitting grip leaves the constrained body in the simulation. ONE / MANY brings back the other six points and their coupling springs. The hinged swings stay nearby for comparison.',
 learn='Reconstruct one spring using the familiar pickable point. While you hold this small study’s point, the hand places it; release returns it to physics. This intentionally simpler hand boundary differs from the museum’s force-transmitting rose grip. The spring always refers to the same anchor. A thin cylinder draws the attachment; it is not the force.',
 explain='The offset points from the body to the anchor. Subtracting rest length gives extension, which can be negative under compression. Stiffness converts extension into force. Damping subtracts a term proportional to velocity. Gravity is supplied by the engine, so the hanging equilibrium is longer than the spring’s unloaded rest length. The zero-length guard keeps direction finite; the 150 N cap bounds the authored model. A hinge is different: it constrains a pivot instead of applying this extensible spring law.',
 tryit='Keep stiffness and the release position fixed; change damping from 0.5 to 3.0. Predict less persistent motion. Then restore damping and double stiffness. The return should be stronger for the same extension; rest length itself has not changed.',
 onward='A spring can repeat because forces continually change velocity. In Choreography, a similar repetition will come from assigning positions.',
 keep='Keep the restoring-force/damping distinction. Begin with one visible point; defer the coupled row and separate hinge construction until the mechanism is legible.',
 retained='The later Wavefunctions chapter develops rhythm, records, phase and sound.'),
dict(map='Change_Choreography',file='07_phase.gd',title='The same return, a different cause',subjects=['Period','Phase','Relative rate','Accumulated angle','Prescribed motion'],
 encounter='The rods turn together; one offset becomes visible against their agreement. Their eyes follow you without causing the rods to turn. Look back toward the spring. Both repeat, but the repetition is being made differently. Beside the rods, the conveyor lets timing accumulate as a physical queue.',
 learn='Keep two sphere points as the tips of two thin arms. Freeze them and remove collision for this diagram. Store one angle for each arm. OFFSET changes an angle once; DRIFT changes how much one angle gains each second. The small study uses accumulated angles so a rate edit preserves current position.',
 explain='A six-second period means `TAU / 6` radians per second. Each update adds rate times delta. `sin` and `cos` place the tip on a circle. They do not calculate torque. `fposmod` keeps displayed angles within one turn and discards whole-turn counts. Equal rates preserve a phase offset; unequal rates grow it. The full phase-rod array evaluates angle from elapsed time, frequency and phase; changing its frequency can jump phase. This small continuation deliberately preserves angle, like the paired-time study. Keep that difference visible.',
 tryit='Apply OFFSET while rates are equal: the 45° gap remains. Restart, apply DRIFT, and wait thirty seconds: the 4% rate difference adds 72°. Halve that difference to 2% and predict 36°. A new input changes one term, not every part of the study.',
 onward='Keep the distinction between authored position and simulated force. The next two points attract each other; neither is assigned a circular path.',
 keep='Keep the phase rods as primary because the existing writing makes a necessary distinction between similar movements with different causes. Keep the conveyor’s “Everything worked, and this happened” passage as reflection; no new rate/queue tutorial is forced into this hall.',
 retained='These rods are driven by an angle formula. They do not keep time because a restoring force pulls them back.'),
dict(map='VFM_07_Gravity',file='08_attraction.gd',title='Let both points answer',subjects=['Pair forces','Equal and opposite contributions','Superposition','Softening','Initial conditions'],
 encounter='Begin with PAIR. Two spheres move under their mutual attraction; the visitor is not a source in this comparison. PAIR / FIVE restores five sources and admits you as another one. The added body changes the sum of the relations, not the law of each pair.',
 learn='Return to two instances of the same physical point. Give them opposite initial velocities, then calculate one force from the displacement between them. Apply it to one body and its negative to the other. Contacts and uniform gravity are off for this isolated pair.',
 explain='The source positions are world positions, so the force is already in world axes. Both masses enter its strength; the engine divides by each receiving mass during integration. Adding softening squared keeps the force finite at close range; it changes the near-field model. This is not a guaranteed circular orbit or an exact energy-conserving integrator. Equal and opposite forces preserve total momentum within numerical tolerance while the pair remains isolated. The museum’s five-source mode adds a visitor/controller boundary, so the displayed point subsystem is no longer isolated.',
 tryit='Double only a.mass while keeping the initial velocities. The shared force doubles. The acceleration of a stays the same, while b’s acceleration doubles. Predict both responses before running. Set both positions equal to check that softening returns a finite zero vector.',
 onward='Two bodies can interact while passing through one another. Support adds a different relation: a surface that prevents penetration.',
 keep='Keep the question “Who gets to stay still?” and the distinction between fixed and mutual sources. Replace the old Verlet interface instructions with the actual rigid-body pair.',
 retained='No new instruction says “be complicated.” Each pair contributes the same softened attraction, with an equal and opposite force on its partner.'),
dict(map='VFM_09_Legs',file='09_support.gd',title='What lets the cube stay up?',subjects=['Collision shapes','Contact support','Gravity','Waking a sleeping body'],
 encounter='The removable-leg table carries a load. Pull the rose leg and the contacts change. Nothing needs to command the falling path. Nearby walkers remind us that reaching a foot toward a floor and receiving physical support are different operations.',
 learn='Bring back the cube from Primitives. This small first reconstruction uses one box resting on one support. The mesh and collider share dimensions. REMOVE SUPPORT moves the supporting body sideways and wakes the load. Let the physics engine supply the result before building the full table.',
 explain='`BoxMesh` makes a surface visible; `BoxShape3D` makes its boundary available to physics. The support is static; the load is a rigid body with ordinary gravity. The starting gap is one centimetre. Contact catches the falling cube and can keep it still. Moving the support supplies no downward command to the load. `sleeping = false` ensures a body that had settled resumes simulation. The full table introduces load position and several contact patches; this first example proves the prerequisite, contact support, without teaching a gait controller.',
 tryit='Move the support only 0.1 m instead of 1.5 m and restart. Enough overlap should remain to hold the centred cube. Then use the larger displacement and compare. Keep body dimensions and gravity fixed.',
 onward='A contact can maintain rest or change motion during an impact. The bowling point returns for the second case.',
 keep='Keep “Staying still is now an outcome of contact” and the distinction between foot placement and support. Defer the support-polygon algorithm until the student needs a prediction for multiple contacts.',
 retained='Staying still is now an outcome of contact.'),
dict(map='VFM_08_Arena',file='10_impulse.gd',title='One impact, then the world',subjects=['Impulse','Momentum change','One-shot state','Collision response'],
 encounter='Pick up the black bowling point or use ROLL. Ten pins wait down the lane. The first contact changes the next one; the score records a consequence of the bodies meeting. Recoil, the cradle, the bag and the catalyst offer other interventions around this primary encounter.',
 learn='Use the same point twice for the smallest collision. One is the striker; one receives it. Apply an impulse once, then let the physics engine handle their contact. This first reconstruction is a gravity-free horizontal collision, before the lane adds floor friction, rolling and pin shapes.',
 explain='Impulse has units N·s, or kg·m/s. A 3 N·s impulse changes a 1 kg body’s velocity by 3 m/s before contact. `apply_central_impulse` belongs in the one-shot action, not in every physics update. The `used` flag prevents repeated button events from adding more impacts. Collision layers and masks admit the two points to one another. They do not prescribe an elastic outcome or tell the target which way to travel. Restart the study for the next isolated trial; the museum ROLL button remains a repeatable play control.',
 tryit='Double the striker’s mass while keeping the impulse. Its initial speed should halve. Predict that speed separately from what the collision will do. Then compare the actual collision rather than assuming ten pins must always fall.',
 onward='Force was sustained; impulse happened once. In the last hall, holding a trigger sustains an acceleration request to the player body.',
 keep='Keep collision conservation as a stated-model comparison. Move the crab/food selector out of the primary lesson; targeting is not the new operation needed here.',
 retained='Conservation constrains the total across the two bodies. It does not require each body to keep its own speed, or even its original direction.'),
dict(map='Vectors_Act5_ForceAsPlace',file='11_flight.gd',title='The player becomes the receiver',subjects=['Held actions','Controller direction','Acceleration requests','Receiver ownership','Continued velocity'],
 encounter='Take the two black points in the capability court. Aim where you want to travel and hold the triggers. Release them while you are moving. The acceleration request ends; your acquired motion remains, while gravity and contact continue. The visor can show velocity beside the request.',
 learn='Extend the same point once more. The complete thrust_point.gd below reports an acceleration only while held and activated. It identifies the actual XRTools player from the holding controller. The tiny station script creates two instances. Mount this study inside the existing capability court: its already-installed FieldCarryAdapter supplies collision-aware player movement.',
 explain='The controller’s local -Z is its pointing direction. Each point returns 11 m/s² along that direction. Two aligned points request 22; opposed points cancel. The existing museum receiver sums requests belonging to that player, adds gravity once, and retains velocity through move_player. The point never sets the camera transform. The request uses the museum’s `ada_thrust_points` contract: `receiver()`, `acceleration()` and `held()`. Dropping stops firing. This minimal continuation implements XR hands; the larger museum point also has a desktop pointer adapter.',
 tryit='Point one hand up and one down, press both triggers, and predict cancellation of thrust. Gravity still acts. Then aim both upward: 22 m/s² of requested thrust exceeds the court’s 9.8 m/s² gravity. Release without dropping and compare the continuing velocity. Physical headset comfort remains a playtest question.',
 onward='The object has become a capacity in the world. It can still be studied through the same distinctions: direction, request, receiver, accumulated state and contact. The racer and large experiments remain places to use those distinctions together.',
 keep='Keep the receiver-boundary argument. Reuse the existing player adapter instead of teaching a second locomotion system. The catalyst remains a distinct intervention tool, not another name for the thrust points.',
 retained='Writing the same vector into two objects had not made them the same kind of body. One controller erased what another had just written.')
]

def fence(path):return '\n```gdscript\n'+path.read_text(encoding='utf8').rstrip()+'\n```\n'
def make_tutorial(row,index):
    shared='../../../doc/book/course/forces-shared-code.md'
    s=f"# {row['title']}\n\n**Learning elements**\n\n"+'\n'.join('- '+x for x in row['subjects'])+'\n\n'+row['encounter']+'\n\n## Continue the object\n\n'+row['learn']+'\n\n'
    s+=f"Keep `point_body.gd`, `free_point.gd` and `study.gd` together in your Forces study folder. Their complete source and the supplied museum boundary are in [Shared code]({shared}). `PointBody` is the unchanged Lines class; `study.gd` only supplies captions, buttons and cylinder drawing. It contains no force rule.\n\n"
    s+=f"Save the following as `{row['file']}` and attach it to your existing `PointStudy` Node3D inside this museum hall. Replace the previous lesson script; keep its file. Use a clear working bay with floor-level origin and unit scale, away from other experiments. The museum supplies the room, floor, lights, camera and XR hands. Restart the study between matched trials. This reconstructs the selected operation, not every object in the hall.\n\n"
    if index==10:s+='This last lesson requires the loaded `force_capability_lab` court and its movement adapter; a bare Node3D scene will display the points but will not make a player fly. Save `thrust_point.gd` beside the other files.\n\n### thrust_point.gd\n\n<!-- student-code:thrust_point.gd -->\n'+fence(CODE/'thrust_point.gd')+'\n'
    s+=f"## Complete continuation — {row['file']}\n\n<!-- student-code:{row['file']} -->\n"+fence(CODE/row['file'])+'\n## Read what changes\n\n'+row['explain']+'\n\n## Try another beginning\n\n'+row['tryit']+'\n\n## Carry onward\n\n'+row['onward']+'\n\n'
    if row['map']=='VFM_05_Launch':s+='PAIR in the museum uses complementary angles at equal speed. Under its equal-height, uniform-gravity, drag-free model the two flights share horizontal range but usually have different durations. Keep this comparison after the single flight.\n\n'
    s+='[Reflection](final.md) asks what this encounter permits and leaves out. It need not explain all this code. The archived earlier tutorial remains in the dated [before record](../../../doc/book/iterations/2026-10-08-forces-one-body-through-the-halls/before/commons/maps/'+row['map']+'/tutorial.md).\n'
    return s

def main():
    OUT.mkdir(parents=True,exist_ok=True)
    plan=json.loads((ROOT/'commons/artifacts/force_halls/curation.json').read_text(encoding='utf8'))
    if '--write' in sys.argv:
        for i,row in enumerate(ROWS):
            (ROOT/'commons/maps'/row['map']/'tutorial.md').write_text(make_tutorial(row,i),encoding='utf8')
            contract=next(r for r in plan['halls'] if r['map']==row['map'])
            contract['lesson']=row['learn'];contract['carry']=row['onward'];contract['independent_check']=row['tryit']
            (ROOT/'commons/maps'/row['map']/'FORCES_LESSON.md').write_text(f"# {row['title']}\n\nPrimary: `{contract['tutorial_artifact']}`.\n\n"+row['learn']+'\n\nCarry: '+row['onward']+'\n\nCheck: '+row['tryit']+'\n',encoding='utf8')
        plan['date']='2026-10-08'
        (ROOT/'commons/artifacts/force_halls/curation.json').write_text(json.dumps(plan,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
        common='# Forces — shared code and the museum boundary\n\nUse the existing Endless Museum and the PointStudy established in Primitives. Add the lesson files to the same project; they require its installed Godot XR Tools and existing push_button.tscn. The shared files are supplied in full below. No dollar references or undeclared scene nodes are required.\n\nThis is a sequence of related studies, not a claim that one physical instance automatically travels through every hall. Save your source files; replace the script on PointStudy for each lesson. The code continues the point class. Ordinary physics uses metres, kilograms and seconds. Only the flight lesson requires the museum’s player receiver; its exact contract is declared there.\n\n'
        for f,desc in [('point_body.gd','Unchanged from Lines: a visible sphere, matching collision boundary and XR pickup.'),('free_point.gd','A new subclass: physical release, explicit damping and gravity settings. Each lesson chooses whether to enable gravity or freeze its marker.'),('study.gd','Supplied display furniture. Buttons emit the named action once per press. The thin cylinder is a drawing of a relation, without a collider.')]:
            common+='## '+f+'\n\n'+desc+'\n\n'+fence(CODE/f)+'\n'
        common+='## Existing receiver for the last hall\n\n`commons/artifacts/force_capability_lab/force_capability_lab.gd` sums `acceleration()` from `ada_thrust_points` whose `receiver()` matches the player. `commons/artifacts/force_field_zone/field_carry_provider.gd` performs the XRTools movement handoff. These supplied museum components own collisions and gravity. Rebuilding the player is not part of this lesson. The continuation introduces the point’s action and its receiver contract.\n'
        (ROOT/'doc/book/course/forces-shared-code.md').write_text(common,encoding='utf8')
        (CODE/'README.md').write_text('# Forces: the same point gains responses\n\nEleven complete lesson scripts for PointStudy inside the existing Endless Museum. Open the corresponding commons/maps/MAP/tutorial.md for the learning sequence. Shared code: doc/book/course/forces-shared-code.md. The last study requires the existing capability court receiver; all require Godot XR Tools and the museum push button.\n\nRun `tools/probes/forces_lesson_chain.gd` in the project with Godot 4.6, headless, XR off. The probe loads these exact files. `tools/write_forces_point_lessons.py` checks that the displayed tutorial fences still match them.\n',encoding='utf8')
    # Byte-for-byte code parity: the actual tested continuation is what the student reads.
    parity=[]
    for row in ROWS:
        s=(ROOT/'commons/maps'/row['map']/'tutorial.md').read_text(encoding='utf8')
        for name,code in re.findall(r'<!-- student-code:([^>]+) -->\s*```gdscript\n(.*?)\n```',s,re.S):
            parity.append({'map':row['map'],'file':name,'passed':code.strip()==(CODE/name).read_text(encoding='utf8').strip()})
    (OUT/'code-parity.json').write_text(json.dumps(parity,indent=2),encoding='utf8')
    assert len(parity)==12 and all(p['passed'] for p in parity)
    (OUT/'lesson-decisions.json').write_text(json.dumps(ROWS,ensure_ascii=False,indent=2),encoding='utf8')
    for name in ['forces_lesson_chain.json','forces_lesson_chain.log']:
        p=ROOT/'ada_run'/name
        if p.exists():shutil.copy2(p,OUT/name)
    css='body{margin:0;background:#eae7df;color:#19191e;font:18px/1.65 Georgia,serif}main{max-width:1080px;margin:auto;padding:40px}h1{font-size:2.7rem;line-height:1.1}h2{margin-top:2em}nav{font:14px system-ui;display:flex;flex-wrap:wrap;gap:12px}a{color:#763d59}article{background:#fffdf8;padding:32px;margin:24px 0;border-top:4px solid #26252b}pre{background:#20232b;color:#f5ede3;padding:20px;overflow:auto;font:14px/1.5 Consolas,monospace}code{font-family:Consolas,monospace}img{width:100%;height:auto}blockquote{border-left:3px solid #a8798e;margin-left:0;padding-left:20px}.two{display:grid;grid-template-columns:1fr 1fr;gap:20px}.meta{font:14px/1.5 system-ui}.badge{background:#ede4e8;padding:10px}@media(max-width:800px){.two{grid-template-columns:1fr}main{padding:16px}}'
    def md(s):return markdown.markdown(s,extensions=['fenced_code','tables','footnotes'])
    def page(title,body):return '<!doctype html><html lang="en"><meta charset="utf-8"><meta name="viewport" content="width=device-width"><title>'+html.escape(title)+'</title><style>'+css+'</style><main><nav><a href="index.html">Review</a><a href="tutorials.html">All eleven tutorials</a><a href="shared.html">Shared code</a><a href="final.html">Existing reflections</a></nav>'+body+'</main></html>'
    (OUT/'shared.html').write_text(page('Shared code',md((ROOT/'doc/book/course/forces-shared-code.md').read_text(encoding='utf8'))),encoding='utf8')
    tutorial=[];final=[];summary=[];cards=[]
    current=None
    p=OUT/'forces_lesson_chain.json'
    if p.exists():current=json.loads(p.read_text(encoding='utf8'))
    for i,row in enumerate(ROWS):
        m=row['map'];src=ROOT/'commons/maps'/m
        for dest,name,collection in [('tutorial','tutorial.md',tutorial),('final','final.md',final)]:
            text=(src/name).read_text(encoding='utf8')
            # Resolve museum/book image URLs to local files in this offline review.
            text=re.sub(r'\]\(/book-review/([^\)]+)\)',lambda x:']('+ (ROOT/x.group(1)).as_uri()+')',text)
            rendered=md(text)
            def resolve_link(match):
                url=html.unescape(match.group(1))
                if url=='final.md':return 'href="final.html#'+m+'"'
                if url.endswith('forces-shared-code.md'):return 'href="shared.html"'
                if not url.startswith(('http:','https:','file:','#','/')):
                    target=(src/url).resolve()
                    if target.exists():return 'href="'+target.as_uri()+'"'
                return match.group(0)
            rendered=re.sub(r'href="([^"]+)"',resolve_link,rendered)
            collection.append(f'<article id="{m}"><p class="meta">{i+1:02} / {m}</p>{rendered}</article>')
            if dest=='tutorial':(OUT/(m+'.html')).write_text(page(row['title'],rendered),encoding='utf8')
        summary.append(f"## {i+1}. {m} — {row['title']}\n\n"+row['encounter']+' '+row['learn']+' '+row['onward']+'\n')
        image=OUT/'museum'/m/'primary.png'
        visual=f'<img src="museum/{m}/primary.png" alt="Actual Endless Museum view of {html.escape(row["title"])}">' if image.exists() else '<p class="meta">Museum capture pending.</p>'
        extra=OUT/'museum'/m/'expanded.png'
        if extra.exists():visual+=f'<details><summary>Open the full experiment</summary><img src="museum/{m}/expanded.png"></details>'
        student=OUT/'museum'/m/'student.png'
        if student.exists():visual+=f'<details><summary>The exact student code running in this museum hall</summary><p class="meta">Temporary probe instance of PointStudy, beside the existing exhibit. This extra copy is not installed permanently.</p><img src="museum/{m}/student.png"></details>'
        old=(BEFORE/m/'tutorial.md').read_text(encoding='utf8')
        before_title=old.splitlines()[0].lstrip('# ')
        cards.append(f'<article id="{m}"><p class="meta">{i+1:02} / {m}</p><h2>{html.escape(row["title"])}</h2>{visual}<p>{html.escape(row["encounter"])}</p><div class="two"><div><h3>Before</h3><p>{html.escape(before_title)}</p><a href="before/commons/maps/{m}/tutorial.md">Full earlier tutorial</a></div><div><h3>After</h3><p>{html.escape(row["learn"])}</p><a href="{m}.html">Read the tested continuation</a></div></div><p class="badge"><strong>Writing decision:</strong> {html.escape(row["keep"])}</p><blockquote>{html.escape(row["retained"])}</blockquote><p class="meta">The quoted line is retained as editorial evidence; final.md has not been rewritten in this pass. Some older exhibit-specific instructions in those reflections still need alignment.</p></article>')
    (OUT/'tutorials.html').write_text(page('Forces — eleven tutorials','<h1>One body gains responses</h1>'+''.join(tutorial)),encoding='utf8')
    (OUT/'final.html').write_text(page('Forces — existing reflections','<h1>Existing reflective sequence</h1><p>Preserved for editorial comparison. Several passages name earlier interfaces; this is not a claim that every described artifact is currently placed.</p>'+''.join(final)),encoding='utf8')
    (OUT/'summaries.md').write_text('# Forces — eleven lesson summaries\n\n'+ '\n'.join(summary),encoding='utf8')
    (OUT/'tutorials.md').write_text('# Forces — complete tutorial continuations\n\n'+'\n\n---\n\n'.join((ROOT/'commons/maps'/r['map']/'tutorial.md').read_text(encoding='utf8') for r in ROWS),encoding='utf8')
    nav='<nav>'+''.join(f'<a href="#{r["map"]}">{i+1}. {html.escape(r["title"])}</a>' for i,r in enumerate(ROWS))+'</nav>'
    result=f"{sum(c['passed'] for c in current['checks'])}/{len(current['checks'])} Godot checks" if current else 'Godot checks pending'
    header='<h1>One body gains responses</h1><p>Eleven existing Forces halls. One focused reconstruction in each; the familiar point returns wherever its shape remains useful. The cube returns for contact support. The player becomes the final receiver.</p><p>Good writing can steer the plan. Phase rods remain primary in Choreography because the existing text makes prescribed motion distinct from a spring. The conveyor stays beside them as a physical consequence.</p><p class="badge">'+result+'; 12 displayed-code blocks match the tested files. Jolt integration and simulated XRTools input; physical headset testing belongs to your visit.</p><p><a href="summaries.md">One file: all lesson summaries</a> · <a href="tutorials.md">Complete tutorials as Markdown</a> · <a href="forces_lesson_chain.json">Assertions</a> · <a href="capture-status.json">Museum capture checks</a></p><p>Before/after below refers to the tutorial revision. Images are new renders inside the actual museum. Expanded views show the optional full experiment. Existing final.md files are preserved; old control descriptions in them remain a separate editorial pass.</p>'
    (OUT/'index.html').write_text(page('Forces — one body through the halls',header+nav+''.join(cards)),encoding='utf8')
    print('Rendered eleven tutorials; code parity:',len(parity),'/',len(parity))

if __name__=='__main__':main()
