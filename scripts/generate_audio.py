"""批量生成离线朗读音频（单字 / 组词 / 例句）。

用法：
    python scripts/generate_audio.py              # 全量生成（可断点续跑）
    python scripts/generate_audio.py --limit 10   # 只生成前 10 条做验证
    python scripts/generate_audio.py --voice zh-CN-XiaoxiaoNeural

说明：
- 使用 edge-tts（微软在线神经语音）合成，产物为 24kHz 单声道 mp3；
  生成一次即可随 App 离线分发，用户设备不再依赖系统 TTS。
- 单字存在多音字问题，这里用「同音字替换」的方式保证读音正确：
  例如「长」在数据里是 cháng，若默认读 zhǎng，就改合成同音的「常」。
  单字音频只承载音节，替换成同音字不会改变发音。
- 已经存在的文件会跳过，中途失败可以直接重跑。
- 需要联网；如需代理，先设置 HTTPS_PROXY 环境变量。
"""

import argparse
import asyncio
import hashlib
import io
import json
import os
import sys
from typing import Dict, List, Tuple

import edge_tts
from pypinyin import Style, lazy_pinyin

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "assets", "data", "hanzi_data.json")
AUDIO_DIR = os.path.join(ROOT, "assets", "audio")
MANIFEST = os.path.join(AUDIO_DIR, "manifest.json")

VOICE = "zh-CN-XiaoxiaoNeural"
CONCURRENCY = 14

# 数据里读音与引擎默认读音不同、但数据集内找不到同音字的少数几个字，
# 这里手工指定同音字（只影响读音，不影响显示）。
CURATED_HOMOPHONES = {
    "脏": "赃",  # zāng，避免读成 zàng
    "缝": "逢",  # féng，避免读成 fèng
}


def pinyin_of(text: str) -> str:
    return "".join(lazy_pinyin(text, style=Style.TONE))


def load_data() -> List[dict]:
    with io.open(DATA, encoding="utf-8") as f:
        return json.load(f)


def build_homophones(data: List[dict]) -> Dict[str, str]:
    """pinyin -> 一个同音字，用于纠正单字多音字。"""
    chars = set()
    for item in data:
        chars.add(item["char"])
        for w in item.get("words") or []:
            chars.update(w["text"])
        sentence = item.get("sentence")
        if sentence:
            chars.update(sentence["text"])

    buckets: Dict[str, str] = {}
    for ch in chars:
        if not ("\u4e00" <= ch <= "\u9fff"):
            continue
        py = pinyin_of(ch)
        buckets.setdefault(py, ch)
    return buckets


def collect_jobs(data: List[dict]) -> List[Tuple[str, str, bool]]:
    """返回 [(text, 路径, 是否单字)]，按 text 去重。"""
    homophones = build_homophones(data)
    jobs: List[Tuple[str, str, bool]] = []
    seen = set()

    for item in data:
        char = item["char"]
        target_pinyin = item["pinyin"].replace(" ", "")
        spoken = char
        if pinyin_of(char) != target_pinyin:
            alt = homophones.get(target_pinyin) or CURATED_HOMOPHONES.get(char)
            if alt and alt != char:
                spoken = alt
        if char not in seen:
            seen.add(char)
            jobs.append(
                (
                    spoken,
                    os.path.join(AUDIO_DIR, "chars", f'{item["id"]}.mp3'),
                    True,
                )
            )

    for item in data:
        for w in item.get("words") or []:
            text = w["text"]
            if text in seen:
                continue
            seen.add(text)
            name = hashlib.md5(text.encode("utf-8")).hexdigest()[:10]
            jobs.append(
                (text, os.path.join(AUDIO_DIR, "words", f"{name}.mp3"), False)
            )

    for item in data:
        sentence = item.get("sentence")
        if not sentence:
            continue
        text = sentence["text"]
        if text in seen:
            continue
        seen.add(text)
        jobs.append(
            (
                text,
                os.path.join(AUDIO_DIR, "sentences", f'{item["id"]}.mp3'),
                False,
            )
        )

    return jobs


async def synth(sem: asyncio.Semaphore, text: str, path: str) -> bool:
    if os.path.exists(path) and os.path.getsize(path) > 512:
        return True
    async with sem:
        for attempt in range(3):
            try:
                os.makedirs(os.path.dirname(path), exist_ok=True)
                comm = edge_tts.Communicate(text, VOICE)
                await comm.save(path)
                if os.path.getsize(path) > 512:
                    return True
            except Exception as exc:  # noqa: BLE001 - 重试后放弃
                if attempt == 2:
                    print(f"[失败] {text}: {exc}", flush=True)
                await asyncio.sleep(1.5 * (attempt + 1))
    return False


async def main_async(limit: int | None) -> None:
    data = load_data()
    jobs = collect_jobs(data)
    if limit:
        jobs = jobs[:limit]

    total = len(jobs)
    done = 0
    failed = 0
    sem = asyncio.Semaphore(CONCURRENCY)
    lock = asyncio.Lock()

    async def worker(text: str, path: str) -> None:
        nonlocal done, failed
        ok = await synth(sem, text, path)
        async with lock:
            if ok:
                done += 1
            else:
                failed += 1
            if (done + failed) % 50 == 0 or (done + failed) == total:
                print(f"进度 {done + failed}/{total}，失败 {failed}", flush=True)

    tasks = [asyncio.create_task(worker(t, p)) for t, p, _ in jobs]
    for i in range(0, len(tasks), 200):
        await asyncio.gather(*tasks[i : i + 200])

    write_manifest(data)
    print(f"完成：{done} 条，失败 {failed} 条", flush=True)
    if failed:
        sys.exit(1)


def write_manifest(data: List[dict]) -> None:
    """生成 text -> 资源路径 的索引，供运行时查表。"""
    mapping: Dict[str, str] = {}
    for item in data:
        char = item["char"]
        path = f'assets/audio/chars/{item["id"]}.mp3'
        if os.path.exists(os.path.join(ROOT, path)):
            mapping.setdefault(char, path)

    for item in data:
        for w in item.get("words") or []:
            name = hashlib.md5(w["text"].encode("utf-8")).hexdigest()[:10]
            path = f"assets/audio/words/{name}.mp3"
            if os.path.exists(os.path.join(ROOT, path)):
                mapping.setdefault(w["text"], path)

    for item in data:
        sentence = item.get("sentence")
        if not sentence:
            continue
        path = f'assets/audio/sentences/{item["id"]}.mp3'
        if os.path.exists(os.path.join(ROOT, path)):
            mapping.setdefault(sentence["text"], path)

    with io.open(MANIFEST, "w", encoding="utf-8") as f:
        json.dump(mapping, f, ensure_ascii=False, indent=0)
    print(f"索引：{len(mapping)} 条 -> {MANIFEST}", flush=True)


def main() -> None:
    global VOICE

    parser = argparse.ArgumentParser()
    parser.add_argument("--limit", type=int, default=None)
    parser.add_argument("--voice", default=VOICE)
    args = parser.parse_args()

    VOICE = args.voice
    asyncio.run(main_async(args.limit))


if __name__ == "__main__":
    main()
