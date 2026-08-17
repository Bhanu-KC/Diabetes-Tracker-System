// Insulin Tracker screen showing logged insulin doses.


import 'dart:async';

import 'package:flutter/material.dart';
import 'add_insulin_screen.dart';
import '../database/entities/insulin_entity.dart';
import '../database/repositories/insulin_repository.dart';
import '../services/notification_service.dart';
import '../theme/app_theme.dart';

/// Lists and manages all insulin records.
class InsulinScreen extends StatefulWidget {
  const InsulinScreen({super.key});

  @override
  State<InsulinScreen> createState() => _InsulinScreenState();
}

class _InsulinScreenState extends State<InsulinScreen> {
  /// Search box controller and current query.
  final _searchController = TextEditingController();
  String _searchQuery = '';

  /// Live insulin list, null while loading.
  List<InsulinEntity>? _records;

  /// Load error shown instead of the list.
  String? _error;

  /// Insulin stream subscription, cancelled in [dispose].
  StreamSubscription<List<InsulinEntity>>? _recordsSub;

  @override
  void initState() {
    super.initState();
    _init();
  }

  /// Starts listening to the live insulin stream.
  Future<void> _init() async {
    try {
      final repo = await InsulinRepository.getInstance();
      if (!mounted) return;
      _recordsSub = repo.watchAll().listen(
        (records) {
          if (mounted) setState(() => _records = records);
        },
        onError: (e) {
          if (mounted) setState(() => _error = '$e');
        },
      );
    } catch (e) {
      if (mounted) setState(() => _error = '$e');
    }
  }

  @override
  void dispose() {
    _searchController.dispose();
    _recordsSub?.cancel();
    super.dispose();
  }

  /// Insulin records filtered by the search query.
  List<InsulinEntity> get _filtered {
    final records = _records ?? const [];
    if (_searchQuery.isEmpty) return records;
    return records
        .where((i) => i.name.toLowerCase().contains(_searchQuery.toLowerCase()))
        .toList();
  }

  /// Opens the Add Insulin screen in edit mode.
  Future<void> _openEdit(InsulinEntity record) async {
    await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => AddInsulinScreen(existing: record)),
    );
  }

  /// Asks for confirmation, then deletes the record.
  Future<void> _confirmDelete(InsulinEntity record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Delete Insulin Record'),
        content: Text('${record.name} (${_formatDose(record.dose)})?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Delete',
              style: TextStyle(color: AppColors.errorRed),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    try {
      final repo = await InsulinRepository.getInstance();
      await repo.delete(record);
      // Cancel the reminder for the deleted record.
      await NotificationService.instance.cancelNotification(
        NotificationService.insulinNotificationId(record.id!),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Insulin record deleted'),
          backgroundColor: AppColors.softGreen,
        ),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Failed to delete insulin record: $e'),
          backgroundColor: AppColors.errorRed,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      backgroundColor: AppColors.backgroundGrey,
      appBar: AppBar(title: const Text('Insulin Tracker')),
      body: _buildBody(theme),
      // Opens the Add Insulin screen.
      floatingActionButton: FloatingActionButton(
        onPressed: () => Navigator.push(
          context,
          MaterialPageRoute(builder: (_) => const AddInsulinScreen()),
        ),
        child: const Icon(Icons.add),
      ),
    );
  }

  /// Body: error, spinner, or the search box plus list.
  Widget _buildBody(ThemeData theme) {
    if (_error != null) {
      return _messageState(theme, Icons.error_outline, _error!);
    }
    final records = _records;
    if (records == null) {
      // Spinner while loading.
      return const Center(child: CircularProgressIndicator());
    }

    final filtered = _filtered;
    return Column(
      children: [
        // Search box to filter the list.
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: TextField(
            controller: _searchController,
            onChanged: (v) => setState(() => _searchQuery = v),
            decoration: InputDecoration(
              hintText: 'Search insulin...',
              prefixIcon: const Icon(Icons.search),
              // Clear button while a query is active.
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () {
                        _searchController.clear();
                        setState(() => _searchQuery = '');
                      },
                    )
                  : null,
            ),
          ),
        ),
        const SizedBox(height: 12),
        // Insulin cards, or the empty state.
        Expanded(
          child: filtered.isEmpty
              ? _emptyState(theme)
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (_, i) => _InsulinCard(
                    data: filtered[i],
                    onTap: () => _openEdit(filtered[i]),
                    onLongPress: () => _confirmDelete(filtered[i]),
                  ),
                ),
        ),
      ],
    );
  }

  /// Centered icon and message for the error state.
  Widget _messageState(ThemeData theme, IconData icon, String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            Text(
              message,
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.subtitleGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Empty state with a hint.
  Widget _emptyState(ThemeData theme) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.biotech_outlined, size: 80, color: Colors.grey.shade300),
            const SizedBox(height: 16),
            Text(
              'No insulin records found',
              style: theme.textTheme.displaySmall?.copyWith(
                color: AppColors.subtitleGrey,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              _searchQuery.isNotEmpty
                  ? 'Try a different search term'
                  : 'Tap + to add your first insulin record',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: AppColors.subtitleGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Formats a dose: whole numbers lose the decimal part.
String _formatDose(double dose) {
  if (dose == dose.roundToDouble()) return dose.toInt().toString();
  return dose.toString();
}

/// Converts "HH:mm" to a 12-hour time like "2:30 PM".
String _formatTime(String time) {
  final parts = time.split(':');
  if (parts.length != 2) return time;
  final hour = int.tryParse(parts[0]) ?? 8;
  final minute = int.tryParse(parts[1]) ?? 0;
  final period = hour >= 12 ? 'PM' : 'AM';
  final h12 = hour % 12 == 0 ? 12 : hour % 12;
  return '$h12:${minute.toString().padLeft(2, '0')} $period';
}

/// One insulin record shown as a tappable card.
class _InsulinCard extends StatelessWidget {
  final InsulinEntity data;
  final VoidCallback onTap;
  final VoidCallback onLongPress;
  const _InsulinCard({
    required this.data,
    required this.onTap,
    required this.onLongPress,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        onLongPress: onLongPress,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              // Rounded icon box on the left.
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: AppColors.lightBlue,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.biotech,
                  color: AppColors.primaryBlue,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              // Name, chips and injection time.
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      data.name,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 4),
                    // Dose and site chips.
                    Row(
                      children: [
                        _chip(Icons.science, '${_formatDose(data.dose)} units'),
                        const SizedBox(width: 6),
                        _chip(Icons.location_on_outlined, data.site),
                      ],
                    ),
                    const SizedBox(height: 6),
                    // Injection time with a clock icon.
                    Row(
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: AppColors.subtitleGrey,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          _formatTime(data.time),
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              // Check mark showing the dose was logged.
              Icon(
                Icons.check_circle_outline,
                color: AppColors.softGreen.withValues(alpha: 0.6),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Small grey pill for dose/site info.
  Widget _chip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: AppColors.backgroundGrey,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: AppColors.subtitleGrey),
          const SizedBox(width: 4),
          Text(
            text,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade700),
          ),
        ],
      ),
    );
  }
}
