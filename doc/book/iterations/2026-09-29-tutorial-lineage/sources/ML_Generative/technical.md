# ML Generative — Technical

The map runs a generative adversarial network (GAN). A generator takes random noise as input and produces images; a discriminator judges whether an image is real or fake. Both are trained alternately until the generator's outputs fool the discriminator.

```gdscript
class_name GAN extends Node

var generator: FeedforwardNet
var discriminator: FeedforwardNet

func train_step(real_batch: Array) -> void:
    # Train discriminator
    var noise: Array = sample_noise(real_batch.size())
    var fake_batch: Array = noise.map(func(z): return generator.forward(z))
    var d_loss_real := -log_mean(real_batch.map(func(x): return discriminator.forward(x)))
    var d_loss_fake := -log_mean(fake_batch.map(func(x): return 1.0 - discriminator.forward(x)))
    discriminator.step(d_loss_real + d_loss_fake)

    # Train generator
    noise = sample_noise(real_batch.size())
    var g_loss := -log_mean(noise.map(func(z): return discriminator.forward(generator.forward(z))))
    generator.step(g_loss)
```

## Training Dynamics

GAN training is notoriously unstable. If the discriminator becomes too good too fast, the generator's gradient vanishes (the discriminator assigns probability near 0 to all fakes, so there's nothing to learn from). If the generator becomes too good, the discriminator has no signal. Balanced training requires careful hyperparameter tuning.

Mode collapse is another failure mode. The generator discovers a small subset of outputs that reliably fool the discriminator and refuses to produce anything else. The discriminator cannot counter this because the fakes it sees are all from the collapsed mode.

## VAE Alternative

Variational autoencoders (VAEs) offer a different approach. The encoder maps inputs to a distribution over a latent space; the decoder maps latent samples back to input space. The loss combines reconstruction error with a Kullback-Leibler divergence that keeps the latent distribution close to a standard normal.

```gdscript
func vae_loss(x: Array, mu: Array, log_var: Array, x_reconstructed: Array) -> float:
    var recon: float = mse(x, x_reconstructed)
    var kl := 0.0
    for i in range(mu.size()):
        kl += 0.5 * (exp(log_var[i]) + mu[i] * mu[i] - 1.0 - log_var[i])
    return recon + kl
```

VAEs avoid GAN's instability but tend to produce blurrier samples because the reconstruction loss penalises per-pixel error rather than distribution-level similarity. Modern hybrids (VAE-GAN, diffusion models) combine both approaches.

## Complexity

A forward pass through either generator or discriminator is O(L·N²) for L layers of width N. A training step computes one forward and one backward pass through each network, so the per-step cost is roughly 4× a single network's forward cost.

Within the sequence, Generative is the creative turn. ML_Synthesis will next gather every thread the sequence has developed.

## Diffusion Models

Diffusion models have displaced GANs for high-quality image generation. The model learns to reverse a gradual noising process: given a noisy image, predict the clean image (or, equivalently, predict the noise that was added). At inference, start from pure noise and iteratively denoise.

```gdscript
func diffusion_forward(x_0: Array, t: int, noise_schedule: Array) -> Array:
    # Add noise scaled by the schedule at step t
    var alpha_t: float = noise_schedule[t]
    var noise: Array = sample_gaussian(x_0.size())
    var x_t: Array = []
    for i in range(x_0.size()):
        x_t.append(sqrt(alpha_t) * x_0[i] + sqrt(1.0 - alpha_t) * noise[i])
    return x_t

func diffusion_reverse(x_t: Array, t: int, model) -> Array:
    # Predict the noise, then subtract it to recover x_{t-1}
    var predicted_noise: Array = model.forward([x_t, t])
    var x_t_minus_1: Array = []
    for i in range(x_t.size()):
        x_t_minus_1.append(x_t[i] - predicted_noise[i] * step_size(t))
    return x_t_minus_1
```

Diffusion avoids GAN's mode collapse and VAE's blurriness, at the cost of slow inference (hundreds of denoising steps per sample). Guided diffusion and classifier-free guidance let the generation be conditioned on text or other signals.

## Autoregressive Generation

Language models generate text autoregressively — one token at a time, conditioning on previous tokens. Temperature scales the logits before softmax, controlling the randomness of the sampling. Top-k sampling restricts each step to the k most-probable tokens. Nucleus (top-p) sampling restricts to the smallest set of tokens whose cumulative probability exceeds p.

```gdscript
func sample_token(logits: Array, temperature: float = 1.0, top_k: int = 40) -> int:
    var scaled: Array = []
    for l in logits:
        scaled.append(l / temperature)
    var sorted_indices := argsort_desc(scaled)
    var top := sorted_indices.slice(0, top_k)
    var probs: Array = softmax_subset(scaled, top)
    return sample_categorical(top, probs)
```

## Evaluation

Generative models are hard to evaluate. Inception Score and Frechet Inception Distance measure output quality against a reference distribution. Human evaluation remains the gold standard for images and text. For structured outputs, task-specific metrics (BLEU for translation, perplexity for language modelling) are common but each has known failure modes.
