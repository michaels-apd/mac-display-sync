#!/bin/bash

SCRIPT_DIR="$(dirname "$0")"

BRIGHTNESS=${1:-35}

if [[ ! "$BRIGHTNESS" =~ ^[0-9]+$ ]] || [ "$BRIGHTNESS" -lt 0 ] || [ "$BRIGHTNESS" -gt 100 ]; then
    echo "Usage: sync-brightness.sh <0-100>"
    exit 1
fi

clamp() {
    local val=$1
    (( val < 0 )) && val=0
    (( val > 100 )) && val=100
    echo $val
}

# Adjust multipliers based on brightness level
if [ "$BRIGHTNESS" -le 50 ]; then
    # Low brightness: Studio needs more boost
    STUDIO_MULT=1.30
    LG_MULT=0.70
else
    # High brightness: narrow the gap to avoid clipping
    STUDIO_MULT=1.1
    LG_MULT=0.9
fi

# Calculate brightness values
STUDIO_VAL=$(clamp $(printf "%.0f" $(echo "$BRIGHTNESS * $STUDIO_MULT" | bc)))
LG_VAL=$(clamp $(printf "%.0f" $(echo "$BRIGHTNESS * $LG_MULT" | bc)))

echo "Syncing displays to $BRIGHTNESS%"

# Dynamically detect and control displays
STUDIO_COUNT=0
LG_COUNT=0

# Get display information and process each display
while read -r line; do
    if [[ $line =~ ^\[([0-9]+)\].*StudioDisplay ]]; then
        # Found Studio Display
        STUDIO_COUNT=$((STUDIO_COUNT + 1))
        echo "  Studio Display: $STUDIO_VAL%"
        "$SCRIPT_DIR/bin/apple-brightness" "$STUDIO_VAL"
    elif [[ $line =~ ^\[([0-9]+)\].*LG\ UltraFine ]]; then
        # Found LG UltraFine
        DISPLAY_NUM="${BASH_REMATCH[1]}"
        LG_COUNT=$((LG_COUNT + 1))
        echo "  LG UltraFine $LG_COUNT: $LG_VAL%"
        m1ddc display "$DISPLAY_NUM" set luminance "$LG_VAL" > /dev/null
    fi
done < <(m1ddc display list)

# Summary
if [ $STUDIO_COUNT -eq 0 ] && [ $LG_COUNT -eq 0 ]; then
    echo "No supported displays found"
fi