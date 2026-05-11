import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../core/constants/app_theme.dart';
import '../../core/constants/app_strings.dart';
import '../../core/utils/date_utils.dart';
import '../../data/models/task.dart';
import '../../domain/ai_engine/voice_parser.dart';
import '../../providers/task_provider.dart';

final isListeningProvider = StateProvider<bool>((ref) => false);

class VoiceInputButton extends ConsumerWidget {
  const VoiceInputButton({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final isListening = ref.watch(isListeningProvider);

    return GestureDetector(
      onTap: () => _showVoiceSheet(context, ref),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          gradient: AppTheme.primaryGradient,
          shape: BoxShape.circle,
          boxShadow: [
            BoxShadow(
              color: AppTheme.primary.withOpacity(0.4),
              blurRadius: 14,
              spreadRadius: isListening ? 3 : 0,
            ),
          ],
        ),
        child: Icon(
          isListening ? Icons.mic : Icons.mic_none,
          color: Colors.white,
          size: 20,
        ),
      ),
    );
  }

  void _showVoiceSheet(BuildContext context, WidgetRef ref) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => _VoiceSheet(ref: ref),
    );
  }
}

// ── Voice Sheet ─────────────────────────────────────────────────────────────
class _VoiceSheet extends StatefulWidget {
  final WidgetRef ref;
  const _VoiceSheet({required this.ref});

  @override
  State<_VoiceSheet> createState() => _VoiceSheetState();
}

class _VoiceSheetState extends State<_VoiceSheet> {
  final _controller = TextEditingController();
  bool _showInput = false;
  String _simulated = '';
  bool _isSimulating = false;

  final _examples = [
    'morning tasks',
    'long tasks evening',
    'show short tasks',
    'high priority',
    'all tasks',
    'утром долгие задачи',
    'вечером короткие',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _simulateVoice() async {
    setState(() => _isSimulating = true);
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;
    setState(() {
      _isSimulating = false;
      _simulated = 'Do all long tasks in the morning';
      _controller.text = _simulated;
      _showInput = true;
    });
  }

  void _process(String text) {
    if (text.trim().isEmpty) return;
    Navigator.pop(context);

    final parser = VoiceIntentParser();
    final command = parser.parse(text.trim());
    final allTasks = widget.ref.read(taskNotifierProvider);

    final hasFilters = command.timeFilter != null ||
        command.durationFilter != null ||
        command.priorityFilter != null;

    final filtered = hasFilters
        ? parser.applyFilter(allTasks, command)
        : allTasks;

    _showResults(context, widget.ref, command, filtered, parser, text.trim());
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: Container(
        padding: const EdgeInsets.fromLTRB(20, 10, 20, 24),
        decoration: const BoxDecoration(
          color: AppTheme.surface,
          borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 40, height: 4,
              decoration: BoxDecoration(
                  color: AppTheme.surfaceLight,
                  borderRadius: BorderRadius.circular(2)),
            ),
            const SizedBox(height: 16),
            const Row(children: [
              Icon(Icons.mic, color: AppTheme.primaryLight, size: 20),
              SizedBox(width: 8),
              Text('Voice Command',
                  style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w600,
                      color: AppTheme.textPrimary)),
            ]),
            const SizedBox(height: 4),
            const Align(
              alignment: Alignment.centerLeft,
              child: Text('Hold mic to record, or type / pick a hint',
                  style: TextStyle(fontSize: 12, color: AppTheme.textMuted)),
            ),
            const SizedBox(height: 16),

            GestureDetector(
              onTap: _simulateVoice,
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 300),
                width: 64,
                height: 64,
                decoration: BoxDecoration(
                  gradient: _isSimulating
                      ? const LinearGradient(
                          colors: [AppTheme.highPriority, AppTheme.mediumPriority])
                      : AppTheme.primaryGradient,
                  shape: BoxShape.circle,
                  boxShadow: [
                    BoxShadow(
                      color: (_isSimulating
                              ? AppTheme.highPriority
                              : AppTheme.primary)
                          .withOpacity(0.5),
                      blurRadius: 18,
                      spreadRadius: _isSimulating ? 5 : 2,
                    ),
                  ],
                ),
                child: Icon(
                  _isSimulating ? Icons.mic : Icons.mic_none,
                  color: Colors.white,
                  size: 26,
                ),
              ),
            ),
            const SizedBox(height: 6),
            Text(
              _isSimulating ? 'Listening...' : 'Tap to record',
              style: TextStyle(
                  fontSize: 12,
                  color: _isSimulating
                      ? AppTheme.highPriority
                      : AppTheme.textMuted),
            ),

            const SizedBox(height: 16),

            if (_showInput || _simulated.isNotEmpty) ...[
              TextField(
                controller: _controller,
                style: const TextStyle(
                    color: AppTheme.textPrimary, fontSize: 14),
                decoration: InputDecoration(
                  hintText: 'Edit or type your command...',
                  hintStyle: const TextStyle(
                      color: AppTheme.textMuted, fontSize: 13),
                  filled: true,
                  fillColor: AppTheme.cardBg,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: BorderSide.none,
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                    borderSide: const BorderSide(
                        color: AppTheme.primary, width: 1.5),
                  ),
                  prefixIcon: const Icon(Icons.edit_outlined,
                      color: AppTheme.textMuted, size: 16),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.clear,
                        color: AppTheme.textMuted, size: 16),
                    onPressed: () => _controller.clear(),
                  ),
                  contentPadding: const EdgeInsets.symmetric(vertical: 12),
                ),
                onSubmitted: _process,
              ),
              const SizedBox(height: 10),
            ] else ...[
              TextButton.icon(
                onPressed: () => setState(() => _showInput = true),
                icon: const Icon(Icons.keyboard_alt_outlined,
                    size: 14, color: AppTheme.textSecondary),
                label: const Text('Type instead',
                    style: TextStyle(
                        color: AppTheme.textSecondary, fontSize: 12)),
              ),
              const SizedBox(height: 6),
            ],

            SizedBox(
              height: 30,
              child: ListView(
                scrollDirection: Axis.horizontal,
                children: _examples
                    .map((e) => _ExampleChip(
                          text: e,
                          onTap: () {
                            _controller.text = e;
                            setState(() => _showInput = true);
                          },
                        ))
                    .toList(),
              ),
            ),

            const SizedBox(height: 12),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton.icon(
                onPressed: () => _process(_controller.text),
                icon: const Icon(Icons.search, size: 16),
                label: const Text('Find & Filter Tasks'),
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppTheme.primary,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12)),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showResults(
    BuildContext context,
    WidgetRef ref,
    VoiceCommand command,
    List<Task> tasks,
    VoiceIntentParser parser,
    String originalText,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (ctx) => DraggableScrollableSheet(
        initialChildSize: 0.55,
        maxChildSize: 0.9,
        minChildSize: 0.3,
        builder: (_, controller) => Container(
          decoration: const BoxDecoration(
            color: AppTheme.surface,
            borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
          ),
          child: Column(
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 10, 20, 0),
                child: Column(
                  children: [
                    Container(
                      width: 40, height: 4,
                      decoration: BoxDecoration(
                          color: AppTheme.surfaceLight,
                          borderRadius: BorderRadius.circular(2)),
                    ),
                    const SizedBox(height: 12),
                    Row(children: [
                      Container(
                        padding: const EdgeInsets.all(7),
                        decoration: BoxDecoration(
                          color: AppTheme.primary.withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: const Icon(Icons.mic,
                            color: AppTheme.primaryLight, size: 14),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text('Recognized',
                                style: TextStyle(
                                    fontSize: 10,
                                    color: AppTheme.textMuted,
                                    fontWeight: FontWeight.w500)),
                            Text(originalText,
                                style: const TextStyle(
                                    fontSize: 13,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w500),
                                maxLines: 2,
                                overflow: TextOverflow.ellipsis),
                          ],
                        ),
                      ),
                    ]),
                    const SizedBox(height: 8),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppTheme.accent.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                            color: AppTheme.accent.withOpacity(0.25)),
                      ),
                      child: Row(children: [
                        const Icon(Icons.auto_awesome,
                            color: AppTheme.accent, size: 12),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(
                              parser.generateExplanation(command),
                              style: const TextStyle(
                                  fontSize: 11,
                                  color: AppTheme.accent,
                                  fontWeight: FontWeight.w500)),
                        ),
                      ]),
                    ),
                    const SizedBox(height: 4),
                    Align(
                      alignment: Alignment.centerLeft,
                      child: Text(
                        tasks.isEmpty
                            ? 'No tasks found'
                            : '${tasks.length} task${tasks.length == 1 ? '' : 's'} found',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted),
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
              Expanded(
                child: tasks.isEmpty
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Icon(Icons.search_off,
                                size: 40, color: AppTheme.textMuted),
                            const SizedBox(height: 8),
                            const Text('No tasks found',
                                style: TextStyle(
                                    fontSize: 15,
                                    color: AppTheme.textPrimary,
                                    fontWeight: FontWeight.w600)),
                            const SizedBox(height: 4),
                            const Text('Try a different query',
                                style: TextStyle(
                                    color: AppTheme.textMuted,
                                    fontSize: 12)),
                          ],
                        ),
                      )
                    : ListView.builder(
                        controller: controller,
                        padding: const EdgeInsets.fromLTRB(20, 4, 20, 60),
                        itemCount: tasks.length,
                        itemBuilder: (_, i) =>
                            _ResultCard(task: tasks[i]),
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _ExampleChip extends StatelessWidget {
  final String text;
  final VoidCallback onTap;
  const _ExampleChip({required this.text, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        margin: const EdgeInsets.only(right: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          color: AppTheme.primary.withOpacity(0.1),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppTheme.primary.withOpacity(0.3)),
        ),
        child: Text(text,
            style: const TextStyle(
                fontSize: 11,
                color: AppTheme.primaryLight,
                fontWeight: FontWeight.w500)),
      ),
    );
  }
}

class _ResultCard extends StatelessWidget {
  final Task task;
  const _ResultCard({required this.task});

  Color _color(Priority p) {
    switch (p) {
      case Priority.high: return AppTheme.highPriority;
      case Priority.medium: return AppTheme.mediumPriority;
      case Priority.low: return AppTheme.lowPriority;
    }
  }

  @override
  Widget build(BuildContext context) {
    final c = _color(task.priority);
    return Container(
      margin: const EdgeInsets.only(bottom: 6),
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: AppTheme.cardBg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppTheme.surfaceLight.withOpacity(0.5)),
      ),
      child: Row(
        children: [
          Container(
              width: 3,
              height: 32,
              decoration: BoxDecoration(
                  color: c, borderRadius: BorderRadius.circular(2))),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(task.title,
                    style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppTheme.textPrimary),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Wrap(
                  spacing: 4,
                  children: [
                    Text(AppDateUtils.formatDuration(task.estimatedMinutes),
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted)),
                    if (task.scheduledStart != null) ...[
                      Text('·',
                          style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                      Text(AppDateUtils.formatTime(task.scheduledStart!),
                          style: const TextStyle(
                              fontSize: 10, color: AppTheme.primaryLight)),
                    ],
                    Text('·',
                        style: TextStyle(color: AppTheme.textMuted, fontSize: 10)),
                    Text('due ${task.deadline.day}.${task.deadline.month}',
                        style: const TextStyle(
                            fontSize: 10, color: AppTheme.textMuted)),
                  ],
                ),
              ],
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
                color: c.withOpacity(0.12),
                borderRadius: BorderRadius.circular(6)),
            child: Text(
              task.scheduledStart != null ? 'Scheduled' : 'Unscheduled',
              style: TextStyle(
                  fontSize: 9, fontWeight: FontWeight.w600, color: c),
            ),
          ),
        ],
      ),
    );
  }
}
