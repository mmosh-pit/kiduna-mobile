import 'package:flutter/material.dart';

import '../models/presale_mock_data.dart';
import '../widgets/presale_detail_view.dart';
import '../widgets/presale_list_view.dart';

/// Root screen for the Exchange section.
///
/// Manages internal navigation between the presale list and detail views
/// using a [ValueNotifier]. No GoRouter routes — this is a section-internal
/// view stack:
///
///   null            → PresaleListView (list of presale cards)
///   PresaleMockItem → PresaleDetailView (full details + buy)
class ExchangeScreen extends StatefulWidget {
  const ExchangeScreen({super.key});

  @override
  State<ExchangeScreen> createState() => _ExchangeScreenState();
}

class _ExchangeScreenState extends State<ExchangeScreen> {
  PresaleMockItem? _selected;

  @override
  Widget build(BuildContext context) {
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 200),
      child: _selected == null
          ? PresaleListView(
              key: const ValueKey('presale-list'),
              onPresaleTap: (presale) => setState(() => _selected = presale),
            )
          : PresaleDetailView(
              key: ValueKey('presale-detail-${_selected!.id}'),
              presale: _selected!,
              onBack: () => setState(() => _selected = null),
            ),
    );
  }
}
