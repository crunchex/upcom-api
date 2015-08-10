library upcom_api.lib.src.ros.ros;

import 'dart:io';

/// A class for static ROS methods that don't require instantiation of
/// any classes as objects.
abstract class Ros {
  static void startRosCore() {
    String buildCommand = '/opt/ros/indigo/setup.bash && roscore';
    Process.start('bash', ['-c', '. $buildCommand'], runInShell: true);
  }
}