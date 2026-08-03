/// A prototype, not a decision.
///
/// The archive specifies five *primary* clusters for Kinship Duna and the
/// principle that clusters **arise** from parentage and working relationships.
/// It does not say what happens at twenty. This module exists so that question
/// can be judged by looking rather than by argument.
///
/// Everything here is deliberately **outside the contract**. The super-group of
/// a cluster is read from an id convention in the demo fixture (`g{n}-c{m}`)
/// rather than from a schema field, because whether clusters group — and into
/// what — is Moto's ruling to make, not ours to bake in.
library;

enum NavMode {
  /// No collapse: every orbit stays individual at any zoom. `?nav=off`.
  none,

  /// Zooming out past the canon's 0.7× floor collapses clusters into
  /// super-clusters. The same map at a coarser scale.
  ///
  /// Consistent with the canon: *"everything is present"*, *"pan and zoom to
  /// any orbit"*, and the 0.7×–2.4× range being explicitly qualified as the
  /// span **"before context changes."**
  collapse,

  /// Star traversal. Below the zoom floor every cluster becomes a **star** —
  /// a steady point of light — and *all* of them fit on one screen, because
  /// the floor is derived from the Field's own extent rather than fixed.
  /// Zoom toward a star, or click it, and it resolves into its orbit.
  /// `?nav=traverse`.
  ///
  /// The difference from [collapse] is that collapse keeps every super-cluster
  /// at its original position and size, so zooming out puts you *inside* one
  /// large faint ellipse instead of above the whole Ecosystem. Stars are marks,
  /// not regions, so the whole system genuinely fits.
  ///
  /// Consistent with the canon on three counts: *"everything is present"* (no
  /// cluster is ever removed, only drawn small), *"pan and zoom to any orbit"*,
  /// and the far band's own rule that distance reduces fidelity rather than
  /// existence. Stars are **steady** — a star brightens only when something
  /// real happens in that cluster, never to advertise that it is clickable.
  traverse,

  /// Five clusters at a time, with next and previous.
  ///
  /// Included so the alternative can be seen rather than described. It sits
  /// against three separate canon statements: *"everything is present"*, *"the
  /// found thing pulls to the front **rather than rendering as a list**"*, and
  /// *"the Field is not a ranked list rendered as space"* — and it discards
  /// spatial memory, which the Field-scale spec names as a goal.
  page;

  /// **Collapse is the default.** Zoom out and the orbits merge into
  /// super-clusters — the whole system at a glance; zoom in and you are back
  /// in a region, panning between neighbours. `?nav=off` disables it.
  static NavMode fromUrl(String? value) => switch (value) {
        'off' => NavMode.none,
        'page' => NavMode.page,
        'traverse' => NavMode.traverse,
        _ => NavMode.collapse,
      };
}

/// Below this the Field is "zoomed out past context" and clusters collapse.
/// It is the canon's own lower clamp — the point it calls *before context
/// changes*.
const collapseBelowZoom = 0.7;

/// How far out the demo lets the camera travel, so there is somewhere to
/// collapse *into*. The shipped Field still clamps at 0.7×.
const demoMinZoom = 0.34;

/// Clusters shown per page in [NavMode.page].
const clustersPerPage = 5;

/// How many clusters are reachable at once in [NavMode.traverse]. Everything
/// else is a star on the margin. `?clusters=3` narrows it.
int clustersPerView = 5;

/// Resting zoom for a traverse window.
const traverseEnterZoom = 1.0;

/// A whisper of scale during a traverse — depth, not a zoom. The dissolve
/// carries the change; the camera barely moves.
const traverseDriftZoom = 0.965;
const traverseArriveZoom = 1.035;

/// How long one traverse takes, end to end. Under the canon's 900ms Gather,
/// because nothing is arriving here — the Field is being exchanged.
const traverseTravelSeconds = 0.46;

/// The super-group a cluster belongs to, by fixture-id convention.
///
/// `formation-learning` → `formation`. Returns the id unchanged when it carries no convention, so
/// a real Ecosystem simply has one group per cluster and collapse is a no-op.
String superGroupOf(String clusterId) {
  final dash = clusterId.indexOf('-');
  return dash <= 0 ? clusterId : clusterId.substring(0, dash);
}
