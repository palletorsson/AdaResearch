"""Next placement-first group: two remaining soft-body maps and three swarms."""
import prepare_void_transfer_batch as base
base.OUT=base.ROOT/'doc/void-transfer/2026-10-21-batch-31'
base.JOBS={'softbodies_03':'Codex','swarmintelligence_02':'Codex'}
base.SOURCE_SELECTIONS={
    'softbodies_03':{'sequence':'softbodies','maps':[
        'ProceduralGeneration_Reaction_Diffusion_Systems','Topology_Entropy_Morphogenesis']},
    'swarmintelligence_02':{'sequence':'swarmintelligence','maps':[
        'SwarmIntelligence_Boids_Algorithm','SwarmIntelligence_Agent_Based_Modeling_ABM',
        'SwarmIntelligence_Ant_Colony_Optimization']},
}
if __name__=='__main__':base.main()
