// Source factories remain authoritative for every plank, wall, flap and template.
const fs=require('node:fs'),path=require('node:path'),crypto=require('node:crypto'),root=path.resolve(__dirname,'..'),src=path.resolve(root,'../ada_encyclopedia/public/studies/matter-and-logic/physics'),C=require(path.join(src,'package/build/cannon.min.js'));
const v=p=>[p.x,p.y,p.z],q=p=>[p.x,p.y,p.z,p.w];
function body(b,id,look){return {id,look,mass:b.mass,position:v(b.position),quaternion:q(b.quaternion),inertia:v(b.inertia),linear_damping:b.linearDamping,angular_damping:b.angularDamping,material:b.material?.name,shapes:b.shapes.map((s,i)=>({...s.type===C.Shape.types.BOX?{type:'box',size:v(s.halfExtents).map(x=>2*x)}:{type:'sphere',radius:s.radius},at:v(b.shapeOffsets[i]),quaternion:q(b.shapeOrientations[i])}))}}
const graphs={};
for(const [kind,file,builder] of [['stackqueue','sqboard.js','buildStackQueue'],['functions','funcboard.js','buildFuncBoard'],['loops','loopboard.js','buildLoopBoard'],['ruleboard','board.js','buildBoard']]){
 const g=require(path.join(src,file))[builder](C),ids=new Map(g.world.bodies.map((b,i)=>[b,'body_'+i])),looks=new Map(g.statics.map(p=>[p.body,p.kind]));
 const d=graphs[kind]={kind,BW:3,BH:6,rockers:[],inlets:{},hinges:[],bodies:g.world.bodies.map(b=>body(b,ids.get(b),looks.get(b))),constants:{},poses:{},templates:{},source:file,sha256:crypto.createHash('sha256').update(fs.readFileSync(path.join(src,file))).digest('hex')};
 for(const [name,value] of Object.entries(g))if(typeof value==='number'||name===name.toUpperCase()&&value&&typeof value==='object'&&!Array.isArray(value)&&!value.world)d.constants[name]=value;
 if(kind==='stackqueue'){
  d.templates.stack=body(g.makeCrate('stack','monitor').body,'new','crate');d.templates.queue=body(g.makeCrate('queue','monitor').body,'new','crate');
 }else if(kind==='functions'||kind==='loops'){
  d.flap=ids.get(g.flap.body);for(const bit of [0,1]){g.setFlap(!!bit);d.poses['flap'+bit]={position:v(g.flap.body.position),quaternion:q(g.flap.body.quaternion)}}
  if(kind==='loops'){d.trap=ids.get(g.trap.body);for(const bit of [0,1]){g.setTrap(!!bit);d.poses['trap'+bit]={position:v(g.trap.body.position),quaternion:q(g.trap.body.quaternion)}}d.templates.marble=body(g.spawn(),'new','marble');}
  else {d.templates.entry=body(g.spawn('entry'),'new','marble');d.templates.resume=body(g.spawn('resume'),'new','marble');d.templates.crate=body(g.pushFrame({n:0,ret:'main'}).body,'new','crate');}
 }else{
  d.flaps=g.flaps.map(f=>({id:ids.get(f.body),level:f.level,poses:[f.pose(0),f.pose(1)]}));d.trays=g.trays.map(t=>({id:ids.get(t.body),p:t.p}));d.templates.marble=body(g.spawn(0),'new','marble');
 }
}
fs.writeFileSync(path.join(root,'commons/artifacts/matter_reference/computing-boards.json'),JSON.stringify({graphs},null,2)+'\n');console.log(Object.fromEntries(Object.entries(graphs).map(([k,v])=>[k,{bodies:v.bodies.length,templates:Object.keys(v.templates)}])));
