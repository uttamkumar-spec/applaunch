import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_provider.dart';
import '../models/admin_models.dart';
import '../providers/admin_provider.dart';

class AdminHomeScreen extends ConsumerWidget {
  const AdminHomeScreen({super.key});

  void _showCreateUser(BuildContext context, WidgetRef ref) {
    final name = TextEditingController();
    final email = TextEditingController();
    final password = TextEditingController();
    String role = 'athlete';
    bool submitting = false;
    String? error;

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setState) => Padding(
          padding: EdgeInsets.only(
            left: 20,
            right: 20,
            top: 20,
            bottom: MediaQuery.of(ctx).viewInsets.bottom + 20,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Create user', style: Theme.of(ctx).textTheme.titleLarge),
              const SizedBox(height: 16),
              TextField(controller: name, decoration: const InputDecoration(labelText: 'Full name')),
              const SizedBox(height: 12),
              TextField(controller: email, decoration: const InputDecoration(labelText: 'Email')),
              const SizedBox(height: 12),
              TextField(
                controller: password,
                obscureText: true,
                decoration: const InputDecoration(labelText: 'Temporary password'),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: role,
                decoration: const InputDecoration(labelText: 'Role'),
                items: const [
                  DropdownMenuItem(value: 'athlete', child: Text('Athlete')),
                  DropdownMenuItem(value: 'coach', child: Text('Coach')),
                  DropdownMenuItem(value: 'admin', child: Text('Admin')),
                ],
                onChanged: (v) => setState(() => role = v ?? 'athlete'),
              ),
              if (error != null) ...[
                const SizedBox(height: 10),
                Text(error!, style: TextStyle(color: Theme.of(ctx).colorScheme.error)),
              ],
              const SizedBox(height: 16),
              ElevatedButton(
                onPressed: submitting
                    ? null
                    : () async {
                        setState(() => submitting = true);
                        try {
                          await ref.read(adminServiceProvider).createUser(
                                name: name.text.trim(),
                                email: email.text.trim(),
                                password: password.text,
                                role: role,
                              );
                          ref.invalidate(adminUsersProvider);
                          if (ctx.mounted) Navigator.of(ctx).pop();
                        } catch (e) {
                          setState(() {
                            error = 'Could not create user. Check the details and try again.';
                            submitting = false;
                          });
                        }
                      },
                child: submitting
                    ? const SizedBox(
                        height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Text('Create'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final usersAsync = ref.watch(adminUsersProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Admin'),
        actions: [
          IconButton(
            icon: const Icon(Icons.tune_rounded),
            onPressed: () => context.push('/admin/limits'),
          ),
          IconButton(
            icon: const Icon(Icons.logout_rounded),
            onPressed: () async {
              await ref.read(authControllerProvider).signOut();
              if (context.mounted) context.go('/login');
            },
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreateUser(context, ref),
        icon: const Icon(Icons.person_add_alt_1_rounded),
        label: const Text('New user'),
      ),
      body: RefreshIndicator(
        onRefresh: () async => ref.invalidate(adminUsersProvider),
        child: usersAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(child: Text('Could not load users: $e')),
          data: (users) {
            if (users.isEmpty) {
              return ListView(
                children: const [
                  Padding(
                    padding: EdgeInsets.all(40),
                    child: Text('No users yet.'),
                  ),
                ],
              );
            }
            return ListView.builder(
              padding: const EdgeInsets.all(20),
              itemCount: users.length,
              itemBuilder: (context, i) {
                final u = users[i];
                return Card(
                  child: ListTile(
                    leading: CircleAvatar(
                      backgroundColor: AppColors.primaryLight,
                      child: Text(
                        u.name.isNotEmpty ? u.name[0].toUpperCase() : '?',
                        style: const TextStyle(color: AppColors.primaryDark),
                      ),
                    ),
                    title: Text(u.name),
                    subtitle: Text(u.email),
                    trailing: Chip(label: Text(u.role)),
                  ),
                );
              },
            );
          },
        ),
      ),
    );
  }
}

class AdminLimitsScreen extends ConsumerStatefulWidget {
  const AdminLimitsScreen({super.key});

  @override
  ConsumerState<AdminLimitsScreen> createState() => _AdminLimitsScreenState();
}

class _AdminLimitsScreenState extends ConsumerState<AdminLimitsScreen> {
  final _athletesController = TextEditingController();
  final _messagesController = TextEditingController();
  bool _initialized = false;
  bool _saving = false;

  void _populate(PlatformLimits limits) {
    if (_initialized) return;
    _athletesController.text = limits.maxAthletesPerCoach.toString();
    _messagesController.text = limits.dailyAiMessagesPerAthlete.toString();
    _initialized = true;
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    final limits = PlatformLimits(
      maxAthletesPerCoach: int.tryParse(_athletesController.text) ?? 20,
      dailyAiMessagesPerAthlete: int.tryParse(_messagesController.text) ?? 50,
    );
    try {
      await ref.read(adminServiceProvider).updateLimits(limits);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Limits updated.')));
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(const SnackBar(content: Text("Couldn't save. Try again shortly.")));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final limitsAsync = ref.watch(platformLimitsProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Platform Limits')),
      body: limitsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Could not load limits: $e')),
        data: (limits) {
          _populate(limits);
          return Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextField(
                  controller: _athletesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Max athletes per coach'),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _messagesController,
                  keyboardType: TextInputType.number,
                  decoration: const InputDecoration(labelText: 'Daily AI messages per athlete'),
                ),
                const SizedBox(height: 24),
                ElevatedButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          height: 20, width: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                      : const Text('Save'),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
