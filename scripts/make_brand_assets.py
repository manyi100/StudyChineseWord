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
ADAPTIVE_SCALE = 0.72
SPLASH_SCALE = 0.62


def main() -> None:
    if not os.path.exists(SOURCE):
        raise SystemExit(f"缺少源图：{SOURCE}")

    master = Image.open(SOURCE).convert("RGBA")
    if master.size != (CANVAS, CANVAS):
        master = master.resize((CANVAS, CANVAS), Image.LANCZOS)

    # 用四角像素的均值作为背景色，透明区域（圆角外部）会被这个颜色填满
    w, h = master.size
    corners = [
        master.getpixel((2, 2)),
        master.getpixel((w - 3, 2)),
        master.getpixel((2, h - 3)),
        master.getpixel((w - 3, h - 3)),
    ]
    bg = tuple(sum(c[i] for c in corners) // 4 for i in range(3))

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
