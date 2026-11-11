"""从开源笔顺库 Make Me a Hanzi 提取入学必备 720 字的矢量轮廓 (strokes) 与中心骨架 (medians)，
生成离线数据包 assets/data/stroke_data.json。
"""
import json
import os
import urllib.request

PROJECT_ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
HANZI_JSON = os.path.join(PROJECT_ROOT, "assets", "data", "hanzi_data.json")
OUTPUT_JSON = os.path.join(PROJECT_ROOT, "assets", "data", "stroke_data.json")

URLS = [
    "https://raw.githubusercontent.com/skishore/makemeahanzi/master/graphics.txt",
    "https://cdn.jsdelivr.net/gh/skishore/makemeahanzi@master/graphics.txt",
    "https://fastly.jsdelivr.net/gh/skishore/makemeahanzi@master/graphics.txt",
]


def main() -> None:
    with open(HANZI_JSON, "r", encoding="utf-8") as f:
        hanzi_list = json.load(f)
    target_chars = {item["char"] for item in hanzi_list}
    print(f"目标汉字数: {len(target_chars)}")

    raw = None
    for url in URLS:
        try:
            print(f"正在下载: {url}")
            req = urllib.request.Request(url, headers={"User-Agent": "Mozilla/5.0"})
            with urllib.request.urlopen(req, timeout=45) as resp:
                raw = resp.read().decode("utf-8")
            break
        except Exception as exc:
            print(f"下载失败: {exc}")

    if not raw:
        raise RuntimeError("无法下载 Make Me a Hanzi graphics.txt")

    stroke_map = {}
    for line in raw.splitlines():
        line = line.strip()
        if not line:
            continue
        obj = json.loads(line)
        ch = obj.get("character")
        if ch in target_chars:
            stroke_map[ch] = {
                "strokes": obj["strokes"],
                "medians": obj["medians"],
            }

    print(f"匹配成功: {len(stroke_map)} / {len(target_chars)}")
    with open(OUTPUT_JSON, "w", encoding="utf-8") as f:
        json.dump(stroke_map, f, ensure_ascii=False, separators=(",", ":"))
    size_kb = os.path.getsize(OUTPUT_JSON) // 1024
    print(f"已保存 {OUTPUT_JSON} ({size_kb} KB)")


if __name__ == "__main__":
    main()
