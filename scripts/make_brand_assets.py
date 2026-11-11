"""生成 App 图标 / 启动图所需的素材。

用法（在项目根目录）：

    python scripts/make_brand_assets.py

输入：assets/branding/app_icon_source.png
    - 设计稿原图，建议 1024×1024，可以带透明圆角
输出：assets/branding/app_icon.png              1024×1024，铺满、无透明（iOS / 桌面图标）
    assets/branding/app_icon_foreground.png    Android 自适应图标前景（透明底，内容占 72%）
    assets/branding/splash_logo.png            启动图 Logo（透明底，内容占 62%）

生成后会打印取到的背景色，把该值同步到 pubspec.yaml 的
flutter_native_splash.color / android_12.color 即可让启动图与图标无缝衔接。
"""

import os

from PIL import Image

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
BRAND_DIR = os.path.join(ROOT, "assets", "branding")
SOURCE = os.path.join(BRAND_DIR, "app_icon_source.png")

CANVAS = 1024
# Android 自适应图标的安全区是中间 66%，前景不要超出，否则文字会被圆形遮罩裁掉
ADAPTIVE_SCALE = 0.66
SPLASH_SCALE = 0.55


def sample_background(image: Image.Image, band: int = 28) -> tuple:
    """取边缘一圈“不透明”像素的中位数作为纸张底色。

    源图是带透明圆角的方形，四角本身没有有效颜色，不能直接取角点，
    所以沿着四条边往里一圈采样，跳过透明像素。
    """
    w, h = image.size
    pixels = image.load()
    xs = list(range(band)) + list(range(w - band, w))
    ys = list(range(h))
    samples = []

    for y in ys:
        for x in xs:
            r, g, b, a = pixels[x, y]
            if a > 240:
                samples.append((r, g, b))

    ys2 = list(range(band)) + list(range(h - band, h))
    for y in ys2:
        for x in range(w):
            r, g, b, a = pixels[x, y]
            if a > 240:
                samples.append((r, g, b))

    if not samples:
        return (246, 241, 227)

    channels = []
    for i in range(3):
        values = sorted(s[i] for s in samples)
        channels.append(values[len(values) // 2])
    return tuple(channels)


def main() -> None:
    if not os.path.exists(SOURCE):
        raise SystemExit(f"缺少源图：{SOURCE}")

    master = Image.open(SOURCE).convert("RGBA")
    if master.size != (CANVAS, CANVAS):
        master = master.resize((CANVAS, CANVAS), Image.LANCZOS)

    bg = sample_background(master)

    flat = Image.new("RGB", (CANVAS, CANVAS), bg)
    flat.paste(master, (0, 0), master)
    flat.save(os.path.join(BRAND_DIR, "app_icon.png"))

    def centered(scale: float) -> Image.Image:
        size = int(CANVAS * scale)
        art = master.resize((size, size), Image.LANCZOS)
        canvas = Image.new("RGBA", (CANVAS, CANVAS), (0, 0, 0, 0))
        offset = (CANVAS - size) // 2
        canvas.paste(art, (offset, offset), art)
        return canvas

    centered(ADAPTIVE_SCALE).save(
        os.path.join(BRAND_DIR, "app_icon_foreground.png")
    )
    centered(SPLASH_SCALE).save(os.path.join(BRAND_DIR, "splash_logo.png"))

    print(f"背景色：#%02X%02X%02X" % bg)
    print("已生成：app_icon.png / app_icon_foreground.png / splash_logo.png")


if __name__ == "__main__":
    main()
