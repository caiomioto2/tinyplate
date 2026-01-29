# /remotion - Remotion Development Skill for Claude Code

A Claude Code skill for quickly rendering Remotion composition frames for visual inspection. Replaces the slow Chrome-based workflow (30-60s) with direct rendering (3-5s).

## Installation

1. Clone this repo to your Claude skills directory:
   ```bash
   git clone <repo-url> ~/.claude/skills/remotion
   ```

2. Make the script executable:
   ```bash
   chmod +x ~/.claude/skills/remotion/render-frame.sh
   ```

3. Set the required environment variable (add to your shell profile):
   ```bash
   export REMOTION_PROJECT_PATH="/path/to/your/remotion/project"
   ```

4. Add the skill permission to your project's `.claude/settings.local.json`:
   ```json
   {
     "permissions": {
       "allow": [
         "Skill(remotion)"
       ]
     }
   }
   ```

## Usage

```bash
# Single frame
/render-frame <composition-id> <frame-number>

# Multiple frames (rendered in parallel)
/render-frame <composition-id> <frame1> <frame2> <frame3> ...
```

### Examples

```bash
# Render frame 100
/render-frame MyComposition 100

# Render key frames for review
/render-frame MyComposition 0 150 300 449

# Different composition
/render-frame AnotherComposition 225
```

## Output

Frames are saved to `/tmp/claude-frames/` with timestamped filenames:
```
/tmp/claude-frames/2024-01-24_143052_MyComposition_100.png
```

After rendering, use Claude's Read tool to view the images.

## Features

- **Auto-detects running dev server** on ports 3000, 3001, 3002
- **Auto-starts server** if not running (with polling until ready)
- **Validates composition IDs** and lists available compositions on error
- **Validates frame ranges** and shows valid range on error
- **Parallel rendering** for multiple frames
- **Progress logging** for visibility into what's happening

## Requirements

- A Remotion project with `remotion.config.ts`
- Node.js and npm
- `REMOTION_PROJECT_PATH` environment variable set

## Performance

| Scenario | Time |
|----------|------|
| Single frame, server running | ~3-5 seconds |
| Single frame, cold start | ~10-15 seconds |
| 4 frames parallel, server running | ~5-8 seconds |

## License

MIT
