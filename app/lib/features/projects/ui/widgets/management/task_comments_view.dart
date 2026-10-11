import 'package:flutter/material.dart';
import 'package:get/get.dart';

import 'package:imker/features/projects/domain/models/project_task.dart';
import 'package:imker/features/projects/ui/viewmodels/project_management_controller.dart';

/// Comentarios de una tarea, al estilo de Reddit: hilos anidados, votos a
/// favor/en contra, responder y colapsar un hilo.
class TaskCommentsView extends StatefulWidget {
  const TaskCommentsView({super.key, required this.taskId});

  final String taskId;

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

  void _send() {
    final text = _input.text.trim();
    if (text.isEmpty) return;
    Get.find<ProjectManagementController>().addComment(widget.taskId, text);
    _input.clear();
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectManagementController>();
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
              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
            ),
            onPressed: _send,
            child: const Text('Comentar'),
          ),
        ),
        const SizedBox(height: 8),
        Obx(() {
          final comments = controller.taskById(widget.taskId)?.comments ?? const [];
          final total = comments.fold<int>(0, (sum, c) => sum + c.threadSize);
          if (comments.isEmpty) {
            return Padding(
              padding: const EdgeInsets.only(top: 16),
              child: Text(
                'Aún no hay comentarios. ¡Sé el primero!',
                textAlign: TextAlign.center,
                style: tt.bodyMedium,
              ),
            );
          }
          return Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                '$total comentario${total == 1 ? '' : 's'}',
                style: tt.labelLarge?.copyWith(color: cs.onSurfaceVariant),
              ),
              Divider(color: cs.outline),
              for (final c in comments)
                _CommentNode(key: ValueKey(c.id), taskId: widget.taskId, comment: c),
            ],
          );
        }),
      ],
    );
  }
}

class _CommentNode extends StatefulWidget {
  const _CommentNode({super.key, required this.taskId, required this.comment});

  final String taskId;
  final TaskComment comment;

  @override
  State<_CommentNode> createState() => _CommentNodeState();
}

class _CommentNodeState extends State<_CommentNode> {
  bool _collapsed = false;
  bool _replying = false;
  final _reply = TextEditingController();

  @override
  void dispose() {
    _reply.dispose();
    super.dispose();
  }

  void _sendReply() {
    final text = _reply.text.trim();
    if (text.isEmpty) return;
    Get.find<ProjectManagementController>().addComment(
      widget.taskId,
      text,
      parentId: widget.comment.id,
    );
    _reply.clear();
    setState(() => _replying = false);
  }

  @override
  Widget build(BuildContext context) {
    final controller = Get.find<ProjectManagementController>();
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final c = widget.comment;

    final upColor = c.userVote == 1 ? cs.primary : cs.onSurfaceVariant;
    final downColor = c.userVote == -1 ? cs.tertiary : cs.onSurfaceVariant;

    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Encabezado: tocarlo colapsa o expande el hilo.
          InkWell(
            onTap: () => setState(() => _collapsed = !_collapsed),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 11,
                  backgroundColor: cs.tertiaryContainer,
                  child: Text(
                    c.author.isEmpty ? '?' : c.author[0].toUpperCase(),
                    style: TextStyle(fontSize: 11, color: cs.onTertiaryContainer),
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: Text(
                    c.author,
                    overflow: TextOverflow.ellipsis,
                    style: tt.labelLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                ),
                Text(
                  ' · ${_timeAgo(c.createdAt)}',
                  style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                ),
                if (_collapsed)
                  Text(
                    ' · ${c.threadSize} ${c.threadSize == 1 ? 'comentario' : 'comentarios'}',
                    style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                  ),
                const Spacer(),
                Icon(
                  _collapsed ? Icons.unfold_more : Icons.unfold_less,
                  size: 16,
                  color: cs.onSurfaceVariant,
                ),
              ],
            ),
          ),
          if (!_collapsed)
            Container(
              margin: const EdgeInsets.only(left: 10, top: 4),
              padding: const EdgeInsets.only(left: 12),
              decoration: BoxDecoration(
                border: Border(left: BorderSide(color: cs.outline.withValues(alpha: 0.6), width: 2)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(c.body, style: tt.bodyMedium),
                  const SizedBox(height: 4),
                  Row(
                    children: [
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'A favor',
                        icon: Icon(Icons.arrow_upward, size: 18, color: upColor),
                        onPressed: () => controller.voteComment(widget.taskId, c.id, 1),
                      ),
                      Text(
                        '${c.score}',
                        style: tt.labelLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: c.userVote == 1
                              ? cs.primary
                              : c.userVote == -1
                              ? cs.tertiary
                              : null,
                        ),
                      ),
                      IconButton(
                        visualDensity: VisualDensity.compact,
                        tooltip: 'En contra',
                        icon: Icon(Icons.arrow_downward, size: 18, color: downColor),
                        onPressed: () => controller.voteComment(widget.taskId, c.id, -1),
                      ),
                      TextButton.icon(
                        onPressed: () => setState(() => _replying = !_replying),
                        icon: const Icon(Icons.chat_bubble_outline, size: 16),
                        label: const Text('Responder'),
                      ),
                    ],
                  ),
                  if (_replying)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 6),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          TextField(
                            controller: _reply,
                            autofocus: true,
                            minLines: 1,
                            maxLines: 4,
                            decoration: InputDecoration(
                              hintText: 'Responder a ${c.author}...',
                              isDense: true,
                              filled: true,
                              fillColor: cs.surface,
                              border: OutlineInputBorder(
                                borderRadius: BorderRadius.zero,
                                borderSide: BorderSide(color: cs.outline),
                              ),
                            ),
                          ),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.end,
                            children: [
                              TextButton(
                                onPressed: () => setState(() => _replying = false),
                                child: const Text('Cancelar'),
                              ),
                              FilledButton(
                                style: FilledButton.styleFrom(
                                  shape: const RoundedRectangleBorder(
                                    borderRadius: BorderRadius.zero,
                                  ),
                                ),
                                onPressed: _sendReply,
                                child: const Text('Responder'),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                  for (final reply in c.replies)
                    _CommentNode(key: ValueKey(reply.id), taskId: widget.taskId, comment: reply),
                ],
              ),
            ),
        ],
      ),
    );
  }
}

String _timeAgo(DateTime date) {
  final diff = DateTime.now().difference(date);
  if (diff.inMinutes < 1) return 'ahora';
  if (diff.inMinutes < 60) return 'hace ${diff.inMinutes} min';
  if (diff.inHours < 24) return 'hace ${diff.inHours} h';
  return 'hace ${diff.inDays} d';
}
