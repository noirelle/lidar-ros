from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, DeclareLaunchArgument
from launch.launch_description_sources import PythonLaunchDescriptionSource, AnyLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.substitutions import FindPackageShare
import os

def generate_launch_description():
    # Paths to other launch files
    driver_launch_path = PathJoinSubstitution([
        FindPackageShare('ydlidar_ros2_driver'),
        'launch',
        'ydlidar_launch.py'
    ])
    
    bridge_launch_path = PathJoinSubstitution([
        FindPackageShare('rosbridge_server'),
        'launch',
        'rosbridge_websocket_launch.xml'
    ])

    # Parameters
    params_file = DeclareLaunchArgument(
        'params_file',
        default_value=PathJoinSubstitution([
            FindPackageShare('ydlidar_ros2_driver'),
            'params',
            'ydlidar.yaml'
        ])
    )

    return LaunchDescription([
        params_file,
        # Include LiDAR Driver
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(driver_launch_path),
            launch_arguments={'params_file': LaunchConfiguration('params_file')}.items()
        ),
        # Include ROSBridge WebSocket Server
        IncludeLaunchDescription(
            AnyLaunchDescriptionSource(bridge_launch_path),
            launch_arguments={'port': '9090'}.items()
        )
    ])
