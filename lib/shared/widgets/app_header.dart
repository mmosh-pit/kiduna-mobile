import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../config/assets.dart';
import '../../core/extensions/context_extensions.dart';

// Header ground (prototype `.lab` — rgba(18,12,7,.97)); a one-off chrome value,
// not a theme token. The small selector chrome below (radius/padding) follows
// the same one-off pattern as the header's fixed height/logo size.
const Color _headerBg = Color.fromRGBO(18, 12, 7, 0.97);

/// Persona ids the header offers, mirroring the prototype's Design Lab Persona
/// selector. The prototype currently exposes a single persona (`alice`); add
/// more ids here (and their `l10n` labels in [_personaLabel]) as they land.
const List<String> _personaIds = ['alice'];

const String _defaultPersonaId = 'alice';
const String _defaultViewId = 'ncev';

/// View ids the header offers, mirroring the prototype's Studio View selector
/// (`STUDIO_VIEWS`). UI-only for now — selecting one changes the shown value
/// and drives nothing downstream.
const List<String> _viewIds = [
  'ncev',
  'aev',
  'sceneRough',
  'sceneRoughV2',
  'sceneRoughV3',
];

/// Maps the current router location to the selected view id.
String _viewIdForLocation(String location) =>
    location.startsWith('/studio/aev') ? 'aev' : 'ncev';

/// Maps a view id to its route, or `null` for views with no page yet.
String? _routeForViewId(String id) {
  switch (id) {
    case 'ncev':
      return Routes.field;
    case 'aev':
      return Routes.aev;
    default:
      return null;
  }
}

/// Resolves the display label for a persona [id] from localized strings.
String _personaLabel(BuildContext context, String id) {
  switch (id) {
    case 'alice':
      return context.l10n.aliceCatalyst;
    default:
      return id;
  }
}

/// Resolves the display label for a view [id] from localized strings.
String _viewLabel(BuildContext context, String id) {
  final l10n = context.l10n;
  switch (id) {
    case 'ncev':
      return l10n.viewNcev;
    case 'aev':
      return l10n.viewAev;
    case 'sceneRough':
      return l10n.viewSceneRough;
    case 'sceneRoughV2':
      return l10n.viewSceneRoughV2;
    case 'sceneRoughV3':
      return l10n.viewSceneRoughV3;
    default:
      return id;
  }
}

/// The app's top bar — the Kiduna logo on a warm dark ground, with the View and
/// Persona selectors on the trailing edge (mirroring the prototype's Design Lab
/// header).
///
/// A shared, page-agnostic header. Both dropdowns are UI-only for now: they
/// track local selection and drive nothing downstream. Changing the View leaves
/// the selected Persona untouched.
class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  String _persona = _defaultPersonaId;
  String _view = _defaultViewId;

  void _onPersonaChanged(String id) {
    setState(() => _persona = id);
  }

  void _onViewChanged(String id) {
    setState(() => _view = id);
    final route = _routeForViewId(id);
    if (route != null) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    try {
      final location = GoRouterState.of(context).uri.toString();
      final activeView = _viewIdForLocation(location);
      if (activeView != _view) {
        WidgetsBinding.instance.addPostFrameCallback((_) {
          if (mounted) setState(() => _view = activeView);
        });
      }
    } on GoError catch (_) {
      // No GoRouterState in test context — use local _view.
    }
    return Container(
      height: 74,
      padding: const EdgeInsets.symmetric(horizontal: 24),
      decoration: BoxDecoration(
        color: _headerBg,
        border: Border(
          bottom: BorderSide(
            color: context.kiduna.camel.withValues(alpha: 0.28),
          ),
        ),
      ),
      child: Row(
        children: [
          SvgPicture.asset(AppAssets.kidunaLogo, width: 138, height: 40),
          const SizedBox(width: 16),
          Expanded(
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                // View can shrink and ellipsize so the bar never overflows on
                // narrow surfaces; Persona keeps its natural width.
                Flexible(
                  child: _ViewSelector(
                    selected: _view,
                    onChanged: _onViewChanged,
                  ),
                ),
                const SizedBox(width: 12),
                _PersonaSelector(
                  selected: _persona,
                  onChanged: _onPersonaChanged,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

/// The "View" label + dropdown. Long view labels ellipsize in the trailing
/// space rather than overflowing the bar.
class _ViewSelector extends StatelessWidget {
  const _ViewSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Row(
      children: [
        if (!context.isMobile) ...[
          Text(
            context.l10n.view,
            style: context.kidunaText.eyebrowSmall.copyWith(
              color: colors.quiet,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 12),
            decoration: BoxDecoration(
              color: colors.surface,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: colors.line),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: const ValueKey('header-view-dropdown'),
                value: selected,
                isDense: true,
                isExpanded: true,
                dropdownColor: colors.surface,
                borderRadius: BorderRadius.circular(8),
                icon: Icon(Icons.expand_more, size: 18, color: colors.quiet),
                style: context.kidunaText.label.copyWith(color: colors.cream),
                onChanged: (value) {
                  if (value != null) {
                    onChanged(value);
                  }
                },
                selectedItemBuilder: (context) => [
                  for (final id in _viewIds)
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        _viewLabel(context, id),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
                items: [
                  for (final id in _viewIds)
                    DropdownMenuItem<String>(
                      value: id,
                      child: Text(
                        _viewLabel(context, id),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}

/// The "Persona" label + dropdown, mirroring the prototype's labelled select.
class _PersonaSelector extends StatelessWidget {
  const _PersonaSelector({required this.selected, required this.onChanged});

  final String selected;
  final ValueChanged<String> onChanged;

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        // The caption is dropped on narrow surfaces to keep the bar uncluttered.
        if (!context.isMobile) ...[
          Text(
            context.l10n.persona,
            style: context.kidunaText.eyebrowSmall.copyWith(
              color: colors.quiet,
            ),
          ),
          const SizedBox(width: 8),
        ],
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: const ValueKey('header-persona-dropdown'),
              value: selected,
              isDense: true,
              dropdownColor: colors.surface,
              borderRadius: BorderRadius.circular(8),
              icon: Icon(Icons.expand_more, size: 18, color: colors.quiet),
              style: context.kidunaText.label.copyWith(color: colors.cream),
              onChanged: (value) {
                if (value != null) {
                  onChanged(value);
                }
              },
              items: [
                for (final id in _personaIds)
                  DropdownMenuItem<String>(
                    value: id,
                    child: Text(_personaLabel(context, id)),
                  ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}
