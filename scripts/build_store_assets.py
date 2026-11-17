"""生成 Google Play 商店图标与特色图片。

用法：python scripts/build_store_assets.py
输出：
  store/assets/app-icon-512.png        512x512 商店图标
  store/assets/feature-graphic-1024x500.png
  store/assets/feature-graphic-1024x500.jpg
"""

from pathlib import Path

from PIL import Image, ImageDraw, ImageFont

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store" / "assets"
OUT.mkdir(parents=True, exist_ok=True)

BG = (244, 234, 216)
INK = (46, 42, 37)
SOFT = (110, 100, 88)
ACCENT = (180, 71, 46)
CARD = (255, 253, 248)

CN_FONT = Path(r"C:\Windows\Fonts\simkai.ttf")  # 楷体，与 App 内字形风格一致
CN_FALLBACK = ROOT / "assets" / "fonts" / "LXGWWenKai-Subset.ttf"
LATIN_FONT = Path(r"C:\Windows\Fonts\segoeuib.ttf")
LATIN_REG = Path(r"C:\Windows\Fonts\segoeui.ttf")


def has_glyphs(font_path: Path, text: str) -> bool:
    from fontTools.ttLib import TTFont

    cmap = set()
    with TTFont(str(font_path), fontNumber=0, lazy=True) as f:
        for table in f["cmap"].tables:
            cmap.update(table.cmap.keys())
    return all(ord(ch) in cmap for ch in text if not ch.isspace())


def build_icon() -> None:
    src = Image.open(ROOT / "assets" / "branding" / "app_icon.png").convert("RGBA")
    icon = src.resize((512, 512), Image.LANCZOS)
    # Play 要求 512x512 32 位 PNG，且不能有透明边（透明会被当成白色）
    square = Image.new("RGBA", (512, 512), BG + (255,))
    square.alpha_composite(icon)
    square.save(OUT / "app-icon-512.png", "PNG", optimize=True)
    print("icon:", (OUT / "app-icon-512.png").stat().st_size, "bytes")


def rounded_rect(draw, box, radius, fill):
    draw.rounded_rectangle(box, radius=radius, fill=fill)


def build_feature() -> None:
    W, H = 1024, 500
    img = Image.new("RGB", (W, H), BG)
    d = ImageDraw.Draw(img)

    # 柔和底纹：右上角暖色光晕 + 底部细线
    glow = Image.new("L", (W, H), 0)
    gd = ImageDraw.Draw(glow)
    gd.ellipse((640, -260, 1180, 280), fill=40)
    img.paste(Image.new("RGB", (W, H), (250, 214, 170)), (0, 0), glow)

    # 左侧品牌区
    icon = Image.open(OUT / "app-icon-512.png").convert("RGBA").resize((132, 132), Image.LANCZOS)
    mask = Image.new("L", (132, 132), 0)
    ImageDraw.Draw(mask).rounded_rectangle((0, 0, 131, 131), radius=30, fill=255)
    img.paste(icon, (72, 74), mask)

    cn_title = "入学必备720字"
    cn_ok = has_glyphs(CN_FONT, cn_title) or has_glyphs(CN_FALLBACK, cn_title)
    cn_path = CN_FONT if has_glyphs(CN_FONT, cn_title) else CN_FALLBACK
    title_font = ImageFont.truetype(str(cn_path), 74) if cn_ok else ImageFont.truetype(str(LATIN_FONT), 68)
    d.text((72, 232), cn_title, font=title_font, fill=INK)

    sub_font = ImageFont.truetype(str(LATIN_FONT), 34)
    d.text((74, 330), "HanziRoots · 720 Characters", font=sub_font, fill=ACCENT)

    tag_font = ImageFont.truetype(str(LATIN_REG), 26)
    tags = ["笔顺动画", "描红纠错", "3,380 条离线点读"]
    x = 74
    for text in tags:
        f = ImageFont.truetype(str(cn_path), 24) if cn_ok else tag_font
        bbox = d.textbbox((0, 0), text, font=f)
        w = bbox[2] - bbox[0] + 34
        rounded_rect(d, (x, 396, x + w, 446), 25, CARD)
        d.text((x + 17, 409), text, font=f, fill=SOFT)
        x += w + 14

    # 右侧字卡示意
    card = (700, 84, 944, 416)
    shadow = Image.new("RGBA", (W, H), (0, 0, 0, 0))
    ImageDraw.Draw(shadow).rounded_rectangle((706, 92, 950, 424), radius=28, fill=(46, 42, 37, 26))
    img.paste(Image.alpha_composite(img.convert("RGBA"), shadow).convert("RGB"), (0, 0))
    d = ImageDraw.Draw(img)
    rounded_rect(d, card, 28, CARD)
    # 田字格
    gx0, gy0, gx1, gy1 = 722, 106, 922, 306
    d.rectangle((gx0, gy0, gx1, gy1), outline=(214, 198, 170), width=2)
    d.line(((gx0 + gx1) // 2, gy0, (gx0 + gx1) // 2, gy1), fill=(226, 212, 186), width=1)
    d.line((gx0, (gy0 + gy1) // 2, gx1, (gy0 + gy1) // 2), fill=(226, 212, 186), width=1)
    d.line((gx0, gy0, gx1, gy1), fill=(236, 224, 202), width=1)
    d.line((gx1, gy0, gx0, gy1), fill=(236, 224, 202), width=1)

    glyph = "学"
    if has_glyphs(cn_path, glyph):
        gfont = ImageFont.truetype(str(cn_path), 168)
        bbox = d.textbbox((0, 0), glyph, font=gfont)
        gw, gh = bbox[2] - bbox[0], bbox[3] - bbox[1]
        d.text(
            ((gx0 + gx1 - gw) / 2 - bbox[0], (gy0 + gy1 - gh) / 2 - bbox[1]),
            glyph,
            font=gfont,
            fill=INK,
        )

    d.text((738, 324), "xué", font=ImageFont.truetype(str(LATIN_FONT), 34), fill=ACCENT)
    d.text((738, 366), "学习", font=ImageFont.truetype(str(cn_path), 26), fill=SOFT)
    d.text((800, 368), "to learn", font=ImageFont.truetype(str(LATIN_REG), 22), fill=SOFT)

    img.save(OUT / "feature-graphic-1024x500.png", "PNG", optimize=True)
    img.save(OUT / "feature-graphic-1024x500.jpg", "JPEG", quality=92, optimize=True)
    print("feature:", (OUT / "feature-graphic-1024x500.png").stat().st_size, "bytes")


if __name__ == "__main__":
    build_icon()
    build_feature()
