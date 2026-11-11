import os
import json
import zipfile
import glob
import argparse
from PIL import Image

"""
python crop_hanzi_gridv2.py grid_*.jpg --start-id 461 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
python crop_hanzi_gridv2.py grid_15*.jpg --start-id 697 --rows 2 --cols 2 --output-dir assets/images --json  assets/data/hanzi_data.json
"""
TARGET_WIDTH = 526
TARGET_HEIGHT = 290
TARGET_RATIO = TARGET_WIDTH / TARGET_HEIGHT

def center_crop_and_resize(img: Image.Image) -> Image.Image:
    w, h = img.size
    current_ratio = w / h
    if current_ratio > TARGET_RATIO:
        new_w = int(h * TARGET_RATIO)
        left = (w - new_w) // 2
        img = img.crop((left, 0, left + new_w, h))
    elif current_ratio < TARGET_RATIO:
        new_h = int(w / TARGET_RATIO)
        top = (h - new_h) // 2
        img = img.crop((0, top, w, top + new_h))
    return img.resize((TARGET_WIDTH, TARGET_HEIGHT), Image.Resampling.LANCZOS)

def split_grid_image(image_path: str, rows: int = 2, cols: int = 2, margin_ratio: float = 0.025) -> list:
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
            dx = cell_w * margin_ratio
            dy = cell_h * margin_ratio
            crop_box = (int(x1 + dx), int(y1 + dy), int(x2 - dx), int(y2 - dy))
            cell_img = img.crop(crop_box)
            sub_images.append(center_crop_and_resize(cell_img))
    return sub_images

def main():
    parser = argparse.ArgumentParser(description="Crop Hanzi grid images and update metadata.")
    parser.add_argument("images", nargs="+", help="Image paths or glob patterns (e.g. grid_*.jpg)")
    parser.add_argument("--start-id", type=int, required=True, help="Starting character ID")
    parser.add_argument("--rows", type=int, default=2, help="Grid rows")
    parser.add_argument("--cols", type=int, default=2, help="Grid cols")
    parser.add_argument("--output-dir", required=True, help="Directory to save cropped webp images")
    parser.add_argument("--json", required=True, help="Path to hanzi_data.json")
    args = parser.parse_args()

    # 展开所有通配符路径
    expanded_images = []
    for pattern in args.images:
        matched = sorted(glob.glob(pattern))
        if matched:
            expanded_images.extend(matched)
        else:
            expanded_images.append(pattern)

    os.makedirs(args.output_dir, exist_ok=True)
    current_id = args.start_id
    processed_count = 0

    for img_path in expanded_images:
        if not os.path.exists(img_path):
            print(f"[跳过] 文件不存在: {img_path}")
            continue
        
        print(f"[处理中] {img_path}")
        sub_imgs = split_grid_image(img_path, rows=args.rows, cols=args.cols, margin_ratio=0.025)
        for sub_img in sub_imgs:
            hanzi_id_str = f"{current_id:04d}"
            out_path = os.path.join(args.output_dir, f"{hanzi_id_str}.webp")
            sub_img.save(out_path, "WEBP", quality=85)
            current_id += 1
            processed_count += 1

    # 更新 JSON 数据
    if os.path.exists(args.json):
        with open(args.json, "r", encoding="utf-8") as f:
            data = json.load(f)
        
        start_id = args.start_id
        end_id = current_id - 1
        for item in data:
            hid = item.get("id")
            if hid and hid.isdigit() and start_id <= int(hid) <= end_id:
                item["imageAsset"] = f"assets/images/{hid}.webp"
                item["needsReview"] = False

        with open(args.json, "w", encoding="utf-8") as f:
            json.dump(data, f, ensure_ascii=False, indent=2)
        print(f"[更新数据] 已同步更新 {args.json} 中从 {start_id:04d} 到 {end_id:04d}（共 {processed_count} 个）汉字的 imageAsset 字段。")
    else:
        print(f"[警告] JSON 文件不存在: {args.json}")

if __name__ == "__main__":
    main()