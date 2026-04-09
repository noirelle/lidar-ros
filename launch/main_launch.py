from launch import LaunchDescription
from launch.actions import IncludeLaunchDescription, DeclareLaunchArgument
from launch.launch_description_sources import PythonLaunchDescriptionSource, AnyLaunchDescriptionSource
from launch.substitutions import LaunchConfiguration, PathJoinSubstitution
from launch_ros.actions import Node
from launch_ros.substitutions import FindPackageShare
import os

def generate_launch_description():
    # Paths
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

    slam_params_path = '/app/ros2_ws/params/slam_toolbox.yaml'

    # Parameters
    params_file = DeclareLaunchArgument(
        'params_file',
        default_value=PathJoinSubstitution([
            FindPackageShare('ydlidar_ros2_driver'),
            'params',
            'X3.yaml'
        ])
    )

    return LaunchDescription([
        params_file,
        
        # 1. LiDAR Driver
        IncludeLaunchDescription(
            PythonLaunchDescriptionSource(driver_launch_path),
            launch_arguments={'params_file': LaunchConfiguration('params_file')}.items()
        ),
        
        # 2. SLAM Toolbox (Asynchronous Mapping)
        Node(
            package='slam_toolbox',
            executable='async_slam_toolbox_node',
            name='slam_toolbox',
            output='screen',
            parameters=[slam_params_path, {'use_sim_time': False}]
        ),

        # 3. Static TF for Lidar-only SLAM (Identity odom -> base_link)
        Node(
            package='tf2_ros',
            executable='static_transform_publisher',
            name='static_tf_odom_to_base',
            arguments=['0', '0', '0', '0', '0', '0', 'odom', 'base_link']
        ),

        # 4. TF Web Republisher (Required for roslibjs TFClient)
        Node(
            package='tf2_web_republisher',
            executable='tf2_web_republisher',
            name='tf2_web_republisher'
        ),

        # 5. ROSBridge WebSocket Server
        IncludeLaunchDescription(
            AnyLaunchDescriptionSource(bridge_launch_path),
            launch_arguments={'port': '9090'}.items()
        )
    ])
