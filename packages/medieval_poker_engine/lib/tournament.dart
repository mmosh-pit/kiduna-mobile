/// Tournament bracket shape — pure logic, no transport or persistence.
///
/// Kept out of the main engine barrel (like `service.dart`) so plain rules
/// consumers do not pull in tournament concepts. A host owns the clock and the
/// rooms; this owns who plays whom.
library;

export 'src/tournament/bracket.dart';
