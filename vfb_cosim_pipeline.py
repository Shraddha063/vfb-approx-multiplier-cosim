import numpy as np
import scipy.signal as signal
import subprocess
import matplotlib.pyplot as plt

# ---------------------------------------------------------
# 1. GENERATE NDE SENSOR INPUT & FILTER BANK COEFFICIENTS
# ---------------------------------------------------------
fs = 10000  # Sampling frequency: 10 kHz
t = np.linspace(0, 0.05, int(fs * 0.05), endpoint=False)

# Multi-frequency NDE Sensor Signal: Low (100Hz), Mid (500Hz), High (2000Hz)
sig_100hz  = 0.8 * np.sin(2 * np.pi * 100 * t)
sig_500hz  = 1.0 * np.sin(2 * np.pi * 500 * t)
sig_2000hz = 0.5 * np.sin(2 * np.pi * 2000 * t)
raw_sensor_signal = sig_100hz + sig_500hz + sig_2000hz + np.random.normal(0, 0.1, size=len(t))

# FIR Filter Bank Design (Low-pass, Band-pass, High-pass)
num_taps = 17
b_lp = signal.firwin(num_taps, 250, fs=fs)
b_bp = signal.firwin(num_taps, [300, 800], pass_zero=False, fs=fs)
b_hp = signal.firwin(num_taps, 1200, pass_zero=False, fs=fs)

# Quantize signal and coefficients to 8-bit unsigned scale (0 to 255)
def quantize_8bit(data):
    scaled = (data - np.min(data)) / (np.max(data) - np.min(data) + 1e-8) * 255
    return np.clip(scaled, 0, 255).astype(np.uint8)

q_signal = quantize_8bit(raw_sensor_signal)

# ---------------------------------------------------------
# 2. VERILOG HARDWARE CO-SIMULATION FUNCTION
# ---------------------------------------------------------
# Compile Verilog HDL code using Icarus Verilog
subprocess.run(["iverilog", "-o", "vfb_sim.vvp", "approx_multiplier.v", "tb_runner.v"], check=True)

def run_verilog_filter_channel(b_coeffs, input_bytes):
    q_b = quantize_8bit(b_coeffs)
    n_samples = len(input_bytes)
    
    # Create input vector file for Verilog MAC operations
    input_pairs = []
    for n in range(num_taps, n_samples):
        for k in range(num_taps):
            input_pairs.append((q_b[k], input_bytes[n - k]))
            
    with open("input_pairs.txt", "w") as f:
        for val_a, val_b in input_pairs:
            f.write(f"{val_a} {val_b}\n")
            
    # Execute Verilog hardware simulation
    subprocess.run(["vvp", "vfb_sim.vvp"], check=True)
    
    # Read back hardware computed products
    with open("hardware_outputs.txt", "r") as f:
        raw_products = [int(line.strip()) for line in f.readlines() if line.strip()]
        
    # Accumulate MAC outputs
    filtered_out = np.zeros(n_samples)
    idx = 0
    for n in range(num_taps, n_samples):
        mac_sum = 0
        for k in range(num_taps):
            mac_sum += raw_products[idx]
            idx += 1
        filtered_out[n] = mac_sum
        
    return filtered_out

print("Simulating Verilog Hybrid Dadda Multiplier across Filter Bank channels...")
hw_lp = run_verilog_filter_channel(b_lp, q_signal)
hw_bp = run_verilog_filter_channel(b_bp, q_signal)
hw_hp = run_verilog_filter_channel(b_hp, q_signal)

# Floating point baseline filters for comparison
sw_lp = signal.lfilter(b_lp, 1.0, raw_sensor_signal)
sw_bp = signal.lfilter(b_bp, 1.0, raw_sensor_signal)
sw_hp = signal.lfilter(b_hp, 1.0, raw_sensor_signal)

# Normalize for visual overlay comparison
def norm(x): return x / (np.max(np.abs(x)) + 1e-8)

print("Co-simulation complete!")

# ---------------------------------------------------------
# 3. PLOT AND SAVE VISUALIZATION FOR GITHUB
# ---------------------------------------------------------
fig, axs = plt.subplots(4, 1, figsize=(12, 10))

axs[0].plot(t * 1000, raw_sensor_signal, color='gray')
axs[0].set_title("Input Composite NDE Sensor Signal (Time Domain)")
axs[0].set_ylabel("Amplitude")
axs[0].grid(True)

axs[1].plot(t * 1000, norm(sw_lp), color='blue', label='Software Floating-Point FIR')
axs[1].plot(t * 1000, norm(hw_lp), color='red', linestyle='--', label='Verilog Approx Dadda Hardware')
axs[1].set_title("Channel 1: Low-Pass Band (<250 Hz)")
axs[1].set_ylabel("Norm Amplitude")
axs[1].legend()
axs[1].grid(True)

axs[2].plot(t * 1000, norm(sw_bp), color='blue', label='Software Floating-Point FIR')
axs[2].plot(t * 1000, norm(hw_bp), color='green', linestyle='--', label='Verilog Approx Dadda Hardware')
axs[2].set_title("Channel 2: Band-Pass Band (300 Hz - 800 Hz)")
axs[2].set_ylabel("Norm Amplitude")
axs[2].legend()
axs[2].grid(True)

axs[3].plot(t * 1000, norm(sw_hp), color='blue', label='Software Floating-Point FIR')
axs[3].plot(t * 1000, norm(hw_hp), color='purple', linestyle='--', label='Verilog Approx Dadda Hardware')
axs[3].set_title("Channel 3: High-Pass Band (>1200 Hz)")
axs[3].set_xlabel("Time (ms)")
axs[3].set_ylabel("Norm Amplitude")
axs[3].legend()
axs[3].grid(True)

plt.tight_layout()
plt.savefig("vfb_hardware_cosim_output.png", dpi=300)
plt.show()
