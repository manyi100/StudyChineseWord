"""把隐私政策 / 服务条款整页渲染成图片，并校验中英切换与站内链接。"""

from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store" / "raw"
OUT.mkdir(parents=True, exist_ok=True)

PAGES = [
    ("privacy-policy.html", "legal-privacy"),
    ("terms-of-service.html", "legal-terms"),
]


def main() -> None:
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        for name, slug in PAGES:
            page = browser.new_page(viewport={"width": 820, "height": 1200}, device_scale_factor=2)
            errors = []
            page.on("pageerror", lambda e: errors.append(str(e)))
            page.goto((ROOT / "docs" / name).as_uri(), wait_until="load")
            page.wait_for_timeout(600)
            page.screenshot(path=str(OUT / f"{slug}-zh.png"), full_page=True)

            page.click("#btn-en")
            page.wait_for_timeout(400)
            page.screenshot(path=str(OUT / f"{slug}-en.png"), full_page=True)

            nav_visible = page.locator("#nav-terms-en, #nav-home-en").count()
            print(f"{name}: lang={page.get_attribute('html', 'lang')} title={page.title()} errors={errors} nav={nav_visible}")
            page.close()
        browser.close()


if __name__ == "__main__":
    main()
