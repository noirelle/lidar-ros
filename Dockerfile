FROM ros:humble

RUN apt update && apt install -y \
    build-essential \
    cmake \
    pkg-config \
    git \
    ros-humble-slam-toolbox \
    ros-humble-rosbridge-suite \
    python3-colcon-common-extensions \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

# Install YDLidar-SDK (Hardcoded from local src)
COPY src/YDLidar-SDK /tmp/YDLidar-SDK
RUN mkdir -p /tmp/YDLidar-SDK/build && \
    cd /tmp/YDLidar-SDK/build && \
    cmake .. && \
    make && \
    make install && \
    rm -rf /tmp/YDLidar-SDK

# Build YDLIDAR ROS 2 Driver (Hardcoded from local src)
COPY src/ydlidar_ros2_driver /app/ros2_ws/src/ydlidar_ros2_driver
WORKDIR /app/ros2_ws
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && colcon build --symlink-install"

ENV TURTLEBOT3_MODEL=burger
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
RUN echo "source /app/ros2_ws/install/setup.bash" >> ~/.bashrc

WORKDIR /app