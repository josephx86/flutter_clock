// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';

import 'package:flutter_clock_helper/model.dart';
import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'container_hand.dart';
import 'drawn_hand.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// A basic analog clock.
///
/// You can do better than this!
class AnalogClock extends StatefulWidget {
  const AnalogClock(this.model);

  final ClockModel model;

  @override
  _AnalogClockState createState() => _AnalogClockState();
}

class _AnalogClockState extends State<AnalogClock> {
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  WeatherCondition _weatherCondition;
  var _location = '';
  Timer _timer;

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();
  }

  @override
  void didUpdateWidget(AnalogClock oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.model != oldWidget.model) {
      oldWidget.model.removeListener(_updateModel);
      widget.model.addListener(_updateModel);
    }
  }

  @override
  void dispose() {
    _timer?.cancel();
    widget.model.removeListener(_updateModel);
    super.dispose();
  }

  void _updateModel() {
    setState(() {
      _temperature = widget.model.temperatureString;
      _temperatureRange = '(${widget.model.low} - ${widget.model.highString})';
      _weatherCondition = widget.model.weatherCondition;
      _location = widget.model.location;
    });
  }

  void _updateTime() {
    setState(() {
      _now = DateTime.now();
      // Update once per second. Make sure to do it at the beginning of each
      // new second, so that the clock is accurate.
      _timer = Timer(
        Duration(seconds: 1) - Duration(milliseconds: _now.millisecond),
        _updateTime,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    // There are many ways to apply themes to your clock. Some are:
    //  - Inherit the parent Theme (see ClockCustomizer in the
    //    flutter_clock_helper package).
    //  - Override the Theme.of(context).colorScheme.
    //  - Create your own [ThemeData], demonstrated in [AnalogClock].
    //  - Create a map of [Color]s to custom keys, demonstrated in
    //    [DigitalClock].
    final customTheme = ThemeData(
      primaryColor: Colors.red,
      highlightColor: Colors.green,
      accentColor: Colors.yellow,
    );

    final constrastColor = Color.fromARGB(0x66, 0, 0, 0);
    final sideWidgetsMargins = EdgeInsets.all(8);
    final time = DateFormat.Hms().format(DateTime.now());

    // If there is an icon for condition, use it.

    // In production use real API to determine sunset/sunrise time.
    // For Flutter Clock contest, assume sun rises at 6a.m. and sets at 6p.m.
    var isDaylight = (_now.hour >= 6) || (_now.hour < 18);

    var conditionAsset = '';
    switch (_weatherCondition) {
      case WeatherCondition.cloudy:
        conditionAsset = isDaylight ? 'day_cloudy.png' : 'night_cloudy.png';
        break;
      case WeatherCondition.foggy:
        conditionAsset = 'foggy.png';
        break;
      case WeatherCondition.rainy:
        conditionAsset = isDaylight ? 'day_rain.png' : 'night_rainy.png';
        break;
      case WeatherCondition.snowy:
        conditionAsset = isDaylight ? 'day_snowy.png' : 'night_snowy.png';
        break;
      case WeatherCondition.sunny:
        conditionAsset = isDaylight ? 'sunny.png' : 'night_clear.png';
        break;
      case WeatherCondition.thunderstorm:
        conditionAsset =
            isDaylight ? 'day_thunderstorm.png' : 'night_thunderstorm.png';
        break;
      case WeatherCondition.windy:
        conditionAsset = 'windy.png';
        break;
    }

    conditionAsset = 'assets/images/weathericons/$conditionAsset';
    print(conditionAsset);

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage('assets/images/background.jpg'),
            fit: BoxFit.cover,
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Comfortaa',
            color: Colors.white,
          ),
          child: Stack(
            children: [
              // Example of a hand drawn with [CustomPainter].
              DrawnHand(
                color: customTheme.accentColor,
                thickness: 4,
                size: 1,
                angleRadians: _now.second * radiansPerTick,
              ),
              DrawnHand(
                color: customTheme.highlightColor,
                thickness: 16,
                size: 0.9,
                angleRadians: _now.minute * radiansPerTick,
              ),
              // Example of a hand drawn with [Container].
              ContainerHand(
                color: Colors.transparent,
                size: 0.5,
                angleRadians: _now.hour * radiansPerHour +
                    (_now.minute / 60) * radiansPerHour,
                child: Transform.translate(
                  offset: Offset(0.0, -60.0),
                  child: Container(
                    width: 32,
                    height: 150,
                    decoration: BoxDecoration(
                      color: customTheme.primaryColor,
                    ),
                  ),
                ),
              ),
              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  padding: sideWidgetsMargins,
                  color: constrastColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      SizedBox(
                        height: 8,
                      ),
                      Text(_location),
                    ],
                  ),
                ),
              ),
              Positioned(
                right: 0,
                bottom: 0,
                child: Container(
                  padding: sideWidgetsMargins,
                  color: constrastColor,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: <Widget>[
                      Image.asset(
                        conditionAsset,
                        width: 48,
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Text(
                        _temperature,
                        textAlign: TextAlign.end,
                        style: TextStyle(
                          fontSize: 22,
                        ),
                      ),
                      SizedBox(
                        height: 8,
                      ),
                      Text(
                        _temperatureRange,
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
