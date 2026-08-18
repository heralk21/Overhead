"""Shared: high-quality MP4 writer + anti-banding dither."""
import numpy as np
import imageio

def hq_writer(path, fps):
    # CRF 14 + slow preset = visually lossless; faststart for web playback.
    return imageio.get_writer(
        path, fps=fps, codec="libx264", format="FFMPEG",
        macro_block_size=1, ffmpeg_log_level="error",
        output_params=["-crf", "14", "-preset", "slow",
                       "-pix_fmt", "yuv420p", "-movflags", "+faststart"],
    )

_noise = None
def dither(arr):
    """Add +/-2 level noise to break up 8-bit banding in dark gradients."""
    global _noise
    h, w = arr.shape[:2]
    if _noise is None or _noise.shape[:2] != (h, w):
        rng = np.random.default_rng(11)
        _noise = rng.integers(-2, 3, size=(h, w, 3)).astype(np.int16)
    out = arr.astype(np.int16) + _noise
    return np.clip(out, 0, 255).astype(np.uint8)

def render(path, fps, frame_fn, n):
    w = hq_writer(path, fps)
    for i in range(n):
        w.append_data(dither(np.asarray(frame_fn(i / fps))))
    w.close()
    print("wrote", path, "frames", n)
