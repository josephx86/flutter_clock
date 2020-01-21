// Copyright 2019 The Chromium Authors. All rights reserved.
// Use of this source code is governed by a BSD-style license that can be
// found in the LICENSE file.

import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';
import 'package:flutter_clock_helper/model.dart';
import 'package:intl/intl.dart';
import 'package:vector_math/vector_math_64.dart' show radians;

import 'background_image.dart';
import 'drawn_hand.dart';

/// Total distance traveled by a second or a minute hand, each second or minute,
/// respectively.
final radiansPerTick = radians(360 / 60);

/// Total distance traveled by an hour hand, each hour, in radians.
final radiansPerHour = radians(360 / 12);

/// Max number of slices
final maxSliceCount = BackgroundImage.rowCount * BackgroundImage.columnCount;

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
  final _containerKey = GlobalKey();
  var _now = DateTime.now();
  var _temperature = '';
  var _temperatureRange = '';
  WeatherCondition _weatherCondition;
  var _location = '';
  Timer _timer;
  int _backgroundImageIndex;
  bool _assetsLoaded, _firstScramble;

  // Default is 28
  double _scaledFontSize = 28;
  double _clockDiameter = 0;

  List _backgroundImages;
  final _slices = List(maxSliceCount);
  final _orderedSlices = List(maxSliceCount);
  var _fullBackgroundAssetName = 'assets/images/backgrounds/0/background.jpg';

  @override
  void initState() {
    super.initState();
    widget.model.addListener(_updateModel);
    // Set the initial values.
    _updateTime();
    _updateModel();

    _assetsLoaded = false;
    _firstScramble = true;
    _loadAssets();

    WidgetsBinding.instance.addPostFrameCallback((_) => _calculateFontSize());
  }

  void _loadAssets() async {
    await Future.delayed(Duration(milliseconds: 400), () {
      _backgroundImages = [
        BackgroundImage(0),
        BackgroundImage(1),
        BackgroundImage(2),
        BackgroundImage(3),
        BackgroundImage(4),
        BackgroundImage(5),
      ];

      _backgroundImageIndex = -1;
      _nextBackgroundImage();

      _scrambleSlices();
      return null;
    });
  }

  void _nextBackgroundImage() {
    if (_assetsLoaded || _firstScramble) {
      _backgroundImageIndex++;
      if (_backgroundImageIndex >= _backgroundImages.length) {
        _backgroundImageIndex = 0;
      }

      _fullBackgroundAssetName =
          'assets/images/backgrounds/$_backgroundImageIndex/background.jpg';
      for (var i = 0; i < maxSliceCount; i++) {
        _orderedSlices[i] =
            _backgroundImages[_backgroundImageIndex].getSliceNameAt(i);
      }

      _scrambleSlices();
    }
  }

  void _scrambleSlices() {
    final ununsedIndices = List();
    for (var i = 0; i < maxSliceCount; i++) {
      ununsedIndices.add(i);
    }

    var prng = Random(DateTime.now().microsecond);
    int count = 0;
    while (ununsedIndices.length > 0) {
      var index = prng.nextInt(maxSliceCount);
      if (ununsedIndices.contains(index)) {
        ununsedIndices.remove(index);
        var assetName = _orderedSlices[index];
        _slices[count] = assetName;
        count++;
      }
    }

    _assetsLoaded = true;
    _firstScramble = false;
  }

  void _calculateFontSize() {
    RenderBox renderBox = _containerKey.currentContext.findRenderObject();
    setState(() {
      _scaledFontSize = 0.04 * renderBox.size.shortestSide;
      _clockDiameter = 0.95 * renderBox.size.shortestSide;
    });
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

  String _getConditionAsset() {
    // In production use real API to determine sunset/sunrise time.
    // For Flutter Clock contest, assume sun rises at 6a.m. and sets at 6p.m.
    var isDaylight = (_now.hour >= 6) && (_now.hour < 18);

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

    return 'assets/images/weathericons/$conditionAsset';
  }

  void _arrangeSlices() {
    if (_assetsLoaded) {
      // Determine if slice at index is supposed to be there.
      final index = _now.second;
      final String correctSlice = _orderedSlices[index];
      final String misplacedSlice = _slices[index];
      final index2 = _slices.indexOf(correctSlice);
      final mustReplace = (correctSlice.compareTo(misplacedSlice) != 0);
      if (mustReplace) {
        // Save misplaced slice name and put correct slice name in place.
        _slices[index] = correctSlice;

        // Wherever the correct slice came from, put misplaced slice there.
        _slices[index2] = misplacedSlice;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final constrastColor = Color.fromARGB(0xaa, 0, 0, 0);
    final sideWidgetsMargins = EdgeInsets.all(8);
    final time = DateFormat.Hms().format(DateTime.now());

    var conditionAsset = _getConditionAsset();

    // Process background slices
    if (_now.second == 0) {
      _nextBackgroundImage();
    }

    _arrangeSlices();

    return Semantics.fromProperties(
      properties: SemanticsProperties(
        label: 'Analog clock with time $time',
        value: time,
      ),
      child: Container(
        key: _containerKey,
        decoration: BoxDecoration(
          image: DecorationImage(
            image: AssetImage(_fullBackgroundAssetName),
            fit: BoxFit.cover,
          ),
        ),
        child: DefaultTextStyle(
          style: TextStyle(
            fontFamily: 'Comfortaa',
            color: Colors.white,
            fontSize: _scaledFontSize,
          ),
          child: Stack(
            children: [
              _assetsLoaded
                  ? Container(
                      width: double.infinity,
                      height: double.infinity,
                      child: GridView.count(
                        crossAxisCount: 10,
                        children: _slices
                            .asMap()
                            .map((i, assetName) {
                              final img = AnimatedOpacity(
                                opacity: (i <= _now.second) ? 0.0 : 1.0,
                                duration: Duration(milliseconds: 800),
                                child: Image.asset(assetName),
                              );
                              return MapEntry(i, img);
                            })
                            .values
                            .toList(),
                      ),
                    )
                  : Positioned(
                      left: 0,
                      top: 0,
                      child: Text(
                        'Loading assets...',
                      ),
                    ),
              Center(
                child: Container(
                  decoration: BoxDecoration(
                      image: DecorationImage(
                    image: AssetImage('assets/images/ring.png'),
                    fit: BoxFit.cover,
                  )),
                  width: _clockDiameter,
                  height: _clockDiameter,
                ),
              ),

              // Hours hand
              DrawnHand(
                color: Colors.black,
                thickness: 8,
                size: 0.45,
                angleRadians: _now.hour * radiansPerHour +
                    (_now.minute / 60) * radiansPerHour,
              ),

              // Minutes hand
              DrawnHand(
                color: Colors.black,
                thickness: 4,
                size: 0.65,
                angleRadians: _now.minute * radiansPerTick,
              ),

              // Seconds hand
              DrawnHand(
                color: Colors.red,
                thickness: 2,
                size: 0.85,
                angleRadians: _now.second * radiansPerTick,
              ),

              Positioned(
                left: 0,
                bottom: 0,
                child: Container(
                  padding: sideWidgetsMargins,
                  color: constrastColor,
                  child: Text(_location),
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
                          fontSize: _scaledFontSize + 10,
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
