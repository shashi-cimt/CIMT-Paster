import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../utils/fonts.dart';

class CommonAppBar extends StatelessWidget implements PreferredSizeWidget {
  final dynamic title; // Can be String or Widget
  final bool showBackButton;
  final VoidCallback? onBackPressed;
  final List<Widget>? actions;
  final PreferredSizeWidget? bottom;
  final Color? backgroundColor;
  final bool centerTitle;
  final double elevation;
  final double? titleSpacing;

  const CommonAppBar({
    super.key,
    required this.title,
    this.showBackButton = true,
    this.onBackPressed,
    this.actions,
    this.bottom,
    this.backgroundColor,
    this.centerTitle = false,
    this.elevation = 0,
    this.titleSpacing = 0,
  });

  @override
  Size get preferredSize => Size.fromHeight(
        kToolbarHeight + (bottom?.preferredSize.height ?? 0.0),
      );

  @override
  Widget build(BuildContext context) {
    Widget titleWidget;
    if (title is Widget) {
      titleWidget = title as Widget;
    } else {
      titleWidget = Text(
        (title ?? '').toString(),
        style: const TextStyle(
          color: Colors.white,
          fontWeight: FontWeight.w600,
          fontSize: 18,
          letterSpacing: 0.5,
          fontFamily: 'Roboto',
        ),
      );
    }

    return AppBar(
      elevation: elevation,
      backgroundColor: backgroundColor ?? Font.primaryColor,
      systemOverlayStyle: const SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness: Brightness.light,
        statusBarBrightness: Brightness.dark,
      ),
      centerTitle: centerTitle,
      titleSpacing: showBackButton ? titleSpacing : NavigationToolbar.kMiddleSpacing,
      automaticallyImplyLeading: false,
      leading: showBackButton
          ? IconButton(
              icon: const Icon(
                Icons.arrow_back_ios_new_rounded,
                color: Colors.white,
                size: 20,
              ),
              onPressed: onBackPressed ??
                  () {
                    if (Navigator.canPop(context)) {
                      Navigator.pop(context);
                    } else {
                      Navigator.popUntil(context, (route) => route.isFirst);
                    }
                  },
              tooltip: 'Back',
            )
          : null,
      title: titleWidget,
      actions: actions,
      bottom: bottom,
    );
  }
}

class CommonHomeButton extends StatelessWidget {
  const CommonHomeButton({super.key});

  @override
  Widget build(BuildContext context) {
    return IconButton(
      icon: const Icon(Icons.home_rounded, color: Colors.white, size: 22),
      onPressed: () {
        Navigator.popUntil(context, (route) => route.isFirst);
      },
      tooltip: 'Home',
    );
  }
}
