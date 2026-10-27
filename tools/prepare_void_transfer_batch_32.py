"""Continue placement-first transfers: remaining swarms and first uncovered ML maps."""
import prepare_void_transfer_batch as base
base.OUT=base.ROOT/'doc/void-transfer/2026-10-21-batch-32'
base.JOBS={'swarmintelligence_03':'Codex','machinelearning_02':'Codex'}
base.SOURCE_SELECTIONS={
    'swarmintelligence_03':{'sequence':'swarmintelligence','maps':[
        'SwarmIntelligence_Particle_Swarm_Optimization','SwarmIntelligence_Swarm_Intelligence_Algorithms']},
    'machinelearning_02':{'sequence':'machinelearning','maps':[
        'ML_Classification','ML_Neural_Networks','ML_Perception']},
}
if __name__=='__main__':base.main()
