import rclpy
from rclpy.node import Node
from sensor_msgs.msg import LaserScan
import math
import time
import random

class FakeLidar(Node):
    def __init__(self):
        super().__init__('fake_lidar')
        self.publisher_ = self.create_publisher(LaserScan, 'scan', 10)
        timer_period = 0.1  # 10Hz
        self.timer = self.create_timer(timer_period, self.timer_callback)
        self.counter = 0

    def timer_callback(self):
        msg = LaserScan()
        msg.header.stamp = self.get_clock().now().to_msg()
        msg.header.frame_id = 'base_scan'
        
        # 360 degrees, 1 degree resolution
        msg.angle_min = 0.0
        msg.angle_max = 2.0 * math.pi
        msg.angle_increment = math.pi / 180.0
        msg.time_increment = 0.0
        msg.scan_time = 0.1
        msg.range_min = 0.12
        msg.range_max = 10.0

        ranges = []
        # Fake rectangular room boundaries (x in [-3, 3], y in [-2.5, 2.5])
        # Plus a dynamic moving object
        for i in range(360):
            angle = i * msg.angle_increment
            r = 10.0 # initialize with max range
            
            # Wall distances
            if math.cos(angle) > 0:
                r = min(r, 3.0 / math.cos(angle)) # Right wall x = 3
            elif math.cos(angle) < 0:
                r = min(r, -3.0 / math.cos(angle)) # Left wall x = -3
                
            if math.sin(angle) > 0:
                r = min(r, 2.5 / math.sin(angle)) # Top wall y = 2.5
            elif math.sin(angle) < 0:
                r = min(r, -2.5 / math.sin(angle)) # Bottom wall y = -2.5
            
            # Add a moving object (e.g., someone walking in a circle)
            obj_x = 1.5 * math.cos(self.counter * 0.05)
            obj_y = 1.5 * math.sin(self.counter * 0.05)
            obj_radius = 0.4
            
            dist_to_obj = math.hypot(obj_x, obj_y)
            angle_to_obj = math.atan2(obj_y, obj_x)
            
            # Check if ray hits the object
            angle_diff = math.atan2(math.sin(angle - angle_to_obj), math.cos(angle - angle_to_obj))
            if abs(angle_diff) < math.asin(obj_radius / dist_to_obj):
                # Approximate distance to object surface
                hit_dist = dist_to_obj - math.sqrt(abs(obj_radius**2 - (dist_to_obj * math.sin(angle_diff))**2))
                if hit_dist > 0:
                    r = min(r, hit_dist)

            # Add realistic sensor noise
            r += random.uniform(-0.03, 0.03)
            
            # Clip between min and max
            r = max(msg.range_min, min(r, msg.range_max))
            ranges.append(r)

        msg.ranges = ranges
        
        self.publisher_.publish(msg)
        self.get_logger().info(f'Publishing fake lidar data (seq {self.counter})')
        self.counter += 1

def main(args=None):
    rclpy.init(args=args)
    fake_lidar = FakeLidar()
    
    try:
        rclpy.spin(fake_lidar)
    except KeyboardInterrupt:
        pass
    
    fake_lidar.destroy_node()
    rclpy.shutdown()

if __name__ == '__main__':
    main()
