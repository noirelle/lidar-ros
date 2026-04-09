#!/bin/bash
# Simple script to serve the radar visualization

# Get the directory of the script
DIR="$( cd "$( dirname "${BASH_SOURCE[0]}" )" && pwd )"
cd "$DIR"

echo "=================================================="
echo "      LiDAR Visualization Dashboard"
echo "      Access at: http://localhost:8000"
echo "=================================================="

# Use python to serve the files
python3 -m http.server 8000
