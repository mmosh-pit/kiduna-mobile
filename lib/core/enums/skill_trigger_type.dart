/// How a Skill is activated — maps to the backend's `SkillTriggerType` enum.
enum SkillTriggerType {
  event,
  time,
  condition,
  command;

  String toJson() => name;

  static SkillTriggerType fromJson(String value) =>
      SkillTriggerType.values.firstWhere(
        (e) => e.name == value,
        orElse: () => SkillTriggerType.command,
      );
}
