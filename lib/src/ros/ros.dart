library upcom_api.lib.src.ros.ros;

import 'dart:async';
import 'dart:io';

/// A class for static ROS methods that don't require instantiation of
/// any classes as objects.
abstract class Ros {
  static void startRosCore() {
    String buildCommand = '/opt/ros/indigo/setup.bash && roscore';
    Process.start('bash', ['-c', '. $buildCommand'], runInShell: true);
  }

  /// Lists currently running nodes.
  ///
  /// Equivalent to running 'rosnode list'.
  static Future<List> listRunningNodes() {
    Completer c = new Completer();

    String buildCommand = '/opt/ros/indigo/setup.bash && rosnode list';
    Process.run('bash', ['-c', '. $buildCommand'], runInShell: true).then((ProcessResult result) {
      List<String> nodesList = result.stdout.split('\n');
      // Splitting on newline yields an empty element in the last spot.
      nodesList.removeLast();
      c.complete(nodesList);
    });

    return c.future;
  }
}