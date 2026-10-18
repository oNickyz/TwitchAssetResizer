# Twitch Asset Resizer

A lightweight Windows utility that exports PNG images into multiple sizes commonly used for Twitch channel assets.

Keep `TwitchAssetResizer.bat` and `TwitchAssetResizer.ps1` together in the same folder. Drop a PNG onto the batch file, choose an asset category, and the script generates the selected variants in an organized output folder. It is designed for creators who want a quick, repeatable export workflow without opening an image editor for every size.

## Features

- **Drag and drop:** Drop a `.png` image onto the batch file.
- **Eight menu options:** Badges, emotes and Cheermotes, Channel Points icons, profile picture, profile banner, offline/player banner preset, information panels, or a full export package.
- **High-quality resizing:** Uses ImageMagick with the Lanczos filter when available.
- **Windows fallback:** Uses GDI+ with high-quality bicubic interpolation if ImageMagick is not installed.
- **Transparency:** Preserves alpha transparency and avoids stretching the artwork.
- **Exact canvas sizes:** For square or banner presets, the artwork is fitted proportionally and centered on a transparent canvas when needed.
- **Organized output:** Creates a dedicated export folder beside the source image. If that folder already exists, a numbered folder is created instead.
- **Basic file-size warnings:** Alerts for certain known Twitch asset limits; final files should still be checked before upload.

## Requirements

- Windows 10 or Windows 11
- A source image in PNG format
- Optional but recommended: [ImageMagick](https://imagemagick.org/)

ImageMagick is optional. If the `magick` command is available in your `PATH`, the script uses ImageMagick and Lanczos resampling automatically. Otherwise, it falls back to Windows GDI+.

## How to use

1. Download the ZIP release and extract **all files** into one folder.
2. Keep `TwitchAssetResizer.bat` and `TwitchAssetResizer.ps1` in the same folder. Do not move or delete either file.
3. Drag and drop a PNG image onto the `.bat` file.
4. Choose an asset category from the menu by entering a number from `1` to `8`.
5. Wait for the export to finish, then open the generated folder next to the original image.

If you launch the script without dragging in a file, it will ask you to enter the image path. The original image is not modified.

### Output folder

The output folder follows this naming pattern:

```text
image_name_Twitch_Exports/
```

If that folder already exists, the script creates `image_name_Twitch_Exports_2`, then `_3`, and so on, to avoid overwriting earlier exports.

## Export presets

| Menu option | Asset category | Export dimensions |
|---:|---|---|
| `1` | Subscription and Bits badges | 18×18, 36×36, 72×72 px |
| `2` | Emotes and Cheermotes | 28×28, 56×56, 112×112 px |
| `3` | Channel Points icons / reward icons | 28×28, 56×56, 112×112 px |
| `4` | Profile picture | 256×256 px |
| `5` | Profile banner | 1200×480 px |
| `6` | Offline/player banner preset | 1920×1080 px |
| `7` | Information panel | Scales proportionally to fit within 320×600 px |
| `8` | Full export package | Exports all categories above |

The full package creates subfolders for each category. All dimensions are presets implemented by this script; not every preset is a separate mandatory Twitch upload size. In particular, the 28×28, 56×56, and 112×112 emote variants are for manual upload workflows. Twitch also supports automatic resizing for eligible emote uploads.

## Image handling and quality

- The source artwork is resized proportionally; it is not stretched to fill the target dimensions.
- When a fixed canvas is required, any extra space is transparent and the image is centered.
- Lanczos resampling is used when ImageMagick is available. The built-in Windows fallback uses high-quality bicubic interpolation.
- PNG compression is enabled, but reducing dimensions does not guarantee that an image meets every file-size limit.
- Upscaling cannot restore detail that is absent from the original image.

For the best results, start with a high-resolution PNG. For emotes and badges, a transparent background and clean edges are recommended.

## Twitch requirements and references

Twitch requirements can vary by asset type and upload workflow and may change. Check the official documentation and the upload interface before publishing:

- [Subscriber Badge Guide](https://help.twitch.tv/s/article/subscriber-badge-guide)
- [Custom Bit Badges](https://help.twitch.tv/s/article/custom-bit-badges-guide)
- [Emote Formatting and Instant Emote Upload Requirements](https://help.twitch.tv/s/article/emote-guidelines)
- [Profile and account image settings](https://help.twitch.tv/s/article/twitch-account-settings)
- [Channel Page Setup and profile banner guidance](https://help.twitch.tv/s/article/channel-page-setup)
- [How to Edit Info Panels](https://help.twitch.tv/s/article/how-to-edit-info-panels)
- [Channel Points Guide for Creators](https://help.twitch.tv/s/article/channel-points-guide)

The script displays basic file-size warnings for subscription/Bits badges, information panels, and banner presets. These warnings are only checks, not a guarantee of acceptance by Twitch. Review the final dimensions, file size, and appearance before uploading.

## Limitations

- Windows batch script; not designed for macOS or Linux.
- Accepts PNG input only.
- Does not upload images to Twitch.
- Does not create animated emotes or GIFs.
- Twitch may change its requirements, so export presets may need maintenance.

## License

This project is licensed under the **MIT License**, with copyright attributed to **MEGAzLand™**. See [`LICENSE`](LICENSE) for the full license text.

The MIT License applies to this project's code. It does not grant permission to use Twitch trademarks or MEGAzLand™ branding, logos, or other brand assets as if officially affiliated or endorsed.

## Disclaimer

This is an independent community utility. It is not affiliated with, endorsed by, or officially supported by Twitch Interactive, Inc. Twitch and its related marks are trademarks of their respective owners.
