"""生成 assets/data/meanings_en.json（单字 / 组词 / 例句 英文释义）。

数据来源：
- 单字、组词：CC-CEDICT（https://www.mdbg.net/chinese/dictionary?page=cedict）
  按「词条 + 拼音」精确匹配，因此多音字能取到对应义项（长 cháng / zhǎng 不会混）。
  CC-CEDICT 采用 CC BY-SA 4.0，正式商用前请评估署名与传染性条款，
  或把这批释义替换为自建 / 付费词库；结构上只需保持同一份 JSON。
- 例句：build/sent_en_*.tsv 人工翻译（按 build/sentences.tsv 的序号对应）。

用法：
    python scripts/build_meanings_en.py
"""

import io
import json
import os
import re

from pypinyin import Style, lazy_pinyin
from pypinyin.contrib.tone_convert import to_tone3

ROOT = os.path.dirname(os.path.dirname(os.path.abspath(__file__)))
DATA = os.path.join(ROOT, "assets", "data", "hanzi_data.json")
CEDICT = os.path.join(ROOT, "build", "cedict.txt")
OUT = os.path.join(ROOT, "assets", "data", "meanings_en.json")
SENT_TSV = os.path.join(ROOT, "scripts", "data", "sent_en.tsv")
WORD_TSV = os.path.join(ROOT, "scripts", "data", "word_en_extra.tsv")

# 词典里对儿童无意义、或会产生歧义的义项，直接丢掉
NOISE = (
    "kangxi radical",
    "surname ",
    "abbr. for",
    "abbr for",
    "old variant",
    "variant of",
    "used in the names of",
    "see also",
    "also written",
    "also pr",
    "taiwan pr",
    "japanese ",
    "erhua variant",
    "archaic",
    "dialect",
    "internet slang",
    "buddhist",
    "physics",
    "chemistry",
    "math.",
    "grammar",
    "med.",
    "anatomy",
    "computing",
    "finance",
    "earthly branch",
    "solar month",
    "compass point",
    "aunt flo",
    "menstruat",
    "vulgar",
    "derog",
    "euphemism",
    "sexual",
    "curse",
    "fig.",
    "used figuratively",
    "onomat",
    "penis",
    "slang",
    "prostitut",
    "brothel",
    "opium",
    "masturbat",
    "condom",
    "anus",
    "semen",
    "pornograph",
    "one's death",
)

# CEDICT 没有覆盖、或义项不适合儿童的少量手工修正
CHAR_OVERRIDES = {
    "一": "one",
    "二": "two",
    "三": "three",
    "四": "four",
    "五": "five",
    "六": "six",
    "七": "seven",
    "八": "eight",
    "九": "nine",
    "十": "ten",
    "百": "hundred",
    "千": "thousand",
    "万": "ten thousand",
    "亿": "a hundred million",
    "了": "finished; (particle)",
    "的": "(possessive particle)",
    "地": "ground; earth",
    "得": "to get; must",
    "着": "(ongoing action particle)",
    "把": "to hold; (object marker)",
    "被": "quilt; (passive marker)",
    "吗": "(question particle)",
    "呢": "(question particle)",
    "吧": "(suggestion particle)",
    "啊": "ah; oh",
    "呀": "ah; oh",
    "哦": "oh; I see",
    "嗯": "yes; hmm",
    "喂": "hello (on the phone)",
    "只": "only; (measure word)",
    "还": "still; to return",
    "干": "dry; to do",
    "爪": "claw; paw",
    "缝": "to sew; seam",
    "午": "noon",
    "么": "(suffix for questions)",
    "棵": "measure word for trees",
    "粒": "grain; a grain of",
    "霞": "rosy clouds",
    "隐": "hidden; to hide",
    "捡": "to pick up",
    "拎": "to carry (by hand)",
    "子": "child; son",
    "虫": "insect; bug",
    "筝": "zither",
    "蜻": "dragonfly (in 蜻蜓)",
    # 同形字 / 多义字：CEDICT 给的是冷僻义项，这里换成教学常用义
    "中": "middle; in; center",
    "后": "behind; after",
    "里": "inside; in",
    "云": "cloud",
    "鸟": "bird",
    "星": "star",
    "太": "too; very",
    "奶": "grandma; milk",
    "父": "father",
    "之": "(possessive particle)",
    "于": "at; in; to",
    "元": "yuan (currency); first",
    "角": "corner; horn",
    "朵": "a flower (measure word)",
    "支": "measure word for pens",
    "回": "to return; to go back",
    "关": "to close; to turn off",
    "单": "single; list",
    "节": "festival; holiday; joint",
    "黄": "yellow",
    "绿": "green",
    "广": "wide; broad",
    "团": "group; round",
    "欢": "happy; joyful",
    "丑": "ugly",
    "粗": "thick; coarse",
    "曲": "bent; curve",
    "假": "fake; false",
    "弹": "to play (an instrument)",
    "英": "hero; English (in 英语)",
    "塘": "pond",
    "本": "root; origin",
    "场": "place; field",
    "操": "to exercise; to hold",
    "烟": "smoke",
    "糖": "sugar; candy",
    "沙": "sand",
    "穿": "to wear; to put on",
    "采": "to pick; to gather",
    "猎": "to hunt",
    "战": "war; to fight",
    "森": "forest",
    "裤": "trousers; pants",
    "苹": "apple (in 苹果)",
    "金": "gold",
    "碟": "small plate; saucer",
    "店": "shop; store",
    "布": "cloth",
    "伞": "umbrella",
    "豚": "piglet",
    "宇": "universe; space",
    "世": "world; generation",
    "台": "platform; stage",
    "鸭": "duck",
    "蝇": "fly (insect)",
    "钟": "clock; bell",
    "井": "well",
    "脏": "dirty",
    # 第二批：仍是「义项选错 / 带冗余说明」的字
    "左": "left",
    "水": "water",
    "比": "to compare; than",
    "齿": "tooth",
    "张": "to open; measure word for flat things",
    "往": "toward; to go",
    "血": "blood",
    "雪": "snow",
    "春": "spring",
    "夸": "to praise",
    "方": "square; direction",
    "马": "horse",
    "羽": "feather",
    "蓝": "blue",
    "薄": "thin; slight",
    "谷": "valley; grain",
    "粉": "powder; flour",
    "阳": "sun; sunshine",
    "乡": "countryside; hometown",
    "村": "village",
    "季": "season",
    "给": "to give; to",
    "热": "hot; to heat",
    "酱": "sauce; paste",
    "洼": "hollow; puddle",
    "纺": "to spin (thread)",
    "划": "to row; to paddle",
    "棉": "cotton",
    "球": "ball",
    "袖": "sleeve",
    "帕": "handkerchief",
    "铁": "iron",
    "巾": "towel; cloth",
    "影": "shadow; image",
    "炭": "charcoal",
    "柴": "firewood",
    "航": "to sail; navigation",
    "城": "city",
    "楼": "building; floor",
    "霜": "frost",
    "露": "dew",
    "团": "group; round",
    # 第三批（真机逐字校对）：取「教学常用义」而不是词典第一个义项
    "士": "soldier",
    "当": "to be; to serve as",
    "业": "studies; business",
    "群": "group; herd",
    "食": "food; to eat",
    "减": "to subtract; to reduce",
    "满": "full; to fill",
    "站": "to stand; station",
    "园": "garden",
    "行": "to go; to walk",
    "快": "fast; quick",
    "面": "face; noodles",
    "户": "household; door",
    "末": "end; tip",
    "兵": "soldier",
    "农": "farming",
    "客": "guest",
    "主": "owner; main",
}

WORD_OVERRIDES = {
    "右手": "right hand",
    "左手": "left hand",
    "右边": "right side",
    "左边": "left side",
    "一只": "one (animal or bird)",
    "一双": "a pair of",
    "一条": "one (long thing)",
    "一张": "one (flat thing)",
    "一片": "a slice; a stretch of",
    "一件": "one (piece of clothing)",
    "一辆": "one (vehicle)",
    "一座": "one (building, mountain)",
    "一本": "one (book)",
    "一把": "one (handful, tool)",
    "一根": "one (stick-like thing)",
    "一颗": "one (small round thing)",
    "一朵": "one (flower, cloud)",
    "一棵": "one (tree, plant)",
    "一粒": "one grain of",
    "一群": "a group of",
    "一半": "half",
    "一些": "some",
    "一起": "together",
    "一下": "a little while; once",
    "一点儿": "a little bit",
    "一点": "a little",
    "一直": "always; straight",
    "一样": "the same",
    "一定": "certainly; must",
    "一般": "general; usual",
    "一边": "one side; while",
    "一天": "one day",
    "一年": "one year",
    "十分": "very; ten minutes",
    "十几": "a dozen or so",
    "几十": "dozens of",
    "两个": "two (of them)",
    "三个": "three (of them)",
    "四个": "four (of them)",
    "几个": "several",
    "这么": "so; this much",
    "那么": "so; that much",
    "怎么": "how",
    "什么": "what",
    "为什么": "why",
    "多少": "how many; how much",
    "多少年": "how many years",
    "第一": "first",
    "第二": "second",
    "一半儿": "half",
}

SENTENCE_NOTE = (
    "例句英文来自 build/sent_en_*.tsv（与 build/sentences.tsv 的序号一一对应）。"
)


def pinyin_numbered(text: str) -> str:
    """用与 CEDICT 一致的带调数字拼音，用于精确匹配词条。

    注意：这里的 text 是「数据里标注的读音」，不是 pypinyin 猜的默认读音。
    多音字必须按数据标注查（长 cháng / zhǎng、干 gān / gàn），
    否则会取到另一个读音的义项。
    """
    parts = []
    for token in text.split():
        if not token:
            continue
        if token.isascii() and token.replace("ü", "v").isalpha():
            # 已经是不带声调的拼音，交给 pypinyin 按读音补全
            parts.extend(
                lazy_pinyin(token, style=Style.TONE3, neutral_tone_with_five=True)
            )
            continue
        parts.append(to_tone3(token, neutral_tone_with_five=True))
    return " ".join(parts)


def load_cedict():
    table = {}
    if not os.path.exists(CEDICT):
        raise SystemExit(
            "缺少 build/cedict.txt，请先下载 CC-CEDICT 并解压到该路径。"
        )
    with io.open(CEDICT, encoding="utf-8") as f:
        for line in f:
            if line.startswith("#"):
                continue
            m = re.match(r"^(\S+) (\S+) \[([^\]]+)\] /(.*)/$", line.strip())
            if not m:
                continue
            simplified, pinyin, defs = m.group(2), m.group(3), m.group(4)
            table.setdefault((simplified, pinyin), []).append(defs.split("/"))
    return table


def clean(defs, limit=2, max_len=44, sense_len=32):
    """把 CEDICT 的一条释义整理成适合儿童阅读的短句。

    规则：去掉拼音、量词标注与术语标签；条目内部用分号分隔的义项拆开，
    每个义项单独过筛；含汉字的残留（量词标注没清干净）整条丢弃；
    单个义项超过 sense_len 直接丢弃（宁可少释义，也不要半句话）。
    """
    picked = []
    for item in defs:
        raw = item.strip()
        if not raw:
            continue
        # 先去掉括号 / 方括号里的补充说明，例如 "(CL:座[zuo4])"
        raw = re.sub(r"\([^)]*\)", "", raw)
        raw = re.sub(r"\[[^\]]*\]", "", raw)
        raw = re.sub(r"\bCL:[^;,]*", "", raw, flags=re.IGNORECASE)
        raw = re.sub(r"\|[^;]*", "", raw)
        raw = raw.replace("classifier for", "measure word for")

        for text in raw.split(";"):
            text = re.sub(r"\s+", " ", text).strip(" ,.")
            if not text:
                continue
            # 含汉字说明标注没清干净，不要
            if re.search(r"[\u4e00-\u9fff]", text):
                continue
            low = text.lower()
            if any(bad in low for bad in NOISE):
                continue
            # 纯数字义项（如 "2"）在已有英文义项时没有价值
            if re.fullmatch(r"\d+", text):
                continue
            if len(text) > sense_len:
                continue
            if low in [p.lower() for p in picked]:
                continue
            picked.append(text)
            if len(picked) >= limit:
                break
        if len(picked) >= limit:
            break

    if not picked:
        return None

    out = "; ".join(picked)
    while len(out) > max_len and "; " in out:
        out = out.rsplit("; ", 1)[0]
    return out


def lookup(table, text, pinyin, limit=2):
    key = pinyin_numbered(pinyin)
    lists = table.get((text, key))
    if not lists:
        # 拼音对不上（儿化、轻声标注差异）时退化为只看词条
        lists = [
            entry
            for (simplified, _), entries in table.items()
            if simplified == text
            for entry in entries
        ]
    if not lists:
        return None
    # 取义项最少的那条（通常是本义，而不是生僻组合）
    lists.sort(key=lambda defs: len(defs))
    for defs in lists:
        out = clean(defs, limit=limit)
        if out:
            return out
    return None


def load_tsv(path, key=str):
    table = {}
    if not os.path.exists(path):
        return table
    with io.open(path, encoding="utf-8") as f:
        for line in f:
            line = line.rstrip("\n")
            if not line.strip():
                continue
            k, v = line.split("\t", 1)
            table[key(k)] = v.strip()
    return table


def main():
    with io.open(DATA, encoding="utf-8") as f:
        data = json.load(f)

    table = load_cedict()
    extra_words = load_tsv(WORD_TSV)
    sent_en = load_tsv(SENT_TSV, key=int)

    chars = {}
    words = {}
    sentences = {}
    char_order = []
    sentence_order = []

    for item in data:
        char = item["char"]
        if char not in char_order:
            char_order.append(char)
            chars[char] = CHAR_OVERRIDES.get(char) or lookup(
                table, char, item["pinyin"], limit=1
            )

        for w in item.get("words") or []:
            text = w["text"]
            if text in words:
                continue
            words[text] = (
                WORD_OVERRIDES.get(text)
                or extra_words.get(text)
                or lookup(table, text, w["pinyin"], limit=1)
            )

        s = item.get("sentence")
        if s and s["text"] not in sentence_order:
            sentence_order.append(s["text"])

    # 例句译文按出现顺序编号合并
    missing_sent = []
    for idx, text in enumerate(sentence_order, 1):
        en = sent_en.get(idx)
        if en:
            sentences[text] = en
        else:
            missing_sent.append(text)

    chars = {k: v for k, v in chars.items() if v}
    words = {k: v for k, v in words.items() if v}
    sentences = {k: v for k, v in sentences.items() if v}

    payload = {
        "_meta": {
            "chars": len(chars),
            "words": len(words),
            "sentences": len(sentences),
            "source": "CC-CEDICT (chars/words) + hand translations (sentences)",
            "note": SENTENCE_NOTE,
        },
        "chars": chars,
        "words": words,
        "sentences": sentences,
    }
    os.makedirs(os.path.dirname(OUT), exist_ok=True)
    with io.open(OUT, "w", encoding="utf-8") as f:
        json.dump(payload, f, ensure_ascii=False, indent=0)

    print(f"单字 {len(chars)} / 组词 {len(words)} / 例句 {len(sentences)}")
    if missing_sent:
        print(f"例句缺译文 {len(missing_sent)} 条，例如：{missing_sent[:3]}")
    absent = [c for c in char_order if c not in chars]
    if absent:
        print(f"单字缺释义 {len(absent)}：{''.join(absent[:20])}")


if __name__ == "__main__":
    main()