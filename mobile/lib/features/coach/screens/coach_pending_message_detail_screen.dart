import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/models/guardrail_rule.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/coach_provider.dart';

/// One routed athlete question: shows the question plus a lifestyle summary
/// for context, lets the coach ask the AI follow-up questions about the
/// athlete, get an AI-drafted starting reply, edit it freely, and send the
/// final version to the athlete.
class CoachPendingMessageDetailScreen extends ConsumerStatefulWidget {
  const CoachPendingMessageDetailScreen({super.key, required this.pendingMessageId});
  final String pendingMessageId;

  @override
  ConsumerState<CoachPendingMessageDetailScreen> createState() => _CoachPendingMessageDetailScreenState();
}

class _CoachPendingMessageDetailScreenState extends ConsumerState<CoachPendingMessageDetailScreen> {
  PendingCoachMessage? _detail;
  bool _loading = true;
  String? _loadError;

  final _replyController = TextEditingController();
  final _askController = TextEditingController();
  String? _askAnswer;

  bool _asking = false;
  bool _drafting = false;
  bool _sending = false;
  String? _actionError;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    try {
      final detail = await ref.read(coachServiceProvider).fetchPendingMessageDetail(widget.pendingMessageId);
      if (mounted) setState(() => _detail = detail);
    } catch (e) {
      if (mounted) setState(() => _loadError = "Couldn't load this question.");
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _askAi() async {
    final question = _askController.text.trim();
    if (question.isEmpty) return;
    setState(() {
      _asking = true;
      _actionError = null;
    });
    try {
      final answer = await ref.read(coachServiceProvider).askAboutAthlete(widget.pendingMessageId, question);
      if (mounted) setState(() => _askAnswer = answer);
    } catch (_) {
      if (mounted) setState(() => _actionError = "Couldn't get an answer just now.");
    } finally {
      if (mounted) setState(() => _asking = false);
    }
  }

  Future<void> _getDraft() async {
    setState(() {
      _drafting = true;
      _actionError = null;
    });
    try {
      final draft = await ref.read(coachServiceProvider).draftReply(widget.pendingMessageId);
      if (mounted) setState(() => _replyController.text = draft);
    } catch (_) {
      if (mounted) setState(() => _actionError = "Couldn't get a draft just now.");
    } finally {
      if (mounted) setState(() => _drafting = false);
    }
  }

  Future<void> _send() async {
    final reply = _replyController.text.trim();
    if (reply.isEmpty) return;
    setState(() {
      _sending = true;
      _actionError = null;
    });
    try {
      await ref.read(coachServiceProvider).respondToPendingMessage(widget.pendingMessageId, reply);
      if (mounted) Navigator.of(context).pop();
    } catch (_) {
      if (mounted) {
        setState(() {
          _actionError = "Couldn't send just now — try again.";
          _sending = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_detail?.athleteName ?? 'Athlete question')),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _loadError != null
              ? Center(child: Text(_loadError!))
              : SingleChildScrollView(
                  padding: const EdgeInsets.all(20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Question', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 6),
                      Container(
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(color: AppColors.surface, borderRadius: BorderRadius.circular(12)),
                        child: Text(_detail!.message),
                      ),
                      if (_detail!.matchedRuleLabel != null) ...[
                        const SizedBox(height: 6),
                        Text('Routed by rule: ${_detail!.matchedRuleLabel}',
                            style: Theme.of(context).textTheme.bodySmall),
                      ],
                      const SizedBox(height: 20),
                      ExpansionTile(
                        tilePadding: EdgeInsets.zero,
                        title: const Text('Athlete lifestyle summary'),
                        childrenPadding: const EdgeInsets.only(bottom: 12),
                        children: [
                          Text(_detail!.lifestyleSummary ?? 'No data available yet.'),
                        ],
                      ),
                      const Divider(height: 32),
                      Text('Ask the AI about this athlete', style: Theme.of(context).textTheme.titleMedium),
                      const SizedBox(height: 4),
                      Text(
                        'For your own understanding only — never shown to the athlete.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: TextField(
                              controller: _askController,
                              decoration: const InputDecoration(hintText: 'e.g. what has this athlete logged this week?'),
                            ),
                          ),
                          IconButton(
                            onPressed: _asking ? null : _askAi,
                            icon: _asking
                                ? const SizedBox(height: 18, width: 18, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.send_rounded, color: AppColors.primary),
                          ),
                        ],
                      ),
                      if (_askAnswer != null) ...[
                        const SizedBox(height: 10),
                        Container(
                          padding: const EdgeInsets.all(14),
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(_askAnswer!, style: const TextStyle(color: AppColors.primaryDark)),
                        ),
                      ],
                      const Divider(height: 32),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('Your reply to the athlete', style: Theme.of(context).textTheme.titleMedium),
                          TextButton.icon(
                            onPressed: _drafting ? null : _getDraft,
                            icon: _drafting
                                ? const SizedBox(height: 16, width: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                : const Icon(Icons.auto_awesome_rounded, size: 18),
                            label: const Text('Get AI draft'),
                          ),
                        ],
                      ),
                      Text(
                        'A draft is a starting point — review and rephrase before sending.',
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: _replyController,
                        maxLines: 6,
                        decoration: const InputDecoration(
                          hintText: 'Write your reply, or tap "Get AI draft" for a starting point…',
                          border: OutlineInputBorder(),
                        ),
                      ),
                      if (_actionError != null) ...[
                        const SizedBox(height: 8),
                        Text(_actionError!, style: TextStyle(color: Theme.of(context).colorScheme.error)),
                      ],
                      const SizedBox(height: 16),
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _sending ? null : _send,
                          child: _sending
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                                )
                              : const Text('Send to athlete'),
                        ),
                      ),
                    ],
                  ),
                ),
    );
  }
}
