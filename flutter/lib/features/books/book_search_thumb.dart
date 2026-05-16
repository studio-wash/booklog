import 'package:flutter/material.dart';

Widget bookSearchThumbPlaceholder(ThemeData theme) {
  return ColoredBox(
    color: theme.colorScheme.surfaceContainerHighest,
    child: Center(
      child: Icon(
        Icons.menu_book_outlined,
        color: theme.colorScheme.onSurfaceVariant,
        size: 28,
      ),
    ),
  );
}

Widget bookSearchThumb(String imageUrl, ThemeData theme) {
  if (imageUrl.trim().isEmpty) {
    return bookSearchThumbPlaceholder(theme);
  }
  return ClipRRect(
    borderRadius: BorderRadius.circular(6),
    child: Image.network(
      imageUrl,
      fit: BoxFit.cover,
      errorBuilder: (_, __, ___) => bookSearchThumbPlaceholder(theme),
    ),
  );
}
