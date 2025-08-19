# RSA Encryption Visualization

## 🔐 Cryptographic Authority & Digital Sovereignty

A comprehensive implementation of RSA public-key cryptography with interactive key generation, encryption/decryption visualization, and cryptographic security analysis. This implementation explores the mathematics of prime factorization, the politics of digital trust, and the power structures embedded in cryptographic systems.

## 🎯 Algorithm Overview

RSA (Rivest-Shamir-Adleman) is a public-key cryptographic algorithm that enables secure communication without prior key exchange. It relies on the computational difficulty of factoring large composite numbers into their prime factors, creating an asymmetric encryption system where public keys can be shared openly while private keys remain secret.

### Key Concepts

1. **Public-Key Cryptography**: Asymmetric encryption using key pairs
2. **Prime Factorization**: Security based on difficulty of factoring large numbers
3. **Modular Arithmetic**: Mathematical operations in finite fields
4. **Euler's Totient Function**: φ(n) = (p-1)(q-1) for prime factors p, q
5. **Modular Multiplicative Inverse**: Finding d such that e·d ≡ 1 (mod φ(n))
6. **Digital Signatures**: Authentication using private key signing

## 🔧 Technical Implementation

### Core Algorithm Features

- **Key Generation**: Prime number generation with Miller-Rabin primality testing
- **Encryption/Decryption**: Fast modular exponentiation for message processing
- **Multiple Key Sizes**: 128, 256, 512, and 1024-bit demonstrations
- **Interactive Visualization**: 3D representation of cryptographic operations
- **Security Analysis**: Real-time assessment of cryptographic strength
- **Step-by-Step Animation**: Detailed visualization of mathematical operations

### RSA Key Generation Process

#### Step 1: Prime Generation
```
1. Generate two large prime numbers p and q
2. Ensure p ≠ q for security
3. Use Miller-Rabin primality test for verification
4. Bit size determines security level
```

#### Step 2: Modulus Computation
```
n = p × q
```
- n is the RSA modulus used in both public and private keys
- Security depends on difficulty of factoring n back into p and q

#### Step 3: Euler's Totient Function
```
φ(n) = (p-1) × (q-1)
```
- φ(n) counts integers relatively prime to n
- Essential for computing the private exponent

#### Step 4: Public Exponent Selection
```
Choose e such that 1 < e < φ(n) and gcd(e, φ(n)) = 1
```
- Common choice: e = 65537 (2^16 + 1)
- Must be coprime to φ(n)

#### Step 5: Private Exponent Computation
```
d = e^(-1) mod φ(n)
```
- d is the modular multiplicative inverse of e
- Computed using Extended Euclidean Algorithm

### Encryption and Decryption

#### Encryption Process
```
C = M^e mod n
```
- M: Plaintext message (as integer)
- C: Ciphertext (encrypted message)
- (e, n): Public key

#### Decryption Process
```
M = C^d mod n
```
- C: Ciphertext to decrypt
- M: Recovered plaintext
- (d, n): Private key

### Mathematical Foundations

#### Miller-Rabin Primality Test
```gdscript
func is_prime(n, k_rounds):
    # Write n-1 as d * 2^r
    d = n - 1
    r = 0
    while d % 2 == 0:
        d //= 2
        r += 1
    
    # Perform k rounds of testing
    for i in range(k_rounds):
        a = random(2, n-2)
        x = mod_exp(a, d, n)
        
        if x == 1 or x == n-1:
            continue
        
        composite = true
        for j in range(r-1):
            x = (x * x) % n
            if x == n-1:
                composite = false
                break
        
        if composite:
            return false
    
    return true
```

#### Fast Modular Exponentiation
```gdscript
func mod_exp(base, exponent, modulus):
    result = 1
    base = base % modulus
    
    while exponent > 0:
        if exponent % 2 == 1:
            result = (result * base) % modulus
        exponent = exponent >> 1
        base = (base * base) % modulus
    
    return result
```

## 🎮 Interactive Controls

### Basic Controls
- **SPACE**: Start encryption of demo message
- **D**: Decrypt current ciphertext
- **G**: Generate new RSA key pair
- **R**: Reset entire RSA system
- **M**: Change demonstration message
- **S**: Toggle step-by-step vs. complete execution

### Key Size Controls
- **1**: 128-bit keys (demo only - easily breakable)
- **2**: 256-bit keys (educational purposes)
- **3**: 512-bit keys (moderate security)
- **4**: 1024-bit keys (legacy standard)

### Configuration Parameters
- **Key Size**: Bits of security (affects prime size)
- **Primality Test Rounds**: Miller-Rabin test iterations
- **Message Format**: Text vs. numeric input
- **Visualization Detail**: Show intermediate steps and calculations

## 📊 Visualization Features

### 3D Cryptographic Representation
- **Public Key Zone**: Green area displaying public key components
- **Private Key Zone**: Red area showing private key (secure)
- **Prime Factors**: Magenta spheres representing p and q
- **Message Flow**: Visual encryption/decryption pipeline
- **Calculation Steps**: Animated mathematical operations

### Security Analysis Display
- **Key Strength Assessment**: Real-time security level evaluation
- **Factorization Difficulty**: Estimated computational requirements
- **Performance Metrics**: Key generation and operation timing
- **Vulnerability Warnings**: Educational security notices

### Mathematical Operation Visualization
- **Modular Exponentiation**: Step-by-step calculation display
- **Prime Generation**: Animated primality testing
- **Key Component Relationships**: Visual representation of mathematical connections
- **Binary Representations**: Optional bit-level display

## 🏳️‍🌈 Cryptographic Authority Framework

### Digital Sovereignty Politics
RSA encryption embodies fundamental questions about digital power and cryptographic authority:

- **Who controls the keys?** Public-key distribution creates trust hierarchies
- **What constitutes security?** Key length assumptions embed temporal power structures
- **How is cryptographic authority established?** Certificate authorities and trust chains
- **What gets protected vs. exposed?** Asymmetric encryption privileges certain communications

### Algorithmic Justice Questions
1. **Cryptographic Equity**: Does strong encryption serve all communities equally?
2. **Digital Divide**: How do computational requirements exclude participants?
3. **Trust Infrastructure**: Who decides cryptographic standards and implementations?
4. **Surveillance Resistance**: How does encryption challenge state power?

## 🔬 Educational Applications

### Cryptographic Fundamentals
- **Public-Key Cryptography**: Understanding asymmetric encryption principles
- **Number Theory**: Prime numbers, modular arithmetic, and mathematical security
- **Computational Complexity**: Security based on computational hardness assumptions
- **Digital Trust**: Certificate authorities, key distribution, and trust models

### Mathematical Concepts
- **Prime Number Generation**: Probabilistic primality testing algorithms
- **Modular Exponentiation**: Efficient computation in finite fields
- **Euler's Theorem**: Theoretical foundation for RSA correctness
- **Extended Euclidean Algorithm**: Computing modular multiplicative inverses

## 📈 Performance Characteristics

### Computational Complexity

#### Key Generation
- **Prime Generation**: O(k² × log³ n) where k is primality test rounds
- **Modular Inverse**: O(log φ(n)) using Extended Euclidean Algorithm
- **Total Key Generation**: Dominated by prime generation complexity

#### Encryption/Decryption
- **Modular Exponentiation**: O(log e) for encryption, O(log d) for decryption
- **Message Processing**: Linear in message length
- **Performance**: Decryption typically slower due to larger private exponent

### Security Analysis

#### Key Size Recommendations
| Key Size | Security Level | Factorization Effort | Status |
|----------|----------------|----------------------|---------|
| 512 bits | ~80 bits | 2^80 operations | Deprecated |
| 1024 bits | ~80 bits | 2^80 operations | Legacy |
| 2048 bits | ~112 bits | 2^112 operations | Current Standard |
| 3072 bits | ~128 bits | 2^128 operations | High Security |
| 4096 bits | ~140 bits | 2^140 operations | Maximum Recommended |

#### Vulnerability Considerations
- **Factorization Attacks**: Quantum computers threaten RSA security
- **Timing Attacks**: Side-channel vulnerabilities in implementation
- **Weak Random Number Generation**: Compromise of prime generation
- **Small Message Attacks**: Vulnerability with small plaintext values

## 🎓 Learning Objectives

### Primary Goals
1. **Master public-key cryptography** principles and mathematical foundations
2. **Understand computational security** based on number-theoretic assumptions
3. **Analyze cryptographic protocols** and their real-world implications
4. **Explore digital sovereignty** and cryptographic power structures

### Advanced Topics
- **Elliptic Curve Cryptography**: More efficient alternative to RSA
- **Post-Quantum Cryptography**: Quantum-resistant algorithms
- **Cryptographic Protocols**: Key exchange, digital signatures, certificates
- **Side-Channel Analysis**: Physical security of cryptographic implementations

## 🔍 Experimental Scenarios

### Recommended Explorations

1. **Key Size Security Analysis**
   - Compare factorization difficulty across key sizes
   - Analyze performance vs. security tradeoffs
   - Study quantum computing threats to current standards

2. **Prime Generation Efficiency**
   - Compare different primality testing algorithms
   - Analyze prime distribution and generation patterns
   - Study pseudorandom number generator quality

3. **Implementation Vulnerabilities**
   - Explore timing attack susceptibilities
   - Analyze side-channel information leakage
   - Study secure implementation practices

4. **Cryptographic Protocol Design**
   - Design secure key exchange protocols
   - Implement digital signature schemes
   - Study certificate authority trust models

## 🚀 Advanced Features

### Cryptographic Extensions
- **Digital Signatures**: RSA signing and verification
- **Hybrid Cryptography**: RSA with symmetric ciphers
- **Key Escrow**: Secure key backup and recovery
- **Multi-Party Protocols**: Threshold cryptography

### Security Enhancements
- **Side-Channel Resistance**: Timing attack mitigation
- **Secure Random Generation**: Cryptographically strong entropy
- **Key Validation**: Public key verification protocols
- **Forward Secrecy**: Perfect forward secrecy implementations

### Visualization Improvements
- **Network Protocol Simulation**: SSL/TLS handshake visualization
- **Attack Scenario Demonstrations**: Common vulnerability exploits
- **Performance Benchmarking**: Comparative algorithm analysis
- **Historical Context**: Evolution of cryptographic standards

## 🎯 Critical Questions for Reflection

1. **How do cryptographic algorithms embody particular values about privacy and security?**
2. **What are the social implications of computational security assumptions?**
3. **When might strong encryption conflict with other social values?**
4. **How do cryptographic standards reflect power relationships in digital systems?**

## 📚 Further Reading

### Foundational Papers
- Rivest, R., Shamir, A., & Adleman, L. (1978). A Method for Obtaining Digital Signatures and Public-Key Cryptosystems
- Miller, G. L. (1976). Riemann's Hypothesis and Tests for Primality
- Rabin, M. O. (1980). Probabilistic Algorithm for Testing Primality

### Cryptographic Literature
- Menezes, A., van Oorschot, P., & Vanstone, S. (1996). Handbook of Applied Cryptography
- Katz, J., & Lindell, Y. (2014). Introduction to Modern Cryptography
- Ferguson, N., Schneier, B., & Kohno, T. (2010). Cryptography Engineering

### Critical Cryptography Studies
- Rogaway, P. (2015). The Moral Character of Cryptographic Work
- Green, M. (2013). A Few Thoughts on Cryptographic Engineering
- Levy, S. (2001). Crypto: How the Code Rebels Beat the Government

## 🔧 Technical Implementation Details

### RSA Key Generation
```gdscript
func generate_rsa_keys(bit_size):
    # Generate two large primes
    p = generate_large_prime(bit_size / 2)
    q = generate_large_prime(bit_size / 2)
    
    # Compute modulus
    n = p * q
    
    # Compute Euler's totient
    phi_n = (p - 1) * (q - 1)
    
    # Choose public exponent
    e = 65537
    while gcd(e, phi_n) != 1:
        e += 2
    
    # Compute private exponent
    d = mod_inverse(e, phi_n)
    
    return {
        "public_key": [e, n],
        "private_key": [d, n],
        "primes": [p, q]
    }
```

### Secure Prime Generation
```gdscript
func generate_large_prime(bit_size):
    while true:
        candidate = random_odd_number(bit_size)
        
        # Quick primality pre-screening
        if not passes_trial_division(candidate):
            continue
        
        # Miller-Rabin primality test
        if miller_rabin_test(candidate, rounds):
            return candidate
```

### Message Processing
```gdscript
func process_message(message, chunk_size):
    chunks = []
    for i in range(0, message.length(), chunk_size):
        chunk = message.substr(i, chunk_size)
        number = string_to_number(chunk)
        chunks.append(number)
    return chunks

func encrypt_chunks(chunks, public_key):
    encrypted = []
    for chunk in chunks:
        ciphertext = mod_exp(chunk, public_key[0], public_key[1])
        encrypted.append(ciphertext)
    return encrypted
```

## 📊 Performance Metrics

### Key Generation Analysis
- **Prime Generation Time**: Time to find suitable primes
- **Mathematical Operations**: Modular arithmetic complexity
- **Security Validation**: Cryptographic strength assessment
- **Memory Usage**: Storage requirements for different key sizes

### Encryption Performance
- **Message Processing Speed**: Throughput for different message sizes
- **Modular Exponentiation Efficiency**: Optimization techniques impact
- **Comparative Analysis**: RSA vs. other cryptographic algorithms
- **Scalability**: Performance degradation with key size increase

### Security Evaluation
- **Cryptographic Strength**: Estimated security bits
- **Vulnerability Assessment**: Known attack resistance
- **Implementation Security**: Side-channel attack resilience
- **Long-term Viability**: Quantum computing threat analysis

---

**Status**: ✅ Complete - Production Ready  
**Complexity**: Advanced Cryptography  
**Prerequisites**: Number Theory, Modular Arithmetic, Computational Complexity  
**Estimated Learning Time**: 6-8 hours for basic concepts, 20+ hours for cryptographic mastery 