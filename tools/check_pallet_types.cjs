const fs=require('node:fs'),path=require('node:path');
const root=path.resolve(__dirname,'..'),web=path.resolve(root,'../ada_encyclopedia'),ts=require(path.join(web,'node_modules/typescript'));
const files=['src/lib/handmade-prefabs.ts','src/lib/primitive-prefabs.ts','src/lib/prefab-workbench-store.ts','src/lib/capacity-artifacts.ts','src/lib/modular-terms.ts','src/app/api/handmade-prefabs/route.ts','src/app/api/modular-terms/route.ts','src/app/api/void-spawnlists/route.ts'].map(f=>path.join(web,f));
const p=ts.createProgram(files,{noEmit:true,strict:true,skipLibCheck:true,esModuleInterop:true,target:ts.ScriptTarget.ES2022,module:ts.ModuleKind.ESNext,moduleResolution:ts.ModuleResolutionKind.Bundler,baseUrl:web,paths:{'@/*':['./src/*']},jsx:ts.JsxEmit.ReactJSX});
const all=ts.getPreEmitDiagnostics(p),errors=all.filter(d=>d.category===ts.DiagnosticCategory.Error&&d.file&&files.includes(path.normalize(d.file.fileName)));
const messages=errors.map(d=>ts.flattenDiagnosticMessageText(d.messageText,'\n'));
fs.writeFileSync(path.join(root,'ada_run/pallet-assemblage/types-checks.json'),JSON.stringify({passed:!errors.length,scope:'Changed catalogue, bridge and recipe modules; the full web repo has unrelated existing diagnostics.',files:files.map(f=>path.relative(web,f)),errors:messages,otherDiagnostics:all.length-errors.length},null,2)+'\n');
console.log(messages.length?messages.join('\n'):'Changed pallet catalogue/bridge modules type-check.');process.exitCode=errors.length?1:0;
