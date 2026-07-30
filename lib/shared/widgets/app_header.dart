import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:go_router/go_router.dart';

import '../../app/routes.dart';
import '../../config/assets.dart';
import '../../core/extensions/context_extensions.dart';
import '../../core/utils/responsive.dart';

// Header ground (prototype `.lab` — rgba(18,12,7,.97)); a one-off chrome value,
// not a theme token. The small selector chrome below (radius/padding) follows
// the same one-off pattern as the header's fixed height/logo size.
const Color _headerBg = Color.fromRGBO(18, 12, 7, 0.97);

/// Persona ids the header offers, mirroring the prototype's Design Lab Persona
/// selector. The prototype currently exposes a single persona (`alice`); add
/// more ids here (and their `l10n` labels in [_personaLabel]) as they land.
const List<String> _personaIds = ['alice'];

const String _defaultPersonaId = 'alice';

/// At or above this width Stories + Download are shown alongside the
/// selectors. Surface already shows at desktop (≥1024); these extras need
/// more room.
const double _extrasWidth = 1440;

/// View ids the header offers, mirroring the prototype's Studio View selector
/// (`STUDIO_VIEWS`). Selecting a view navigates to its route (see
/// [_routeForViewId]); the selected value is derived from the current route.
const List<String> _viewIds = [
  'ncev',
  'aev',
  'sceneRough',
  'sceneRoughV2',
  'sceneRoughV3',
];

/// Maps the current router location to the selected view id.
String _viewIdForLocation(String location) =>
    location == Routes.aev ? 'aev' : 'ncev';

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

/// The app's top bar — the Kiduna logo plus the prototype's Design-Lab chrome:
/// Surface, View, and Persona selectors, a Stories button, and the Download
/// button.
///
/// A shared, page-agnostic header. The View dropdown navigates between view
/// routes (its value tracks the current route); Persona is UI-only local state
/// and is preserved across a View change. Surface, Stories, and Download are
/// UI-only and are hidden on narrow surfaces.
class AppHeader extends StatefulWidget {
  const AppHeader({super.key});

  @override
  State<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends State<AppHeader> {
  String _persona = _defaultPersonaId;

  void _onPersonaChanged(String id) {
    setState(() => _persona = id);
  }

  /// Navigates to the selected View's page. Persona is preserved — it is not
  /// part of the route. Views with no page yet show a brief notice.
  void _onViewSelected(BuildContext context, String id) {
    final route = _routeForViewId(id);
    if (route == null) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(context.l10n.viewComingSoon)));
      return;
    }
    final router = GoRouter.maybeOf(context);
    if (router == null) {
      return;
    }
    if (route != router.routerDelegate.currentConfiguration.uri.path) {
      context.go(route);
    }
  }

  @override
  Widget build(BuildContext context) {
    final location = GoRouter.maybeOf(
      context,
    )?.routerDelegate.currentConfiguration.uri.path;
    final currentView = _viewIdForLocation(location ?? Routes.field);
    final width = context.screenWidth;
    final showSurface = width >= Breakpoints.desktop;
    final showExtras = width >= _extrasWidth;
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
          const SizedBox(width: 20),
          if (showSurface) ...[
            const _SurfaceSelector(),
            const SizedBox(width: 12),
          ],
          // View fills the middle and ellipsizes so the bar never overflows.
          Flexible(
            child: _ViewSelector(
              selected: currentView,
              onChanged: (id) => _onViewSelected(context, id),
            ),
          ),
          const SizedBox(width: 12),
          _PersonaSelector(selected: _persona, onChanged: _onPersonaChanged),
          if (showExtras) ...[
            const SizedBox(width: 12),
            const _StoriesButton(),
            const SizedBox(width: 16),
            const _DownloadButton(),
          ],
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

/// The "Surface" dropdown — the prototype's Surface selector, fixed to Kiduna
/// Studio (Web/Live are listed; Express/TV are shown as "coming later"). UI-only.
class _SurfaceSelector extends StatelessWidget {
  const _SurfaceSelector();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    final l10n = context.l10n;
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Text(
          l10n.surface,
          style: context.kidunaText.eyebrowSmall.copyWith(color: colors.quiet),
        ),
        const SizedBox(width: 8),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12),
          decoration: BoxDecoration(
            color: colors.surface,
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: colors.line),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              key: const ValueKey('header-surface-dropdown'),
              value: 'studio',
              isDense: true,
              dropdownColor: colors.surface,
              borderRadius: BorderRadius.circular(8),
              icon: Icon(Icons.expand_more, size: 18, color: colors.quiet),
              style: context.kidunaText.label.copyWith(color: colors.cream),
              onChanged: (_) {},
              items: [
                DropdownMenuItem(value: 'web', child: Text(l10n.kidunaWeb)),
                DropdownMenuItem(
                  value: 'studio',
                  child: Text(l10n.kidunaStudio),
                ),
                DropdownMenuItem(value: 'live', child: Text(l10n.kidunaLive)),
                DropdownMenuItem(
                  value: 'express',
                  enabled: false,
                  child: Text('${l10n.kidunaExpress} · ${l10n.comingLater}'),
                ),
                DropdownMenuItem(
                  value: 'tv',
                  enabled: false,
                  child: Text('${l10n.kidunaTv} · ${l10n.comingLater}'),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// The "Stories" button (UI-only in this pass).
class _StoriesButton extends StatelessWidget {
  const _StoriesButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return TextButton(
      onPressed: () {},
      style: TextButton.styleFrom(
        foregroundColor: colors.cream,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      child: Text(
        context.l10n.stories,
        style: context.kidunaText.label.copyWith(color: colors.cream),
      ),
    );
  }
}

/// The teal "Download Studio Design Kit" button (UI-only in this pass).
class _DownloadButton extends StatelessWidget {
  const _DownloadButton();

  @override
  Widget build(BuildContext context) {
    final colors = context.kiduna;
    return DecoratedBox(
      decoration: BoxDecoration(
        color: colors.sky,
        borderRadius: BorderRadius.circular(8),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        child: Text(
          context.l10n.downloadDesignKit,
          style: context.kidunaText.labelStrong.copyWith(
            color: colors.skyButtonInk,
          ),
        ),
      ),
    );
  }
}
