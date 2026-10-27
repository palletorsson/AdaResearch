// One pure TypeScript compiler serves the live Three.js item and native trials.
const fs=require('fs'),path=require('path'),crypto=require('crypto');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),ts=require(path.join(web,'node_modules/typescript'));
require.extensions['.ts']=(module,file)=>module._compile(ts.transpileModule(fs.readFileSync(file,'utf8'),{compilerOptions:{module:ts.ModuleKind.CommonJS,target:ts.ScriptTarget.ES2022}}).outputText,file);
const {PORTAL_DEFAULTS,PORTAL_LIMITS,validatePortal,compilePortal,fitPortalToShaft}=require(path.join(web,'src/lib/portal-study.ts'));
const document=JSON.parse(fs.readFileSync(path.join(root,'commons/modular/terms.json'),'utf8')),template=document.terms.s_portal_copies_model;
const sources=[path.join(web,'src/lib/portal-study.ts'),path.join(root,'commons/modular/portal_piece.gd'),path.join(root,'commons/modular/recipe_area.gd')];
const hash=crypto.createHash('sha256');sources.forEach(p=>hash.update(fs.readFileSync(p)));hash.update(JSON.stringify(template));const source_hash=hash.digest('hex');
try{
 const action=process.argv[2];
 if(action==='describe')process.stdout.write(JSON.stringify({defaults:PORTAL_DEFAULTS,limits:PORTAL_LIMITS,template,terms:document.terms,source_hash}));
 else if(action==='validate')process.stdout.write(JSON.stringify({settings:validatePortal(JSON.parse(process.argv[3])),source_hash}));
 else if(action==='fit')process.stdout.write(JSON.stringify(fitPortalToShaft(JSON.parse(process.argv[3]))));
 else if(action==='compile'){
  const request=JSON.parse(fs.readFileSync(process.argv[3],'utf8'));
  if(request.source_hash!==source_hash)throw Error('Portal source changed; reload before saving');
  process.stdout.write(JSON.stringify({...compilePortal(request.settings,template,request.placement==='floor16'),source_hash}));
 }else throw Error('Unknown compiler action');
}catch(error){process.stderr.write(String(error));process.exitCode=1;}
