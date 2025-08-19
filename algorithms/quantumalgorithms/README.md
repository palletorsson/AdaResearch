# Quantum Algorithms Collection

## Overview
Explore the mind-bending world of quantum computation through immersive VR visualizations. Experience superposition, entanglement, and quantum interference as tangible phenomena while learning how quantum algorithms solve problems beyond classical reach.

## Contents

### ⚛️ **Quantum Foundations**
- **[Superposition](superposition/)** - Quantum states existing in multiple configurations simultaneously

## 🎯 **Learning Objectives**
- Understand fundamental quantum mechanical principles in computational contexts
- Experience quantum superposition and entanglement through spatial visualization
- Master the difference between classical and quantum information processing
- Explore quantum algorithm design principles and complexity advantages
- Visualize quantum interference patterns and measurement effects

## ⚛️ **Quantum Fundamentals**

### **Quantum Bits (Qubits)**
```gdscript
# Classical bit representation
enum ClassicalBit { ZERO, ONE }

# Quantum bit representation using complex amplitudes
class Qubit:
    var amplitude_0: Complex  # Amplitude for |0⟩ state
    var amplitude_1: Complex  # Amplitude for |1⟩ state
    
    func _init(alpha: Complex = Complex(1, 0), beta: Complex = Complex(0, 0)):
        amplitude_0 = alpha
        amplitude_1 = beta
        normalize()
    
    func normalize():
        # Ensure |α|² + |β|² = 1 (normalization condition)
        var norm_squared = amplitude_0.magnitude_squared() + amplitude_1.magnitude_squared()
        var norm = sqrt(norm_squared)
        amplitude_0 = amplitude_0.divide_real(norm)
        amplitude_1 = amplitude_1.divide_real(norm)
    
    func measure() -> int:
        # Probability of measuring |0⟩ is |α|²
        var prob_zero = amplitude_0.magnitude_squared()
        if randf() < prob_zero:
            # Collapse to |0⟩ state
            amplitude_0 = Complex(1, 0)
            amplitude_1 = Complex(0, 0)
            return 0
        else:
            # Collapse to |1⟩ state
            amplitude_0 = Complex(0, 0)
            amplitude_1 = Complex(1, 0)
            return 1
```

### **Quantum Superposition**
```gdscript
class SuperpositionState:
    var basis_states: Dictionary  # basis_state -> amplitude
    
    func create_equal_superposition(num_qubits: int) -> SuperpositionState:
        var state = SuperpositionState.new()
        var num_states = pow(2, num_qubits)
        var amplitude = Complex(1.0 / sqrt(num_states), 0)
        
        # All basis states have equal amplitude
        for i in range(num_states):
            var basis_string = int_to_binary_string(i, num_qubits)
            state.basis_states[basis_string] = amplitude
        
        return state
    
    func apply_hadamard(qubit_index: int):
        # H|0⟩ = (|0⟩ + |1⟩)/√2, H|1⟩ = (|0⟩ - |1⟩)/√2
        var new_states = {}
        
        for basis_state in basis_states:
            var amplitude = basis_states[basis_state]
            var state_array = basis_state_to_array(basis_state)
            
            if state_array[qubit_index] == 0:
                # |0⟩ → (|0⟩ + |1⟩)/√2
                var new_state_0 = state_array.duplicate()
                var new_state_1 = state_array.duplicate()
                new_state_1[qubit_index] = 1
                
                add_amplitude(new_states, array_to_basis_state(new_state_0), 
                             amplitude.multiply_real(1.0/sqrt(2)))
                add_amplitude(new_states, array_to_basis_state(new_state_1), 
                             amplitude.multiply_real(1.0/sqrt(2)))
            else:
                # |1⟩ → (|0⟩ - |1⟩)/√2
                var new_state_0 = state_array.duplicate()
                var new_state_1 = state_array.duplicate()
                new_state_0[qubit_index] = 0
                
                add_amplitude(new_states, array_to_basis_state(new_state_0), 
                             amplitude.multiply_real(1.0/sqrt(2)))
                add_amplitude(new_states, array_to_basis_state(new_state_1), 
                             amplitude.multiply_real(-1.0/sqrt(2)))
        
        basis_states = new_states
```

## 🌊 **Quantum Interference**

### **Amplitude Interference**
```gdscript
class QuantumInterference:
    func demonstrate_interference():
        # Two-slit experiment analog in quantum computation
        var initial_state = Qubit.new(Complex(1, 0), Complex(0, 0))  # |0⟩
        
        # Apply Hadamard (creates superposition - "splits" the wave)
        var superposition = apply_hadamard(initial_state)  # (|0⟩ + |1⟩)/√2
        
        # Apply phase rotation (introduces path difference)
        var phase = PI / 4  # 45-degree phase
        superposition.amplitude_1 = superposition.amplitude_1.multiply(
            Complex(cos(phase), sin(phase))
        )
        
        # Apply another Hadamard (recombines the paths)
        var final_state = apply_hadamard(superposition)
        
        return final_state
    
    func visualize_interference_pattern(num_experiments: int):
        var measurement_results = []
        
        for i in range(num_experiments):
            var final_state = demonstrate_interference()
            measurement_results.append(final_state.measure())
        
        # Plot histogram showing interference pattern
        plot_measurement_histogram(measurement_results)
```

### **Quantum Phase**
- **Global Phase**: Overall phase factor that doesn't affect measurement
- **Relative Phase**: Phase differences between amplitudes that create interference
- **Geometric Phase**: Phase acquired through quantum state evolution
- **Berry Phase**: Topological phase in parameter space

## 🔗 **Quantum Entanglement**

### **Bell States**
```gdscript
func create_bell_state() -> TwoQubitState:
    # Create maximally entangled state: (|00⟩ + |11⟩)/√2
    var state = TwoQubitState.new()
    var amplitude = Complex(1.0/sqrt(2), 0)
    
    state.amplitudes["00"] = amplitude
    state.amplitudes["01"] = Complex(0, 0)
    state.amplitudes["10"] = Complex(0, 0)
    state.amplitudes["11"] = amplitude
    
    return state

func demonstrate_spooky_action(bell_state: TwoQubitState):
    # Measure first qubit
    var result_1 = bell_state.measure_qubit(0)
    
    # Due to entanglement, second qubit is now determined
    var result_2 = bell_state.measure_qubit(1)
    
    # Results are always perfectly correlated
    assert(result_1 == result_2)
```

### **Quantum Teleportation**
```gdscript
func quantum_teleportation(unknown_state: Qubit, 
                          entangled_pair: TwoQubitState) -> Qubit:
    # Bell measurement on unknown state + first entangled qubit
    var bell_measurement = perform_bell_measurement(unknown_state, 
                                                  entangled_pair.qubit_0)
    
    # Apply correction to second entangled qubit based on measurement
    var teleported_state = entangled_pair.qubit_1
    apply_correction(teleported_state, bell_measurement)
    
    return teleported_state
```

## 🚀 **VR Quantum Experience**

### **Immersive Quantum Visualization**
- **Bloch Sphere Navigation**: Fly through 3D qubit state space
- **Superposition Visualization**: See quantum states as probability clouds
- **Entanglement Threads**: Visualize quantum correlations as spatial connections
- **Interference Patterns**: Watch quantum amplitudes constructively and destructively interfere

### **Interactive Quantum Gates**
- **Gate Manipulation**: Apply quantum gates with hand controllers
- **Circuit Construction**: Build quantum circuits by connecting gates
- **State Evolution**: Watch quantum states transform through gate operations
- **Measurement Effects**: Experience wavefunction collapse through interaction

## 🔬 **Quantum Algorithms**

### **Grover's Search Algorithm**
```gdscript
# Quantum search in unsorted database - quadratic speedup
func grovers_algorithm(database_size: int, target_item: int) -> int:
    var num_qubits = ceil(log2(database_size))
    var num_iterations = ceil(PI/4 * sqrt(database_size))
    
    # Initialize superposition of all states
    var state = create_equal_superposition(num_qubits)
    
    for i in range(num_iterations):
        # Oracle: flip amplitude of target state
        oracle_query(state, target_item)
        
        # Diffusion operator: inversion about average
        diffusion_operator(state)
    
    # Measure to get answer
    return measure_state(state)

func oracle_query(state: SuperpositionState, target: int):
    # Flip the amplitude of the target state
    var target_string = int_to_binary_string(target, state.num_qubits)
    if target_string in state.basis_states:
        state.basis_states[target_string] = state.basis_states[target_string].multiply_real(-1)
```

### **Quantum Fourier Transform**
```gdscript
func quantum_fourier_transform(state: SuperpositionState):
    var n = state.num_qubits
    
    for i in range(n):
        # Apply Hadamard to qubit i
        apply_hadamard(state, i)
        
        # Apply controlled phase rotations
        for j in range(i + 1, n):
            var phase = 2 * PI / pow(2, j - i + 1)
            apply_controlled_phase(state, j, i, phase)
    
    # Reverse qubit order
    reverse_qubit_order(state)
```

## 🔗 **Related Categories**
- [Optimization](../optimization/) - Quantum annealing and QAOA
- [Machine Learning](../machinelearning/) - Quantum machine learning algorithms
- [Cryptography](../cryptography/) - Quantum cryptography and Shor's algorithm
- [Physics Simulation](../physicssimulation/) - Quantum system simulation

## 🌌 **Applications**

### **Quantum Cryptography**
- **Quantum Key Distribution**: Provably secure communication
- **Quantum Random Number Generation**: True randomness from quantum measurements
- **Post-quantum Cryptography**: Classical algorithms resistant to quantum attacks

### **Quantum Simulation**
- **Molecular Modeling**: Drug discovery and materials science
- **High-energy Physics**: Simulating particle interactions
- **Condensed Matter**: Many-body quantum systems
- **Chemical Reactions**: Quantum effects in catalysis

### **Quantum Machine Learning**
- **Quantum Neural Networks**: Leveraging quantum superposition for learning
- **Variational Quantum Eigensolvers**: Finding ground states
- **Quantum Approximate Optimization**: Combinatorial optimization problems
- **Quantum Support Vector Machines**: Pattern recognition with quantum kernels

## 🎨 **Quantum Philosophy**

Quantum mechanics challenges classical intuitions about reality:

- **Wave-Particle Duality**: Information existing in superposition until measured
- **Observer Effect**: Measurement fundamentally altering reality
- **Non-locality**: Instantaneous correlations across arbitrary distances
- **Complementarity**: Incompatible measurements revealing different aspects
- **Uncertainty Principle**: Fundamental limits to simultaneous knowledge

## 📊 **Quantum Complexity**
- **BQP**: Bounded-error quantum polynomial time
- **Quantum Supremacy**: Problems where quantum computers outperform classical
- **NISQ Era**: Noisy intermediate-scale quantum devices
- **Error Correction**: Protecting quantum information from decoherence

## 🔮 **Future Quantum Computing**
- **Fault-Tolerant Quantum Computing**: Error-corrected logical qubits
- **Quantum Internet**: Distributed quantum information processing
- **Quantum AI**: Artificial intelligence enhanced by quantum computation
- **Quantum Advantage**: Practical problems where quantum helps

---
*"If you think you understand quantum mechanics, you don't understand quantum mechanics." - Richard Feynman*

*Exploring the computational possibilities of the quantum world*