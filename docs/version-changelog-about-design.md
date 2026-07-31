# Version & Changelog on About Page — Design

**Date:** 2026-07-31
**Status:** approved

## Goal

Replace the hardcoded about-page text on the main menu with a dynamic version number
(injected from the git tag by CI) and a scrollable changelog read from a bundled file.

## Components

### 1. VersionData autoload (`autoload/version_data.gd`)

- `version: String = "dev"` — CI replaces `"dev"` with the actual tag name via `sed`
- `changelog: String` — loaded at ready from `res://CHANGELOG.md`
- Falls back to empty string if the file is missing

### 2. CHANGELOG.md (project root)

- Hand-maintained markdown file
- Bundled into the pck by the default `export_filter = "all_resources"`

### 3. CI injection step (`export.yml`)

Added before the Export steps:

```bash
TAG=${GITHUB_REF#refs/tags/}
sed -i "s/\"dev\"/\"$TAG\"/" autoload/version_data.gd
```

### 4. About page update (`scenes/menu/MainMenu.gd`)

- Replace the `_create_info_screen` call for `"about"` with a custom
  `_create_about_screen` method
- Shows the version number as a gold title
- Shows the changelog in a `RichTextLabel` inside a `ScrollContainer`
- If the changelog is empty or missing, show a fallback message

### 5. ExportManifest update

- Reference `VersionData` to prevent tree-shaking

## Files touched

| File | Action |
|------|--------|
| `autoload/version_data.gd` | Create |
| `project.godot` | Register autoload `VersionData` |
| `CHANGELOG.md` | Create |
| `scenes/menu/MainMenu.gd` | Replace hardcoded about with `_create_about_screen` |
| `autoload/ExportManifest.gd` | Add VersionData reference |
| `.github/workflows/export.yml` | Add inject-version step |

## Edge cases

- **Tag missing (manual dispatch):** `version` stays `"dev"` — clearly indicates a dev build
- **CHANGELOG.md missing:** show placeholder text "暂无更新日志"
- **File read failure on exported build:** `FileAccess.get_file_as_string` works with
  bundled resources; if it fails fall back to `ResourceLoader`
