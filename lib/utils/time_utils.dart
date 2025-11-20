// lib/utils/time_utils.dart
import 'dart:math';

import 'package:flutter/material.dart';

/// Compute local time for an offset in hours (supports fractional offsets).
DateTime getLocalTimeForOffset(double offsetHours) {
  final nowUtc = DateTime.now().toUtc();
  final hours = offsetHours.truncate();
  final minutes = ((offsetHours - hours) * 60).round();
  return nowUtc.add(Duration(hours: hours, minutes: minutes));
}

/// Compute subsolar longitude (approximate) in degrees -180..180.
/// At 12:00 UTC the subsolar longitude ~ 0°.
double computeSubsolarLongitude() {
  final now = DateTime.now().toUtc();

  // Convert to Julian Day
  final year = now.year;
  final month = now.month;
  final day = now.day;
  final hour = now.hour +
      now.minute / 60.0 +
      now.second / 3600.0 +
      now.millisecond / 3600000.0;

  int a = ((14 - month) / 12).floor();
  int y = year + 4800 - a;
  int m = month + 12 * a - 3;

  double julianDay = day +
      ((153 * m + 2) / 5).floor() +
      365 * y +
      (y / 4).floor() -
      (y / 100).floor() +
      (y / 400).floor() -
      32045 +
      hour / 24.0;

  double jd = julianDay;

  // Julian centuries from J2000.0
  double t = (jd - 2451545.0) / 36525.0;

  // Mean sidereal time (deg)
  double gmst = 280.46061837 +
      360.98564736629 * (jd - 2451545.0) +
      0.000387933 * t * t -
      t * t * t / 38710000.0;

  gmst = gmst % 360.0;
  if (gmst < 0) gmst += 360.0;

  // Equation of Time (deg)
  double l0 = (280.46646 + 36000.76983 * t) % 360;
  double m0 = 357.52911 + 35999.05029 * t;
  double e = 0.016708634 - 0.000042037 * t - 0.0000001267 * t * t;

  double epsilon = 23.439291 - 0.0130042 * t;

  double yTerm = (tan(_deg2rad(epsilon / 2)) * tan(_deg2rad(epsilon / 2)));

  double eqTimeDeg = yTerm * sin(2 * _deg2rad(l0)) -
      2 * e * sin(_deg2rad(m0)) +
      4 * e * yTerm * sin(_deg2rad(m0)) * cos(_deg2rad(l0)) -
      0.5 * yTerm * yTerm * sin(4 * _deg2rad(l0)) -
      1.25 * e * e * sin(2 * _deg2rad(m0));

  double equationOfTime = eqTimeDeg * (180 / 3.1415926535); // convert radians to degrees

  // Subsolar longitude = GMST*15° - Equation of Time - hour angle
  double subsolarLon = gmst - 180 - equationOfTime;

  // Wrap into -180..180
  subsolarLon = ((subsolarLon + 540) % 360) - 180;

  return subsolarLon;
}

double _deg2rad(num d) => d * 3.1415926535 / 180.0;

