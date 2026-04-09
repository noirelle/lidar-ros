#!/bin/bash

# Source ROS 2 base and our pre-built hardware workspace
source /opt/ros/humble/setup.bash
if [ -f "/app/ros2_ws/install/setup.bash" ]; then
    source /app/ros2_ws/install/setup.bash
fi

echo "Starting ROS2 WebSocket Bridge..."
ros2 launch rosbridge_server rosbridge_websocket_launch.xml port:=9090 &
BRIDGE_PID=$!

# Check for real LIDAR driver presence (now baked into the image)
if [ -d "/app/ros2_ws/src/ydlidar_ros2_driver" ]; then
    echo "Starting YDLIDAR S2 PRO Node (Hardware Mode)..."
    
    # Locked-in configuration found by the Auto-Detector
    ros2 run ydlidar_ros2_driver ydlidar_ros2_driver_node --ros-args \
        -p port:=/dev/ttyUSB0 \
        -p baudrate:=115200 \
        -p isSingleChannel:=true \
        -p lidar_type:=1 \
        -p support_motor_dtr:=true \
        -p frame_id:=base_scan \
        -p device_type:=0 \
        -p sample_rate:=4 \
        -p intensity:=false &
    LIDAR_PID=$!
else
    echo "Hardware driver NOT found. Falling back to Simulation Mode..."
    python3 /app/src/fake_lidar.py &
    LIDAR_PID=$!
fi

echo "Starting HTTP Server for Web Frontend on Port 8000..."
cd /app/src
python3 -m http.server 8000 &
HTTP_PID=$!

# Handle shutdown gracefully
cleanup() {
    echo "Shutting down..."
    kill $BRIDGE_PID
    kill $LIDAR_PID
    kill $HTTP_PID
    exit 0
}

trap cleanup SIGINT SIGTERM

echo "=================================================="
echo "      Pipeline Running Successfully!"
echo "      Web UI: http://localhost:8000"
echo "=================================================="

# Wait for all processes
wait $BRIDGE_PID $LIDAR_PID $HTTP_PID
