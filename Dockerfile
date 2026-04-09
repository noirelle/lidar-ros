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
    unzip \
    && rm -rf /var/lib/apt/lists/*

# Install YDLidar-SDK from zip bundle
COPY bundles/YDLidar-SDK_bundle.zip /tmp/
RUN unzip /tmp/YDLidar-SDK_bundle.zip -d /tmp/ && \
    mkdir -p /tmp/YDLidar-SDK/build && \
    cd /tmp/YDLidar-SDK/build && \
    cmake .. && \
    make && \
    make install && \
    rm -rf /tmp/YDLidar-SDK /tmp/YDLidar-SDK_bundle.zip

# Build YDLIDAR ROS 2 Driver from zip bundle
COPY bundles/ydlidar_ros2_bundle.zip /app/ros2_ws/src/
RUN unzip /app/ros2_ws/src/ydlidar_ros2_bundle.zip -d /app/ros2_ws/src/ && \
    rm /app/ros2_ws/src/ydlidar_ros2_bundle.zip

# Copy launch and demo files
COPY launch /app/ros2_ws/launch
COPY demo /app/demo

WORKDIR /app/ros2_ws
RUN /bin/bash -c "source /opt/ros/humble/setup.bash && colcon build"

EXPOSE 9090 8000

ENV TURTLEBOT3_MODEL=burger
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc
RUN echo "source /app/ros2_ws/install/setup.bash" >> ~/.bashrc

# Set the default command to launch everything
CMD ["/bin/bash", "-c", "source /app/ros2_ws/install/setup.bash && ros2 launch /app/ros2_ws/launch/main_launch.py"]