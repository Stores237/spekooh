import 'package:flutter/widgets.dart';

/// Every grid in this app was designed for a mobile column count (2, 3, or
/// 4 columns). On the web build, viewport width isn't capped to a phone —
/// a fixed crossAxisCount there lets cells stretch unbounded as the window
/// widens, ballooning card height (GridView.count height = cellWidth /
/// childAspectRatio) until most of a desktop screen is empty card padding.
/// Scaling the column count with width keeps individual cells close to
/// their designed mobile size at any viewport.
int responsiveCrossAxisCount(BuildContext context, int mobileCount) {
  final width = MediaQuery.sizeOf(context).width;
  if (width >= 900) return mobileCount + 2;
  if (width >= 600) return mobileCount + 1;
  return mobileCount;
}
