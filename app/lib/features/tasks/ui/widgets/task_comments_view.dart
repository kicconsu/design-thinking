import 'package:flutter/material.dart';

import 'package:imker/core/widgets/profile_avatar.dart';

import '../../domain/models/task_comment.dart';
import 'package:imker/core/utils/clock.dart';

/// Comentarios de una tarea: caja para escribir y la lista, del más nuevo al
/// más viejo.
class TaskCommentsView extends StatefulWidget {
  const TaskCommentsView({
    super.key,
    required this.comments,
    required this.isLoading,
    required this.loaded,
    required this.isSending,
    required this.authorOf,
    required this.onSend,
    this.error,
    this.onRetry,
    this.clock = systemClock,
  });

  final List<TaskComment> comments;
  final bool isLoading;

  /// Si ya hubo un primer intento de carga.
  final bool loaded;
  final bool isSending;
  final String Function(TaskComment comment) authorOf;

  /// Devuelve null si el comentario se guardó o el mensaje de error.
  final Future<String?> Function(String body) onSend;
  final String? error;
  final VoidCallback? onRetry;
  final Clock clock;

  @override
  State<TaskCommentsView> createState() => _TaskCommentsViewState();
}

class _TaskCommentsViewState extends State<TaskCommentsView> {
  final _input = TextEditingController();

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final error = await widget.onSend(_input.text);
    if (!mounted) return;
    if (error == null) {
      _input.clear();
    } else {
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(SnackBar(content: Text(error)));
    }
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: _input,
          minLines: 2,
          maxLines: 5,
          decoration: InputDecoration(
            hintText: 'Añade un comentario...',
            filled: true,
            fillColor: cs.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.zero,
              borderSide: BorderSide(color: cs.outline),
            ),
          ),
        ),
        const SizedBox(height: 6),
        Align(
          alignment: Alignment.centerRight,
          child: FilledButton(
            style: FilledButton.styleFrom(
              shape: const RoundedRectangleBorder(
                borderRadius: BorderRadius.zero,
              ),
            ),
            onPressed: widget.isSending ? null : _send,
            child: widget.isSending
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('Comentar'),
          ),
        ),
        const SizedBox(height: 8),
        ..._list(context, tt, cs),
      ],
    );
  }

  List<Widget> _list(BuildContext context, TextTheme tt, ColorScheme cs) {
    if (widget.comments.isEmpty) {
      if (widget.isLoading || !widget.loaded) {
        return const [
          Padding(
            padding: EdgeInsets.only(top: 16),
            child: Center(child: CircularProgressIndicator()),
          ),
        ];
      }
      return [
        Padding(
          padding: const EdgeInsets.only(top: 16),
          child: Column(
            children: [
              Text(
                widget.error ?? 'Aún no hay comentarios. ¡Sé el primero!',
                textAlign: TextAlign.center,
                style: tt.bodyMedium,
              ),
              if (widget.error != null && widget.onRetry != null)
                TextButton(
                  onPressed: widget.onRetry,
                  child: const Text('Reintentar'),
                ),
            ],
          ),
        ),
      ];
    }

    final total = widget.comments.length;
    return [
      Text(
        '$total comentario${total == 1 ? '' : 's'}',
        style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
      ),
      Divider(color: cs.outline),
      for (final comment in widget.comments)
        _CommentTile(
          comment: comment,
          author: widget.authorOf(comment),
          clock: widget.clock,
        ),
    ];
  }
}

class _CommentTile extends StatelessWidget {
  const _CommentTile({
    required this.comment,
    required this.author,
    required this.clock,
  });

  final TaskComment comment;
  final String author;
  final Clock clock;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final when = _timeAgo(comment.createdAt, clock);

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              ProfileAvatar(name: author, radius: 11),
              const SizedBox(width: 8),
              Flexible(
                child: Text(
                  author,
                  overflow: TextOverflow.ellipsis,
                  style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                ),
              ),
              if (when != null)
                Text(
                  ' · $when',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
            ],
          ),
          Container(
            margin: const EdgeInsets.only(left: 10, top: 4),
            padding: const EdgeInsets.only(left: 12),
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(
                  color: cs.outline.withValues(alpha: 0.6),
                  width: 2,
                ),
              ),
            ),
            child: Align(
              alignment: Alignment.centerLeft,
              child: Text(comment.body, style: tt.bodyMedium),
            ),
          ),
        ],
      ),
    );
  }
}

String? _timeAgo(DateTime? date, Clock clock) {
  if (date == null) return null;
  final diff = clock().difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return 'hace ${diff.inDays} d';
}
