"""
批量配图生成脚本 —— 使用 Google Gemini API (Nano Banana / Nano Banana Pro)

【使用前必读】
1. 这个脚本需要联网调用 Google 的 Gemini API，不能在Claude的沙盒环境里跑通，
   需要你在自己的电脑上运行（已确认本沙盒的网络白名单不包含
   generativelanguage.googleapis.com，这也是为什么由你本地执行）。
2. 需要先去 https://aistudio.google.com/apikey 申请一个 Gemini API Key，
   然后设置环境变量：
       export GEMINI_API_KEY="你的key"   (Mac/Linux)
       setx GEMINI_API_KEY "你的key"      (Windows，设置后重开终端)
3. 安装依赖：
       pip install requests pillow

【风格一致性怎么保证】
脚本支持传入一张"参考风格图"(REFERENCE_IMAGE_PATH)。建议你先手动用Gemini
生成或上传一张你最满意的"水彩风格示例图"，把路径填进下面的配置区，
脚本会把这张参考图和每次的文字描述一起发给模型，要求"保持同样的水彩风格"，
这样720张图风格才不会一张张跑偏。

如果暂时没有参考图，把 REFERENCE_IMAGE_PATH 留空也可以运行，
只是风格一致性会差一些，跑完后建议人工挑出明显风格不对的重新生成。

【断点续跑】
脚本是可断点续跑的：已经生成过图片的字会自动跳过(根据 hanzi_data.json
里 imageAsset 是否已经填好判断)，所以网络中断或者跑到一半都可以重新执行。

【费用提示】(2026年3月数据，请以Google官方定价页为准)
- gemini-2.5-flash-image (Nano Banana基础版): 约 $0.039/张，批量模式 $0.0195/张
- gemini-3-pro-image-preview (Nano Banana Pro): 约 $0.134/张，风格一致性更好
720张全部生成，基础版约 $14~28，Pro版约 $96，请根据预算选择 MODEL_NAME。
"""

import os
import json
import time
import base64
import subprocess
from pathlib import Path

import requests
from PIL import Image

# ========== 配置区：根据需要修改 ==========
PROJECT_ROOT = Path(__file__).resolve().parent
DATA_JSON_PATH = PROJECT_ROOT / "assets" / "data" / "hanzi_data.json"
IMAGES_OUTPUT_DIR = PROJECT_ROOT / "assets" / "images"

# Nano Banana 基础版（便宜）；如果想要更强的风格一致性，
# 改成 "gemini-3-pro-image-preview" (Nano Banana Pro，更贵)
MODEL_NAME = "gemini-2.5-flash-image"

# 可选：一张你最满意的"水彩风格示例图"路径，留空字符串则不使用参考图
REFERENCE_IMAGE_PATH = ""  # 例如: "/Users/you/style_reference.png"

# 统一风格描述，会拼接到每条prompt前面
STYLE_PREFIX = (
    "手绘水彩风格儿童插画，色彩柔和自然，笔触有水彩晕染质感，"
    "背景简洁干净（接近白色或浅色），主体居中，画面温暖可爱，适合小学识字教材。"
)
STYLE_SUFFIX = (
    "重要要求：画面中不能出现任何文字、字母、拼音、数字、水印或标志；"
    "不要儿童面部特写以避免肖像问题；整体风格统一、简洁，不要过于复杂的背景细节。"
)

# 请求间隔秒数（避免触发速率限制），以及失败重试次数
SLEEP_BETWEEN_CALLS = 900.0
MAX_RETRIES = 3

# 导出图片的边长（正方形），与之前验证过的压缩流程衔接
TARGET_SIZE = 400
WEBP_QUALITY = 80
# ===========================================


def build_prompt(entry: dict) -> str:
    """根据汉字本身的例句生成具体的画面描述，比单纯用汉字含义更有叙事感、更贴近教材插画风格。"""
    char = entry["char"]
    sentence = entry.get("sentence")
    words = entry.get("words", [])

    if sentence and sentence.get("text"):
        visual_brief = f"请画出这句话所描绘的场景：「{sentence['text']}」（这是讲解汉字「{char}」的例句，画面要能体现这个场景）。"
    elif words:
        word_list = "、".join(w["text"] for w in words)
        visual_brief = f"请画出能体现「{char}」字含义的画面，可参考相关词语：{word_list}。"
    else:
        visual_brief = f"请画出能体现汉字「{char}」含义的简单场景。"

    return f"{STYLE_PREFIX}{visual_brief}{STYLE_SUFFIX}"


def call_gemini_image_api(prompt: str, reference_image_bytes: bytes | None) -> bytes:
    """调用 Gemini generateContent 接口，返回生成图片的原始字节(PNG)。"""
#    api_key = os.environ.get("GEMINI_API_KEY")
    api_key = "AQ.Ab8RN6LTH1p-5SBugbAnaAvYQNV1v2yh7jSnqEyULEcVZkXHgQ"
    if not api_key:
        raise RuntimeError("请先设置环境变量 GEMINI_API_KEY")

    url = f"https://generativelanguage.googleapis.com/v1beta/models/{MODEL_NAME}:generateContent"
    headers = {
        "x-goog-api-key": api_key,
        "Content-Type": "application/json",
    }

    parts = []
    if reference_image_bytes:
        parts.append({
            "inline_data": {
                "mime_type": "image/png",
                "data": base64.b64encode(reference_image_bytes).decode("utf-8"),
            }
        })
        parts.append({"text": f"参考上面这张图的画风。{prompt}"})
    else:
        parts.append({"text": prompt})

    body = {"contents": [{"parts": parts}]}

    resp = requests.post(url, headers=headers, json=body, timeout=60)
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


def process_and_save(raw_png_bytes: bytes, output_webp_path: Path) -> None:
    """把原始PNG裁切/缩放成正方形，再转成WebP压缩保存。"""
    tmp_png_path = output_webp_path.with_suffix(".tmp.png")
    with open(tmp_png_path, "wb") as f:
        f.write(raw_png_bytes)

    img = Image.open(tmp_png_path).convert("RGBA")
    # 居中裁切成正方形，再统一缩放到目标尺寸
    w, h = img.size
    side = min(w, h)
    left = (w - side) // 2
    top = (h - side) // 2
    img = img.crop((left, top, left + side, top + side)).resize(
        (TARGET_SIZE, TARGET_SIZE), Image.LANCZOS
    )
    img.save(tmp_png_path, "PNG")

    subprocess.run(
        ["cwebp", "-q", str(WEBP_QUALITY), str(tmp_png_path), "-o", str(output_webp_path)],
        check=True,
        capture_output=True,
    )
    tmp_png_path.unlink(missing_ok=True)


def main():
    with open(DATA_JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    IMAGES_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    reference_bytes = None
    if REFERENCE_IMAGE_PATH:
        with open(REFERENCE_IMAGE_PATH, "rb") as f:
            reference_bytes = f.read()

    todo = [e for e in data if not e.get("imageAsset")]
    print(f"共{len(data)}个字，其中{len(todo)}个还没有配图，开始生成...")

    for i, entry in enumerate(todo, 1):
        char_id = entry["id"]
        char = entry["char"]
        pinyin_plain = entry["pinyin"].encode("ascii", "ignore").decode() or "x"
        filename = f"{char_id}_{pinyin_plain}.webp"
        output_path = IMAGES_OUTPUT_DIR / filename

        if output_path.exists():
            entry["imageAsset"] = f"assets/images/{filename}"
            continue

        prompt = build_prompt(entry)
        print(f"[{i}/{len(todo)}] 生成「{char}」...")

        for attempt in range(1, MAX_RETRIES + 1):
            try:
                raw_bytes = call_gemini_image_api(prompt, reference_bytes)
                process_and_save(raw_bytes, output_path)
                entry["imageAsset"] = f"assets/images/{filename}"
                sleep(30000)
                break
            except Exception as e:
                print(f"  第{attempt}次尝试失败: {e}")
                if attempt == MAX_RETRIES:
                    print(f"  「{char}」生成失败，跳过，可稍后重新运行脚本补齐")
                else:
                    time.sleep(SLEEP_BETWEEN_CALLS * attempt)

        # 每生成完一个字就立即保存一次进度，避免中途中断丢失已生成的结果
        with open(DATA_JSON_PATH, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)

        time.sleep(SLEEP_BETWEEN_CALLS)

    print("全部完成！")


if __name__ == "__main__":
    main()
