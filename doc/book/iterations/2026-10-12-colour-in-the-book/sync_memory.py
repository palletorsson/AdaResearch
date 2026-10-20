"""Record the bounded Colour incorporation in the existing revisioned memory."""
from prepare import HERE, ROOT, HALLS, put
import json,sys
sys.path.insert(0,str(ROOT/'tools'))
import project_memory, museum_connections, museum_memory

def main():
    assert not (HERE/'memory-receipt.json').exists(),'Already recorded.'
    report=HERE.relative_to(ROOT).as_posix()
    state=json.loads((ROOT/'doc/book/memory/state.json').read_text(encoding='utf-8'))
    revision=state['revision']; receipts=[]
    completion='12 October — Colour incorporated: eight canonical tutorials from the reviewed drafts, 21 printed files. Material → light → RGB choice → bands → HSV field → stored cell → accumulated paint → layered view. Same PointBody and Palette return; recorded values are copied explicitly. Grid/Walls gain supplied pointer targets. 811 native assertions, 39 GPU checks, 36 configurations, 27 rejected faults. Current final texts and museum runtime preserved. Teacher-authored synthetic evidence; no independent learner or physical headset claim. '+report+'/index.html'
    for scope,note in [('sequence:color',{'summary':completion,'reason':'Continue after Transformation and Arrays, using the existing reviewed Colour drafts. Selected learner operations and larger museum encounters remain distinct.','open_question':'Review Paint density and physical pointer use in the prepared museum; Rainbow making remains optional. Pattern_Disco receives the independent palette choice.'}),('project',{'summary':state['notes']['project']['summary']+'\n\n'+completion})]:
        result=project_memory.mutate(ROOT,{'action':'note','expected_revision':revision,'scope':scope,'note':note});revision=result['revision'];receipts.append(result)
    result=project_memory.mutate(ROOT,{'action':'finding','expected_revision':revision,'finding':{'scope':'sequence:color','kind':'source','text':'Eight Colour tutorials are now canonical and paired with the current reflections. The exact printed programs have fresh native evidence.','reason':'The earlier outlines did not contain the complete reviewed construction. Promotion restores the learner lineage and declares each support dependency.','sequence_effect':'Familiar geometry and PointBody continue; Palette state returns unchanged in Walls. Small controls fit the prepared museum pointer.','project_effect':'Arrays addresses continue into assignments and stored marks; Pattern_Disco can independently change the palette. The reflections retain their own critical and poetic tasks.','method':'Source comparison, exact fenced-code extraction, native/GPU assertions, 27 deliberate faults, preserved source hashes.','created_by':'Codex Colour incorporation 2026-10-12','related_scopes':['project','sequence:array_tutorial','sequence:tiling'],'source_paths':[f'commons/maps/{h}/tutorial.md' for h in HALLS]+[report+'/'+n for n in ['sequence-verification.json','promotion.json','plan-receipt.json','lineage.json']]}})
    revision=result['revision'];receipts.append(result)
    connections=museum_connections.read(ROOT);cr=connections['revision'];old=connections['summaries']['sequence:color']
    paths=list(old['sources'])+[f'commons/maps/{h}/tutorial.md' for h in HALLS]+[report+'/sequence-verification.json',report+'/lineage.json']
    result=museum_connections.mutate(ROOT,{'action':'summary','expected_revision':cr,'id':'sequence:color','record':{'summary':'Known forms and addressed arrays acquire different colour relations: material assignment, illumination, RGB choice, ordered bands, sampled HSV, retained cell colours, accumulated marks and layered views. Eight canonical full-code tutorials now use the reviewed drafts; current reflections preserve composition, pleasure and the politics of choosing appearances.','carry':'Same PointBody returns in Nails, Pillar and Paint; Grid Palette returns unchanged in Walls. Recorded RGB values move by explicit copy. The next disco can keep its pattern while changing its palette. Fresh 12 October teacher-authored evidence; no live study installation or headset claim.','question':'Where is the colour kept, what receives it, and what does that value leave undecided? Keep Paint manageable; review physical controls with a reader.','source_paths':paths}});cr=result['revision'];receipts.append(result)
    edges=[
        ('colour-inherited-point','map:Point_Lines','map:Color_Nails','body','reuses','The exact inherited PointBody and LineSkin files are printed again. The carried point now supplies input to a colour function; construction is reused, not a persisted runtime node.',['commons/maps/Point_Lines/tutorial.md','commons/maps/Color_Nails/tutorial.md',report+'/sequence-verification.json']),
        ('colour-owned-palette','map:Color_Grid_Pallet','map:Color_Walls','selection','reuses','Walls uses the exact Palette class taught in Grid; two instances own separate indices and colour lists. The reuse is source code, not automatic transfer of a running palette.',['commons/maps/Color_Grid_Pallet/tutorial.md','commons/maps/Color_Walls/tutorial.md',report+'/sequence-verification.json']),
        ('colour-address-receiver','map:Array','map:Color_Grid_Pallet','trace','reuses','An address that retained presence now retains a colour after selection moves. The grid is newly constructed; this is a reused addressing capacity, not a shared runtime record.',['commons/maps/Array/tutorial.md','commons/maps/Color_Grid_Pallet/tutorial.md'])]
    for id,source,target,thread,relation,reason,paths in edges:
        result=museum_connections.mutate(ROOT,{'action':'connection','expected_revision':cr,'id':id,'record':{'from':source,'to':target,'thread':thread,'relation':relation,'status':'documented','reason':reason,'source_paths':paths}});cr=result['revision'];receipts.append(result)
    p=ROOT/'doc/book/course/storyboards/CONTEXT.md';t=p.read_text(encoding='utf-8');heading='# Move between whole and part\n\n'
    assert t.startswith(heading)
    put(p,heading+'**'+completion+'** Eight plan entries and Museum Memory updated. One sequence only; next author review, then the next requested sequence. Do not rerun the one-shot plan/memory sync scripts.\n\n'+t[len(heading):])
    model=museum_memory.model(ROOT)
    for scope in ['project','sequence:color']:
        packet=museum_memory.packet(model,scope)
        assert 'Colour incorporated' in json.dumps(packet,ensure_ascii=False),scope
    put(HERE/'memory-receipt.json',json.dumps({'project_memory_revision':revision,'connections_revision':cr,'packet_visibility':['project','sequence:color'],'receipts':receipts},ensure_ascii=False,indent=2)+'\n')
    print('Colour memory recorded globally and locally; explicit source-reuse connections added.')

if __name__=='__main__':main()
