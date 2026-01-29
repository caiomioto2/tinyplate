#!/bin/bash
set -e

# /render-frame skill - Quickly render Remotion frames for visual inspection
# Usage: render-frame.sh <composition-id> <frame-numbers...>

# Colors for output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[1;33m'
NC='\033[0m' # No Color

# Parse arguments
if [ $# -lt 2 ]; then
    echo -e "${RED}Error: Missing arguments${NC}"
    echo "Usage: /render-frame <composition-id> <frame-numbers...>"
    echo "Example: /render-frame TradeNarrative-PLTR-Profit 100"
    exit 1
fi

COMPOSITION_ID="$1"
shift
FRAMES=("$@")

# Validate environment
if [ -z "$REMOTION_PROJECT_PATH" ]; then
    echo -e "${RED}Error: REMOTION_PROJECT_PATH environment variable is not set${NC}"
    echo "Set it to your Remotion project root, e.g.:"
    echo "  export REMOTION_PROJECT_PATH=/path/to/remotion/trade-visuals"
    exit 1
fi

if [ ! -d "$REMOTION_PROJECT_PATH" ]; then
    echo -e "${RED}Error: REMOTION_PROJECT_PATH does not exist: $REMOTION_PROJECT_PATH${NC}"
    exit 1
fi

if [ ! -f "$REMOTION_PROJECT_PATH/remotion.config.ts" ] && [ ! -f "$REMOTION_PROJECT_PATH/remotion.config.js" ]; then
    echo -e "${RED}Error: No remotion.config found in $REMOTION_PROJECT_PATH${NC}"
    exit 1
fi

cd "$REMOTION_PROJECT_PATH"

# Function to check if server is running
check_server() {
    for port in 3000 3001 3002; do
        if curl -s --max-time 1 "http://localhost:$port" > /dev/null 2>&1; then
            echo $port
            return 0
        fi
    done
    return 1
}

# Function to wait for server to be ready
wait_for_server() {
    local max_attempts=60  # 30 seconds
    local attempt=0
    while [ $attempt -lt $max_attempts ]; do
        if check_server > /dev/null 2>&1; then
            return 0
        fi
        sleep 0.5
        ((attempt++))
    done
    return 1
}

# Check if server is running, start if not
SERVER_PORT=$(check_server) || true
if [ -z "$SERVER_PORT" ]; then
    echo -e "${YELLOW}Starting Remotion dev server...${NC}"
    npm run dev > /dev/null 2>&1 &
    SERVER_PID=$!

    if wait_for_server; then
        SERVER_PORT=$(check_server)
        echo -e "${GREEN}Server started on port $SERVER_PORT${NC}"
    else
        echo -e "${RED}Error: Could not start Remotion dev server after 30s${NC}"
        kill $SERVER_PID 2>/dev/null || true
        exit 1
    fi
else
    echo "Using existing server on port $SERVER_PORT"
fi

# Get available compositions
echo "Fetching compositions..."
COMPOSITIONS_RAW=$(npx remotion compositions src/index.ts 2>&1)

# Extract just the composition lines (format: "Name     FPS     WxH     Frames (Duration)")
# Filter out progress bars and other output
COMPOSITIONS_OUTPUT=$(echo "$COMPOSITIONS_RAW" | grep -E '^[A-Za-z].*[0-9]+x[0-9]+.*[0-9]+ \(' || true)

# Check if composition exists (match at the start of the line)
COMP_LINE=$(echo "$COMPOSITIONS_OUTPUT" | grep -E "^${COMPOSITION_ID}[[:space:]]" || true)
if [ -z "$COMP_LINE" ]; then
    echo -e "${RED}Error: Composition '$COMPOSITION_ID' not found${NC}"
    echo ""
    echo "Available compositions:"
    echo "$COMPOSITIONS_OUTPUT" | awk '{print "  " $1}'
    exit 1
fi

# Parse composition info from the line
# Format: "TradeNarrative-PLTR-Profit    30      1080x1920      450 (15.00 sec)"
FPS=$(echo "$COMP_LINE" | awk '{print $2}')
DIMENSIONS=$(echo "$COMP_LINE" | awk '{print $3}')
WIDTH=$(echo "$DIMENSIONS" | cut -d'x' -f1)
HEIGHT=$(echo "$DIMENSIONS" | cut -d'x' -f2)
DURATION=$(echo "$COMP_LINE" | awk '{print $4}')

# Default duration if we couldn't parse it
if [ -z "$DURATION" ] || [ "$DURATION" = "0" ]; then
    DURATION=450
fi
if [ -z "$WIDTH" ]; then WIDTH=1080; fi
if [ -z "$HEIGHT" ]; then HEIGHT=1920; fi

# Validate frame numbers
for frame in "${FRAMES[@]}"; do
    if ! [[ "$frame" =~ ^[0-9]+$ ]]; then
        echo -e "${RED}Error: Invalid frame number '$frame' - must be a positive integer${NC}"
        exit 1
    fi
    if [ "$frame" -ge "$DURATION" ]; then
        echo -e "${RED}Error: Frame $frame is out of range for composition '$COMPOSITION_ID' (valid range: 0-$((DURATION-1)))${NC}"
        exit 1
    fi
done

# Generate output directory and timestamp
TIMESTAMP=$(date +"%Y-%m-%d_%H%M%S")
OUTPUT_DIR="${SCRATCHPAD_DIR:-/tmp/claude-frames}"
mkdir -p "$OUTPUT_DIR"

# Render frames in parallel
echo "Rendering ${#FRAMES[@]} frame(s)..."
PIDS=()
OUTPUT_FILES=()

for frame in "${FRAMES[@]}"; do
    OUTPUT_FILE="$OUTPUT_DIR/${TIMESTAMP}_${COMPOSITION_ID}_${frame}.png"
    OUTPUT_FILES+=("$OUTPUT_FILE")

    echo "  Rendering frame $frame..."
    npx remotion still src/index.ts "$COMPOSITION_ID" "$OUTPUT_FILE" --frame "$frame" --overwrite > /dev/null 2>&1 &
    PIDS+=($!)
done

# Wait for all renders to complete
FAILED=0
for i in "${!PIDS[@]}"; do
    if ! wait "${PIDS[$i]}"; then
        echo -e "${RED}Failed to render frame ${FRAMES[$i]}${NC}"
        FAILED=1
    fi
done

if [ "$FAILED" -eq 1 ]; then
    echo -e "${RED}Error: Some frames failed to render${NC}"
    exit 1
fi

# Output results
echo ""
if [ "${#FRAMES[@]}" -eq 1 ]; then
    echo -e "${GREEN}Rendered: ${OUTPUT_FILES[0]}${NC}"
    echo "  Dimensions: ${WIDTH}x${HEIGHT}"
    echo "  Composition: $COMPOSITION_ID"
    echo "  Frame: ${FRAMES[0]} of $DURATION"
else
    echo -e "${GREEN}Rendered ${#FRAMES[@]} frames:${NC}"
    for i in "${!OUTPUT_FILES[@]}"; do
        echo "  - ${OUTPUT_FILES[$i]} (frame ${FRAMES[$i]})"
    done
    echo "  Dimensions: ${WIDTH}x${HEIGHT}"
fi

echo ""
echo "Use the Read tool to view the rendered image(s)."
