from pathlib import Path
import json,hashlib
R=Path.cwd();H=R/'doc/book/iterations/2026-09-20-qfep-sandbox-review';B=H/'before';M='QFEP_Sandbox';D=R/'commons/maps'/M
def read(p):return json.loads((R/p).read_text(encoding='utf-8-sig'))
def write(p,d):(R/p).write_text(json.dumps(d,ensure_ascii=False,indent=2)+'\n',encoding='utf-8')
def md(n,s):(D/n).write_text(s,encoding='utf-8')
m=json.loads((B/'commons/maps'/M/'map_data.json').read_text(encoding='utf-8'))
m['map_info'].update(name='Where the control reaches',title='Connect / Cut',description='Repeat a handle movement before and after connecting one reactor. Compare the handle setting with the value the receiver actually uses.')
m['map_info']['metadata']['learning_objectives']=['Distinguish local feedback from a received input','Connect and cut one explicit control route','Compare one parameter at a time','Separate an authored visual response from a measured physical quantity']
m['map_info']['museum'].update(artifact_placement='map',sculpture_clear_rects=[[0,0,14,16]])
w,h=14,16
structure=[['w' if x in [0,w-1] or z in [0,h-1] else '1' for x in range(w)] for z in range(h)]
for z in [0,h-1]:
 for x in [6,7,8]:structure[z][x]='1'
for x,z in [(8,5),(7,9),(11,12)]:structure[z][x]='2'
inter=[['' for x in range(w)] for z in range(h)]
for x,z,t in [(2,2,'tt:180:qfep_mastery:180:0.5'),(3,11,'reactive_particles:0:1:1#field_seed:401'),(5,5,'lambda_slider:180:0:1#calibration:none'),(8,5,'phi_slider:180:0.1:1#sign_study:on#phi:0'),(11,12,'qfep_formula_3d:180:0.05:1'),(7,9,'qfep_reactor:180:0.3:1#wiring_study:on')]:inter[z][x]=t
utilities=[['' for x in range(w)] for z in range(h)]
utilities[1][7]='s';utilities[2][7]='sub:map';utilities[14][7]='t'
m['layers']={'structure':structure,'utilities':utilities,'interactables':inter}
m['documentation'].update(summary='One control route can be connected, cut and repeated.',layout='Open 14 by 16 laboratory; front handles and connection panel, receiver on a rear plinth, independent secondary works to the sides.',objective='Compare offered values with the inputs one receiver uses.',key_elements=['Lambda rail and signed Phi rail remain full size','CONNECT / CUT accepts or holds input values for one reactor','REPEAT restarts the receiver animation with its current values','Independent particle field and formula remain secondary comparisons'])
write(f'commons/maps/{M}/map_data.json',m)
t=(B/'commons/maps'/M/'final.md').read_text(encoding='utf-8')
a=t.index('Repeat one handle movement');b=t.index('Give the proposed experiment',a)
t=t[:a]+'''<!-- @qfep_reactor -->

Repeat one handle movement while attending only to its local feedback. Then repeat it while attending to the reactor. At first the route is cut. The console shows the values at the handles and, separately, those the reactor uses. Your hand can travel while the receiver's numbers stay where they were. The orb keeps pulsing. It was already doing that before you arrived.

Press CONNECT / CUT. The paths light up and the receiver takes the current handle values. Keep PHI still and move LAMBDA again. Compare the two readings before looking at the colour and the speed of the emitted particles. Something now carries your gesture beyond the rail.

Cut the route again. Move the handle back. The receiver keeps its last inputs, including the one you were trying to undo. Disconnection has left a memory of your action. It has not restored an innocent beginning.

Connect again and leave LAMBDA steady. Move PHI across zero. On this reactor it lightens or darkens the colour; it does not measure a changing entropy. The same signed weight that directed particles on the earlier rail has arrived in another body and acquired another consequence. The name of the parameter did not decide that consequence. Someone wrote this mapping.

REPEAT restarts the reactor's pulse and jitter from the same animation start while keeping the values it received. Choose a setting, repeat it, then alter one handle and repeat again. Follow something specific: the pulse, the colour, or the maximum particle speed printed at the receiver. Changing both handles together is also available. First give yourself something to compare it with.

Look toward the neighbouring particle field. It has its own movement and has not joined this connection. Your gesture and its motion occupy the same room. That proximity can be persuasive. The lit paths tell a narrower story: these two handles reach this receiver.

''' + t[b:]
t=t.replace('Give the proposed experiment a concrete observation: a deformation, a persistence time or a numerical error. “More alive” would still require an explanation of what that phrase is intended to describe.', 'You can now make and interrupt a connection. You cannot yet use these handles to invent another response. What would have to change for that freedom to become available too? “More alive” still requires an account of what you noticed, and of whose possibilities the change supports.')
t=t.replace('<!-- @ -->\n\n','')
md('final.md',t)
archive='# Earlier Sandbox proposals\n\nPreserved 20 September 2026. These texts imagine a global reactive laboratory, live entropy measures and actions not supplied by the current implementation. They remain development material. The restored encounter makes one explicit route inspectable; it does not fulfil every earlier proposal.\n'
for n in ['technical.md','tutorial.md','critical.md']:archive+='\n---\n\n## Preserved '+n+'\n\n'+(B/'commons/maps'/M/n).read_text(encoding='utf-8')
md('design-proposals.md',archive)
md('technical.md','''# A value needs a receiver

Edge of Chaos compared numerical steps while keeping a model and its start fixed. Sandbox compares the presence of a connection. Two existing controls and one existing qfep_reactor make the experiment; the separate particle field and formula retain their independent behaviour.

The historical reactor and particle field searched the group qfep_slider. The handles register elsewhere. A matching parameter name therefore supplied no working route. The opt-in wiring_study mode uses the actual LambdaSlider and PhiSlider instances beside the reactor, under the same parent hall. It requires exactly one of each and fails closed if either is missing or ambiguous. It never searches another hall. The study reactor leaves global reactive aggregation and bypasses the historical group lookup. Other reactor placements retain their earlier mode.

The console receives handle signals in both states so it can show the offered values. Delivery is conditional:

```gdscript
func _lambda_changed(value: float) -> void:
    if connected:
        receiver.set_lambda(value)
        receiver._update_visuals()
    _refresh()
```

CONNECT immediately sends both current handle values. CUT stops subsequent delivery and retains the last receiver values. The readout reads current_lambda and current_phi from the receiver, not copies of the handle labels. It also reads the actual particle material's initial_velocity_max. Both illuminated paths terminate at this receiver; the independent field is not wired as a side effect.

In this existing reactor, lambda selects a colour gradient, particle maximum launch speed 0.1 + 0.4*lambda, spread, an authored population band and pulse/jitter branches. Phi lightens the colour by phi*0.3 for positive values and darkens it for negative values. It does not change the reactor's temporal sensitivity. These are authored mappings, not measurements of entropy or universal biological regimes. The internal toy score (1-lambda)-0.8*lambda+0.2*phi supplies no entropy estimate and is not displayed as scientific evidence.

REPEAT resets time, pulse phase and the reactor's seeded random generator, retaining connection and inputs. It restarts its GPU particle emission; histories of individual GPU particles are not asserted bit-identical. Identical CPU update steps from this start are checked separately from rendered screenshots. It does not reset the whole hall, visitor, or independent particle field.

The restored map has three rectangular 14 by 16 layers, a clear entrance and exit, full-size handles, and separate support cells for Phi, reactor and formula. Its former inconsistent layers and large central block are retained in the review snapshot. All six artifact families remain. Reactor becomes a third primary because its received values and response now provide essential evidence. The old tt entry remains secondary but has no living scene in the current registry.

The remaining chapter asks what can change the response law itself. This panel can connect, cut and replay a particular mapping. It cannot edit that mapping. Synthesis applies local controls to a deformable body next.
''')
md('tutorial.md','''# Connect one route

Move a handle before connecting it. Compare the handle value with the reactor's used value. Press CONNECT / CUT and repeat the gesture. Leave the other handle steady.

Cut the route, then move the handle back. The reactor holds its last inputs. Connect again to deliver the present settings. REPEAT restarts its animation while retaining those inputs.

Lambda changes this reactor's colour and particle speed. Phi lightens or darkens its colour. Neither operation measures entropy. The neighbouring particle field keeps moving independently.

The implementation and reset limits are in technical.md. Earlier imagined global controls and score-driven motion are preserved in design-proposals.md.
''')
md('critical.md','''# The gesture and its jurisdiction

The handle moves. The receiver does not follow. Both are visible, both have numbers, and the room encourages us to read them as one system. A connection is easy to imagine into that gap.

Making the route work gives the hand a consequence. Cutting it leaves the receiver with the last values it accepted. The glow continues. Refusal to listen and return to a previous condition are different operations; this little laboratory lets them part company.

The earlier draft's question about administered freedom remains. The visitor has access to the handles and now to the route between them and one body. The ranges, response laws and available connections are still authored. A switch expands what can be done here without making the whole arrangement revisable.

The particle field nearby need not submit to make the room coherent. Its continuing motion gives the encounter an outside: another process occupies this space without receiving this particular gesture. What would be lost if every object answered every hand?

In the project's QFEP terms, a more responsive system is not automatically a more caring one. Ask who can alter the mapping, who can interrupt it, and what persists after interruption. Self-Q brings that question back to the maker: does building an obedient receiver train us to expect obedience wherever we see a control?
''')
md('summary.md','''# Where the control reaches

Seventh of eight QFEP Laboratory halls, restored to the authored museum route. The existing lambda and signed phi handles feed one reactor through an explicit CONNECT / CUT switch. The console distinguishes offered settings from receiver inputs and shows maximum particle launch speed. REPEAT restarts the reactor animation with the same received values.

All six artifact families remain. Lambda, Phi and reactor are primary; the independent particle field, formula and historical tt are secondary. The grid is consistently 14 by 16, with an open approach and support plinths. This encounter investigates causal wiring and the limits of parametric control. It makes no universal criticality claim. Headset comfort and learner understanding remain unverified.
''')
md('blurb.md','''*Your hand returns. The light does not.*

Between a gesture and its consequence, a connection.

You can cut it. Something still remains.
''')
p='commons/data/artifact_roles.json';d=read(p);d['roles'][M]['qfep_reactor']='primary';d['order'][M]['primary']=['lambda_slider','phi_slider','qfep_reactor'];d['order'][M]['secondary']=[x for x in d['order'][M]['secondary'] if x!='qfep_reactor'];write(p,d)
p='commons/data/museum_core_encounters.json';d=read(p);r=d['rooms'][M];r.update(primary_tokens=['lambda_slider','phi_slider','qfep_reactor'],reason='Make, interrupt and repeat a local connection; compare a handle value with one receiver input and response.',status='encounter_and_text_revised',review_evidence=H.relative_to(R).as_posix()+'/SUMMARY.md',learner_verified=False)
for k,n in [('text_sha256','final.md'),('map_sha256','map_data.json')]:r[k]=hashlib.sha256((D/n).read_bytes()).hexdigest()
write(p,d)
lines={'lambda_slider':'The handle moves. Where does its value go?','phi_slider':'A signed weight arrives in another body.','qfep_reactor':'Cut the route. Something still remains.'}
p='commons/data/book/qfeplaboratory.json';d=read(p);e=next(e for e in d['pearls'] if e['map']==M);e.update(hero='qfep_reactor',lines=[{'token':k,'text':v,'by':'hand'} for k,v in lines.items()]);write(p,d)
for p in ['commons/data/trunk_branches.json','commons/data/museum/trunk_branches.json']:
 d=read(p);node=next(n for n in d['trunk'] if n['node']=='qfeplaboratory')
 for e in node['pearls']+d.get('hand_pearls',{}).get('qfeplaboratory',[]):
  if e.get('map')==M:e.update(hero='qfep_reactor',says=lines,says_by={k:'hand' for k in lines})
 write(p,d)
p='commons/maps/sequences/qfeplaboratory.json';d=read(p);s=d['sequences']['qfeplaboratory'];s['content'][6]='QFEP_Sandbox: Where the control reaches';g=next(g for g in s['artifact_groups'] if g['map']==M);g['rationale']='Connect and cut one identified receiver, compare offered and used inputs, and keep the surrounding works independent.';write(p,d)
p='commons/artifacts/registry/qfep.json';d=read(p);a=d['artifacts']['qfep_reactor'];a.setdefault('parameters',{})['wiring_study']='on/off: local CONNECT / CUT and REPEAT experiment; actual receiver values and particle maximum speed';a['description']='An animated orb with authored lambda colour/speed and signed phi lightness mappings. Optional wiring_study connects exactly one pair of same-hall handles, displays received values, and can cut or repeat the response. Its toy score does not measure entropy.';write(p,d)
print('Sandbox map, encounters and manuscript aligned; all six families retained')
