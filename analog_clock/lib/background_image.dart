class BackgroundImage {
  static final rowCount = 6;
  static final columnCount = 10;
  final _assetIndex;
  final _maxIndex = rowCount * columnCount;

  List _slices = List();

  BackgroundImage(this._assetIndex) {
    // Create array
    for (var i = 0; i < rowCount; i++) {
      _slices.add(List(columnCount));
      for (var j = 0; j < columnCount; j++) {
        _slices[i][j] =
            'assets/images/backgrounds/$_assetIndex/slice_${i}_$j.jpg';
      }
    }
  }

  String getSliceNameAt(int index) {
    if ((index < 0) || (index >= _maxIndex)) {
      index = 0;
    }

    final imageRow = index ~/ columnCount;
    final imageColumn = index % columnCount;

    return _slices[imageRow][imageColumn];
  }
}
