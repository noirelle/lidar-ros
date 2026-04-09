#!/bin/bash

# Source ROS2 humility environment
source /opt/ros/humble/setup.bash

echo "Starting ROS2 WebSocket Bridge..."
ros2 launch rosbridge_server rosbridge_websocket_launch.xml port:=9090 &
BRIDGE_PID=$!

# Check for real LIDAR driver in /app/src/
if [ -d "/app/src/sllidar_ros2" ]; then
    echo "Hardware driver found in /app/src/sllidar_ros2. Building..."
    mkdir -p /app/ros2_ws/src
    cp -r /app/src/sllidar_ros2 /app/ros2_ws/src/
    cd /app/ros2_ws
    colcon build --symlink-install
    source /app/ros2_ws/install/setup.bash
    
    echo "Starting RPLIDAR A2 Node (Hardware Mode)..."
    ros2 run sllidar_ros2 sllidar_node --ros-args -p serial_port:=/dev/ttyUSB0 -p serial_baudrate:=115200 -p frame_id:=base_scan -p angle_compensate:=true &
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
