"""抓取商店截图：跳过引导 → 首页。

用法：python scripts/shoot_flow.py
"""

from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store" / "raw"
OUT.mkdir(parents=True, exist_ok=True)

URL = "http://127.0.0.1:8765/"


def tap(page, x, y, wait=1500):
    page.mouse.click(x, y)
    page.wait_for_timeout(wait)


def main() -> None:
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        ctx = browser.new_context(
            viewport={"width": 360, "height": 640},
            device_scale_factor=3,
            is_mobile=True,
            has_touch=True,
            locale="zh-CN",
        )
        page = ctx.new_page()
        page.goto(URL, wait_until="load", timeout=60000)
        page.wait_for_timeout(9000)

        # 跳过四页引导
        tap(page, 223, 590, wait=2000)
        page.screenshot(path=str(OUT / "phone-03-home.png"))
        print("home captured")

        # 进入第 1 阶段 → 课程列表
        tap(page, 180, 212, wait=2500)
        page.screenshot(path=str(OUT / "phone-04-lessons.png"))
        print("lessons captured")

        # 进入第 1 课 → 学习卡片
        tap(page, 180, 152, wait=3000)
        page.screenshot(path=str(OUT / "phone-05-card.png"))
        print("card captured")

        # 关闭提示、打开英文释义、下滑到组词与例句
        tap(page, 334, 78, wait=800)
        tap(page, 330, 24, wait=900)
        page.mouse.move(180, 420)
        page.mouse.wheel(0, 700)
        page.wait_for_timeout(1200)
        page.screenshot(path=str(OUT / "phone-06-card-words.png"))
        print("words captured")

        # 返回首页，切到「按部首」
        tap(page, 27, 30, wait=1200)
        tap(page, 27, 30, wait=1500)
        tap(page, 180, 127, wait=2000)
        page.screenshot(path=str(OUT / "phone-07-radicals.png"))
        print("radicals captured")

        # 切到「按笔画」
        tap(page, 288, 127, wait=2000)
        page.screenshot(path=str(OUT / "phone-08-strokes.png"))
        print("strokes captured")

        # 按部首 → 木 → 汉字网格
        tap(page, 180, 127, wait=1500)
        tap(page, 180, 216, wait=2000)
        page.screenshot(path=str(OUT / "phone-09-grid.png"))
        print("grid captured")

        # 网格里点「木」，看多笔画字的笔顺卡片
        tap(page, 53, 133, wait=3000)
        page.screenshot(path=str(OUT / "phone-10-card-mu.png"))
        print("mu card captured")
        browser.close()


if __name__ == "__main__":
    main()
