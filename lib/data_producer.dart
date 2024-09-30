import 'dart:math';

class DataProducer {
  static double getValue() {
    var now = DateTime.now();
    var seconds = now.microsecond + now.second * 1000;
    return 100 * sin((seconds / 60000.0 * pi));
  }
}