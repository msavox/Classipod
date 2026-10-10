import 'package:classipod/core/constants/app_palette.dart';
import 'package:classipod/core/extensions/build_context_extensions.dart';
import 'package:flutter/cupertino.dart';

/// A settings row whose value is a bar, drawn like the volume and seek bars.
///
/// Shared by every screen that builds a colour by hand, so they all adjust the
/// same way: select starts adjusting the row, the wheel then changes its value.
class ColorChannelTile extends StatelessWidget {
  final String title;
  final double fraction;
  final bool isSelected;
  final bool isAdjusting;
  final VoidCallback onTap;
  final ValueChanged<double> onDrag;

  const ColorChannelTile({
    super.key,
    required this.title,
    required this.fraction,
    required this.isSelected,
    required this.isAdjusting,
    required this.onTap,
    required this.onDrag,
  });

  @override
  Widget build(BuildContext context) {
    final bool isDarkTheme =
        CupertinoTheme.of(context).brightness == Brightness.dark;
    final Color borderColor = isDarkTheme
        ? AppPalette.darkSliderBorderColor
        : AppPalette.sliderBorderColor;
    final List<Color> inactiveGradientColors = isDarkTheme
        ? const [
            AppPalette.darkSliderGradientColor1,
            AppPalette.darkSliderGradientColor2,
          ]
        : const [
            AppPalette.inActiveSliderGradientColor1,
            AppPalette.inActiveSliderGradientColor2,
          ];
    final Color textColor = isSelected
        ? context.appInverseTextColor
        : context.appPrimaryTextColor;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        height: 30,
        width: double.infinity,
        child: DecoratedBox(
          decoration: BoxDecoration(
            border: isSelected
                ? const Border(
                    top: BorderSide(
                      color: AppPalette.selectedTileTopBorderColor,
                    ),
                    bottom: BorderSide(
                      color: AppPalette.selectedTileBottomBorderColor,
                    ),
                  )
                : null,
            gradient: isSelected
                ? const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      AppPalette.selectedTileGradientColor1,
                      AppPalette.selectedTileGradientColor2,
                    ],
                  )
                : null,
          ),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Row(
              spacing: 6,
              children: [
                if (isAdjusting)
                  Icon(
                    CupertinoIcons.arrow_left_right,
                    size: 14,
                    color: textColor,
                  ),
                Text(
                  title,
                  style: CupertinoTheme.of(context).textTheme.textStyle
                      .copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: textColor,
                      ),
                ),
                Expanded(
                  child: LayoutBuilder(
                    builder: (context, constraints) {
                      void handleDrag(Offset localPosition) =>
                          onDrag(localPosition.dx / constraints.maxWidth);

                      return GestureDetector(
                        onHorizontalDragStart: (details) =>
                            handleDrag(details.localPosition),
                        onHorizontalDragUpdate: (details) =>
                            handleDrag(details.localPosition),
                        onTapDown: (details) =>
                            handleDrag(details.localPosition),
                        child: SizedBox(
                          height: 14,
                          child: Stack(
                            children: [
                              DecoratedBox(
                                decoration: BoxDecoration(
                                  border: Border.all(color: borderColor),
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: inactiveGradientColors,
                                  ),
                                ),
                                child: const SizedBox(
                                  width: double.infinity,
                                  height: double.infinity,
                                ),
                              ),
                              Container(
                                height: 14,
                                width: fraction * constraints.maxWidth,
                                decoration: const BoxDecoration(
                                  gradient: LinearGradient(
                                    begin: Alignment.topCenter,
                                    end: Alignment.bottomCenter,
                                    colors: [
                                      AppPalette.nowProgressBarGradientColor1,
                                      AppPalette.nowProgressBarGradientColor4,
                                      AppPalette.nowProgressBarGradientColor8,
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Shows the colour being built, the way the device colour screen shows its
/// swatches.
class ColorPreviewTile extends StatelessWidget {
  final Color color;

  const ColorPreviewTile({super.key, required this.color});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(4, 6, 4, 4),
      child: SizedBox(
        height: 26,
        child: DecoratedBox(
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(width: 1.5),
          ),
          child: const SizedBox(width: double.infinity),
        ),
      ),
    );
  }
}
