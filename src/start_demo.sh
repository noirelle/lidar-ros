#!/bin/bash

# Source ROS2 humility environment
source /opt/ros/humble/setup.bash

echo "Starting ROS2 WebSocket Bridge..."
ros2 launch rosbridge_server rosbridge_websocket_launch.xml port:=9090 &
BRIDGE_PID=$!

# Check for real LIDAR driver in /app/src/
if [ -d "/app/src/ydlidar_ros2_driver" ]; then
    echo "YDLIDAR driver found. Setting up workspace..."
    rm -rf /app/ros2_ws
    mkdir -p /app/ros2_ws/src
    cp -r /app/src/ydlidar_ros2_driver /app/ros2_ws/src/
    
    echo "--- Debug: Workspace Structure ---"
    ls -F /app/ros2_ws/src/ydlidar_ros2_driver/package.xml
    echo "--- End Debug ---"
    
    cd /app/ros2_ws
    colcon build --symlink-install --packages-select ydlidar_ros2_driver
    source /app/ros2_ws/install/setup.bash
    
    echo "Starting YDLIDAR X3 Pro Node (Hardware Mode)..."
    # Port: /dev/ttyUSB0, Baudrate: 128000, Model: X3/G4
    ros2 run ydlidar_ros2_driver ydlidar_ros2_driver_node --ros-args \
        -p port:=/dev/ttyUSB0 \
        -p baudrate:=128000 \
        -p frame_id:=base_scan \
        -p device_type:=0 \
        -p sample_rate:=4 \
        -p intensity:=false &
    LIDAR_PID=$!

    # Add a small diagnostic logger to confirm data flow in the terminal
    (while true; do 
        if [ $LIDAR_PID -gt 0 ]; then
            ros2 topic hz /scan --window 5 | head -n 2
        fi
        sleep 10
    done) &
    LOGGER_PID=$!
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
    [ ! -z "$LOGGER_PID" ] && kill $LOGGER_PID
    exit 0
}

trap cleanup SIGINT SIGTERM

echo "=================================================="
echo "      Pipeline Running Successfully!"
echo "      Web UI: http://localhost:8000"
echo "=================================================="

# Wait for all processes
wait $BRIDGE_PID $LIDAR_PID $HTTP_PID
