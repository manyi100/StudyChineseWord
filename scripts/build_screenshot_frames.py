"""把原始截图排版成 1080x1920 的 Google Play 商店截图（带标题）。

用法：python scripts/build_screenshot_frames.py
输入：store/raw/phone-*.png
输出：store/screenshots/zh/01..06-*.png
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFilter, ImageFont

ROOT = Path(__file__).resolve().parent.parent
RAW = ROOT / "store" / "raw"
OUT = ROOT / "store" / "screenshots" / "zh"
OUT.mkdir(parents=True, exist_ok=True)

W, H = 1080, 1920
BG = (244, 234, 216)
INK = (46, 42, 37)
CARD_SHADOW = (120, 100, 70)

CN_FONT = Path(r"C:\Windows\Fonts\simkai.ttf")

FRAMES = [
    ("phone-03-home.png", "720 字，6 阶段循序渐进", "01-home"),
    ("phone-04-lessons.png", "30 门主题课，每课 4 字", "02-lessons"),
    ("phone-10-card-mu.png", "笔顺演示 + 手指描红纠错", "03-stroke-order"),
    ("phone-06-card-words.png", "单字 · 组词 · 例句，一点即读", "04-words"),
    ("phone-09-grid.png", "174 个部首，按部首查字", "05-radicals"),
    ("phone-08-strokes.png", "按笔画难度，零基础也能学", "06-strokes"),
]


def fit(img: Image.Image, max_w: int, max_h: int) -> Image.Image:
    scale = min(max_w / img.width, max_h / img.height)
    return img.resize((round(img.width * scale), round(img.height * scale)), Image.LANCZOS)


def frame(src: Path, caption: str, out_name: str) -> None:
    canvas = Image.new("RGB", (W, H), BG)
    draw = ImageDraw.Draw(canvas)

    font = ImageFont.truetype(str(CN_FONT), 58)
    bbox = draw.textbbox((0, 0), caption, font=font)
    tw = bbox[2] - bbox[0]
    draw.text(((W - tw) / 2 - bbox[0], 78 - bbox[1]), caption, font=font, fill=INK)

    shot = Image.open(src).convert("RGB")
    shot = fit(shot, 980, 1740)
    x = (W - shot.width) // 2
    y = 170
    r = 26

    # 阴影
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    sd = ImageDraw.Draw(shadow)
    sd.rounded_rectangle(
        (x + 6, y + 14, x + shot.width + 6, y + shot.height + 14),
        radius=r,
        fill=CARD_SHADOW + (70,),
    )
    shadow = shadow.filter(ImageFilter.GaussianBlur(18))
    canvas.paste(Image.alpha_composite(canvas.convert("RGBA"), shadow).convert("RGB"), (0, 0))

    # 圆角截图
    mask = Image.new("L", shot.size, 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, shot.width - 1, shot.height - 1), radius=r, fill=255)
    canvas.paste(shot, (x, y), mask)

    path = OUT / f"{out_name}.png"
    canvas.save(path, "PNG", optimize=True)
    print(f"{path.name}: {path.stat().st_size // 1024} KB  {canvas.size}")


if __name__ == "__main__":
    for src_name, caption, out_name in FRAMES:
        frame(RAW / src_name, caption, out_name)
