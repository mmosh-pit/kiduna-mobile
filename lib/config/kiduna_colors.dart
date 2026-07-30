import 'package:flutter/material.dart';

/// Kiduna "Deep. Warm. Alive." Field palette.
///
/// Exact token values taken from the kiduna-studio-design-kit prototype
/// (`canonical-first-field.module.css`, the `.shell` custom properties). This
/// is the single source of colour truth for the Studio Field surface across
/// web, mobile, and desktop. Never hardcode a Field colour at a call site —
/// read it from here via `Theme.of(context).extension<KidunaColors>()` or the
/// `context.kiduna` helper in `context_extensions.dart`.
///
/// The Field design is intrinsically dark, so [standard] is registered on both
/// the light and dark [ThemeData]; the tokens do not change between them.
@immutable
class KidunaColors extends ThemeExtension<KidunaColors> {
  const KidunaColors({
    required this.field,
    required this.deep,
    required this.surface,
    required this.raised,
    required this.raisedAlt,
    required this.cream,
    required this.text,
    required this.muted,
    required this.quiet,
    required this.sky,
    required this.skyHover,
    required this.skyButtonInk,
    required this.gold,
    required this.camel,
    required this.mint,
    required this.line,
    required this.chocolate,
    required this.darkUmber,
    required this.aubergine,
    required this.navyBlue,
    required this.darkBlue,
    required this.accentPurple,
    required this.accentPurpleScene,
    required this.orange,
    required this.lime,
    required this.magenta,
    required this.creamSupporting,
    required this.accentChocoBrown,
    required this.accentRusticBrown,
    required this.accentChestnut,
    required this.grey,
    required this.black,
    required this.error,
    required this.errorDark,
    required this.complete,
    required this.warning,
    required this.skySoft,
    required this.mintSoft,
    required this.surfaceMuted,
    required this.fgSoft,
    required this.fgDim,
    required this.border,
    required this.borderStrong,
    required this.camelSoft,
    required this.realmOrganization,
    required this.realmAlliance,
    required this.realmProgram,
    required this.realmProject,
    required this.realmRelationship,
    required this.realmCommunity,
    required this.realmConceptual,
    required this.elementActor,
    required this.elementMedia,
    required this.elementAlly,
    required this.elementResource,
    required this.elementAction,
    required this.clusterFormation,
    required this.clusterCare,
    required this.clusterPlace,
    required this.clusterCulture,
    required this.clusterLaw,
    required this.clusterBranch,
  });

  /// Deepest Field background (`--field`).
  final Color field;

  /// Darkest ink and composer ground (`--deep`).
  final Color deep;

  /// Default panel ground / espresso (`--surface`).
  final Color surface;

  /// Raised warm surface (`--raised`).
  final Color raised;

  /// Elevated instrument surface (`--raised-2`).
  final Color raisedAlt;

  /// Headings and highlights (`--cream`).
  final Color cream;

  /// Primary readable text; replaces pure white (`--text`).
  final Color text;

  /// Secondary copy (`--muted`).
  final Color muted;

  /// Tertiary text and quiet labels (`--quiet`).
  final Color quiet;

  /// Ki, navigation, links, and the single primary Action (`--sky`).
  final Color sky;

  /// Sky hover state (`--sky-hover`).
  final Color skyHover;

  /// Ink for content on a sky-filled control (`--sky-button-ink`). Contextual:
  /// it defaults to the local ground ([surface]) and must be overridden per
  /// material where the ground behind the button differs. White or cream ink on
  /// sky is prohibited.
  final Color skyButtonInk;

  /// Kiduna mark, significance, and deliberate upright emphasis (`--gold`).
  final Color gold;

  /// Warm structure and secondary accents (`--camel`).
  final Color camel;

  /// Rare emergence, intelligence, or living state (`--mint`).
  final Color mint;

  /// Hairline borders — camel at 22% alpha (`--line`).
  final Color line;

  /// Material depth (`--kin-chocolate`).
  final Color chocolate;

  /// Dark umber (`--kin-darkumber`).
  final Color darkUmber;

  /// Alternate imaginative ground (`--kin-aubergine`).
  final Color aubergine;

  /// Supporting navy (`--kin-navyblue`).
  final Color navyBlue;

  /// Supporting dark blue (`--kin-darkblue`).
  final Color darkBlue;

  /// Extended accent purple (`--kin-accent-purple`).
  final Color accentPurple;

  /// Purple scene variant (`--kin-accent-purple-scn`).
  final Color accentPurpleScene;

  /// Supporting orange (`--kin-orange`).
  final Color orange;

  /// Supporting lime (`--kin-lime`).
  final Color lime;

  /// Supporting magenta (`--kin-magenta`).
  final Color magenta;

  /// Supporting cream (`--kin-cream`).
  final Color creamSupporting;

  /// Choco brown accent (`--kin-accent-chocobrown`).
  final Color accentChocoBrown;

  /// Rustic brown accent (`--kin-accent-rusticbrown`).
  final Color accentRusticBrown;

  /// Chestnut accent (`--kin-accent-chestnut`).
  final Color accentChestnut;

  /// Grey (`--kin-grey`).
  final Color grey;

  /// Black (`--kin-black`).
  final Color black;

  /// Error / danger (`--kin-error`).
  final Color error;

  /// Error dark variant (`--kin-error-tob`).
  final Color errorDark;

  /// Success / complete (`--kin-complete`).
  final Color complete;

  /// Warning (`--kin-warning`).
  final Color warning;

  /// Sky blue at 14% alpha (`--kin-skyblue-soft`).
  final Color skySoft;

  /// Mint at 16% alpha (`--kin-mint-soft`).
  final Color mintSoft;

  /// Muted surface at 4% alpha (`--surface-muted`).
  final Color surfaceMuted;

  /// Soft foreground at 60% alpha (`--fg-soft`).
  final Color fgSoft;

  /// Dim foreground at 35% alpha (`--fg-dim`).
  final Color fgDim;

  /// Standard border at 12% alpha (`--border`).
  final Color border;

  /// Strong border at 22% alpha (`--border-strong`).
  final Color borderStrong;

  /// Warm accent at 16% alpha (`--accent-warm-soft`).
  final Color camelSoft;

  /// Organization realm identity (`--realm-org`).
  final Color realmOrganization;

  /// Alliance realm identity (`--realm-alliance`).
  final Color realmAlliance;

  /// Program realm identity (`--realm-program`).
  final Color realmProgram;

  /// Project realm identity (`--realm-project`).
  final Color realmProject;

  /// Relationship realm identity (`--realm-relationship`).
  final Color realmRelationship;

  /// Community realm identity (`--realm-community`).
  final Color realmCommunity;

  /// Conceptual realm identity (`--realm-conceptual`).
  final Color realmConceptual;

  /// Actor element identity (`--element-actor`).
  final Color elementActor;

  /// Media element identity (`--element-media`).
  final Color elementMedia;

  /// Ally element identity (`--element-ally`).
  final Color elementAlly;

  /// Resource element identity (`--element-resource`).
  final Color elementResource;

  /// Action element identity (`--element-action`).
  final Color elementAction;

  /// Formation cluster accent.
  final Color clusterFormation;

  /// Care cluster accent.
  final Color clusterCare;

  /// Place cluster accent.
  final Color clusterPlace;

  /// Culture cluster accent.
  final Color clusterCulture;

  /// Law cluster accent.
  final Color clusterLaw;

  /// Branch cluster accent.
  final Color clusterBranch;

  /// Canonical Field palette — matches the prototype token values exactly.
  static const KidunaColors standard = KidunaColors(
    field: Color(0xFF0A0604),
    deep: Color(0xFF060304),
    surface: Color(0xFF1C140D),
    raised: Color(0xFF271B11),
    raisedAlt: Color(0xFF33251A),
    cream: Color(0xFFFFF6D5),
    text: Color(0xFFFFFFE6),
    muted: Color(0xFFCBBCAC),
    quiet: Color(0xFF8F8175),
    sky: Color(0xFF03CCD9),
    skyHover: Color(0xFF2FE0EA),
    skyButtonInk: Color(0xFF1C140D),
    gold: Color(0xFFEAAA00),
    camel: Color(0xFFC19A6B),
    mint: Color(0xFF8FE6C6),
    line: Color(0x38C19A6B),
    chocolate: Color(0xFF6F4A2E),
    darkUmber: Color(0xFF4E3629),
    aubergine: Color(0xFF2A1A2B),
    navyBlue: Color(0xFF100E59),
    darkBlue: Color(0xFF09073A),
    accentPurple: Color(0xFF6536BB),
    accentPurpleScene: Color(0xFF3F2270),
    orange: Color(0xFFF7941D),
    lime: Color(0xFFBEEF00),
    magenta: Color(0xFFEC008C),
    creamSupporting: Color(0xFFF9DDB7),
    accentChocoBrown: Color(0xFF5D4037),
    accentRusticBrown: Color(0xFF8B4513),
    accentChestnut: Color(0xFF7B3F00),
    grey: Color(0xFF9094A3),
    black: Color(0xFF1E1F20),
    error: Color(0xFFFF3A3A),
    errorDark: Color(0xFFAF0E0E),
    complete: Color(0xFF00EB75),
    warning: Color(0xFFFFCA05),
    skySoft: Color(0x2403CCD9),
    mintSoft: Color(0x298FE6C6),
    surfaceMuted: Color(0x0AFFF8F0),
    fgSoft: Color(0x99FFFBF5),
    fgDim: Color(0x59FFFBF5),
    border: Color(0x1FFFF8F0),
    borderStrong: Color(0x38FFF8F0),
    camelSoft: Color(0x29C19A6B),
    realmOrganization: Color(0xFFEAAA00),
    realmAlliance: Color(0xFFB99AE8),
    realmProgram: Color(0xFF4FB6D8),
    realmProject: Color(0xFFD97B2E),
    realmRelationship: Color(0xFF8FE6C6),
    realmCommunity: Color(0xFF62C192),
    realmConceptual: Color(0xFFFFF6D5),
    elementActor: Color(0xFFB99AE8),
    elementMedia: Color(0xFFABDCE8),
    elementAlly: Color(0xFFC19A6B),
    elementResource: Color(0xFFEAAA00),
    elementAction: Color(0xFF03CCD9),
    clusterFormation: Color(0xFF03CCD9),
    clusterCare: Color(0xFFD97B2E),
    clusterPlace: Color(0xFF8FE6C6),
    clusterCulture: Color(0xFFB99AE8),
    clusterLaw: Color(0xFFEAAA00),
    clusterBranch: Color(0xFF62A8DF),
  );

  @override
  KidunaColors copyWith({
    Color? field,
    Color? deep,
    Color? surface,
    Color? raised,
    Color? raisedAlt,
    Color? cream,
    Color? text,
    Color? muted,
    Color? quiet,
    Color? sky,
    Color? skyHover,
    Color? skyButtonInk,
    Color? gold,
    Color? camel,
    Color? mint,
    Color? line,
    Color? chocolate,
    Color? darkUmber,
    Color? aubergine,
    Color? navyBlue,
    Color? darkBlue,
    Color? accentPurple,
    Color? accentPurpleScene,
    Color? orange,
    Color? lime,
    Color? magenta,
    Color? creamSupporting,
    Color? accentChocoBrown,
    Color? accentRusticBrown,
    Color? accentChestnut,
    Color? grey,
    Color? black,
    Color? error,
    Color? errorDark,
    Color? complete,
    Color? warning,
    Color? skySoft,
    Color? mintSoft,
    Color? surfaceMuted,
    Color? fgSoft,
    Color? fgDim,
    Color? border,
    Color? borderStrong,
    Color? camelSoft,
    Color? realmOrganization,
    Color? realmAlliance,
    Color? realmProgram,
    Color? realmProject,
    Color? realmRelationship,
    Color? realmCommunity,
    Color? realmConceptual,
    Color? elementActor,
    Color? elementMedia,
    Color? elementAlly,
    Color? elementResource,
    Color? elementAction,
    Color? clusterFormation,
    Color? clusterCare,
    Color? clusterPlace,
    Color? clusterCulture,
    Color? clusterLaw,
    Color? clusterBranch,
  }) {
    return KidunaColors(
      field: field ?? this.field,
      deep: deep ?? this.deep,
      surface: surface ?? this.surface,
      raised: raised ?? this.raised,
      raisedAlt: raisedAlt ?? this.raisedAlt,
      cream: cream ?? this.cream,
      text: text ?? this.text,
      muted: muted ?? this.muted,
      quiet: quiet ?? this.quiet,
      sky: sky ?? this.sky,
      skyHover: skyHover ?? this.skyHover,
      skyButtonInk: skyButtonInk ?? this.skyButtonInk,
      gold: gold ?? this.gold,
      camel: camel ?? this.camel,
      mint: mint ?? this.mint,
      line: line ?? this.line,
      chocolate: chocolate ?? this.chocolate,
      darkUmber: darkUmber ?? this.darkUmber,
      aubergine: aubergine ?? this.aubergine,
      navyBlue: navyBlue ?? this.navyBlue,
      darkBlue: darkBlue ?? this.darkBlue,
      accentPurple: accentPurple ?? this.accentPurple,
      accentPurpleScene: accentPurpleScene ?? this.accentPurpleScene,
      orange: orange ?? this.orange,
      lime: lime ?? this.lime,
      magenta: magenta ?? this.magenta,
      creamSupporting: creamSupporting ?? this.creamSupporting,
      accentChocoBrown: accentChocoBrown ?? this.accentChocoBrown,
      accentRusticBrown: accentRusticBrown ?? this.accentRusticBrown,
      accentChestnut: accentChestnut ?? this.accentChestnut,
      grey: grey ?? this.grey,
      black: black ?? this.black,
      error: error ?? this.error,
      errorDark: errorDark ?? this.errorDark,
      complete: complete ?? this.complete,
      warning: warning ?? this.warning,
      skySoft: skySoft ?? this.skySoft,
      mintSoft: mintSoft ?? this.mintSoft,
      surfaceMuted: surfaceMuted ?? this.surfaceMuted,
      fgSoft: fgSoft ?? this.fgSoft,
      fgDim: fgDim ?? this.fgDim,
      border: border ?? this.border,
      borderStrong: borderStrong ?? this.borderStrong,
      camelSoft: camelSoft ?? this.camelSoft,
      realmOrganization: realmOrganization ?? this.realmOrganization,
      realmAlliance: realmAlliance ?? this.realmAlliance,
      realmProgram: realmProgram ?? this.realmProgram,
      realmProject: realmProject ?? this.realmProject,
      realmRelationship: realmRelationship ?? this.realmRelationship,
      realmCommunity: realmCommunity ?? this.realmCommunity,
      realmConceptual: realmConceptual ?? this.realmConceptual,
      elementActor: elementActor ?? this.elementActor,
      elementMedia: elementMedia ?? this.elementMedia,
      elementAlly: elementAlly ?? this.elementAlly,
      elementResource: elementResource ?? this.elementResource,
      elementAction: elementAction ?? this.elementAction,
      clusterFormation: clusterFormation ?? this.clusterFormation,
      clusterCare: clusterCare ?? this.clusterCare,
      clusterPlace: clusterPlace ?? this.clusterPlace,
      clusterCulture: clusterCulture ?? this.clusterCulture,
      clusterLaw: clusterLaw ?? this.clusterLaw,
      clusterBranch: clusterBranch ?? this.clusterBranch,
    );
  }

  @override
  KidunaColors lerp(covariant ThemeExtension<KidunaColors>? other, double t) {
    if (other is! KidunaColors) {
      return this;
    }
    return KidunaColors(
      field: Color.lerp(field, other.field, t)!,
      deep: Color.lerp(deep, other.deep, t)!,
      surface: Color.lerp(surface, other.surface, t)!,
      raised: Color.lerp(raised, other.raised, t)!,
      raisedAlt: Color.lerp(raisedAlt, other.raisedAlt, t)!,
      cream: Color.lerp(cream, other.cream, t)!,
      text: Color.lerp(text, other.text, t)!,
      muted: Color.lerp(muted, other.muted, t)!,
      quiet: Color.lerp(quiet, other.quiet, t)!,
      sky: Color.lerp(sky, other.sky, t)!,
      skyHover: Color.lerp(skyHover, other.skyHover, t)!,
      skyButtonInk: Color.lerp(skyButtonInk, other.skyButtonInk, t)!,
      gold: Color.lerp(gold, other.gold, t)!,
      camel: Color.lerp(camel, other.camel, t)!,
      mint: Color.lerp(mint, other.mint, t)!,
      line: Color.lerp(line, other.line, t)!,
      chocolate: Color.lerp(chocolate, other.chocolate, t)!,
      darkUmber: Color.lerp(darkUmber, other.darkUmber, t)!,
      aubergine: Color.lerp(aubergine, other.aubergine, t)!,
      navyBlue: Color.lerp(navyBlue, other.navyBlue, t)!,
      darkBlue: Color.lerp(darkBlue, other.darkBlue, t)!,
      accentPurple: Color.lerp(accentPurple, other.accentPurple, t)!,
      accentPurpleScene: Color.lerp(
        accentPurpleScene,
        other.accentPurpleScene,
        t,
      )!,
      orange: Color.lerp(orange, other.orange, t)!,
      lime: Color.lerp(lime, other.lime, t)!,
      magenta: Color.lerp(magenta, other.magenta, t)!,
      creamSupporting: Color.lerp(creamSupporting, other.creamSupporting, t)!,
      accentChocoBrown: Color.lerp(
        accentChocoBrown,
        other.accentChocoBrown,
        t,
      )!,
      accentRusticBrown: Color.lerp(
        accentRusticBrown,
        other.accentRusticBrown,
        t,
      )!,
      accentChestnut: Color.lerp(accentChestnut, other.accentChestnut, t)!,
      grey: Color.lerp(grey, other.grey, t)!,
      black: Color.lerp(black, other.black, t)!,
      error: Color.lerp(error, other.error, t)!,
      errorDark: Color.lerp(errorDark, other.errorDark, t)!,
      complete: Color.lerp(complete, other.complete, t)!,
      warning: Color.lerp(warning, other.warning, t)!,
      skySoft: Color.lerp(skySoft, other.skySoft, t)!,
      mintSoft: Color.lerp(mintSoft, other.mintSoft, t)!,
      surfaceMuted: Color.lerp(surfaceMuted, other.surfaceMuted, t)!,
      fgSoft: Color.lerp(fgSoft, other.fgSoft, t)!,
      fgDim: Color.lerp(fgDim, other.fgDim, t)!,
      border: Color.lerp(border, other.border, t)!,
      borderStrong: Color.lerp(borderStrong, other.borderStrong, t)!,
      camelSoft: Color.lerp(camelSoft, other.camelSoft, t)!,
      realmOrganization: Color.lerp(
        realmOrganization,
        other.realmOrganization,
        t,
      )!,
      realmAlliance: Color.lerp(realmAlliance, other.realmAlliance, t)!,
      realmProgram: Color.lerp(realmProgram, other.realmProgram, t)!,
      realmProject: Color.lerp(realmProject, other.realmProject, t)!,
      realmRelationship: Color.lerp(
        realmRelationship,
        other.realmRelationship,
        t,
      )!,
      realmCommunity: Color.lerp(realmCommunity, other.realmCommunity, t)!,
      realmConceptual: Color.lerp(realmConceptual, other.realmConceptual, t)!,
      elementActor: Color.lerp(elementActor, other.elementActor, t)!,
      elementMedia: Color.lerp(elementMedia, other.elementMedia, t)!,
      elementAlly: Color.lerp(elementAlly, other.elementAlly, t)!,
      elementResource: Color.lerp(elementResource, other.elementResource, t)!,
      elementAction: Color.lerp(elementAction, other.elementAction, t)!,
      clusterFormation: Color.lerp(
        clusterFormation,
        other.clusterFormation,
        t,
      )!,
      clusterCare: Color.lerp(clusterCare, other.clusterCare, t)!,
      clusterPlace: Color.lerp(clusterPlace, other.clusterPlace, t)!,
      clusterCulture: Color.lerp(clusterCulture, other.clusterCulture, t)!,
      clusterLaw: Color.lerp(clusterLaw, other.clusterLaw, t)!,
      clusterBranch: Color.lerp(clusterBranch, other.clusterBranch, t)!,
    );
  }
}
