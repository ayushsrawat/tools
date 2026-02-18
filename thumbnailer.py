#!/usr/bin/env python3
# /// script
# requires-python = ">=3.11"
# dependencies = [
#     "Pillow",
# ]
# ///

"""
Thumbnailer CLI Tool

A command-line utility to batch generate high-quality square thumbnails 
from images. It is designed to handle portrait and landscape images intelligently.

Usage:
    # install uv (curl -LsSf https://astral.sh/uv/install.sh | sh)
    uv run thumbnailer.py ~/Pictures/medalist/

    or 
    
    # Process a single file
    thumbnailer.py path/to/image.jpg

    # Process an entire directory
    thumbnailer.py path/to/directory/ --size 256

Features:
    - Smart Cropping: Uses a "Top-Center" crop strategy.
        * Portraits: Crops the top square (preserves faces).
        * Landscapes: Crops the center square.
    - Non-Destructive: Saves thumbnails in a separate `thumbs/` folder.
    - High Quality: Uses Lanczos resampling and high-quality JPEG settings.
"""

import sys
import logging
import argparse
from pathlib import Path
try:
    from PIL import Image
except ImportError:
    print("Error: 'Pillow' library not found.")
    print("Try running this with 'uv': uv run thumbnailer.py ...")
    print("Or install manually: pip install Pillow")
    sys.exit(1)

logging.basicConfig(level=logging.INFO, format='%(levelname)s: %(message)s')

VALID_EXTENSIONS = {'.jpg', '.jpeg', '.png', '.bmp', '.tiff', '.webp'}

def crop_top_square(img):
    """
    Crops the image to a square using a heuristic strategy.
    Args:
        img (PIL.Image): The source image object.
    Returns:
        PIL.Image: The cropped square image.
    - If Portrait (Tall): Crops the TOP square (preserves faces).
    - If Landscape (Wide): Crops the CENTER square.
    """
    width, height = img.size
    min_dim = min(width, height)

    if width < height:
        # Portrait: Crop Top Square (preserves faces/heads)
        left = 0
        top = 0
        right = width
        bottom = width
    else:
        # Landscape: Crop Center Square
        left = (width - min_dim) / 2
        top = 0
        right = (width + min_dim) / 2
        bottom = height

    return img.crop((left, top, right, bottom))

def create_thumbnail(src_path, dest_dir, size):
    """
    Generates and saves a thumbnail for a single image file.
    
    Args:
        src_path (Path): Path to the source image.
        dest_dir (Path): Directory where the thumbnail will be saved.
        size (tuple): Target size (width, height).
    """
    try:
        with Image.open(src_path) as img:
            # Handle standard RGB conversion
            if img.mode in ("RGBA", "P"):
                img = img.convert("RGB")

            # 1. Smart Crop (Top-biased)
            img_cropped = crop_top_square(img)
            
            # 2. Resize with High Quality Filter (Lanczos)
            img_thumb = img_cropped.resize(size, Image.Resampling.LANCZOS)
            
            # 3. Save
            output_path = dest_dir / src_path.name
            
            # quality=95 reduces compression artifacts significantly
            # optimize=True does an extra pass to compress without losing quality
            img_thumb.save(output_path, quality=95, optimize=True)
            
            logging.info(f"Generated: {output_path}")

    except Exception as e:
        logging.error(f"Failed to process {src_path.name}: {e}")

def process_directory(dir_path, size):
    thumbs_dir = dir_path / "thumbs"
    thumbs_dir.mkdir(exist_ok=True)
    logging.info(f"Output directory: {thumbs_dir}")

    count = 0
    for file_path in dir_path.iterdir():
        if file_path.is_file() and file_path.suffix.lower() in VALID_EXTENSIONS:
            create_thumbnail(file_path, thumbs_dir, size)
            count += 1
            
    if count == 0:
        logging.warning(f"No images found in {dir_path}")

def process_single_file(file_path, size):
    """Creates a thumbnail for a single file in a ./thumbs/ subdirectory."""
    thumbs_dir = file_path.parent / "thumbs"
    thumbs_dir.mkdir(exist_ok=True)
    create_thumbnail(file_path, thumbs_dir, size)

def main():
    parser = argparse.ArgumentParser(
        description="Generate high-quality square thumbnails.",
        epilog="Example: thumbnailer.py ~/Photos/Vacation/ --size 300"
    )
    parser.add_argument("path", type=str, help="Path to file or directory")
    parser.add_argument("--size", type=int, default=256, help="Size of thumbnail (default: 256)")
    
    args = parser.parse_args()
    input_path = Path(args.path)
    thumb_size = (args.size, args.size)

    if not input_path.exists():
        logging.error(f"Path not found: {input_path}")
        sys.exit(1)

    if input_path.is_dir():
        process_directory(input_path, thumb_size)
    elif input_path.is_file():
        process_single_file(input_path, thumb_size)

if __name__ == "__main__":
    main()
