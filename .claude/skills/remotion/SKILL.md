---
name: remotion
description: Remotion video development toolkit. Use this skill when working with Remotion projects for rendering frames, managing compositions, or video-related tasks. Triggers on tasks involving Remotion, video rendering, frame previews, or composition development.
license: MIT
metadata:
  author: boazsobrado
  version: "1.0.0"
  tags:
    - remotion
    - video
    - rendering
    - frames
    - composition
---

# Remotion Development Toolkit

Quickly render Remotion composition frames for visual inspection during development. Replaces the slow Chrome-based workflow (30-60s) with direct rendering (3-5s).

## Tags
remotion, video, frames, preview, development

## When to Apply

Use this skill when:
- Rendering frames from Remotion compositions for visual inspection
- Debugging animation timing or composition issues
- Previewing key frames without full video render
- Validating composition appearance during development

## Usage

```bash
/render-frame <composition-id> <frame-numbers...>
```

### Examples

```bash
# Single frame
/render-frame TradeNarrative-PLTR-Profit 100

# Multiple frames (rendered in parallel)
/render-frame TradeNarrative-PLTR-Profit 0 100 200 300

# Different composition
/render-frame TradeJourney-AAPL-Profit 225
```

## Requirements

- `REMOTION_PROJECT_PATH` environment variable must be set to the Remotion project root
- Remotion dev server will be auto-started if not running

## Output

Returns paths to rendered PNG files in the scratchpad directory (`/tmp/claude-frames/`). Use the Read tool to view the images.

## Features

- **Auto-detects running dev server** on ports 3000, 3001, 3002
- **Auto-starts server** if not running (with polling until ready)
- **Validates composition IDs** and lists available compositions on error
- **Validates frame ranges** and shows valid range on error
- **Parallel rendering** for multiple frames
- **Progress logging** for visibility into what's happening

## Performance

| Scenario | Time |
|----------|------|
| Single frame, server running | ~3-5 seconds |
| Single frame, cold start | ~10-15 seconds |
| 4 frames parallel, server running | ~5-8 seconds |

## Error Handling

| Error | Output |
|-------|--------|
| Missing env var | Lists how to set `REMOTION_PROJECT_PATH` |
| Invalid composition | Lists all available composition IDs |
| Frame out of range | Shows valid frame range (e.g., 0-449) |
| Server won't start | Timeout error after 30 seconds |
