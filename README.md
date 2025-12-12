# Apple Brightness Control

A macOS utility for controlling display brightness across multiple monitors, including Apple Studio Display and external displays.

## Overview

This project provides two main tools:

1. **`apple-brightness`** - A Swift-based utility for controlling brightness on Apple displays (like Studio Display)
2. **`sync-brightness.sh`** - A shell script that synchronizes brightness across multiple displays with dynamic detection and adaptive calibration

## Building

### Using the Compile Script (Recommended)

```bash
./compile.sh
```

### Manual Compilation

Alternatively, compile the Swift utility manually:

```bash
mkdir -p bin && swiftc -o bin/apple-brightness apple-brightness.swift -framework CoreGraphics -F /System/Library/PrivateFrameworks -framework DisplayServices;
```

## Usage

### Single Display Control

Control brightness on Apple displays:

```bash
./bin/apple-brightness <0-100>
```

**Examples:**
```bash
./bin/apple-brightness 50    # Set brightness to 50%
./bin/apple-brightness 100   # Set brightness to 100%
./bin/apple-brightness 0     # Set brightness to 0% (minimum)
```

### Multi-Display Sync

Synchronize brightness across multiple displays with dynamic detection and adaptive calibration:

```bash
./sync-brightness.sh [0-100]
```

The script **automatically detects** connected displays and applies appropriate control methods. If no brightness value is provided, defaults to **35%**.

**Examples:**
```bash
./sync-brightness.sh        # Use default 35% brightness
./sync-brightness.sh 75     # Sync all displays to 75% (with adaptive multipliers)
./sync-brightness.sh 25     # Sync all displays to 25% (with adaptive multipliers)
```

## Configuration

### Dynamic Display Detection

The `sync-brightness.sh` script **automatically detects** connected displays by querying `m1ddc display list` and identifies:

- **Studio Display** - Controlled via `apple-brightness` using private DisplayServices framework
- **LG UltraFine displays** - Controlled via `m1ddc` using DDC/CI protocol

This means the script works regardless of:
- Display connection order changes
- Displays being unplugged/reconnected  
- Different numbers of displays connected
- Display ID changes after system updates

### Adaptive Display Calibration

The script uses **adaptive multipliers** that adjust based on the target brightness level to ensure optimal display matching:

#### Low Brightness (≤50%)
- **Studio Display**: 1.30x multiplier (needs more boost at low levels)
- **LG UltraFine displays**: 0.70x multiplier

#### High Brightness (>50%)
- **Studio Display**: 1.1x multiplier (narrower gap to avoid clipping)
- **LG UltraFine displays**: 0.9x multiplier

This adaptive approach provides better brightness matching across the full range compared to fixed offsets.

### Modifying Multipliers

Edit the multiplier section in `sync-brightness.sh`:

```bash
# Calculate brightness values
STUDIO_VAL=$(clamp $(printf "%.0f" $(echo "$BRIGHTNESS * $STUDIO_MULT" | bc)))
LG_VAL=$(clamp $(printf "%.0f" $(echo "$BRIGHTNESS * $LG_MULT" | bc)))

# Dynamically detect and control displays
while read -r line; do
    if [[ $line =~ ^\[([0-9]+)\].*StudioDisplay ]]; then
        "$SCRIPT_DIR/bin/apple-brightness" "$STUDIO_VAL"
    elif [[ $line =~ ^\[([0-9]+)\].*LG\ UltraFine ]]; then
        DISPLAY_NUM="${BASH_REMATCH[1]}"
        m1ddc display "$DISPLAY_NUM" set luminance "$LG_VAL" > /dev/null
    fi
done < <(m1ddc display list)
```

### Default Brightness

The script defaults to **35% brightness** when no argument is provided, which is optimal for most indoor lighting conditions.

## Requirements

- **macOS** (tested on Apple Silicon)
- **m1ddc** - Required for controlling external displays (LG UltraFine, etc.)
  - Install via: `brew install m1ddc`
- **bc** - Required for floating-point calculations in the sync script
  - Usually pre-installed on macOS

## How It Works

1. **`apple-brightness`** uses CoreGraphics and DisplayServices frameworks to directly control Apple display brightness
2. **`sync-brightness.sh`** orchestrates brightness changes across multiple displays:
   - **Dynamically detects** connected displays using `m1ddc display list`
   - **Studio Display**: Uses `bin/apple-brightness` (detected by "StudioDisplay" in name)
   - **LG UltraFine**: Uses `m1ddc` with dynamic display numbers (detected by "LG UltraFine" in name)
   - Applies **adaptive multipliers** based on brightness level for optimal matching
   - Automatically clamps values to 0-100 range to prevent invalid settings

### Dynamic Detection Process

1. Script queries `m1ddc display list` to get all connected displays
2. Parses display names to identify display types
3. Extracts dynamic display numbers for `m1ddc` commands
4. Applies appropriate control method for each display type

### Adaptive Algorithm

The sync script uses different multiplier strategies:
- **Low brightness**: Higher contrast between displays for better visibility
- **High brightness**: Reduced contrast to prevent clipping and maintain consistency

## Convenient Shell Alias

For easy access, add this alias to your `~/.zshrc` file:

```bash
alias brightness="~/Projects/AppleBrightness/sync-brightness.sh"
```

Then reload your shell:
```bash
source ~/.zshrc
```

**Usage:**
```bash
brightness        # Use default 35% brightness
brightness 60     # Set to 60% brightness
brightness 100    # Set to 100% brightness
```

## Notes

- **Dynamic display detection** - Script automatically adapts to display configuration changes
- **Robust display handling** - Works regardless of display connection order or ID changes  
- Brightness values are clamped to 0-100 range automatically
- The utility works with Apple's private DisplayServices framework
- External display control requires the `m1ddc` utility for DDC/CI communication
- Script supports any number of connected LG UltraFine displays
