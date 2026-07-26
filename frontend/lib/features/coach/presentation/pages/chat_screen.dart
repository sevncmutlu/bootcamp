import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/main.dart';
import 'package:maki_app/core/widgets/mascot.dart';
import 'package:maki_app/core/widgets/source_card.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_bloc.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_event.dart';
import 'package:maki_app/features/coach/presentation/bloc/coach_state.dart';
import 'package:maki_app/features/coach/domain/entities/coach_message_entity.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bloc = context.read<CoachBloc>();
    if (bloc.state.messages.isEmpty) {
      final welcome = AppLocalizations.of(context)!.welcomeMessage;
      bloc.add(InitChatEvent(welcome));
    }
  }

  void _sendMessage() {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    context.read<CoachBloc>().add(SendMessageEvent(text));
    _scrollToBottom();
  }

  void _scrollToBottom() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  Widget _buildSessionChip(
    BuildContext context, {
    required String label,
    required IconData icon,
    required String triggerMsg,
    required bool isLoading,
  }) {
    final theme = Theme.of(context);
    return ActionChip(
      onPressed: isLoading
          ? null
          : () {
              _messageController.text = triggerMsg;
              _sendMessage();
            },
      avatar: Icon(icon, size: 16, color: theme.colorScheme.primary),
      label: Text(
        label,
        style: TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: theme.colorScheme.primary,
        ),
      ),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      side: BorderSide(color: theme.colorScheme.primary.withValues(alpha: 0.3)),
      backgroundColor: theme.colorScheme.primary.withValues(alpha: 0.05),
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final l10n = AppLocalizations.of(context)!;

    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.menu_rounded),
          onPressed: () => MainNavigationScreen.openDrawer(),
        ),
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Mascot.avatar(pose: MascotPose.happy, size: 28),
            const SizedBox(width: 8),
            Text(
              l10n.navCoach,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ],
        ),
        centerTitle: true,
      ),
      body: BlocConsumer<CoachBloc, CoachState>(
        listener: (context, state) {
          if (!state.isLoading) {
            _scrollToBottom();
          }
        },
        builder: (context, state) {
          return Column(
            children: [
              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
                child: Card(
                  color: theme.colorScheme.surfaceContainerHighest.withValues(
                    alpha: 0.3,
                  ),
                  elevation: 0,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: theme.colorScheme.primary,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                l10n.privacyTitle,
                                style: theme.textTheme.labelMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: theme.colorScheme.primary,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                l10n.privacyMessage,
                                style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  height: 1.3,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              Padding(
                padding: const EdgeInsets.only(left: 16.0, right: 16.0, top: 12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      l10n.sessionHeader,
                      style: theme.textTheme.labelMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: theme.colorScheme.primary,
                      ),
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      height: 40,
                      child: ListView(
                        scrollDirection: Axis.horizontal,
                        children: [
                          _buildSessionChip(
                            context,
                            label: l10n.sessionWeeklyCheckin,
                            icon: Icons.calendar_today_outlined,
                            triggerMsg: l10n.promptWeeklyReview,
                            isLoading: state.isLoading,
                          ),
                          const SizedBox(width: 8),
                          _buildSessionChip(
                            context,
                            label: l10n.sessionDebtStrategy,
                            icon: Icons.calculate_outlined,
                            triggerMsg: l10n.promptDebtPlan,
                            isLoading: state.isLoading,
                          ),
                          const SizedBox(width: 8),
                          _buildSessionChip(
                            context,
                            label: l10n.sessionInflationGuide,
                            icon: Icons.trending_up_outlined,
                            triggerMsg: l10n.promptInflationImpact,
                            isLoading: state.isLoading,
                          ),
                          const SizedBox(width: 8),
                          _buildSessionChip(
                            context,
                            label: l10n.sessionSavingsHack,
                            icon: Icons.savings_outlined,
                            triggerMsg: l10n.promptSavingsAdvice,
                            isLoading: state.isLoading,
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              Expanded(
                child: ListView.builder(
                  controller: _scrollController,
                  padding: const EdgeInsets.all(16.0),
                  itemCount: state.messages.length + (state.isLoading ? 1 : 0),
                  itemBuilder: (context, index) {
                    if (index == state.messages.length) {
                      return const LoadingBubble();
                    }

                    final msg = state.messages[index];
                    return MessageBubble(message: msg);
                  },
                ),
              ),

              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 12.0,
                ),
                decoration: BoxDecoration(
                  color: theme.colorScheme.surface,
                  border: Border(
                    top: BorderSide(
                      color: theme.colorScheme.outline.withValues(alpha: 0.1),
                    ),
                  ),
                ),
                child: SafeArea(
                  child: Row(
                    children: [
                      Expanded(
                        child: TextField(
                          controller: _messageController,
                          decoration: InputDecoration(
                            hintText: l10n.chatPlaceholder,
                            hintStyle: TextStyle(
                              color: theme.colorScheme.onSurfaceVariant.withValues(
                                alpha: 0.5,
                              ),
                            ),
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(28.0),
                              borderSide: BorderSide.none,
                            ),
                            filled: true,
                            fillColor: theme.colorScheme.onSurface.withValues(
                              alpha: 0.05,
                            ),
                            contentPadding: const EdgeInsets.symmetric(
                              horizontal: 20.0,
                              vertical: 12.0,
                            ),
                          ),
                          textCapitalization: TextCapitalization.sentences,
                          onSubmitted: (_) => _sendMessage(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      IconButton(
                        onPressed: state.isLoading ? null : _sendMessage,
                        icon: Icon(
                          Icons.send_rounded,
                          color: state.isLoading
                              ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                              : theme.colorScheme.primary,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class MessageBubble extends StatelessWidget {
  final CoachMessageEntity message;

  const MessageBubble({super.key, required this.message});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final textStyle =
        theme.textTheme.bodyMedium?.copyWith(
          color: message.isUser
              ? theme.colorScheme.onPrimary
              : message.isError
              ? theme.colorScheme.onErrorContainer
              : theme.colorScheme.onSurface,
        ) ??
        const TextStyle();

    return Align(
      alignment: message.isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Column(
          crossAxisAlignment: message.isUser
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (!message.isUser) ...[
                  Mascot.avatar(
                    pose: message.isError
                        ? MascotPose.thinking
                        : MascotPose.happy,
                    size: 32,
                  ),
                  const SizedBox(width: 8),
                ],
                Flexible(
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16.0,
                      vertical: 12.0,
                    ),
                    decoration: BoxDecoration(
                      color: message.isUser
                          ? theme.colorScheme.primary
                          : message.isError
                          ? theme.colorScheme.errorContainer
                          : theme.colorScheme.onSurface.withValues(alpha: 0.05),
                      borderRadius: BorderRadius.only(
                        topLeft: const Radius.circular(16.0),
                        topRight: const Radius.circular(16.0),
                        bottomLeft: Radius.circular(
                          message.isUser ? 16.0 : 0.0,
                        ),
                        bottomRight: Radius.circular(
                          message.isUser ? 0.0 : 16.0,
                        ),
                      ),
                    ),
                    child: MarkdownBody(
                      data: message.text,
                      styleSheet: MarkdownStyleSheet.fromTheme(theme).copyWith(
                        p: textStyle,
                        strong: textStyle.copyWith(fontWeight: FontWeight.bold),
                      ),
                    ),
                  ),
                ),
                if (message.isUser) const SizedBox(width: 24),
              ],
            ),
            if (!message.isUser && message.sources.isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(left: 40, top: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    for (final source in message.sources)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 6),
                        child: SourceCard(
                          title:
                              '${source.institution} · ${source.seriesId} · '
                              '${source.value} ${source.unit}',
                          url: source.sourceUrl.toString(),
                          dataPeriod: source.period,
                        ),
                      ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class LoadingBubble extends StatelessWidget {
  const LoadingBubble({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Align(
      alignment: Alignment.centerLeft,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 4.0),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Mascot.avatar(pose: MascotPose.thinking, size: 32),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 16.0,
                vertical: 12.0,
              ),
              decoration: BoxDecoration(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.05),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(16.0),
                  topRight: Radius.circular(16.0),
                  bottomRight: Radius.circular(16.0),
                ),
              ),
              child: const SizedBox(
                width: 24,
                height: 12,
                child: Center(child: LinearProgressIndicator(minHeight: 2)),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
