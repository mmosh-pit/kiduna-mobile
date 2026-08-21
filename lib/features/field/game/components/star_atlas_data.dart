import 'dart:ui' show Color;

import '../../data/field_models.dart';
import '../enamel_tokens.dart';

class StarRealm {
  const StarRealm(this.name, this.purpose);
  final String name;
  final String purpose;
}

const Map<String, List<StarRealm>> kStarRealms = {
  'organization': [
    StarRealm('Hyphal', 'Work and team formation without extractive logic'),
    StarRealm('Freehold Finance', 'Cooperative finance and capital formation'),
    StarRealm('Soul Kitchen', 'Community nourishment through food'),
    StarRealm('Bihome', 'Co-living and shared housing'),
    StarRealm('Mapshifting', 'Cartography and spatial awareness'),
    StarRealm('Dunaversity', 'Learning without institutional gatekeeping'),
  ],
  'community': [
    StarRealm('Black Love', 'Nurturing Black relationships'),
    StarRealm('Non-Toxic Masculinity', 'Healthy masculine identity'),
    StarRealm('Indigenous Revival', 'Revitalizing indigenous knowledge'),
    StarRealm('Cosmic Humanity', 'Human potential beyond borders'),
    StarRealm('Wokelord', 'Critical consciousness and awareness'),
    StarRealm('Vibe Coast', 'Creative culture and coastal vibes'),
  ],
  'alliance': [
    StarRealm('Service Alliance', 'Mutual aid and cooperative networks'),
    StarRealm('Mountain River Trade', 'Nature-connected resource sharing'),
    StarRealm('Celebrity Solar', 'Collective renewable energy investment'),
    StarRealm('The Long Drum', 'Diaspora cultural connection'),
    StarRealm('Ansanm Ayiti', 'Haitian solidarity and rebuilding'),
    StarRealm('Global Peace', 'Cross-border conflict resolution'),
  ],
  'institution': [
    StarRealm('Ravensong Labs', 'Commons infrastructure R&D'),
    StarRealm('PR Commons', 'Shared public relations resource'),
    StarRealm('True Democracy', 'Governance and democratic innovation'),
    StarRealm('Commons Cooperative', 'Cooperative shared ownership'),
  ],
  'agency': [
    StarRealm('Agency', 'Autonomous self-directed coordination'),
    StarRealm('Contraction', 'Sustainable mindful degrowth'),
    StarRealm('The Ceremony Machine', 'Ritual and ceremonial technology'),
    StarRealm('Party Line', 'Joy and celebration as practice'),
  ],
};

FieldSnapshot starSnapshot(String starId, String label, Color accent) {
  final items = kStarRealms[starId] ?? [];
  final cluster = ClusterDef(
    id: starId,
    label: label,
    accent: accent,
    left: 50,
    top: 50,
    radiusX: 22,
    radiusY: 18,
  );

  final realms = <Realm>[];
  for (var i = 0; i < items.length; i++) {
    realms.add(
      Realm(
        id: '${starId}_$i',
        name: items[i].name,
        typeName: label,
        type: RealmType.parse(label),
        clusterId: starId,
        mass: 2,
        fixture: false,
        purpose: items[i].purpose,
      ),
    );
  }

  return FieldSnapshot(
    schemaVersion: '1.0',
    viewer: Viewer(
      id: 'star-viewer',
      displayName: 'Star Viewer',
      gravity: {for (final r in realms) r.id: Gravity.relevant},
    ),
    ecosystem: EcosystemRef(id: starId, name: label),
    realms: realms,
    clusters: [cluster],
  );
}
