"""校验隐私政策页面的中英切换与排版。"""

from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store" / "raw"
OUT.mkdir(parents=True, exist_ok=True)
URL = (ROOT / "docs" / "privacy-policy.html").as_uri()


def main() -> None:
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        page = browser.new_page(viewport={"width": 900, "height": 1400}, device_scale_factor=1)
        errors = []
        page.on("pageerror", lambda e: errors.append(str(e)))
        page.goto(URL, wait_until="load")
        page.wait_for_timeout(800)
        page.screenshot(path=str(OUT / "privacy-zh.png"), full_page=False)
        page.click("#btn-en")
        page.wait_for_timeout(500)
        page.screenshot(path=str(OUT / "privacy-en.png"), full_page=False)
        print("lang:", page.get_attribute("html", "lang"))
        print("title:", page.title())
        print("errors:", errors)
        browser.close()


if __name__ == "__main__":
    main()
