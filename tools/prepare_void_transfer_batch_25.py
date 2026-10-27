"""Inventory batch 25 once; workers place artifacts without shared-file races."""
import prepare_void_transfer_batch as base

base.OUT = base.ROOT / 'doc/void-transfer/2026-10-21-batch-25'
base.JOBS = {
    'randomness_04': 'Claude worker A',
    'randomness_05': 'Claude worker B',
    'noise_02': 'Claude worker C',
    'noise_03': 'Claude worker D',
    'cellularautomata_02': 'Claude worker D',
}
base.SOURCE_SELECTIONS = {
    'randomness_04': {'sequence': 'randomness', 'maps': [
        'Random_Cubes', 'Random_Rotate_Random_XYZ', 'Random_Walk',
        'Random_Gaussian', 'Random_Mushrooms']},
    'randomness_05': {'sequence': 'randomness', 'maps': [
        'Random_Space_Geometry', 'Randomness_Examples_of_Randomness',
        'Random_Pheromone', 'Random_Space', 'Random_Game']},
    'noise_02': {'sequence': 'noise', 'maps': [
        'Noise_One', 'Noise_Voxel', 'Noise_6_Wall',
        'Noise_Inside_Noise', 'Noise_Cellular']},
    'noise_03': {'sequence': 'noise', 'maps': [
        'Noise_Box', 'Noise_Space_10', 'Noise_Perlin_Simplex', 'Lab_Path']},
    'cellularautomata_02': {'sequence': 'cellularautomata', 'maps': ['CA_GameOfLife']},
}

if __name__ == '__main__':
    base.main()
