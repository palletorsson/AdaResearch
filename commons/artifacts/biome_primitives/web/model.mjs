// Browser companion of encounter_model.gd. The shared demonstration is checked
// against Godot's recorded output; this page is not an embedded Godot renderer.
export const stages = ['Point_One', 'Point_Lines', 'Point_Trace', 'Point_Line_Grid', 'Point_Triangle_Context', 'Primitives_Polythedra', 'Trans_Rotation', 'Trans_Scale'];
export class Encounter {
  constructor(formDNA=null) {
    this.formDNA=formDNA;
    Object.assign(this, {seed:7, extent:12, stage_index:0, withdrawn:false,
      point:[0,.05,0], anchor:[0,.05,0], line_started:false, interval:.12,
      capacity:64, cell_size:1, clock:0, dropped:0, samples:[], elapsed:0, new_stroke:true,hinge_time:0,hinge_angle:0,hinge_held:false,scale_time:0,width_factor:.6});
  }
  level() { return this.stage_index - Number(this.withdrawn); }
  setStage(index) {
    const before=this.level(); this.stage_index=Math.max(0,Math.min(stages.length-1,index));
    this.withdrawn=false; this.transition(before);
  }
  toggle() { const before=this.level(); this.withdrawn=!this.withdrawn; this.transition(before); }
  transition(before) {
    if(this.level()>=1&&!this.line_started) {this.anchor=[...this.point];this.line_started=true;}
    if((before>=2)!==(this.level()>=2)) {this.new_stroke=true;this.elapsed=0;}
  }
  move(p) {
    if(this.level()<0||p.length!==3||!p.every(Number.isFinite)) return;
    const edge=this.extent*.5-.05, clamp=(v,a,b)=>Math.max(a,Math.min(b,v));
    this.point=[clamp(p[0],-edge,edge),clamp(p[1],.05,5),clamp(p[2],-edge,edge)];
  }
  advance(dt, observed=true) {
    if(!Number.isFinite(dt)||dt<=0) return;
    this.clock+=dt;
    if(!observed){this.new_stroke=true;this.elapsed=0;return;}
    if(this.level()<2) return;
    this.elapsed+=dt;
    if(this.elapsed+.000001<this.interval) return;
    this.elapsed%=this.interval;
    const last=this.samples.at(-1);
    if(last&&!this.new_stroke&&Math.hypot(...this.point.map((v,i)=>v-last.p[i]))<.02) return;
    this.samples.push({p:[...this.point],t:this.clock,start:this.new_stroke}); this.new_stroke=false;
    while(this.samples.length>this.capacity) {this.samples.shift();this.dropped++;}
    if(this.dropped&&this.samples.length) this.samples[0].start=true;
  }
  clear() {this.samples=[];this.dropped=0;this.new_stroke=true;this.elapsed=0;}
  address() {
    const n=Math.ceil(this.extent/this.cell_size);
    return [this.point[0],this.point[2]].map(v=>Math.max(0,Math.min(n-1,Math.floor((v+this.extent*.5)/this.cell_size))));
  }
  snapshot() {
    return {schema:'ada.biome-primitives.v1',world:{seed:this.seed,size:this.extent},stage:stages[this.stage_index],
      stage_index:this.stage_index,withdrawn:this.withdrawn,point:[...this.point],anchor:[...this.anchor],
      line_started:this.line_started,interval:this.interval,capacity:this.capacity,cell_size:this.cell_size,
      clock:this.clock,elapsed:this.elapsed,new_stroke:this.new_stroke,samples:structuredClone(this.samples),
      dropped:this.dropped,visible_samples:this.level()>=2?this.samples.length:0,address:this.level()>=3?this.address():[],forms:this.forms(),
      hinge:this.stage_index>=6?{time:this.hinge_time,angle:this.hinge_angle,held:this.hinge_held}:{},scale:this.stage_index===7?{time:this.scale_time,factor:this.width_factor}:{}};
  }
  forms() {
    if(this.level()<4) return [];
    const d=this.formDNA;
    if(!d) throw Error('The form study requires its shared DNA record.');
    const total=d.width*(d.gaps.length+1)+d.gaps.reduce((a,b)=>a+b,0);
    const depth=this.level()>=5&&this.stage_index<6?d.depth:d.panel_thickness;
    let x=-total*.5+d.width*.5;
    return Array.from({length:d.gaps.length+1},(_,i)=>{
      const form={id:'form_'+i,center:[x,d.height*.5,d.front_z-depth*.5],size:[d.width,d.height,depth],front_triangles:2};
      if(this.stage_index>=6){
        form.pivot=[x-d.width*.5,0,d.front_z]; form.yaw=this.hinge_angle;
        const width=d.width*this.activeWidthFactor(); form.size[0]=width;
        const c=Math.cos(form.yaw),s=Math.sin(form.yaw);
        form.center=[form.pivot[0]+c*width*.5-s*depth*.5,d.height*.5,d.front_z-s*width*.5-c*depth*.5];
      }
      if(i<d.gaps.length)x+=d.width+d.gaps[i];
      return form;
    });
  }
  static angleAt(seconds){
    const t=((seconds%20)+20)%20, ease=x=>x*x*(3-2*x);
    if(t<2)return 0;if(t<10)return Math.PI*.5*ease((t-2)/8);
    if(t<12)return Math.PI*.5;return Math.PI*.5*(1-ease((t-12)/8));
  }
  static scalePoseAt(seconds){
    const t=((seconds%48)+48)%48,ease=x=>x*x*(3-2*x);
    if(t<20)return {angle:Encounter.angleAt(t),factor:.6,hinge_time:t};
    if(t<24)return {angle:0,factor:.6+.65*ease((t-20)/4),hinge_time:0};
    if(t<44)return {angle:Encounter.angleAt(t-24),factor:1.25,hinge_time:t-24};
    return {angle:0,factor:1.25-.65*ease((t-44)/4),hinge_time:0};
  }
  activeWidthFactor(){return this.stage_index===7?this.width_factor:1;}
  inHingeSweep(at){
    if(at[1]>this.formDNA.height+.4||at[1]<-.4)return false;
    const maximum=this.stage_index===7?1.25:1;
    return this.forms().some(f=>{if(!f.pivot)return false;const x=at[0]-f.pivot[0],z=at[2]-f.pivot[2];return x>=-.4&&z<=.4&&Math.hypot(x,z)<=this.formDNA.width*maximum+.4;});
  }
  advanceHinge(dt,visitor=false){
    if(this.stage_index<6||this.withdrawn||!Number.isFinite(dt)||dt<=0)return;
    this.hinge_held=visitor&&this.inHingeSweep(this.point);if(this.hinge_held)return;
    if(this.stage_index===7){this.scale_time=(this.scale_time+Math.min(dt,.1))%48;const p=Encounter.scalePoseAt(this.scale_time);this.hinge_time=p.hinge_time;this.hinge_angle=p.angle;this.width_factor=p.factor;return;}
    this.hinge_time=(this.hinge_time+Math.min(dt,.1))%20;this.hinge_angle=Encounter.angleAt(this.hinge_time);
  }
}
