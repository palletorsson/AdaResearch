# True Random Number Generator (TRNG) vs Pseudo-Random Number Generator (PRNG)

## Overview
This algorithm demonstrates the difference between True Random Number Generators (TRNG) and Pseudo-Random Number Generators (PRNG) through visual comparison and statistical analysis.

## What It Does
- **TRNG**: Generates truly random numbers using hardware entropy sources or environmental noise
- **PRNG**: Generates seemingly random numbers using deterministic algorithms and seed values
- **Visual Comparison**: Shows the distribution patterns and statistical properties of both approaches
- **Statistical Analysis**: Provides metrics to distinguish between true and pseudo-random sequences

## Key Concepts

### True Random Number Generator (TRNG)
- Uses unpredictable physical processes
- Examples: atmospheric noise, radioactive decay, thermal noise
- Provides genuine randomness
- Cannot be reproduced or predicted
- Slower generation rate
- Used in cryptography, security applications

### Pseudo-Random Number Generator (PRNG)
- Uses mathematical algorithms with seed values
- Deterministic but appears random
- Can reproduce sequences with same seed
- Fast generation rate
- Used in simulations, games, most applications

## Algorithm Features
- **Distribution Visualization**: Shows how numbers are distributed across ranges
- **Pattern Detection**: Identifies repeating patterns in PRNG sequences
- **Entropy Measurement**: Quantifies the randomness of generated sequences
- **Seed Management**: Demonstrates how seeds affect PRNG output
- **Real-time Generation**: Continuously generates and analyzes new numbers

## Use Cases
- **Cryptography Education**: Understanding randomness requirements
- **Statistical Analysis**: Comparing different random number sources
- **Quality Assurance**: Testing random number generator quality
- **Research**: Studying randomness properties and patterns

## Technical Implementation
- **GDScript**: Written in Godot's scripting language
- **Real-time Processing**: Continuous number generation and analysis
- **Visual Feedback**: Immediate display of results and statistics
- **Configurable Parameters**: Adjustable generation rates and analysis methods

## Performance Considerations
- TRNG generation is slower due to hardware dependency
- PRNG generation is fast and efficient
- Statistical analysis runs in real-time
- Memory usage scales with sequence length

## Future Enhancements
- Additional statistical tests (chi-square, Kolmogorov-Smirnov)
- Hardware entropy source integration
- Custom PRNG algorithm implementations
- Export capabilities for analysis results
