import 'package:flutter/material.dart';

import '../../../core/extensions/context_extensions.dart';
import '../models/scene_mock_data.dart';

/// Bottom sheet form for creating a new scene (app).
///
/// Fields: name, description, category, icon URL, multiple gallery image URLs.
/// Mock only — calls [onCreated] with a new [SceneMockItem].
class SceneCreateForm extends StatefulWidget {
  const SceneCreateForm({super.key, required this.onCreated});

  final ValueChanged<SceneMockItem> onCreated;

  @override
  State<SceneCreateForm> createState() => _SceneCreateFormState();
}

class _SceneCreateFormState extends State<SceneCreateForm> {
  final _nameCtrl = TextEditingController();
  final _descCtrl = TextEditingController();
  final _iconUrlCtrl = TextEditingController();
  final _imageUrlCtrl = TextEditingController();
  String _category = 'productivity';
  final List<String> _imageUrls = [];

  static const _categories = [
    ('productivity', 'Productivity'),
    ('game', 'Game'),
    ('wellness', 'Wellness'),
    ('finance', 'Finance'),
    ('lifestyle', 'Lifestyle'),
  ];

  bool get _canSubmit =>
      _nameCtrl.text.trim().isNotEmpty &&
      _descCtrl.text.trim().isNotEmpty;

  IconData _categoryIcon(String cat) {
    switch (cat) {
      case 'productivity': return Icons.check_circle_outline_rounded;
      case 'game':         return Icons.videogame_asset_rounded;
      case 'wellness':     return Icons.emoji_events_rounded;
      case 'finance':      return Icons.account_balance_wallet_rounded;
      case 'lifestyle':    return Icons.restaurant_menu_rounded;
      default:             return Icons.apps_rounded;
    }
  }

  void _addImageUrl() {
    final url = _imageUrlCtrl.text.trim();
    if (url.isNotEmpty && url.startsWith('http')) {
      setState(() {
        _imageUrls.add(url);
        _imageUrlCtrl.clear();
      });
    }
  }

  void _removeImageUrl(int index) {
    setState(() => _imageUrls.removeAt(index));
  }

  void _submit() {
    final scene = SceneMockItem(
      id: 'scene-${DateTime.now().millisecondsSinceEpoch}',
      name: _nameCtrl.text.trim(),
      description: _descCtrl.text.trim(),
      category: _category,
      status: 'available',
      icon: _categoryIcon(_category),
      iconUrl: _iconUrlCtrl.text.trim().isNotEmpty
          ? _iconUrlCtrl.text.trim()
          : null,
      imageUrls: List.unmodifiable(_imageUrls),
    );
    widget.onCreated(scene);
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _descCtrl.dispose();
    _iconUrlCtrl.dispose();
    _imageUrlCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final bottomInset = MediaQuery.of(context).viewInsets.bottom;

    return Container(
      constraints: BoxConstraints(
        maxHeight: MediaQuery.of(context).size.height * 0.85,
      ),
      padding: EdgeInsets.fromLTRB(20, 20, 20, 20 + bottomInset),
      decoration: BoxDecoration(
        color: colors.raised,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(16)),
        border: Border(top: BorderSide(color: colors.line)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // ── Handle ──
          Center(
            child: Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: colors.quiet,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
          ),
          const SizedBox(height: 20),

          // ── Title ──
          Row(
            children: [
              Container(
                width: 32,
                height: 32,
                decoration: BoxDecoration(
                  color: colors.gold.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: colors.gold.withValues(alpha: 0.15),
                  ),
                ),
                child: Icon(Icons.add_rounded, size: 18, color: colors.gold),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Create Scene',
                    style: context.kidunaText.heading.copyWith(
                      color: colors.cream,
                    ),
                  ),
                  Text(
                    'Add a new app to the Garden',
                    style: context.kidunaText.micro.copyWith(
                      color: colors.quiet,
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 20),

          // ── Scrollable form ──
          Flexible(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  // ── Name ──
                  _FieldLabel(label: 'Scene Name'),
                  const SizedBox(height: 6),
                  _StyledTextField(
                    controller: _nameCtrl,
                    hint: 'e.g. Task Tracker',
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 18),

                  // ── Description ──
                  _FieldLabel(label: 'Description'),
                  const SizedBox(height: 6),
                  _StyledTextField(
                    controller: _descCtrl,
                    hint: 'What does this scene do?',
                    maxLines: 3,
                    onChanged: (_) => setState(() {}),
                  ),
                  const SizedBox(height: 18),

                  // ── Category ──
                  _FieldLabel(label: 'Category'),
                  const SizedBox(height: 6),
                  _CategorySelector(
                    value: _category,
                    categories: _categories,
                    onChanged: (v) => setState(() => _category = v),
                  ),
                  const SizedBox(height: 18),

                  // ── Icon URL ──
                  _FieldLabel(label: 'Icon URL (optional)'),
                  const SizedBox(height: 6),
                  _StyledTextField(
                    controller: _iconUrlCtrl,
                    hint: 'https://example.com/icon.png',
                    onChanged: (_) => setState(() {}),
                  ),
                  if (_iconUrlCtrl.text.trim().isNotEmpty) ...[
                    const SizedBox(height: 8),
                    _ImagePreview(
                      url: _iconUrlCtrl.text.trim(),
                      label: 'Icon preview',
                    ),
                  ],
                  const SizedBox(height: 18),

                  // ── Gallery Images ──
                  _FieldLabel(label: 'Gallery Images (optional)'),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Expanded(
                        child: _StyledTextField(
                          controller: _imageUrlCtrl,
                          hint: 'https://example.com/screenshot.png',
                          onChanged: (_) => setState(() {}),
                        ),
                      ),
                      const SizedBox(width: 8),
                      _AddUrlButton(
                        enabled: _imageUrlCtrl.text.trim().isNotEmpty,
                        onTap: _addImageUrl,
                      ),
                    ],
                  ),

                  // ── Gallery preview list ──
                  if (_imageUrls.isNotEmpty) ...[
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 80,
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        itemCount: _imageUrls.length,
                        separatorBuilder: (_, __) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          return _GalleryThumbnail(
                            url: _imageUrls[index],
                            onRemove: () => _removeImageUrl(index),
                          );
                        },
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${_imageUrls.length} image${_imageUrls.length > 1 ? 's' : ''} added',
                      style: context.kidunaText.micro.copyWith(
                        color: colors.quiet,
                      ),
                    ),
                  ],
                  const SizedBox(height: 28),

                  // ── Submit ──
                  SizedBox(
                    height: 48,
                    child: ElevatedButton(
                      onPressed: _canSubmit ? _submit : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: colors.gold,
                        foregroundColor: colors.skyButtonInk,
                        disabledBackgroundColor:
                            colors.gold.withValues(alpha: 0.15),
                        disabledForegroundColor: colors.muted,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.add_rounded, size: 18,
                              color: _canSubmit
                                  ? colors.skyButtonInk
                                  : colors.muted),
                          const SizedBox(width: 8),
                          Text(
                            'Create Scene',
                            style: context.kidunaText.labelStrong,
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

/// Gallery thumbnail with remove button.
class _GalleryThumbnail extends StatelessWidget {
  const _GalleryThumbnail({required this.url, required this.onRemove});

  final String url;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Stack(
      children: [
        Container(
          width: 100,
          height: 80,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.network(
              url,
              width: 100,
              height: 80,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                color: colors.surface,
                child: Icon(
                  Icons.broken_image_outlined,
                  size: 24,
                  color: colors.error.withValues(alpha: 0.5),
                ),
              ),
            ),
          ),
        ),
        Positioned(
          top: 4,
          right: 4,
          child: GestureDetector(
            onTap: onRemove,
            child: Container(
              width: 20,
              height: 20,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.black.withValues(alpha: 0.7),
                border: Border.all(
                  color: colors.error.withValues(alpha: 0.5),
                ),
              ),
              child: Icon(Icons.close_rounded,
                  size: 12, color: colors.error),
            ),
          ),
        ),
      ],
    );
  }
}

/// Add URL button next to the image URL field.
class _AddUrlButton extends StatelessWidget {
  const _AddUrlButton({required this.enabled, required this.onTap});

  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return GestureDetector(
      onTap: enabled ? onTap : null,
      child: Container(
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: enabled
              ? colors.gold.withValues(alpha: 0.12)
              : colors.surface,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: enabled
                ? colors.gold.withValues(alpha: 0.3)
                : colors.line,
          ),
        ),
        child: Icon(
          Icons.add_photo_alternate_rounded,
          size: 20,
          color: enabled ? colors.gold : colors.muted,
        ),
      ),
    );
  }
}

/// Small image preview row.
class _ImagePreview extends StatelessWidget {
  const _ImagePreview({required this.url, required this.label});

  final String url;
  final String label;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Row(
      children: [
        Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: colors.line),
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(9),
            child: Image.network(
              url,
              width: 40,
              height: 40,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Icon(
                Icons.broken_image_outlined,
                size: 20,
                color: colors.error,
              ),
            ),
          ),
        ),
        const SizedBox(width: 10),
        Text(label,
            style: context.kidunaText.micro.copyWith(color: colors.quiet)),
      ],
    );
  }
}

/// Field label.
class _FieldLabel extends StatelessWidget {
  const _FieldLabel({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Text(
      label,
      style: context.kidunaText.label.copyWith(
        color: context.kiduna.muted,
        fontSize: 12,
      ),
    );
  }
}

/// Styled text field.
class _StyledTextField extends StatelessWidget {
  const _StyledTextField({
    required this.controller,
    required this.hint,
    this.maxLines = 1,
    this.onChanged,
  });

  final TextEditingController controller;
  final String hint;
  final int maxLines;
  final ValueChanged<String>? onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: onChanged,
      style: context.kidunaText.bodySm.copyWith(color: colors.cream),
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: context.kidunaText.bodySm.copyWith(color: colors.quiet),
        filled: true,
        fillColor: colors.surface,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 12,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.line),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.line),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(10),
          borderSide: BorderSide(color: colors.gold, width: 1.5),
        ),
      ),
    );
  }
}

/// Category selector chips.
class _CategorySelector extends StatelessWidget {
  const _CategorySelector({
    required this.value,
    required this.categories,
    required this.onChanged,
  });

  final String value;
  final List<(String, String)> categories;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;

    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final (id, label) in categories)
          GestureDetector(
            onTap: () => onChanged(id),
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 150),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: value == id
                    ? colors.gold.withValues(alpha: 0.12)
                    : colors.surface,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: value == id
                      ? colors.gold.withValues(alpha: 0.3)
                      : colors.line,
                ),
              ),
              child: Text(
                label,
                style: context.kidunaText.bodySm.copyWith(
                  color: value == id ? colors.gold : colors.muted,
                  fontWeight: value == id ? FontWeight.w600 : FontWeight.w400,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
