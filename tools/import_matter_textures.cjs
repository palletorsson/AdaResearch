// Re-run the reference's deterministic canvas recipes, without changing its files.
const fs=require('node:fs'),path=require('node:path'),vm=require('node:vm');
const {createCanvas}=require('C:/Users/palle/.cache/codex-runtimes/codex-primary-runtime/dependencies/node/node_modules/@napi-rs/canvas');
const root=path.resolve(__dirname,'..'),src=path.resolve(root,'../ada_encyclopedia/public/studies/matter-and-logic/pages/matter-gates.html');
const html=fs.readFileSync(src,'utf8'),start=html.indexOf('let seed = 11;'),end=html.indexOf('\n};',html.indexOf('const M = {',start))+3;
const THREE={CanvasTexture:class{constructor(image){this.image=image;this.repeat={set:(...v)=>this.repeatValue=v}}},MeshStandardMaterial:class{constructor(p){Object.assign(this,p)}}};
const recipes=html.slice(start,end)+'\nresult=M;';const context={THREE,lin:x=>x,document:{createElement:()=>createCanvas(1,1)}};vm.createContext(context);vm.runInContext(recipes,context);
const out=path.join(root,'commons/artifacts/matter_reference/textures');fs.mkdirSync(out,{recursive:true});
for(const [name,m] of Object.entries(context.result))if(m.map){fs.writeFileSync(path.join(out,name+'.png'),m.map.image.toBuffer('image/png'));console.log(name,m.map.image.width,m.map.image.height)}
