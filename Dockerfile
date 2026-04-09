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

# Install YDLidar-SDK
RUN git clone https://github.com/YDLIDAR/YDLidar-SDK.git /tmp/YDLidar-SDK && \
    mkdir -p /tmp/YDLidar-SDK/build && \
    cd /tmp/YDLidar-SDK/build && \
    cmake .. && \
    make && \
    make install && \
    rm -rf /tmp/YDLidar-SDK

ENV TURTLEBOT3_MODEL=burger
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

WORKDIR /app