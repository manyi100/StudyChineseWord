"""
批量配图生成脚本（可切换 Gemini / Cloudflare FLUX / 魔搭 Qwen-Image）

【这一版做了什么】
1. 新增 --provider，三个图像服务可切换，其它逻辑（断点续跑、限额、退避重试）不变：
   - cloudflare : Cloudflare Workers AI 上的 FLUX.1 [schnell]，每天约 173 张免费，
                  默认选项。英文提示词，一次出一张单图。
   - modelscope : 魔搭 ModelScope 的 Qwen-Image，中文提示词原生支持，
                  约 250 张/天免费（需实名阿里云账号，限非商用）。一次出一张单图。
   - gemini     : Google Gemini 2.5 Flash Image（Nano Banana），付费，
                  但擅长把 2×2 四宫格画准，一次请求出 4 张。
2. 因为 FLUX / Qwen-Image 画不好严格的 2×2 四宫格，这两个服务改成
   一次请求画一个字（单图），再居中裁到 1.81:1 输出 526×290 的 WebP。
3. 文字默认不印在图上：仓库现有 720 张图都是纯插画，字/拼音/例句由 Flutter
   卡片渲染，所以默认 --overlay none。需要旧教材页那种「文字印在图上」的版式时，
   加 --overlay textbook，脚本用 PIL 合成「左上角当前字 + 左下角带圈序号 +
   底部例句」——中文和圈号交给模型画必然出错，合成才能保证 100% 正确。
4. 固定的风格描述前缀/后缀（扁平卡通、清晰描边、纯白背景），整批风格统一。
5. 已经有 imageAsset 的字自动跳过，已有图片文件绝不覆盖。
6. 断点续跑：每成功一张就把进度写回 hanzi_data.json，中断后重跑不会重复花钱。
7. 429 优先按接口返回的 retryDelay 等待；每日额度用完直接停止本轮。

【用法】
    pip install requests pillow

    # Cloudflare（推荐，免费）
    export CLOUDFLARE_ACCOUNT_ID=你的account_id
    export CLOUDFLARE_API_TOKEN=你的api_token        # 权限勾 Workers AI:Read
    python3 scripts/generate_images_nanobanana.py --provider cloudflare --limit 20

    # 魔搭 Qwen-Image（中文提示词，免费）
    export MODELSCOPE_API_TOKEN=你的token            # modelscope.cn 个人中心 → 访问令牌
    python3 scripts/generate_images_nanobanana.py --provider modelscope --limit 20

    # Gemini（付费）
    export GEMINI_API_KEY=你的key
    python3 scripts/generate_images_nanobanana.py --provider gemini --limit 20

    python3 scripts/generate_images_nanobanana.py --provider cloudflare --all
    python3 scripts/generate_images_nanobanana.py --provider cloudflare --dry-run

    # 要旧教材页那种「字/圈号/例句印在图上」的版式
    python3 scripts/generate_images_nanobanana.py --overlay textbook

    # 先把例句翻成英文画面描述（写回 promptEn），再生成
    python3 scripts/generate_images_nanobanana.py --translate-prompts

    # 换风格重画已有的某一段（会删掉这些 id 的 webp 再重新生成）
    python3 scripts/generate_images_nanobanana.py --reset 51-74 --limit 24

不写 --provider 时读环境变量 IMAGE_PROVIDER，再没有就用 cloudflare。

【文字合成用哪款字体】
项目自带的 LXGWWenKai-Subset.ttf 只是 720 个单字的子集，画不了例句，脚本会按
IMAGE_OVERLAY_FONT 环境变量 → Noto Sans SC → 系统黑体（macOS 冬青黑体 W6 /
Windows 微软雅黑 Bold / Linux Noto CJK）的顺序找一个能覆盖中文的字体。

【英文提示词】
FLUX 的文本编码器基本听不懂中文，而且 prompt 里只要出现中文，它就容易把中文
当成画面内容画出来（于是和图上的合成文字重复）。所以 cloudflare 优先用英文描述：
先读 hanzi_data.json 里的 "promptEn"（或 "prompt_en"），没有就退回中英混写。
跑一次 --translate-prompts 可以让 Cloudflare 的免费文本模型把整本例句翻译成
纯英文画面描述写回 promptEn，之后 prompt 里就没有任何中文字符了。

【四宫格的取舍】
Gemini 一次请求的四张图共享同一张画布，风格更统一，但单张分辨率约 512×512。
FLUX / Qwen-Image 单图分辨率更高（1024×1024 或 1664×928），细节更好，但没有四宫格省事。

【额度参考】(2026年10月数据，以官方定价页为准)
- Cloudflare flux-1-schnell: 10,000 neurons/天免费 ≈ 173 张 1024×1024（4 步）；
  超额 $0.011/1000 neurons ≈ $0.0006/张。
- 魔搭 Qwen-Image: 约 250 张/天，限非商用。
- Gemini 2.5 Flash Image: 约 $0.039/张，批量模式 $0.0195/张。
"""

# 兼容 Python 3.9：让 `float | None` 这类 3.10+ 的注解语法延迟求值，
# 否则在 3.9 上导入时就会抛 TypeError。
from __future__ import annotations

import argparse
import base64
import io
import json
import math
import os
import random
import re
import time
from pathlib import Path

import requests
from PIL import Image, ImageDraw, ImageFont, ImageStat

# ========== 配置区：根据需要修改 ==========

# 项目根目录（脚本在 scripts/ 下，上一级才是项目根）
PROJECT_ROOT = Path(__file__).resolve().parent.parent
DATA_JSON_PATH = PROJECT_ROOT / "assets" / "data" / "hanzi_data.json"
IMAGES_OUTPUT_DIR = PROJECT_ROOT / "assets" / "images"

PROVIDER_CLOUDFLARE = "cloudflare"
PROVIDER_MODELSCOPE = "modelscope"
PROVIDER_GEMINI = "gemini"
SUPPORTED_PROVIDERS = (PROVIDER_CLOUDFLARE, PROVIDER_MODELSCOPE, PROVIDER_GEMINI)

# 默认服务：环境变量 IMAGE_PROVIDER 优先，其次 cloudflare（免费）
DEFAULT_PROVIDER = os.environ.get("IMAGE_PROVIDER", PROVIDER_CLOUDFLARE).strip().lower()
if DEFAULT_PROVIDER not in SUPPORTED_PROVIDERS:
    DEFAULT_PROVIDER = PROVIDER_CLOUDFLARE

# --- Gemini ---
GEMINI_MODEL_NAME = "gemini-2.5-flash-image"
# 兼容旧版：优先环境变量，没设置时用脚本里原有的 key
GEMINI_API_KEY_FALLBACK = "AQ.Ab8RN6LTH1p-5SBugbAnaAvYQNV1v2yh7jSnqEyULEcVZkXHgQ"

# --- Cloudflare Workers AI ---
CLOUDFLARE_MODEL_NAME = "@cf/black-forest-labs/flux-1-schnell"
CLOUDFLARE_STEPS = 4                # schnell 默认 4 步；8 步更细但 neurons 翻倍
CLOUDFLARE_PROMPT_LIMIT = 2048      # 接口对 prompt 长度的硬限制
CLOUDFLARE_FREE_IMAGES_PER_DAY = 173  # 10,000 neurons/天 ÷ 57.6 neurons/张

# --- 魔搭 ModelScope ---
MODELSCOPE_MODEL_NAME = "Qwen/Qwen-Image"
# Qwen-Image 只认这几个预设尺寸：1328x1328、1664x928、928x1664、
# 1472x1140、1140x1472、1584x1056、1056x1584。16:9 最接近 1.81:1。
MODELSCOPE_SIZE = "1664x928"
MODELSCOPE_PROMPT_LIMIT = 800       # 官方文档：提示词不超过 800 字符
MODELSCOPE_NEGATIVE_PROMPT = "文字、字母、拼音、数字、水印、标志、低质量、模糊、复杂背景"
MODELSCOPE_POLL_INTERVAL = 5.0      # 轮询任务状态的间隔
MODELSCOPE_POLL_TIMEOUT = 600.0     # 单个任务最多等多久

# 注意：Cloudflare 的 flux-1-schnell 只接受 prompt 和 steps 两个字段，
# 传 seed 之类其它参数会直接报 "Additional or unevaluated properties"。

# 每个服务用哪种语言的提示词。FLUX 的中文理解很弱，所以用英文
PROVIDER_PROMPT_LANG = {
    PROVIDER_GEMINI: "zh",
    PROVIDER_MODELSCOPE: "zh",
    PROVIDER_CLOUDFLARE: "en",
}

# 一次请求生成几张：只有 Gemini 能稳定画出 2×2 四宫格
PROVIDER_IMAGES_PER_REQUEST = {
    PROVIDER_GEMINI: 2 * 2,
    PROVIDER_MODELSCOPE: 1,
    PROVIDER_CLOUDFLARE: 1,
}

# 请求之间的默认间隔（秒）。免费额度对图像模型通常限制得比较紧
PROVIDER_DEFAULT_INTERVAL = {
    PROVIDER_GEMINI: 60.0,
    PROVIDER_CLOUDFLARE: 10.0,
    PROVIDER_MODELSCOPE: 10.0,
}

# 可选：一张你最满意的"水彩风格示例图"路径，留空则不使用（仅 gemini 支持）
REFERENCE_IMAGE_PATH = ""  # 例如: "C:/style_reference.png"

# 四宫格布局（仅 gemini 使用）：2×2，共 4 张
GRID_COLS = 2
GRID_ROWS = 2
IMAGES_PER_REQUEST = GRID_COLS * GRID_ROWS

# 单张成图尺寸：和现有 263×145 插图同比例（1.81:1），分辨率翻倍
TARGET_WIDTH = 526
TARGET_HEIGHT = 290
TARGET_ASPECT = TARGET_WIDTH / TARGET_HEIGHT

# ---------- 版式合成：把字/圈号/例句印到图上，对齐前 50 张教材原图 ----------
# 前 50 张是教材页裁图：左上角是当前字，左下角是带圈序号，底部是例句。
# 这些文字不要让模型去画（中文和圈号基本写不对），统一用 PIL 合成。
OVERLAY_TEXTBOOK = "textbook"
OVERLAY_NONE = "none"
OVERLAY_MODES = (OVERLAY_TEXTBOOK, OVERLAY_NONE)
# 仓库现在的图都是纯插画，字/拼音/例句由 Flutter 卡片渲染，所以默认不叠字。
# 想要旧教材页那种「印在图上」的版式，加 --overlay textbook。
DEFAULT_OVERLAY = OVERLAY_NONE

# 叠字用的完整中文字体。项目自带的 LXGWWenKai-Subset.ttf 只包含 720 个单字，
# 不含例句里的常用字，直接用来画句子会出现豆腐块，所以这里优先用系统字体。
# 想指定自己的字体：export IMAGE_OVERLAY_FONT=/path/to/font.ttf
FONT_CANDIDATES = [
    (os.environ.get("IMAGE_OVERLAY_FONT", ""), 0),
    (str(PROJECT_ROOT / "assets" / "fonts" / "NotoSansSC-Medium.otf"), 0),
    # macOS
    ("/System/Library/Fonts/Hiragino Sans GB.ttc", 2),   # 冬青黑体 W6
    ("/System/Library/Fonts/STHeiti Medium.ttc", 1),     # 华文黑体 SC Medium
    # Windows
    ("C:/Windows/Fonts/msyhbd.ttc", 0),                  # 微软雅黑 Bold
    ("C:/Windows/Fonts/simhei.ttf", 0),                  # 黑体
    # Linux
    ("/usr/share/fonts/opentype/noto/NotoSansCJK-Bold.ttc", 0),
    ("/usr/share/fonts/truetype/wqy/wqy-zenhei.ttc", 0),
    # 实在没有就用项目自带的子集体：单字没问题，例句可能缺字
    (str(PROJECT_ROOT / "assets" / "fonts" / "LXGWWenKai-Subset.ttf"), 0),
]
FONT_PROBE_TEXT = "的了是不有，。！？0123456789"

PAGE_CHAR_SIZE = 92              # 左上角汉字字号
PAGE_CHAR_TOP_LEFT = (22, 14)    # 左上角汉字的位置（墨迹左上角）
PAGE_SENTENCE_CENTER_Y = 257     # 底部例句的垂直中心
PAGE_SENTENCE_START_SIZE = 48    # 例句初始字号，太长会自动缩小
PAGE_SENTENCE_MIN_SIZE = 24
PAGE_SENTENCE_MAX_WIDTH = 440
PAGE_SENTENCE_LEFT = 67          # 例句不能压到左边圈号，长句从这里开始
PAGE_NUMBER_CENTER = (34, 250)   # 左下角圈号圆心
PAGE_NUMBER_RADIUS = 21
PAGE_NUMBER_LINE_WIDTH = 4
PAGE_NUMBER_FONT_SIZE = 30
PAGE_TEXT_STROKE = 4             # 文字白色描边宽度，保证压在插画上也看得清
PAGE_FADE_TOP = 196              # 从这里开始向下渐隐到白色，给底部文字留干净底色

# 切图时从每格四边各收进去一点，避免把中间的分隔线切进画面
CELL_INSET_RATIO = 0.02

# 几乎是纯色（空白）时判定这一组失败，自动重试
BLANK_STDDEV_THRESHOLD = 5.0

# 每轮默认生成多少张，方便先看质量再决定要不要继续
MAX_IMAGES_PER_RUN = 20

# 单组最多重试几次。触发 429 时会优先按接口返回的 retryDelay 等待
MAX_RETRIES = 5

WEBP_QUALITY = 85

# 统一风格描述（中文）——对齐前 50 张教材原图：扁平卡通、清晰描边、纯白背景
STYLE_PREFIX = (
    "简洁的扁平化卡通插画，可爱温和，柔和马卡龙配色，干净清晰的深色描边，"
    "纯白背景，单一完整主体居中偏上，四周留白充足，画面简洁温馨。"
    "只画场景本身这一张独立插画：不是书页、不是卡片、不是海报，不要任何边框。"
)
STYLE_SUFFIX = (
    "重要要求：画面中不要出现任何文字、汉字、字母、拼音、数字、水印或标志；"
    "不要画书页、卡片、招牌、田字格或边框；不要儿童面部特写；"
    "背景干净简洁，不要复杂的背景细节。"
)

# 统一风格描述（英文，给 FLUX 用）
STYLE_PREFIX_EN = (
    "Simple flat vector cartoon illustration, cute and friendly, "
    "soft macaron pastel colors, clean bold dark outlines, pure white background, "
    "one single complete subject centered in the upper part of the frame, "
    "generous empty white space, warm and simple. "
    "Draw only the scene itself as a standalone picture: "
    "it is not a page, not a card, not a poster, and has no frame or border. "
)
STYLE_SUFFIX_EN = (
    " Critical rules: render absolutely no text, no Chinese characters, no letters, "
    "no pinyin, no numbers, no watermarks and no logos anywhere; "
    "do not draw any book page, card, signboard, grid or frame; "
    "no close-up faces of children; keep the background clean and uncluttered."
)

POSITIONS = ["左上", "右上", "左下", "右下"]
# ===========================================


# ========== 凭证 ==========


def get_api_key() -> str:
    return os.environ.get("GEMINI_API_KEY", "").strip() or GEMINI_API_KEY_FALLBACK


def get_cloudflare_credentials() -> tuple[str, str]:
    account_id = os.environ.get("CLOUDFLARE_ACCOUNT_ID", "").strip()
    token = os.environ.get("CLOUDFLARE_API_TOKEN", "").strip()
    if not account_id or not token:
        raise RuntimeError(
            "Cloudflare 需要设置环境变量 CLOUDFLARE_ACCOUNT_ID 和 CLOUDFLARE_API_TOKEN"
        )
    return account_id, token


def get_modelscope_token() -> str:
    token = (
        os.environ.get("MODELSCOPE_API_TOKEN", "").strip()
        or os.environ.get("MODELSCOPE_API_KEY", "").strip()
    )
    if not token:
        raise RuntimeError("魔搭需要设置环境变量 MODELSCOPE_API_TOKEN")
    return token


def check_provider_credentials(provider: str) -> None:
    """开跑前先确认凭证，别等进了重试循环才报错。"""
    try:
        if provider == PROVIDER_CLOUDFLARE:
            get_cloudflare_credentials()
        elif provider == PROVIDER_MODELSCOPE:
            get_modelscope_token()
        elif provider == PROVIDER_GEMINI:
            if not get_api_key():
                raise RuntimeError("请先设置环境变量 GEMINI_API_KEY")
    except RuntimeError as exc:
        raise SystemExit(str(exc)) from exc


# ========== 错误处理 ==========


class ImageApiError(RuntimeError):
    """带上接口返回的重试建议，429 时能按服务端要求等待。"""

    def __init__(
        self,
        status_code: int,
        message: str,
        retry_delay: float | None = None,
        daily_quota: bool = False,
        provider: str = "",
    ) -> None:
        super().__init__(f"HTTP {status_code}: {message}" if status_code else message)
        self.status_code = status_code
        self.message = message
        self.retry_delay = retry_delay
        self.daily_quota = daily_quota
        self.provider = provider


DAILY_QUOTA_HINTS = (
    "per day",
    "perday",
    "daily",
    "free allocation",
    "neurons",
    "每天",
    "今日",
    "当日",
)


def _looks_like_daily_quota(message: str) -> bool:
    lower = message.lower()
    return any(hint in lower for hint in DAILY_QUOTA_HINTS)


def parse_api_error(resp: requests.Response, provider: str) -> ImageApiError:
    """从错误响应里提取 retryDelay 和是否属于每日额度耗尽。"""
    try:
        payload = resp.json()
    except ValueError:
        payload = {}

    message = ""
    retry_delay = None
    daily_quota = False

    if not isinstance(payload, dict):
        payload = {}

    if provider == PROVIDER_GEMINI:
        error = payload.get("error", {}) or {}
        message = error.get("message") or ""
        for detail in error.get("details", []) or []:
            detail_type = str(detail.get("@type", ""))
            if detail_type.endswith("RetryInfo"):
                match = re.match(r"([\d.]+)s", str(detail.get("retryDelay", "")))
                if match:
                    retry_delay = float(match.group(1))
            if detail_type.endswith("QuotaFailure"):
                for violation in detail.get("violations", []) or []:
                    quota_id = str(violation.get("quotaId", "")).lower()
                    quota_metric = str(violation.get("quotaMetric", "")).lower()
                    if "perday" in quota_id or "per_day" in quota_id or "perday" in quota_metric:
                        daily_quota = True
    elif provider == PROVIDER_CLOUDFLARE:
        errors = payload.get("errors") or []
        if errors and isinstance(errors[0], dict):
            message = str(errors[0].get("message") or "")
        if not message:
            message = str(payload.get("error") or "")
    else:  # modelscope
        message = str(
            payload.get("message") or payload.get("error") or payload.get("detail") or ""
        )
        if not message:
            # 魔搭的错误有时长这样：{"errors": {"message": "..."}}
            errors = payload.get("errors")
            if isinstance(errors, dict):
                message = str(errors.get("message") or "")
            elif isinstance(errors, list) and errors and isinstance(errors[0], dict):
                message = str(errors[0].get("message") or "")

    if not message:
        message = (resp.text or "")[:500] or "未知错误"

    if not daily_quota and _looks_like_daily_quota(message):
        daily_quota = True

    return ImageApiError(
        resp.status_code, message, retry_delay, daily_quota, provider
    )


# ========== 提示词 ==========


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


def build_english_brief(entry: dict) -> str:
    """英文画面描述。优先用数据里手写/翻译好的 promptEn，没有就退回中英混写。"""
    custom = (entry.get("promptEn") or entry.get("prompt_en") or "").strip()
    if custom:
        return custom if custom.endswith((" ", ".", "。")) else custom + ". "

    char = entry["char"]
    sentence = entry.get("sentence")
    words = entry.get("words", [])

    if sentence and sentence.get("text"):
        return (
            f"A single clear scene showing this situation. "
            f"The Chinese note below is for understanding only - "
            f"never write or draw these glyphs: \"{sentence['text']}\" "
            f"(the scene should convey the meaning of the Chinese character {char}). "
        )
    if words:
        word_list = ", ".join(w["text"] for w in words)
        return (
            f"A simple scene about the Chinese character {char}, "
            f"inspired by these words: {word_list}. "
        )
    return f"A simple scene conveying the meaning of the Chinese character {char}. "


def build_grid_prompt(entries: list[dict]) -> str:
    """把 1~4 个字拼成一条四宫格提示词（仅 gemini）。"""
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


def build_single_prompt(entry: dict, prompt_lang: str) -> str:
    """单图提示词（cloudflare / modelscope）。"""
    if prompt_lang == "en":
        return f"{STYLE_PREFIX_EN}{build_english_brief(entry)}{STYLE_SUFFIX_EN}"
    return f"{STYLE_PREFIX}{build_visual_brief(entry)}{STYLE_SUFFIX}"


def build_prompt_for_batch(provider: str, entries: list[dict]) -> str:
    if provider == PROVIDER_GEMINI:
        return build_grid_prompt(entries)
    return build_single_prompt(entries[0], PROVIDER_PROMPT_LANG[provider])


# ========== 各服务调用 ==========


def _request_gemini(prompt: str, reference_image_bytes: bytes | None = None) -> bytes:
    """调用 Gemini generateContent 接口，返回生成图片的原始字节。"""
    api_key = get_api_key()
    if not api_key:
        raise RuntimeError("请先设置环境变量 GEMINI_API_KEY")

    url = (
        f"https://generativelanguage.googleapis.com/v1beta/models/"
        f"{GEMINI_MODEL_NAME}:generateContent"
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
    if resp.status_code >= 400:
        raise parse_api_error(resp, PROVIDER_GEMINI)
    data = resp.json()

    candidates = data.get("candidates", [])
    if not candidates:
        raise ImageApiError(0, f"API没有返回候选结果: {data}", provider=PROVIDER_GEMINI)

    for part in candidates[0]["content"]["parts"]:
        inline_data = part.get("inline_data") or part.get("inlineData")
        if inline_data and inline_data.get("data"):
            return base64.b64decode(inline_data["data"])

    raise ImageApiError(0, f"返回结果中没有找到图片数据: {data}", provider=PROVIDER_GEMINI)


def _request_cloudflare(prompt: str) -> bytes:
    """调用 Cloudflare Workers AI 的 flux-1-schnell，返回图片字节（JPEG）。"""
    account_id, token = get_cloudflare_credentials()
    if len(prompt) > CLOUDFLARE_PROMPT_LIMIT:
        print(f"  提示词超过 {CLOUDFLARE_PROMPT_LIMIT} 字符，已截断")
        prompt = prompt[:CLOUDFLARE_PROMPT_LIMIT]

    url = (
        f"https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/run/"
        f"{CLOUDFLARE_MODEL_NAME}"
    )
    resp = requests.post(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        json={"prompt": prompt, "steps": CLOUDFLARE_STEPS},
        timeout=180,
    )

    if resp.status_code >= 400:
        raise parse_api_error(resp, PROVIDER_CLOUDFLARE)

    # 有的接口版本直接返回二进制图片
    if resp.headers.get("content-type", "").startswith("image/"):
        return resp.content

    data = resp.json()
    if not data.get("success", True):
        raise parse_api_error(resp, PROVIDER_CLOUDFLARE)

    image_b64 = (data.get("result") or {}).get("image")
    if not image_b64:
        raise ImageApiError(0, f"返回结果中没有图片数据: {data}", provider=PROVIDER_CLOUDFLARE)
    return base64.b64decode(image_b64)


def _request_modelscope(prompt: str) -> bytes:
    """调用魔搭 API-Inference 的 Qwen-Image（异步提交 + 轮询），返回图片字节。"""
    token = get_modelscope_token()
    base_url = "https://api-inference.modelscope.cn/v1"
    common_headers = {
        "Authorization": f"Bearer {token}",
        "Content-Type": "application/json",
    }
    if len(prompt) > MODELSCOPE_PROMPT_LIMIT:
        print(f"  提示词超过 {MODELSCOPE_PROMPT_LIMIT} 字符，已截断")
        prompt = prompt[:MODELSCOPE_PROMPT_LIMIT]

    resp = requests.post(
        f"{base_url}/images/generations",
        headers={**common_headers, "X-ModelScope-Async-Mode": "true"},
        data=json.dumps(
            {
                "model": MODELSCOPE_MODEL_NAME,
                "prompt": prompt,
                "negative_prompt": MODELSCOPE_NEGATIVE_PROMPT,
                "size": MODELSCOPE_SIZE,
            },
            ensure_ascii=False,
        ).encode("utf-8"),
        timeout=120,
    )
    if resp.status_code >= 400:
        raise parse_api_error(resp, PROVIDER_MODELSCOPE)

    payload = resp.json()
    task_id = payload.get("task_id")
    if not task_id:
        raise ImageApiError(
            int(payload.get("code") or 0),
            str(payload.get("message") or f"没有拿到 task_id: {payload}"),
            provider=PROVIDER_MODELSCOPE,
        )

    deadline = time.time() + MODELSCOPE_POLL_TIMEOUT
    while time.time() < deadline:
        time.sleep(MODELSCOPE_POLL_INTERVAL)
        status_resp = requests.get(
            f"{base_url}/tasks/{task_id}",
            headers={**common_headers, "X-ModelScope-Task-Type": "image_generation"},
            timeout=60,
        )
        if status_resp.status_code >= 400:
            raise parse_api_error(status_resp, PROVIDER_MODELSCOPE)

        info = status_resp.json()
        status = str(info.get("task_status") or info.get("status") or "").upper()
        if status == "SUCCEED":
            images = info.get("output_images") or []
            if not images:
                raise ImageApiError(
                    0, f"任务成功但没有返回图片: {info}", provider=PROVIDER_MODELSCOPE
                )
            image_resp = requests.get(images[0], timeout=120)
            image_resp.raise_for_status()
            return image_resp.content
        if status in ("FAILED", "CANCELED", "CANCELLED"):
            raise ImageApiError(
                int(info.get("code") or 0),
                str(info.get("error") or info.get("message") or info),
                provider=PROVIDER_MODELSCOPE,
            )

    raise ImageApiError(
        0,
        f"等待生成结果超时（{MODELSCOPE_POLL_TIMEOUT:.0f} 秒），任务 {task_id}",
        provider=PROVIDER_MODELSCOPE,
    )


def request_image(provider: str, prompt: str, reference_image_bytes: bytes | None = None) -> bytes:
    """按 provider 分发，返回一张原始图片的字节。"""
    if provider == PROVIDER_GEMINI:
        return _request_gemini(prompt, reference_image_bytes)
    if provider == PROVIDER_CLOUDFLARE:
        return _request_cloudflare(prompt)
    if provider == PROVIDER_MODELSCOPE:
        return _request_modelscope(prompt)
    raise RuntimeError(f"不支持的服务: {provider}")


# ========== 英文场景描述批量翻译（可选，用 Cloudflare 免费文本模型） ==========

# FLUX 只能可靠理解英文，而且 prompt 里只要出现中文，它就容易把中文当内容画出来。
# 这一步把例句翻译成纯英文的画面描述写进 hanzi_data.json 的 promptEn 字段，
# 之后 cloudflare 的 prompt 里就完全没有中文字符了。
CLOUDFLARE_TEXT_MODEL = "@cf/meta/llama-3.1-8b-instruct"
TRANSLATE_BATCH_SIZE = 8


def _cloudflare_text(prompt: str) -> str:
    account_id, token = get_cloudflare_credentials()
    url = (
        f"https://api.cloudflare.com/client/v4/accounts/{account_id}/ai/run/"
        f"{CLOUDFLARE_TEXT_MODEL}"
    )
    resp = requests.post(
        url,
        headers={
            "Authorization": f"Bearer {token}",
            "Content-Type": "application/json",
        },
        json={
            "messages": [{"role": "user", "content": prompt}],
            "max_tokens": 1024,
        },
        timeout=120,
    )
    if resp.status_code >= 400:
        raise parse_api_error(resp, PROVIDER_CLOUDFLARE)
    data = resp.json()
    if not data.get("success", True):
        raise parse_api_error(resp, PROVIDER_CLOUDFLARE)
    return str((data.get("result") or {}).get("response") or "").strip()


def _has_cjk(text: str) -> bool:
    return any("\u4e00" <= char <= "\u9fff" for char in text)


def _build_translate_prompt(chunk: list[dict]) -> str:
    lines = []
    for index, entry in enumerate(chunk, 1):
        sentence = (entry.get("sentence") or {}).get("text") or ""
        words = "、".join(word["text"] for word in entry.get("words", []))
        hint = f"；词语：{words}" if words else ""
        lines.append(f"{index}. 汉字：{entry['char']}；例句：{sentence}{hint}")
    return (
        "你是儿童插画提示词助手。把下面每一条中文场景改写成一句英文画面描述，"
        "供文生图模型使用。要求：只描述画面里的人物、物体、动作和环境，25 个单词以内；"
        "不要出现任何中文字符；不要提到汉字、文字、书本、卡片或招牌；"
        "严格按编号逐行输出，格式为 `1. ...`，不要任何多余解释。\n\n"
        + "\n".join(lines)
    )


def translate_scene_prompts(data: list[dict]) -> int:
    """给还没有 promptEn 的条目补英文场景描述，返回新增条数。"""
    pending = [
        entry
        for entry in data
        if not (entry.get("promptEn") or entry.get("prompt_en"))
        and (entry.get("sentence") or {}).get("text")
    ]
    if not pending:
        print("所有字都已有英文描述，无需翻译")
        return 0

    total = len(pending)
    print(f"需要翻译 {total} 条（每批 {TRANSLATE_BATCH_SIZE} 条）")
    done = 0
    for start in range(0, total, TRANSLATE_BATCH_SIZE):
        chunk = pending[start : start + TRANSLATE_BATCH_SIZE]
        text = ""
        for attempt in range(1, 4):
            try:
                text = _cloudflare_text(_build_translate_prompt(chunk))
                break
            except ImageApiError as exc:
                if exc.status_code == 429:
                    time.sleep(10 * attempt)
                    continue
                raise
            except requests.RequestException:
                time.sleep(5 * attempt)

        parsed: dict[int, str] = {}
        for line in text.splitlines():
            match = re.match(r"\s*(\d+)\s*[.、)]\s*(.+)", line)
            if not match:
                continue
            index = int(match.group(1))
            desc = match.group(2).strip()
            if 1 <= index <= len(chunk) and desc and not _has_cjk(desc):
                parsed[index] = desc

        for index, entry in enumerate(chunk, 1):
            if index in parsed:
                entry["promptEn"] = parsed[index]
                done += 1
        save_progress(data)
        print(f"  进度 {min(start + len(chunk), total)}/{total}，成功 {done} 条")

    return done


# ========== 裁剪与保存 ==========


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


def _finalize(img: Image.Image) -> Image.Image:
    """裁到 1.81:1 并缩放到目标尺寸。"""
    return _crop_to_aspect(img, TARGET_ASPECT).resize(
        (TARGET_WIDTH, TARGET_HEIGHT), Image.LANCZOS
    )


def _is_blank(img: Image.Image) -> bool:
    return ImageStat.Stat(img.convert("L")).stddev[0] < BLANK_STDDEV_THRESHOLD


# ========== 版式合成（字 + 圈号 + 例句） ==========


def _font_covers(font: ImageFont.FreeTypeFont, text: str) -> bool:
    """用私用区字符的 notdef 图作为参照，判断字体是否真的包含这些字。"""
    notdef = font.getmask("\ue000")
    for char in set(text):
        if char.isspace():
            continue
        mask = font.getmask(char)
        if mask.size == notdef.size and mask.tobytes() == notdef.tobytes():
            return False
    return True


_OVERLAY_FONT: tuple[str, int] | None = None
_OVERLAY_FONT_RESOLVED = False


def _resolve_overlay_font() -> tuple[str, int] | None:
    """挑一个真正包含简体中文的字体，结果缓存。"""
    global _OVERLAY_FONT, _OVERLAY_FONT_RESOLVED
    if _OVERLAY_FONT_RESOLVED:
        return _OVERLAY_FONT

    _OVERLAY_FONT_RESOLVED = True
    for path, index in FONT_CANDIDATES:
        if not path or not Path(path).exists():
            continue
        try:
            font = ImageFont.truetype(path, 40, index=index)
        except OSError:
            continue
        if _font_covers(font, FONT_PROBE_TEXT):
            _OVERLAY_FONT = (path, index)
            return _OVERLAY_FONT

    _OVERLAY_FONT = None
    return None


def _load_font(size: int) -> ImageFont.FreeTypeFont:
    resolved = _resolve_overlay_font()
    if resolved is None:
        raise SystemExit(
            "找不到可用的中文字体来合成例句。请用 IMAGE_OVERLAY_FONT "
            "指定一个完整的中文字体（如 Noto Sans SC），或用 --overlay none 只出纯插画。"
        )
    path, index = resolved
    return ImageFont.truetype(path, size, index=index)


def _text_size(text: str, font: ImageFont.FreeTypeFont, stroke_width: int = 0) -> tuple[int, int]:
    left, top, right, bottom = font.getbbox(text, stroke_width=stroke_width)
    return right - left, bottom - top


def _draw_text_at(
    draw: ImageDraw.ImageDraw,
    text: str,
    font: ImageFont.FreeTypeFont,
    *,
    center: tuple[float, float] | None = None,
    ink_top_left: tuple[float, float] | None = None,
    fill: str = "black",
    stroke_width: int = 0,
    stroke_fill: str = "white",
) -> None:
    """按「墨迹」定位文字：给 center 则整体居中，给 ink_top_left 则左上角对齐。"""
    left, top, right, bottom = font.getbbox(text, stroke_width=stroke_width)
    width, height = right - left, bottom - top
    if center is not None:
        x = center[0] - width / 2 - left
        y = center[1] - height / 2 - top
    else:
        assert ink_top_left is not None
        x = ink_top_left[0] - left
        y = ink_top_left[1] - top
    draw.text(
        (x, y),
        text,
        font=font,
        fill=fill,
        stroke_width=stroke_width,
        stroke_fill=stroke_fill,
    )


def _fit_sentence_font(text: str) -> ImageFont.FreeTypeFont:
    size = PAGE_SENTENCE_START_SIZE
    while size > PAGE_SENTENCE_MIN_SIZE:
        font = _load_font(size)
        if _text_size(text, font, PAGE_TEXT_STROKE)[0] <= PAGE_SENTENCE_MAX_WIDTH:
            return font
        size -= 2
    return _load_font(PAGE_SENTENCE_MIN_SIZE)


def _fade_bottom_to_white(canvas: Image.Image) -> None:
    """底部渐隐成白色，让例句压在插画上也清晰，接近教材页的留白。"""
    band_height = canvas.height - PAGE_FADE_TOP
    if band_height <= 0:
        return
    mask = Image.new("L", (1, band_height))
    for i in range(band_height):
        # 前 55% 渐隐，之后纯白
        mask.putpixel((0, i), min(255, int(255 * i / (band_height * 0.55))))
    mask = mask.resize((canvas.width, band_height))
    white = Image.new("RGB", (canvas.width, band_height), "white")
    canvas.paste(white, (0, PAGE_FADE_TOP), mask)


def _fit_number_font(number: int, radius: int) -> ImageFont.FreeTypeFont:
    """圈内数字：位数多了就缩字号，保证不溢出。"""
    text = str(number)
    size = PAGE_NUMBER_FONT_SIZE
    limit = 2 * radius - 10
    while size > 12:
        font = _load_font(size)
        if _text_size(text, font)[0] <= limit:
            return font
        size -= 2
    return _load_font(12)


def compose_textbook_page(img: Image.Image, entry: dict) -> Image.Image:
    """在插画上叠字：左上角当前字、左下角带圈序号、底部例句。"""
    canvas = img.convert("RGB").copy()
    _fade_bottom_to_white(canvas)
    draw = ImageDraw.Draw(canvas)

    # 1) 左上角：当前汉字
    char_font = _load_font(PAGE_CHAR_SIZE)
    _draw_text_at(
        draw,
        entry["char"],
        char_font,
        ink_top_left=PAGE_CHAR_TOP_LEFT,
        stroke_width=PAGE_TEXT_STROKE,
        stroke_fill="white",
    )

    # 2) 左下角：带圈序号（全局序号，和 0001→①、0004→④ 的规律一致）
    number = int(entry["id"])
    cx, cy = PAGE_NUMBER_CENTER
    radius = PAGE_NUMBER_RADIUS if number < 100 else PAGE_NUMBER_RADIUS + 3
    draw.ellipse(
        (cx - radius, cy - radius, cx + radius, cy + radius),
        outline="black",
        width=PAGE_NUMBER_LINE_WIDTH,
    )
    _draw_text_at(
        draw,
        str(number),
        _fit_number_font(number, radius),
        center=(cx, cy - 1),
    )

    # 3) 底部：例句。能居中就居中，太长时从圈号右侧开始，避免压到圈号
    sentence = (entry.get("sentence") or {}).get("text")
    if sentence:
        font = _fit_sentence_font(sentence)
        left, top, right, bottom = font.getbbox(sentence, stroke_width=PAGE_TEXT_STROKE)
        width, height = right - left, bottom - top
        x = max(PAGE_SENTENCE_LEFT, (TARGET_WIDTH - width) / 2)
        y = PAGE_SENTENCE_CENTER_Y - height / 2
        draw.text(
            (x - left, y - top),
            sentence,
            font=font,
            fill="black",
            stroke_width=PAGE_TEXT_STROKE,
            stroke_fill="white",
        )

    return canvas


def _apply_overlay(img: Image.Image, entry: dict, overlay: str) -> Image.Image:
    if overlay == OVERLAY_TEXTBOOK:
        return compose_textbook_page(img, entry)
    return img


def output_path_for(entry: dict) -> Path:
    # 仓库现有 720 张图统一用 id 命名（0001.webp … 0720.webp）
    return IMAGES_OUTPUT_DIR / f"{entry['id']}.webp"


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


def _save_image(img: Image.Image, entry: dict) -> int:
    path = output_path_for(entry)
    if path.exists():
        # 绝不覆盖已经存在的图片，只把路径登记回 JSON
        entry["imageAsset"] = _asset_path(path)
        return 1
    img.save(path, "WEBP", quality=WEBP_QUALITY, method=6)
    entry["imageAsset"] = _asset_path(path)
    return 1


def save_single_image(raw_bytes: bytes, entry: dict, overlay: str = DEFAULT_OVERLAY) -> int:
    """单图模式：裁到 1.81:1、缩放到 526×290、叠字后保存为 WebP。"""
    img = Image.open(io.BytesIO(raw_bytes)).convert("RGB")
    img = _finalize(img)
    if _is_blank(img):
        raise RuntimeError("生成的图片几乎是空白，重试")
    return _save_image(_apply_overlay(img, entry, overlay), entry)


def split_grid_and_save(
    raw_bytes: bytes, entries: list[dict], overlay: str = DEFAULT_OVERLAY
) -> int:
    """把四宫格按 2×2 切开，逐张裁到 1.81:1、缩放到 526×290、叠字后保存。"""
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

        cell = _finalize(img.crop((left, top, right, bottom)))

        # 模型偶尔只画了两三格，剩下的格子是空白，这种情况整组重试
        if _is_blank(cell):
            raise RuntimeError(
                f"第{index + 1}格几乎是空白，可能模型没画满四格，整组重试"
            )

        saved += _save_image(_apply_overlay(cell, entry, overlay), entry)

    return saved


def save_images(
    provider: str, raw_bytes: bytes, entries: list[dict], overlay: str = DEFAULT_OVERLAY
) -> int:
    if provider == PROVIDER_GEMINI:
        return split_grid_and_save(raw_bytes, entries, overlay)
    return save_single_image(raw_bytes, entries[0], overlay)


def reset_entries(data: list[dict], ids: set[int]) -> tuple[int, int]:
    """清掉指定 id 的配图记录并删除对应 webp，方便按新风格重画。"""
    cleared = 0
    deleted = 0
    for entry in data:
        if int(entry["id"]) not in ids:
            continue
        path = output_path_for(entry)
        # 只动脚本自己生成的 .webp，教材原图 .gif 一律不碰
        if path.exists() and path.suffix == ".webp":
            path.unlink()
            deleted += 1
        if entry.get("imageAsset") and str(entry["imageAsset"]).endswith(".webp"):
            entry["imageAsset"] = None
            cleared += 1
    return cleared, deleted


def parse_id_specs(spec: str) -> set[int]:
    """解析 "51-74,80,90-92" 这样的 id 列表。"""
    ids: set[int] = set()
    for chunk in spec.replace("，", ",").split(","):
        chunk = chunk.strip()
        if not chunk:
            continue
        if "-" in chunk:
            start_text, end_text = chunk.split("-", 1)
            start, end = int(start_text), int(end_text)
            ids.update(range(min(start, end), max(start, end) + 1))
        else:
            ids.add(int(chunk))
    return ids


def save_progress(data: list[dict]) -> None:
    with open(DATA_JSON_PATH, "w", encoding="utf-8") as f:
        json.dump(data, f, ensure_ascii=False, indent=2)


# ========== 命令行与主流程 ==========


def parse_args() -> argparse.Namespace:
    parser = argparse.ArgumentParser(
        description="批量生成汉字配图：可切换 Gemini / Cloudflare FLUX / 魔搭 Qwen-Image"
    )
    parser.add_argument(
        "--provider",
        choices=SUPPORTED_PROVIDERS,
        default=DEFAULT_PROVIDER,
        help=(
            "图像服务。cloudflare=免费（默认），modelscope=魔搭 Qwen-Image，"
            "gemini=付费四宫格"
        ),
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
        "--interval",
        type=float,
        default=None,
        help="两次请求之间的间隔秒数，不填则按服务取默认值",
    )
    parser.add_argument(
        "--overlay",
        choices=OVERLAY_MODES,
        default=DEFAULT_OVERLAY,
        help=(
            "是否把字/圈号/例句印到图上。none=只保留纯插画（默认，和当前 App 一致），"
            "textbook=对齐前 50 张教材版式"
        ),
    )
    parser.add_argument(
        "--reset",
        default="",
        help='重画前先清掉这些 id 的配图（如 "51-74"），然后继续按本轮计划生成',
    )
    parser.add_argument(
        "--translate-prompts",
        action="store_true",
        help="先用 Cloudflare 文本模型把例句翻成英文画面描述（写回 promptEn），不生成图片",
    )
    parser.add_argument(
        "--dry-run",
        action="store_true",
        help="只打印提示词，不调用 API、不写文件",
    )
    return parser.parse_args()


def auth_failure_hint(provider: str) -> str:
    """401/403 时给出针对性的排查方向。"""
    if provider == PROVIDER_MODELSCOPE:
        return (
            "魔搭 API-Inference 需要先在 modelscope.cn 绑定阿里云账号并完成实名认证，"
            "绑定后再重跑；不想折腾可以改用 --provider cloudflare"
        )
    if provider == PROVIDER_CLOUDFLARE:
        return (
            "检查 CLOUDFLARE_API_TOKEN 是否有效（权限需含 Workers AI:Read），"
            "以及 CLOUDFLARE_ACCOUNT_ID 是否填对"
        )
    return "检查 GEMINI_API_KEY 是否有效、该模型是否已开通"


def print_provider_hint(provider: str, planned: int) -> None:
    if provider == PROVIDER_CLOUDFLARE:
        print(
            f"  Cloudflare 免费额度约 {CLOUDFLARE_FREE_IMAGES_PER_DAY} 张/天，"
            "额度用完会报错，次日 08:00（北京时间）重置"
        )
        if planned > CLOUDFLARE_FREE_IMAGES_PER_DAY:
            print(
                f"  本轮计划 {planned} 张，超过单日免费额度，"
                "建议分批跑，或接受少量付费（约 $0.0006/张）"
            )
    elif provider == PROVIDER_MODELSCOPE:
        print("  魔搭 Qwen-Image 免费额度约 250 张/天，需实名账号、限非商用")
    else:
        print("  Gemini 为付费服务，2×2 四宫格一次请求出 4 张")


def main() -> None:
    args = parse_args()
    provider = args.provider
    images_per_request = PROVIDER_IMAGES_PER_REQUEST[provider]
    interval = (
        args.interval
        if args.interval is not None
        else PROVIDER_DEFAULT_INTERVAL[provider]
    )

    with open(DATA_JSON_PATH, encoding="utf-8") as f:
        data = json.load(f)

    if args.translate_prompts:
        check_provider_credentials(PROVIDER_CLOUDFLARE)
        done = translate_scene_prompts(data)
        print(f"翻译完成，新增 {done} 条英文画面描述，已写回 hanzi_data.json")
        return

    IMAGES_OUTPUT_DIR.mkdir(parents=True, exist_ok=True)

    if args.reset:
        cleared, deleted = reset_entries(data, parse_id_specs(args.reset))
        save_progress(data)
        print(f"已重置 {cleared} 条配图记录，删除 {deleted} 个 webp 文件")

    # --dry-run 承诺不写文件，这里也不要顺手把已存在的图片登记进 JSON
    adopted = 0 if args.dry_run else adopt_existing_files(data)
    if adopted:
        save_progress(data)
        print(f"发现 {adopted} 张已存在的图片，已补登记到 JSON")

    todo = [entry for entry in data if not entry.get("imageAsset")]
    print(f"使用服务：{provider}")
    print(f"版式：{args.overlay}")
    if provider == PROVIDER_CLOUDFLARE:
        missing = sum(
            1
            for entry in todo
            if not (entry.get("promptEn") or entry.get("prompt_en"))
        )
        if missing:
            print(
                f"  提示：{missing} 条还没有英文描述（promptEn），"
                "中文例句容易被 FLUX 当成字画出来，建议先跑 --translate-prompts"
            )
    print(
        f"共{len(data)}个字，已有配图{len(data) - len(todo)}个，"
        f"剩余{len(todo)}个待生成"
    )

    if not todo:
        print("全部字都已有配图，无需生成")
        return

    if args.dry_run:
        print("---- 第一组提示词 ----")
        print(build_prompt_for_batch(provider, todo[:images_per_request]))
        return

    check_provider_credentials(provider)

    reference_bytes = None
    if REFERENCE_IMAGE_PATH:
        if provider == PROVIDER_GEMINI:
            with open(REFERENCE_IMAGE_PATH, "rb") as f:
                reference_bytes = f.read()
        else:
            print("提示：参考图只有 gemini 支持，已忽略 REFERENCE_IMAGE_PATH")

    limit = 0 if args.all else max(1, args.limit)
    planned = len(todo) if limit == 0 else min(limit, len(todo))
    requests_needed = math.ceil(planned / images_per_request)
    minutes = requests_needed * (interval + 15) / 60
    print(
        f"本轮计划生成 {planned} 张，约 {requests_needed} 次请求，"
        f"预计 {minutes:.0f} 分钟（每张约 {minutes / planned * 60:.1f} 秒）"
    )
    print_provider_hint(provider, planned)

    generated = 0
    for start in range(0, len(todo), images_per_request):
        if limit and generated >= limit:
            break

        group = todo[start : start + images_per_request]
        chars = "、".join(entry["char"] for entry in group)
        print(
            f"[{start + 1}-{start + len(group)}/{len(todo)}] "
            f"生成一组 {len(group)} 张：{chars}"
        )
        prompt = build_prompt_for_batch(provider, group)

        success = False
        stop_run = False
        for attempt in range(1, MAX_RETRIES + 1):
            try:
                raw_bytes = request_image(provider, prompt, reference_bytes)
                saved = save_images(provider, raw_bytes, group, args.overlay)
                save_progress(data)
                generated += saved
                success = True
                print(f"  已保存 {saved} 张，本轮累计 {generated} 张")
                break
            except ImageApiError as exc:
                if exc.daily_quota:
                    print("  每日额度已用完，本轮到此为止。")
                    print("  明天再跑，或者换一个 key / 升级配额后继续。")
                    print(f"  接口信息：{exc.message}")
                    stop_run = True
                    break

                if exc.status_code == 429:
                    wait = exc.retry_delay or min(
                        600.0, interval * (2 ** (attempt - 1))
                    )
                    wait += random.uniform(0, 5)
                    reason = "触发限流"
                elif exc.status_code in (401, 403):
                    # key 无效、账号没绑定/没实名、没权限：整轮都跑不了，直接停
                    print(f"  鉴权失败（HTTP {exc.status_code}）：{exc.message}")
                    print(f"  {auth_failure_hint(provider)}")
                    stop_run = True
                    break

                elif exc.status_code in (400, 404, 413):
                    # 单个请求的参数/内容问题，换下一个字还能继续
                    print(f"  请求被拒绝（HTTP {exc.status_code}）：{exc.message}")
                    print("  这属于参数或内容问题，重试没有意义，这一组先跳过")
                    break
                else:
                    wait = min(300.0, 10 * (2 ** (attempt - 1))) + random.uniform(0, 3)
                    reason = f"第{attempt}次尝试失败"

                print(f"  {reason}: {exc.message}")
                if attempt < MAX_RETRIES:
                    print(
                        f"  {wait:.0f} 秒后重试"
                        f"（{attempt + 1}/{MAX_RETRIES}）"
                    )
                    time.sleep(wait)
                else:
                    print("  已达到最大重试次数，这一组先跳过")

            except Exception as exc:  # noqa: BLE001 - 生成流程要尽量跑完
                print(f"  第{attempt}次尝试失败: {exc}")
                if attempt < MAX_RETRIES:
                    wait = min(300.0, 10 * (2 ** (attempt - 1))) + random.uniform(0, 3)
                    print(f"  {wait:.0f} 秒后重试")
                    time.sleep(wait)

        if stop_run:
            break

        if not success:
            print("  这一组跳过，下次运行会重新尝试")

        if limit and generated >= limit:
            break

        time.sleep(interval)

    save_progress(data)
    print(f"本轮结束，共生成 {generated} 张。重新运行脚本可继续补齐。")


if __name__ == "__main__":
    main()
