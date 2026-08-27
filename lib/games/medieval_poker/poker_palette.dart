/// Medieval Poker's surface colours.
///
/// Shared by the standings and tournament screens so the two cannot drift.
/// `session_hud.dart` keeps its own private copies — it predates this and is
/// large enough that renaming through it would bury a real change in noise.
library;

import 'package:flutter/painting.dart';

/// Gilt: winners, primary actions, the viewer's own row.
const kPokerGold = Color(0xFFEDC169);

/// Near-black used for text on [kPokerGold].
const kPokerInk = Color(0xFF1B140C);

/// Raised panel over the felt.
const kPokerPanel = Color(0xF21B140C);

/// Hairline around panels and outlined controls.
const kPokerPanelBorder = Color(0xFF6B5533);

/// Defeat, elimination, cancellation.
const kPokerDanger = Color(0xFFB3261E);

/// Muted gilt for eyebrows and secondary labels.
const kPokerMuted = Color(0xFF9C8459);

/// A live table.
const kPokerLive = Color(0xFF7FD0E0);
