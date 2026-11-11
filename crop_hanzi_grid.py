#!/usr/bin/env python3
# -*- coding: utf-8 -*-
"""
汉字配图批量裁剪与重命名脚本 (crop_hanzi_grid.py)
符合 README 规范：
1. 支持将一张 2x2 四宫格拼图按象限（左上、右上、左下、右下）切分为 4 张单图（也支持 3x3 九宫格或单图处理）。
2. 自动去除四宫格分割白边（默认内缩 2% 边缘，可调）。
3. 自动按中心裁剪为 1.81:1 比例（与现有 263x145 插图同比例）。
4. 缩放到 526x290 像素，并以 WebP (quality=85) 保存。
5. 文件名严格按照 hanzi_data.json 中的汉字编号（如 0051.webp, 0052.webp ...）命名，并自动回写 hanzi_data.json。
python crop_hanzi_grid.py grid_01.png grid_02.png grid_03.png grid_04.png grid_05.png grid_06.png grid_07.png grid_08.png grid_09.png grid_10.png --start-id 101 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
python crop_hanzi_grid.py grid_11.jpg grid_12.jpg grid_13.jpg grid_14.jpg grid_15.jpg grid_16.jpg grid_17.jpg grid_18.jpg grid_19.jpg grid_20.jpg --start-id 141 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
python crop_hanzi_grid.py grid_21.jpg grid_22.jpg grid_23.jpg grid_24.jpg grid_25.jpg grid_26.jpg grid_27.jpg grid_28.jpg grid_29.jpg grid_30.jpg --start-id 181 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
python crop_hanzi_grid.py grid_31.jpg grid_32.jpg grid_33.jpg grid_34.jpg grid_35.jpg grid_36.jpg grid_37.jpg grid_38.jpg grid_39.jpg grid_40.jpg --start-id 221 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
python crop_hanzi_grid.py grid_41.jpg grid_42.jpg grid_43.jpg grid_44.jpg grid_45.jpg grid_46.jpg grid_47.jpg grid_48.jpg grid_49.jpg grid_50.jpg --start-id 261 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
python crop_hanzi_grid.py grid_51.jpg grid_52.jpg grid_53.jpg grid_54.jpg grid_55.jpg grid_56.jpg grid_57.jpg grid_58.jpg grid_59.jpg grid_60.jpg --start-id 301 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
python crop_hanzi_grid.py grid_61.jpg grid_62.jpg grid_63.jpg grid_64.jpg grid_65.jpg grid_66.jpg grid_67.jpg grid_68.jpg grid_69.jpg grid_70.jpg --start-id 341 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
python crop_hanzi_grid.py grid_71.jpg grid_72.jpg grid_73.jpg grid_74.jpg grid_75.jpg grid_76.jpg grid_77.jpg grid_78.jpg grid_79.jpg grid_80.jpg --start-id 381 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
python crop_hanzi_grid.py grid_81.jpg grid_82.jpg grid_83.jpg grid_84.jpg grid_85.jpg grid_86.jpg grid_87.jpg grid_88.jpg grid_89.jpg grid_90.jpg --start-id 421 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
python crop_hanzi_grid.py grid_91.jpg grid_92.jpg grid_93.jpg grid_94.jpg grid_95.jpg grid_96.jpg grid_97.jpg grid_98.jpg grid_99.jpg grid_100.jpg --start-id 461 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
"""

import os
import json
import argparse
from PIL import Image

TARGET_WIDTH = 526
TARGET_HEIGHT = 290
TARGET_RATIO = TARGET_WIDTH / TARGET_HEIGHT  # 约 1.8138:1


def center_crop_and_resize(img: Image.Image, target_w: int = TARGET_WIDTH, target_h: int = TARGET_HEIGHT) -> Image.Image:
    """将图片按中心裁剪为目标宽高比，并缩放到指定分辨率 (526x290)"""
    w, h = img.size
    current_ratio = w / h
    target_ratio = target_w / target_h

    if current_ratio > target_ratio:
        # 图片偏宽，按高度基准裁左右
        new_w = int(h * target_ratio)
        left = (w - new_w) // 2
        img = img.crop((left, 0, left + new_w, h))
    elif current_ratio < target_ratio:
        # 图片偏高，按宽度基准裁上下
        new_h = int(w / target_ratio)
        top = (h - new_h) // 2
        img = img.crop((0, top, w, top + new_h))

    return img.resize((target_w, target_h), Image.Resampling.LANCZOS)


def split_grid_image(
    image_path: str,
    rows: int = 2,
    cols: int = 2,
    margin_ratio: float = 0.02
) -> list:
    """
    将网格大图（默认 2x2 四宫格）切分为 rows * cols 张子图。
    顺序：从左到右、从上到下（即：左上、右上、左下、右下）。
    margin_ratio: 自动裁掉每个小格四周的分割线/白边比例（默认 2%）。
    """
    img = Image.open(image_path).convert("RGB")
    w, h = img.size
    cell_w = w / cols
    cell_h = h / rows

    sub_images = []
    for r in range(rows):
        for c in range(cols):
            x1 = c * cell_w
            y1 = r * cell_h
            x2 = (c + 1) * cell_w
            y2 = (r + 1) * cell_h

            # 内缩去除网格白边与外框
            dx = cell_w * margin_ratio
            dy = cell_h * margin_ratio
            crop_box = (int(x1 + dx), int(y1 + dy), int(x2 - dx), int(y2 - dy))

            cell_img = img.crop(crop_box)
            processed_img = center_crop_and_resize(cell_img)
            sub_images.append(processed_img)

    return sub_images


def process_batch(
    input_files: list,
    start_id: int,
    output_dir: str = "assets/images",
    rows: int = 2,
    cols: int = 2,
    margin_ratio: float = 0.02,
    ext: str = "webp",
    json_path: str = "assets/data/hanzi_data.json"
):
    """
    批量处理一组网格图（或单图），按汉字编号顺序输出文件并更新 hanzi_data.json
    """
    os.makedirs(output_dir, exist_ok=True)
    current_id = start_id
    saved_files = []

    for file_path in input_files:
        if not os.path.exists(file_path):
            print(f"[跳过] 文件不存在: {file_path}")
            continue

        if rows == 1 and cols == 1:
            img = Image.open(file_path).convert("RGB")
            # 单图去除外圈可能的画框白边
            w, h = img.size
            dx, dy = int(w * margin_ratio), int(h * margin_ratio)
            img = img.crop((dx, dy, w - dx, h - dy))
            sub_imgs = [center_crop_and_resize(img)]
        else:
            sub_imgs = split_grid_image(file_path, rows=rows, cols=cols, margin_ratio=margin_ratio)

        for sub_img in sub_imgs:
            hanzi_id_str = f"{current_id:04d}"
            out_filename = f"{hanzi_id_str}.{ext}"
            out_path = os.path.join(output_dir, out_filename)

            if ext.lower() == "webp":
                sub_img.save(out_path, "WEBP", quality=85)
            else:
                sub_img.save(out_path, quality=90)

            saved_files.append((hanzi_id_str, out_path))
            print(f"[完成] {file_path} -> {out_path} ({TARGET_WIDTH}x{TARGET_HEIGHT})")
            current_id += 1

    # 如果存在 hanzi_data.json，自动回写 imageAsset 字段
    if json_path and os.path.exists(json_path):
        with open(json_path, "r", encoding="utf-8") as f:
            data = json.load(f)

        id_to_asset = {hid: f"assets/images/{hid}.{ext}" for hid, _ in saved_files}
        updated_count = 0
        for item in data:
            if item.get("id") in id_to_asset:
                item["imageAsset"] = id_to_asset[item["id"]]
                updated_count += 1

        with open(json_path, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"[更新数据] 已同步更新 {json_path} 中 {updated_count} 个汉字的 imageAsset 字段。")

    return saved_files


if __name__ == "__main__":
    parser = argparse.ArgumentParser(description="裁剪多宫格汉字配图并按汉字编号重命名")
    parser.add_argument("inputs", nargs="+", help="输入的图片路径（支持多张四宫格图片按顺序传入）")
    parser.add_argument("--start-id", type=int, required=True, help="起始汉字编号（如 61 代表从 0061 开始命名）")
    parser.add_argument("--rows", type=int, default=2, help="网格行数（默认 2，单图填 1）")
    parser.add_argument("--cols", type=int, default=2, help="网格列数（默认 2，单图填 1）")
    parser.add_argument("--margin", type=float, default=0.02, help="去除边框留白比例（默认 0.02 即 2%%）")
    parser.add_argument("--output-dir", default="assets/images", help="输出目录（默认 assets/images）")
    parser.add_argument("--ext", default="webp", choices=["webp", "png", "jpg"], help="输出图片格式（默认 webp）")
    parser.add_argument("--json", default="assets/data/hanzi_data.json", help="hanzi_data.json 路径")

    args = parser.parse_args()
    process_batch(
        input_files=args.inputs,
        start_id=args.start_id,
        output_dir=args.output_dir,
        rows=args.rows,
        cols=args.cols,
        margin_ratio=args.margin,
        ext=args.ext,
        json_path=args.json
    )
