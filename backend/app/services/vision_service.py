"""Image/video helpers for the form-check feature: reading dimensions,
drawing flaw markers onto a photo, and pulling sample frames out of a
short video clip for per-frame analysis."""

import io

from PIL import Image, ImageDraw, ImageFont

_SEVERITY_COLORS = {
    "high": (248, 113, 113),
    "medium": (245, 158, 11),
    "low": (16, 185, 129),
}


def get_image_dimensions(image_bytes: bytes) -> tuple[int, int]:
    try:
        with Image.open(io.BytesIO(image_bytes)) as img:
            return img.size
    except Exception as exc:
        raise ValueError(f"Could not read image dimensions: {exc}") from exc


def draw_annotations(image_bytes: bytes, flaws: list[dict]) -> bytes:
    """Burns numbered, color-coded markers for each flaw onto the image and
    returns new JPEG bytes. Falls back to the original image if a flaw's
    coordinates fall outside the frame."""
    with Image.open(io.BytesIO(image_bytes)) as img:
        img = img.convert("RGB")
        draw = ImageDraw.Draw(img)
        try:
            font = ImageFont.load_default(size=max(14, img.width // 40))
        except TypeError:
            font = ImageFont.load_default()

        radius = max(10, img.width // 60)
        for i, flaw in enumerate(flaws):
            x, y = flaw.get("x"), flaw.get("y")
            if x is None or y is None:
                continue
            x = min(max(int(x), 0), img.width - 1)
            y = min(max(int(y), 0), img.height - 1)
            color = _SEVERITY_COLORS.get(flaw.get("severity", "medium"), _SEVERITY_COLORS["medium"])

            draw.ellipse([x - radius, y - radius, x + radius, y + radius], outline=color, width=3)
            label = str(i + 1)
            draw.text((x + radius + 4, y - radius), label, fill=color, font=font)

        buf = io.BytesIO()
        img.save(buf, format="JPEG", quality=85)
        return buf.getvalue()


def extract_video_frames(video_path: str, max_frames: int = 6) -> tuple[list[bytes], float]:
    """Samples up to max_frames evenly-spaced JPEG frames from a video file.
    Returns (frame_jpeg_bytes_list, duration_seconds)."""
    import cv2

    cap = cv2.VideoCapture(video_path)
    if not cap.isOpened():
        cap.release()
        raise ValueError("Could not open video file — invalid or corrupt format")

    total = int(cap.get(cv2.CAP_PROP_FRAME_COUNT))
    fps = cap.get(cv2.CAP_PROP_FPS)
    duration = total / fps if fps > 0 else 0

    if total <= 0:
        cap.release()
        raise ValueError("Video contains no readable frames")

    indices = [int(total * i / max_frames) for i in range(max_frames)]
    frames = []
    for idx in indices:
        cap.set(cv2.CAP_PROP_POS_FRAMES, idx)
        ok, frame = cap.read()
        if ok:
            ok, buf = cv2.imencode(".jpg", frame, [cv2.IMWRITE_JPEG_QUALITY, 80])
            if ok:
                frames.append(buf.tobytes())

    cap.release()
    return frames, round(duration, 1)
