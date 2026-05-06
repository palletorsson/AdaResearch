# ML Generative

Generate new data from a learned distribution. GAN, VAE, diffusion.

Build a GAN generator.

```gdscript
class_name Generator extends FeedforwardNet

func generate(noise: Array) -> Array:
    return forward(noise)
```

Takes random noise; produces a sample. The network's weights encode the learned distribution.

Build a GAN discriminator.

```gdscript
class_name Discriminator extends FeedforwardNet

func is_real(sample: Array) -> float:
    var output := forward(sample)
    return output[0]  # scalar probability
```

Outputs the probability the input is real (rather than generated).

Train the GAN.

```gdscript
func train_step(real_batch: Array, generator: Generator, discriminator: Discriminator, lr: float = 0.001) -> void:
    var fake_batch: Array = []
    for _i in real_batch.size():
        var z: Array = sample_noise(32)
        fake_batch.append(generator.generate(z))
    discriminator.backward_real_batch(real_batch, lr)
    discriminator.backward_fake_batch(fake_batch, lr)
    var fake_batch_new: Array = []
    for _i in real_batch.size():
        var z: Array = sample_noise(32)
        fake_batch_new.append(generator.generate(z))
    generator.backward_fool_discriminator(fake_batch_new, discriminator, lr)
```

Alternating training. First the discriminator learns to distinguish; then the generator learns to fool.

Sample noise.

```gdscript
func sample_noise(size: int) -> Array:
    var noise: Array = []
    for _i in size:
        noise.append(randfn(0.0, 1.0))
    return noise
```

Standard Gaussian. Each generator input is an independent noise vector.

Build a VAE encoder.

```gdscript
func vae_encode(x: Array) -> Dictionary:
    var h := encoder_forward(x)
    return {
        "mu": extract_mu(h),
        "log_var": extract_log_var(h),
    }
```

The encoder produces mean and log-variance of a Gaussian. Sampling from this distribution gives the latent code.

Reparameterise for gradient flow.

```gdscript
func reparameterize(mu: Array, log_var: Array) -> Array:
    var z: Array = []
    for i in mu.size():
        var std: float = exp(0.5 * log_var[i])
        var eps: float = randfn(0.0, 1.0)
        z.append(mu[i] + eps * std)
    return z
```

Reparameterisation moves the randomness outside the network. Gradient flows through mu and log_var.

Compute VAE loss.

```gdscript
func vae_loss(x: Array, reconstructed: Array, mu: Array, log_var: Array) -> float:
    var recon_loss: float = 0.0
    for i in x.size():
        recon_loss += (x[i] - reconstructed[i]) ** 2
    var kl_loss: float = 0.0
    for i in mu.size():
        kl_loss += 0.5 * (exp(log_var[i]) + mu[i] * mu[i] - 1.0 - log_var[i])
    return recon_loss + kl_loss
```

Reconstruction plus KL divergence. Balances fidelity against latent-space regularity.

Run a single diffusion step.

```gdscript
func diffusion_forward(x_0: Array, t: float, beta: float = 0.01) -> Array:
    var alpha: float = 1.0 - beta * t
    var noise: Array = sample_noise(x_0.size())
    var x_t: Array = []
    for i in x_0.size():
        x_t.append(sqrt(alpha) * x_0[i] + sqrt(1.0 - alpha) * noise[i])
    return x_t
```

Add progressively more noise. The reverse process is a learned neural network.

You can now build GAN generators and discriminators, train with alternating optimisation, encode and decode with VAEs using reparameterisation, compute VAE loss, and run one diffusion step. ML_Synthesis extends into a multi-paradigm synthesis map.
