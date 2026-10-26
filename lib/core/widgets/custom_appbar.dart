import 'package:flutter/material.dart';
import '../utils/constants.dart';
import 'package:cached_network_image/cached_network_image.dart'; // Import cached_network_image

class CustomAppBar extends StatelessWidget implements PreferredSizeWidget {
  final String title;
  final VoidCallback? onMenuPressed;
  final String? userImageUrl;

  const CustomAppBar({
    super.key,
    this.title = Constants.appName,
    this.onMenuPressed,
    this.userImageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    
    return AppBar(
      backgroundColor: theme.appBarTheme.backgroundColor,
      elevation: theme.appBarTheme.elevation,
      leading: IconButton(
        icon: Icon(
          Icons.menu,
          color: theme.colorScheme.secondary,
          size: 30,
        ),
        onPressed: onMenuPressed ?? () => Scaffold.of(context).openDrawer(),
      ),
      centerTitle: true,
      title: Text(
        title,
        style: theme.appBarTheme.titleTextStyle,
      ),
      actions: [
        Padding(
          padding: const EdgeInsets.only(right: 16.0),
          child: Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: theme.colorScheme.secondary.withOpacity(0.5),
                  blurRadius: 10.0,
                  spreadRadius: 1.0,
                ),
              ],
            ),
            child: CircleAvatar(
              radius: 20,
              backgroundImage: userImageUrl != null 
                  ? CachedNetworkImageProvider(userImageUrl!) as ImageProvider // Use CachedNetworkImageProvider
                  : const AssetImage('assets/default_avatar.png') as ImageProvider,
              backgroundColor: Colors.grey[300],
              child: userImageUrl == null 
                  ? const Icon(Icons.person, color: Colors.grey) 
                  : null,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Size get preferredSize => const Size.fromHeight(kToolbarHeight);
}
