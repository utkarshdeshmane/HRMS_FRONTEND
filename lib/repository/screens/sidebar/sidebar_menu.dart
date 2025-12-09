import 'package:flutter/material.dart';

typedef MenuTapCallback = void Function();

class SidebarMenuItem {
  final String title;
  final IconData icon;
  final List<SidebarMenuItem>? children;
  final MenuTapCallback? onTap;

  SidebarMenuItem({
    required this.title,
    required this.icon,
    this.children,
    this.onTap,
  });
}
