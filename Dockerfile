FROM ros:humble

RUN apt update && apt install -y \
    ros-humble-slam-toolbox \
    ros-humble-rosbridge-suite \
    python3-colcon-common-extensions \
    python3-pip \
    && rm -rf /var/lib/apt/lists/*

ENV TURTLEBOT3_MODEL=burger
RUN echo "source /opt/ros/humble/setup.bash" >> ~/.bashrc

WORKDIR /app