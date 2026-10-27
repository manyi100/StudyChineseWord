"""
批量配图生成脚本（2×2 四宫格 + 自动切分）

【这一版做了什么】
1. 一次 API 请求生成一张 2×2 四宫格，脚本按象限切成 4 张单图。
   原来是每个字一次请求，现在一次请求出 4 张，调用次数降到四分之一。
2. 切出来的单图统一按 1.81:1 处理，输出 526×290 的 WebP。
   和 App 里已有的 263×145 插图同比例，分辨率翻倍，适配高分屏。
3. 每轮默认只生成 20 张（5 次请求），跑完自动停。
   这样方便先看一批质量，也避免一次跑太久、额度失控。
   想一次跑完可以加 --all。
4. 已经有 imageAsset 的字（前 50 个）自动跳过，已有图片文件绝不覆盖。
5. 修掉了旧版成功分支里的 sleep(30000)（那是 8 个多小时）和 900 秒的
   固定间隔，改成请求之间默认间隔 20 秒，失败按 20/40/60 秒退避重试。
6. 旧版把文件写到 scripts/assets/ 下面，App 实际读取的是项目根目录的
   assets/，这一版已经改为直接写根目录。

【用法】
    set GEMINI_API_KEY=你的key
    pip install requests pillow
    python scripts/generate_images_nanobanana.py            # 本轮 20 张
    python scripts/generate_images_nanobanana.py --all      # 跑完全部剩余
    python scripts/generate_images_nanobanana.py --limit 40 # 本轮 40 张
    python scripts/generate_images_nanobanana.py --dry-run  # 只看提示词，不花钱

【断点续跑】
每成功生成一组（4 张）就把进度写回 hanzi_data.json。中断后重新运行会
自动跳过已有配图的字，不会重复花钱，也不会覆盖旧图。

【四宫格的取舍】
一次请求的四张图共享同一张画布，风格更统一，但单张分辨率比单独生成低
（约 512×512 再裁成 1.81:1）。如果某几张质量不满意，把对应条目的
imageAsset 改回 null 再运行即可单独重画。

【费用提示】(2026年3月数据，请以Google官方定价页为准)
- gemini-2.5-flash-image (Nano Banana 基础版): 约 $0.039/张，批量模式 $0.0195/张
- gemini-3-pro-image-preview (Nano Banana Pro): 约 $0.134/张，风格一致性更好
按四宫格算，670 张约需 168 次请求。
"""

import argparse
import base64
import io
import json
import math
import os
import re
import time
from pathlib import Path

import requests
from PIL import Image, ImageStat

# ========== 配置区：根据需要修改 ==========

# 项目根目录（脚本在 scripts/ 下，上一级才是项目根）
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_JSON_PATH = PROJECT_ROOT / "assets" / "data" / "hanzi_data.json"
IMAGES_OUTPUT_DIR = PROJECT_ROOT / "assets" / "images"

# Nano Banana 基础版（便宜）；如果想要更强的风格一致性，
# 改成 "gemini-3-pro-image-preview" (Nano Banana Pro，更贵)
MODEL_NAME = "gemini-2.5-flash-image"

# 可选：一张你最满意的"水彩风格示例图"路径，留空字符串则不使用参考图
REFERENCE_IMAGE_PATH = ""  # 例如: "C:/style_reference.png"

# 四宫格布局：2×2，共 4 张
GRID_COLS = 2
GRID_ROWS = 2
IMAGES_PER_REQUEST = GRID_COLS * GRID_ROWS

# 单张成图尺寸：和现有 263×145 插图同比例（1.81:1），分辨率翻倍
TARGET_WIDTH = 526
TARGET_HEIGHT = 290
TARGET_ASPECT = TARGET_WIDTH / TARGET_HEIGHT

# 切图时从每格四边各收进去一点，避免把中间的分隔线切进画面
CELL_INSET_RATIO = 0.02

# 单格几乎是纯色（空白）时判定这一组失败，自动重试
BLANK_STDDEV_THRESHOLD = 5.0

# 每轮默认生成多少张。20 张 = 5 次请求，方便先看质量再决定要不要继续
MAX_IMAGES_PER_RUN = 20

# 请求间隔（秒）。免费额度通常有每分钟请求数限制，20 秒比较稳
SLEEP_BETWEEN_REQUESTS = 20.0

# 单组最多重试几次
MAX_RETRIES = 3

WEBP_QUALITY = 85

# 统一风格描述，会拼接到每条prompt前面
STYLE_PREFIX = (
    "手绘水彩风格儿童插画，色彩柔和自然，笔触有水彩晕染质感，"
    "背景简洁干净（接近白色或浅色），主体居中，画面温暖可爱，适合小学识字教材。"
)
STYLE_SUFFIX = (
    "重要要求：画面中不能出现任何文字、字母、拼音、数字、水印或标志；"
    "不要儿童面部特写以避免肖像问题；整体风格统一、简洁，不要过于复杂的背景细节。"
)

POSITIONS = ["左上", "右上", "左下", "右下"]

# 兼容旧版：优先环境变量，没设置时用脚本里原有的 key
GEMINI_API_KEY_FALLBACK = "AQ.Ab8RN6LTH1p-5SBugbAnaAvYQNV1v2yh7jSnqEyULEcVZkXHgQ"
# ===========================================


def get_api_key() -> str:
    return os.environ.get("GEMINI_API_KEY", "").strip() or GEMINI_API_KEY_FALLBACK


def build_visual_brief(entry: dict) -> str:
    """根据汉字本身的例句生成具体的画面描述，比单纯画一个字更有叙事感。"""
    char = entry["char"]
    sentence = entry.get("sentence")
    words = entry.get("words", [])

    if sentence and sentence.get("text"):
        return (
            f"请画出这句话所描绘的场景：「{sentence['text']}」"
            f"（这是讲解汉字「{char}」的例句，画面要能体现这个场景）。"
        )
    if words:
        word_list = "、".join(w["text"] for w in words)
        return f"请画出能体现「{char}」字含义的画面，可参考相关词语：{word_list}。"
    return f"请画出能体现汉字「{char}」含义的简单场景。"


def build_grid_prompt(entries: list[dict]) -> str:
    """把 1~4 个字拼成一条四宫格提示词。"""
    layout = (
        "请把整张画面严格分成 2×2 四个大小完全相同的格子，"
        "格与格之间留一条细窄的白色间隔，四格合起来铺满整张图，不要额外的外边框。"
        "每一格都是一幅独立完整的横幅插画，主体居中、上下留出安全边距，"
        "不要把人物或物体画出所属格子，也不要把四格的内容混在一起。"
    )
    if len(entries) < IMAGES_PER_REQUEST:
        layout += f"只画前{len(entries)}格，其余格子保持纯白空白。"

    cells = [
        f"{position}格：{build_visual_brief(entry)}"
        for position, entry in zip(POSITIONS, entries)
    ]
    return f"{STYLE_PREFIX}{layout}{''.join(cells)}{STYLE_SUFFIX}"


def call_gemini_image_api(prompt: str, reference_image_bytes: bytes | None) -> bytes:
    """调用 Gemini generateContent 接口，返回生成图片的原始字节。"""
    api_key = get_api_key()
    if not api_key:
        raise RuntimeError("请先设置环境变量 GEMINI_API_KEY")

    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{MODEL_NAME}:generateContent"
    )
    headers = {
        "x-goog-api-key": api_key,
        "Content-Type": "application/json",
    }

    parts = []
    if reference_image_bytes:
        parts.append(
            {
                "inline_data": {
                    "mime_type": "image/png",
                    "data": base64.b64encode(reference_image_bytes).decode("utf-8"),
                }
            }
        )
        parts.append({"text": f"参考上面这张图的画风。{prompt}"})
    else:
        parts.append({"text": prompt})

    body = {"contents": [{"parts": parts}]}

    resp = requests.post(url, headers=headers, json=body, timeout=120)
    resp.raise_for_status()
    data = resp.json()

    candidates = data.get("candidates", [])
    if not candidates:
        raise RuntimeError(f"API没有返回候选结果: {data}")

    for part in candidates[0]["content"]["parts"]:
        inline_data = part.get("inline_data") or part.get("inlineData")
        if inline_data and inline_data.get("data"):
            return base64.b64decode(inline_data["data"])

    raise RuntimeError(f"返回结果中没有找到图片数据: {data}")


def _crop_to_aspect(img: Image.Image, aspect: float) -> Image.Image:
    """居中裁切到目标宽高比，不拉伸变形。"""
    w, h = img.size
    if w / h > aspect:
        new_w = int(round(h * aspect))
        left = (w - new_w) // 2
        return img.crop((left, 0, left + new_w, h))
    new_h = int(round(w / aspect))
    top = (h - new_h) // 2
    return img.crop((0, top, w, top + new_h))


def _safe_pinyin(entry: dict) -> str:
    """拼音带声调，放进文件名前只保留 ascii 字母数字。"""
    plain = entry.get("pinyin", "").encode("ascii", "ignore").decode().lower()
    plain = re.sub(r"[^a-z0-9]", "", plain)
    return plain or "x"


def output_path_for(entry: dict) -> Path:
    return IMAGES_OUTPUT_DIR / f"{entry['id']}_{_safe_pinyin(entry)}.webp"


def _asset_path(path: Path) -> str:
    return path.relative_to(PROJECT_ROOT).as_posix()


def adopt_existing_files(data: list[dict]) -> int:
    """文件已经在、但 JSON 里没记上的情况，补登记，避免重复生成。"""
    adopted = 0
    for entry in data:
        if entry.get("imageAsset"):
            continue
        path = output_path_for(entry)
        if path.exists():
            entry["imageAsset"] = _asset_path(path)
            adopted += 1
    return adopted


def split_grid_and_save(raw_bytes: bytes, entries: list[dict]) -> int:
    """把四宫格按 2×2 切开，逐张裁到 1.81:1、缩放到 526×290 并保存为 WebP。"""
    img = Image.open(io.BytesIO(raw_bytes)).convert("RGB")
    width, height = img.size
    cell_width = width // GRID_COLS
    cell_height = height // GRID_ROWS
    inset_x = int(cell_width * CELL_INSET_RATIO)
    inset_y = int(cell_height * CELL_INSET_RATIO)

    saved = 0
    for index, entry in enumerate(entries):
        row, col = divmod(index, GRID_COLS)
        left = col * cell_width + inset_x
        top = row * cell_height + inset_y
        right = (col + 1) * cell_width - inset_x
        bottom = (row + 1) * cell_height - inset_y

        cell = img.crop((left, top, right, bottom))
        cell = _crop_to_aspect(cell, TARGET_ASPECT)
        cell = cell.resize((TARGET_WIDTH, TARGET_HEIGHT), Image.LANCZOS)

        # 模型偶尔只画了两三格，剩下的格子是空白，这种情况整组重试
        if ImageStat.Stat(cell.convert("L")).stddev[0] < BLANK_STDDEV_THRESHOLD:
            raise RuntimeError(
                f"第{index + 1}格几乎是空白，可能模型没画满四格，整组重试"
            )

        path = output_path_for(entry)
        if path.exists():
            # 绝不覆盖已经存在的图片，只把路径登记回 JSON
            entry["imageAsset"] = _asset_path(path)
            saved += 1
            continue

        cell.save(path, "WEBP", quality=WEBP_QUALITY, method=6)
        entry["imageAsset"] = _asset_path(path)
        saved += 1

    return saved


def save_progress(data: list[dict]) -> None:
    with open(DATA_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="批量生成汉字配图：一次请求画 2×2 四宫格，再切成四张单图"
    )
    parser.add_argument(
        "--limit",
        type=int,
        default=MAX_IMAGES_PER_RUN,
        help=f"本轮最多生成多少张，默认 {MAX_IMAGES_PER_RUN}",
    )
    parser.add_argument(
        "--all",
        action="store_true",
        help="跑完全部剩余汉字，忽略 --limit",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="只打印第一组的提示词，不调用 API、不写文件",
    )
    return parser.parse_args()


def main() -> None:
    args = parse_args()

    with open(DATA_JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    IMAGES_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    adopted = adopt_existing_files(data)
    if adopted:
        save_progress(data)
        print(f"发现 {adopted} 张已存在的图片，已补登记到 JSON")

    todo = [entry for entry in data if not entry.get("imageAsset")]
    print(
        f"共{len(data)}个字，已有配图{len(data) - len(todo)}个，"
        f"剩余{len(todo)}个待生成"
    )

    if not todo:
        print("全部字都已有配图，无需生成")
        return

    if args.dry_run:
        print("---- 第一组提示词 ----")
        print(build_grid_prompt(todo[:IMAGES_PER_REQUEST]))
        return

    reference_bytes = None
    if REFERENCE_IMAGE_PATH:
        with open(REFERENCE_IMAGE_PATH, "rb") as f:
            reference_bytes = f.read()

    limit = 0 if args.all else max(1, args.limit)
    planned = len(todo) if limit == 0 else min(limit, len(todo))
    requests_needed = math.ceil(planned / IMAGES_PER_REQUEST)
    minutes = requests_needed * (SLEEP_BETWEEN_REQUESTS + 15) / 60
    print(
        f"本轮计划生成 {planned} 张，约 {requests_needed} 次请求，"
        f"预计 {minutes:.0f} 分钟（每张约 {minutes / planned * 60:.1f} 秒）"
    )

    generated = 0
    for start in range(0, len(todo), IMAGES_PER_REQUEST):
        if limit and generated >= limit:
            break

        group = todo[start : start + IMAGES_PER_REQUEST]
        chars = "、".join(entry["char"] for entry in group)
        print(
            f"[{start + 1}-{start + len(group)}/{len(todo)}] "
            f"生成一组 {len(group)} 张：{chars}"
        )
        prompt = build_grid_prompt(group)

        success = False
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                raw_bytes = call_gemini_image_api(prompt, reference_bytes)
                saved = split_grid_and_save(raw_bytes, group)
                save_progress(data)
                generated += saved
                success = True
                print(f"  已切分保存 {saved} 张，本轮累计 {generated} 张")
                break
            except Exception as exc:  # noqa: BLE001 - 生成流程要尽量跑完
                print(f"  第{attempt}次尝试失败: {exc}")
                if attempt < MAX_RETRIES:
                    wait = SLEEP_BETWEEN_REQUESTS * attempt
                    print(f"  {wait:.0f} 秒后重试")
                    time.sleep(wait)

        if not success:
            print("  这一组跳过，下次运行会重新尝试")

        if limit and generated >= limit:
            break

        time.sleep(SLEEP_BETWEEN_REQUESTS)

    save_progress(data)
    print(f"本轮结束，共生成 {generated} 张。重新运行脚本可继续补齐。")


if __name__ == "__main__":
    main()
