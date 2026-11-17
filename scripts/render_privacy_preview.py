"""把隐私政策整页渲染成图片，便于直接查看/校对。"""

from pathlib import Path

from playwright.sync_api import sync_playwright

ROOT = Path(__file__).resolve().parent.parent
OUT = ROOT / "store" / "raw"
OUT.mkdir(parents=True, exist_ok=True)
URL = (ROOT / "docs" / "privacy-policy.html").as_uri()


def main() -> None:
    with sync_playwright() as p:
        browser = p.chromium.launch(channel="chrome", headless=True)
        page = browser.new_page(viewport={"width": 820, "height": 1200}, device_scale_factor=2)
        page.goto(URL, wait_until="load")
        page.wait_for_timeout(600)
        page.screenshot(path=str(OUT / "privacy-full-zh.png"), full_page=True)
        page.click("#btn-en")
        page.wait_for_timeout(400)
        page.screenshot(path=str(OUT / "privacy-full-en.png"), full_page=True)
        h = page.evaluate("document.body.scrollHeight")
        print("full page height:", h)
        browser.close()


if __name__ == "__main__":
    main()
