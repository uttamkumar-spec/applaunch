/// A rule deciding whether an athlete's AI chat message gets an instant AI
/// reply ("auto_respond") or must go to their coach ("route_to_coach").
/// Platform-scope rules (scope == 'platform') are admin-authored and apply
/// to every athlete; coach-scope rules apply only to that coach's own
/// athletes, layered on top of the platform defaults.
class GuardrailRule {
  GuardrailRule({
    required this.id,
    required this.scope,
    required this.label,
    required this.keywords,
    required this.action,
    required this.enabled,
    this.coachId,
    this.responseInstructions,
    this.priority = 100,
  });

  final String id;
  final String scope; // 'platform' | 'coach'
  final String? coachId;
  final String label;
  final List<String> keywords;
  final String action; // 'route_to_coach' | 'auto_respond'
  final String? responseInstructions;
  final int priority;
  final bool enabled;

  bool get isAutoRespond => action == 'auto_respond';

  factory GuardrailRule.fromJson(Map<String, dynamic> j) => GuardrailRule(
        id: j['id'] as String,
        scope: j['scope'] as String,
        coachId: j['coach_id'] as String?,
        label: j['label'] as String? ?? '',
        keywords: (j['keywords'] as List? ?? []).cast<String>(),
        action: j['action'] as String? ?? 'route_to_coach',
        responseInstructions: j['response_instructions'] as String?,
        priority: j['priority'] as int? ?? 100,
        enabled: j['enabled'] as bool? ?? true,
      );

  Map<String, dynamic> toJson() => {
        'label': label,
        'keywords': keywords,
        'action': action,
        'response_instructions': responseInstructions,
        'priority': priority,
        'enabled': enabled,
      };
}

class PendingCoachMessage {
  PendingCoachMessage({
    required this.id,
    required this.athleteId,
    required this.athleteName,
    required this.message,
    required this.createdAt,
    this.matchedRuleLabel,
    this.lifestyleSummary,
  });

  final String id;
  final String athleteId;
  final String athleteName;
  final String message;
  final String? matchedRuleLabel;
  final DateTime createdAt;
  final String? lifestyleSummary;

  factory PendingCoachMessage.fromJson(Map<String, dynamic> j) => PendingCoachMessage(
        id: j['id'] as String,
        athleteId: j['athlete_id'] as String,
        athleteName: j['athlete_name'] as String? ?? 'Athlete',
        message: j['message'] as String? ?? '',
        matchedRuleLabel: j['matched_rule_label'] as String?,
        createdAt: DateTime.parse(j['created_at'] as String),
        lifestyleSummary: j['lifestyle_summary'] as String?,
      );
}
