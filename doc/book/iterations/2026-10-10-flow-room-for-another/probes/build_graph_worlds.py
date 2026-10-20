from pathlib import Path
import json,shutil
R=Path(__file__).resolve().parents[1];D=R/'commons/artifacts/graph_worlds';D.mkdir(parents=True,exist_ok=True)
S=R/'doc/book/studies/graphs-through-the-hands'
for n in ['flow_model.gd','route.gd','traversal.gd']:shutil.copyfile(S/'GT_Flow'/n,D/n)
shutil.copyfile(S/'GT_Spanning_Trees/tree_model.gd',D/'tree_model.gd')
cases=[
('visit','GT_Foundations','A visitor makes the rounds','Present / invented museum','person','visit','Visit each room once; follow the queue.','Vertices are rooms; links are passages. Visiting a room is not walking each passage once.'),
('ants','GT_Layout','An ant trail, drawn twice','Present / simplified animal habitat','ant','layout','Rearrange the drawing; keep every trail.','Vertices are junctions, not individual ants. No pheromone or foraging behaviour is simulated.'),
('bridges','GT_Pathfinding','The closed footbridge','Present / invented riverside town','house','path','Close one bridge; find the fewest-crossings detour.','Passages have equal cost. A shortest graph route need not be the fastest or most accessible walk.'),
('shares','GT_Network_Analysis','The post that gets copied','Present / invented social network','phone','counts','Omit one recorded share; recount incoming events.','Vertices are accounts. Arrows are recorded shares, not friendships, impressions, agreement or trust.'),
('ferry','GT_Connectivity','An island with no return boat','Present / invented ferry service','boat','return','Add a return crossing; compare the mutually reachable islands.','A directed link is a scheduled service in this simplified model. Timetables and missed boats are omitted.'),
('pipes','GT_Spanning_Trees','Water pipes between homes','Present / invented village plan','house','tree','Select cheap connections; break one; add a spare.','Weights are assigned construction costs. This is connectivity planning, not water pressure or hydraulic flow.'),
('harbour','GT_Flow','Room for another delivery','Present / invented harbour plan','depot','flow','Allocate two deliveries; notice the cancelled commitment.','Capacities count crate slots in one interval. Reverse residual steps revise the plan before dispatch.'),
('tools','GT_Matching','Two makers, two tools','Present / invented shared workshop','person','matching','Revise the first pairing so both people can work.','Links encode declared task compatibility. One tool per person; preferences, skill and fairness are not computed.'),
('contact','GT_Network_Analysis','A contact is not an infection','Present / fictional contact experiment','person','disease','Advance one contact round; new infections wait until the next round.','Toy SI process: probability0.35 per infectious-susceptible edge per round; no recovery, duration or biology. Not an epidemic forecast.'),
('euler','GT_Foundations','Seven bridges, four shores','Historical / topological reconstruction','house','euler','Count odd degrees before attempting to use every bridge once.','The seven-edge multigraph follows Euler\'s bridge problem. This is not a geographical reconstruction or the hall\'s vertex-visit lesson.'),
('future','GT_Connectivity','A neighbourhood after the relay fails','Future / invented scenario, not a forecast','relay','future','Lose a central link; switch on the spare connection.','Links are permitted communication paths, not guaranteed power, bandwidth, safety or equitable access.'),
]
source={
'ants':'https://arxiv.org/abs/1103.1612',
'shares':'https://bsky.social/about/blog/7-27-2023-custom-feeds',
'contact':'https://www.nature.com/articles/s41586-021-03694-x',
'euler':'https://eulerarchive.maa.org/',
'harbour':'https://networkx.org/documentation/stable/reference/algorithms/generated/networkx.algorithms.flow.maximum_flow.html'}
out=[]
for id,hall,title,era,kind,mode,action,limit in cases:
 out.append(dict(id=id,hall=hall,title=title,era=era,kind=kind,mode=mode,action=action,limit=limit,source=source.get(id,'')))
(D/'cases.json').write_text(json.dumps(out,ensure_ascii=False,indent=2)+'\n',encoding='utf8')
(D/'graph_worlds.tscn').write_text('[gd_scene load_steps=2 format=3]\n\n[ext_resource type="Script" path="res://commons/artifacts/graph_worlds/graph_worlds.gd" id="1"]\n\n[node name="GraphWorlds" type="Node3D"]\nscript = ExtResource("1")\n',encoding='utf8')
print('Eleven concrete contexts prepared; eight halls plus three extensions.')
