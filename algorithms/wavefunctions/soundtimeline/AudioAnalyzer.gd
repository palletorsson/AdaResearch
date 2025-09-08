# AudioAnalyzer.gd
extends RefCounted

class_name AudioAnalyzer

# FFT processing
static func perform_fft(samples: PackedFloat32Array, fft_size: int) -> PackedFloat32Array:
	var result = PackedFloat32Array()
	result.resize(fft_size / 2)
	
	if samples.size() < fft_size:
		return result
	
	# Simple frequency binning (placeholder for real FFT)
	var window_size = fft_size / result.size()
	
	for i in range(result.size()):
		var magnitude = 0.0
		var start_idx = int(i * window_size)
		var end_idx = int((i + 1) * window_size)
		
		for j in range(start_idx, min(end_idx, samples.size())):
			magnitude += abs(samples[j])
		
		magnitude /= window_size
		result[i] = magnitude
	
	return result

# Spectrum analysis with proper frequency mapping
static func analyze_spectrum(samples: PackedFloat32Array, sample_rate: int = 44100, bands: int = 64) -> PackedFloat32Array:
	var spectrum = PackedFloat32Array()
	spectrum.resize(bands)
	
	if samples.is_empty():
		return spectrum
	
	# Log-scale frequency mapping for better visualization
	var nyquist = sample_rate / 2.0
	var max_freq = min(nyquist, 20000.0)  # Limit to 20kHz
	
	for i in range(bands):
		# Simpler logarithmic frequency distribution
		var log_start = log(20.0) + (log(max_freq) - log(20.0)) * i / bands
		var log_end = log(20.0) + (log(max_freq) - log(20.0)) * (i + 1) / bands
		var freq_start = exp(log_start)
		var freq_end = exp(log_end)
		
		var bin_start = int(freq_start * samples.size() / nyquist)
		var bin_end = int(freq_end * samples.size() / nyquist)
		
		var magnitude = 0.0
		var count = 0
		
		for j in range(bin_start, min(bin_end, samples.size())):
			magnitude += abs(samples[j])
			count += 1
		
		if count > 0:
			magnitude /= count
		
		spectrum[i] = magnitude
	
	return spectrum

# Waveform peak detection
static func find_peaks(samples: PackedFloat32Array, threshold: float = 0.1) -> Array[int]:
	var peaks: Array[int] = []
	
	if samples.size() < 3:
		return peaks
	
	for i in range(1, samples.size() - 1):
		var current = abs(samples[i])
		var prev = abs(samples[i - 1])
		var next = abs(samples[i + 1])
		
		if current > threshold and current > prev and current > next:
			peaks.append(i)
	
	return peaks

# RMS calculation for volume levels
static func calculate_rms(samples: PackedFloat32Array) -> float:
	if samples.is_empty():
		return 0.0
	
	var sum_squared = 0.0
	for sample in samples:
		sum_squared += sample * sample
	
	return sqrt(sum_squared / samples.size())

# Beat detection (simple energy-based)
static func detect_beats(spectrum: PackedFloat32Array, previous_spectrum: PackedFloat32Array, threshold: float = 1.5) -> bool:
	if spectrum.size() != previous_spectrum.size() or spectrum.is_empty():
		return false
	
	var current_energy = 0.0
	var previous_energy = 0.0
	
	# Focus on lower frequencies for beat detection
	var beat_bands = min(spectrum.size() / 4, 16)
	
	for i in range(beat_bands):
		current_energy += spectrum[i]
		previous_energy += previous_spectrum[i]
	
	current_energy /= beat_bands
	previous_energy /= beat_bands
	
	return current_energy > previous_energy * threshold

# Onset detection
static func detect_onsets(samples: PackedFloat32Array, window_size: int = 1024) -> Array[int]:
	var onsets: Array[int] = []
	
	if samples.size() < window_size * 2:
		return onsets
	
	var hop_size = window_size / 4
	var previous_energy = 0.0
	
	for i in range(0, samples.size() - window_size, hop_size):
		var window = samples.slice(i, i + window_size)
		var energy = calculate_rms(window)
		
		# Simple onset detection based on energy increase
		if energy > previous_energy * 1.3 and energy > 0.05:
			onsets.append(i)
		
		previous_energy = energy
	
	return onsets

# Tempo estimation (basic)
static func estimate_tempo(onsets: Array[int], sample_rate: int = 44100) -> float:
	if onsets.size() < 2:
		return 0.0
	
	var intervals: Array[float] = []
	
	for i in range(1, onsets.size()):
		var interval = float(onsets[i] - onsets[i-1]) / sample_rate
		if interval > 0.1 and interval < 2.0:  # Filter reasonable intervals
			intervals.append(interval)
	
	if intervals.is_empty():
		return 0.0
	
	# Find most common interval (simplified)
	intervals.sort()
	var median_interval = intervals[intervals.size() / 2]
	
	return 60.0 / median_interval  # Convert to BPM

# Audio normalization
static func normalize_audio(samples: PackedFloat32Array, target_level: float = 0.8) -> PackedFloat32Array:
	if samples.is_empty():
		return samples
	
	var max_amplitude = 0.0
	for sample in samples:
		max_amplitude = max(max_amplitude, abs(sample))
	
	if max_amplitude == 0.0:
		return samples
	
	var gain = target_level / max_amplitude
	var normalized = PackedFloat32Array()
	normalized.resize(samples.size())
	
	for i in range(samples.size()):
		normalized[i] = samples[i] * gain
	
	return normalized

# Windowing functions
static func apply_hanning_window(samples: PackedFloat32Array) -> PackedFloat32Array:
	var windowed = PackedFloat32Array()
	windowed.resize(samples.size())
	
	for i in range(samples.size()):
		var window_value = 0.5 * (1.0 - cos(2.0 * PI * i / (samples.size() - 1)))
		windowed[i] = samples[i] * window_value
	
	return windowed

# Frequency to mel scale conversion
static func hz_to_mel(hz: float) -> float:
	return 2595.0 * (log(1.0 + hz / 700.0) / log(10.0))

static func mel_to_hz(mel: float) -> float:
	return 700.0 * (pow(10, mel / 2595.0) - 1.0)

# Generate mel-scale frequency bands
static func generate_mel_bands(sample_rate: int, fft_size: int, num_bands: int) -> Array[Vector2]:
	var bands: Array[Vector2] = []
	var nyquist = sample_rate / 2.0
	
	var mel_min = hz_to_mel(0)
	var mel_max = hz_to_mel(nyquist)
	
	for i in range(num_bands + 1):
		var mel = mel_min + (mel_max - mel_min) * i / num_bands
		var hz = mel_to_hz(mel)
		var bin = int(hz * fft_size / sample_rate)
		
		if i > 0:
			var prev_bin = bands[i-1].y if bands.size() > 0 else 0
			bands.append(Vector2(prev_bin, bin))
	
	return bands
