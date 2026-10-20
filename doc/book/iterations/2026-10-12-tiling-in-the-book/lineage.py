"""Nine bounded teaching choices, retaining the reviewed route and its branches."""
from prepare import HERE, ROOT, HALLS, put
import json

DATA = [
    ('Keep the pattern, change its colours',
     'Colour gave the familiar point and addressed grid a palette. Return to them in Disco and follow one square while changing palette and phase separately. The receiver stays fixed; a zero or one can acquire another appearance. Make both palette entries equal, advance the rule, then reveal its retained phase with another palette. Reuse the three existing classes; this lesson starts its own declared state. Foundry next replaces the calculated checker with a source we can edit.',
     'reuse PointBody/GridSurface/Palette; separate phase from colour; equal colours can hide change; no automatic saved-state handoff.',
     'The floor invites a rhythm without deciding how we move with it.',
     'The Colour handoff now names the actual classes and their state lifetime. The inherited readout matches the current Colour file exactly.',
     'Pattern_Disco/museum/palette-navy-pink.png'),
    ('One edit, many appearances',
     'Keep the point, palette and receiver. Store a small asymmetric source as rows of values, then wrap each receiver address back into it. Move the held point over a cell and trigger one edit. Predict every visible occurrence that reads the changed entry before repainting. The larger Foundry machines remain encounters to revisit; the first construction teaches the reach of one source. Carry that source shape and reader into the next lesson, without assuming that a running edit has been saved between halls.',
     'build source[z][x]; posmod address; edit one entry; repaint readers; predict all affected occurrences.',
     'A mark can travel farther than the hand; its stored colours do not preserve the wish behind it.',
     'Retained the focused source lesson and the separate return-visit essay. Only the inherited readout is aligned with Colour.',
     'Pattern_Foundry/museum/room-one-mark.png'),
    ('Change the reading',
     'Keep the source fixed and reflect alternate whole copies through their read addresses. Compare that operation with reversing the stored rows: one changes how the mark is read, the other changes the mark. Edit through a reflected occurrence and locate the source entry it reaches. A symmetric source can conceal the difference, so choose an asymmetric test. The five-column learner display cuts the six-column reflected period short; use the larger museum comparison to see a full return.',
     'read reflection != source mutation; diagnostic asymmetry; block parity; period can exceed tile width.',
     'A useful mark can be the one that refuses to look the same from every direction.',
     'Retained the distinction between lookup and mutation, and the declared limit of the small preview.',
     'Tutorial_Pattern/museum/two-fixed-fields.png'),
    ('Give an address a place',
     'Return to Transformation: turn the receiver from table to wall and change its physical cell width while preserving source values and read rule. Use the receiver’s inverse transform to recover an address from the held point. Predict where the same entry can be found in both placements and how many metres one repeat spans. The installed tunnel extends the comparison around corners; shared source data alone does not guarantee a seamless join. This physical frame becomes the receiver inherited by the glide lesson.',
     'source/rule fixed; table→wall; to_local(hand); cell width in metres; preserve address through transform.',
     'A surface gives an address direction, extent and a finite edge.',
     'Preserved the return to Transformation and the complete receiver later inherited by Symmetry.',
     'Array_Patterns/museum/installed-tunnel.png'),
    ('Compose a reflection and a shift',
     'Extend the previous receiver with a reflection followed by a half-height row shift. Compare P1, PM and PG with the source unchanged; predict the lookup for an even four-row source. A construction button does not prove the complete symmetry classification of every chosen mark. The optional loom adds another distinction: repeated instructions can change while cloth already woven keeps its crossings. SAVE CLOTH explicitly retains that sample for the later cutting table; it is a separate record from the shader studio’s source.',
     'extend surface reader; reflection+half-height glide; even rows; construction != classification; optional loom record→cutting table.',
     'An instruction can repeat; a woven pass also joins work already done.',
     'Kept the newer seven-sample loom and optical-cloth passages, including the explicit saved-cloth handoff.',
     'Symmetry_Seventeen/museum/installed-p1-pg.png'),
    ('Agree, then diverge',
     'Compose two receivers using the known source, rules and physical frames. Unlike Foundry’s many readings of one live source, each receiver now owns a recipe. Copy one recipe to make the pair agree, then edit only the other receiver and show what stays local. Deep copying the nested rows makes that independence real. Choose which surfaces should share a decision and when they should diverge. The temple makes the consequence visible across a whole room without requiring the student to rebuild every architectural surface.',
     'compose independent receiver recipes; deep-copy rows; agreement now != shared future; edit locally.',
     'The room gives an arrangement authority; agreement can still leave room for one different wall.',
     'Preserved the composition exercise and the distinction between copying a recipe and retaining a live link.',
     'Pattern_Temple/museum/court-one-different.png'),
    ('Let height enter the address',
     'Take an optional branch into volume. Stack familiar receivers and store values as layers of rows, values[y][z][x]. Let height shift the column read from the same source; predict a value at an address whose three indices differ. A slice hides other layers while preserving their records. Choose another layer count or shift and account for the result. This develops spatial data; the following surface comparison and fabric shader do not require the volume as a prerequisite.',
     'optional volume branch; values[y][z][x]; height-dependent lookup; slice hides != deletes.',
     'An extra address opens relations while a slice makes some of them temporarily unavailable to view.',
     'Preserved the optional branch and its explicit difference between displayed cells and stored values.',
     'Ribbon_Patterns_01/museum/installed-shift.png'),
    ('Keep the value, change its company',
     'Pause to investigate equal colour values against different surrounds and on different carriers. State what changes, what remains fixed and what you observe, without requiring a particular perceptual answer. The optional runnable reconstruction reuses the point and grid and deliberately shares the targets’ material while keeping their surrounds independent. The volume is not a prerequisite. Bring this controlled comparison into the fabric studio, where one source reaches differently mapped bodies.',
     'observe fixed values/changed surrounds; no prescribed perception; optional shared-material reconstruction; return to surfaces.',
     'Numerical equality does not determine a viewer’s experience.',
     'Kept the reflective pause. The plan no longer treats the optional volume as a required dependency.',
     'Ribbon_Patterns_02/museum/installed-context.png'),
    ('A source reaches a garment',
     'Reuse the address calculation in a small fragment shader inside the supplied museum studio. Follow UV through repeat, offset and sampling, then predict both a sampled colour and its spacing on the wall. After the guided two-to-three repeat edit, choose and predict another count yourself. Saving the studio recipe does not save the changed shader. The optional cutting table can instead load the actual loom record, cut a chosen garment and retain cloth and shape on the wearer. The two save routes remain distinct.',
     'UV→repeat+offset→sample; texel != fragment != vertex; recipe != interpreter; optional saved loom→cut→wear.',
     'A saved appearance can travel onto a body; the desire behind it still needs someone to carry it.',
     'Kept the newer garment choices. Separated the prescribed shader edit from the student’s independent choice.',
     'Ribbon_Patterns_03/museum/installed-studio.png'),
]

def main():
    plan=json.loads((ROOT/'doc/book/course/execution-plan/plan.json').read_text(encoding='utf-8'))
    rows=[]
    for h,values in zip(HALLS,DATA):
        old=next(x for x in plan['lessons'] if x['id']==h)
        title,summary,short,reflection,change,image=values
        rows.append({'id':h,'title':title,'summary':summary,'short':short,'reflection':reflection,'change_note':change,'mode':old['mode'],'dependsOn':[x for x in old['dependsOn'] if not (h=='Ribbon_Patterns_02' and x=='Ribbon_Patterns_01')],'carry':old['carry'],'next':old['next'],'image':{'path':'doc/book/iterations/2026-10-09-tiling-revision/'+image,'date':'2026-10-09','label':'Earlier view inside '+h.replace('_',' ')}})
    rows[0]['carry']='The exact Colour PointBody, Palette and GridSurface classes; calculated value, palette choice and phase remain separate. Code reuse does not persist a running choice.'
    rows[-1]['next']='Change_Intro: compare a curve at two positions and ask how much its value changes. The existing transition is retained; Change is outside this pass.'
    rows[6]['mode']='build' # Optional branch is a real build, not a mandatory prerequisite.
    put(HERE/'lineage.json',json.dumps(rows,ensure_ascii=False,indent=2)+'\n')

if __name__=='__main__':main()
