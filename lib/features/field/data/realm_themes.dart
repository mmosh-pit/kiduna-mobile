/// Canonical 6 Themes and 26 Focuses from Taxonomy V0.14.
///
/// Used by the Realm creation form to populate theme/focus dropdowns
/// and by the backend for validation. Both sides must stay in sync.
abstract final class RealmThemes {
  static const List<String> themes = [
    'People & Care',
    'Society & Justice',
    'Culture & Play',
    'Place & Planet',
    'Work & Wealth',
    'Knowledge & Frontier',
  ];

  static const Map<String, List<String>> focuses = {
    'People & Care': [
      'Health, Disability & Wellbeing',
      'Mental Health, Recovery & Grief',
      'Relationships, Family & Caregiving',
      'Service Communities',
    ],
    'Society & Justice': [
      'Rights, Justice & Solidarity',
      'Civic Life, Democracy & Governance',
      'Community, Mutual Aid & Participation',
      'Safety, Preparedness & Response',
    ],
    'Culture & Play': [
      'Arts & Creative Expression',
      'Heritage, Language & Identity',
      'Spirit, Meaning & Practice',
      'Sports, Outdoors & Recreation',
      'Games, Fandom & Social Entertainment',
      'Media, Storytelling & Journalism',
    ],
    'Place & Planet': [
      'Travel, Hospitality & Tourism',
      'Environment, Climate & Conservation',
      'Energy, Infrastructure & Mobility',
      'Housing, Place & Belonging',
      'Food, Agriculture & Food Systems',
      'Animals & Animal Welfare',
    ],
    'Work & Wealth': [
      'Work, Careers & Trades',
      'Enterprise, Commerce & Markets',
      'Money, Finance & Ownership',
    ],
    'Knowledge & Frontier': [
      'Education, Learning & Skills',
      'Science, Research & Discovery',
      'Technology, AI & Digital Life',
    ],
  };
}
