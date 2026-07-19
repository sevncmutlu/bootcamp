import 'dart:developer' as developer;

import 'package:flutter/material.dart';
import 'package:flutter_markdown_plus/flutter_markdown_plus.dart';
import 'package:maki_app/l10n/app_localizations.dart';
import 'package:maki_app/services/maki_api_client.dart';
import 'package:maki_app/utils/pii_scrubber.dart';
import 'package:maki_app/widgets/mascot.dart';
import 'package:maki_app/widgets/source_card.dart';

class ChatScreen extends StatefulWidget {
  const ChatScreen({super.key});

  @override
  State<ChatScreen> createState() => _ChatScreenState();
}

class _ChatScreenState extends State<ChatScreen> {
  final _messageController = TextEditingController();
  final _scrollController = ScrollController();
  final _sessionId = newSessionId();

  final List<ChatMessage> _messages = [];
  bool _isLoading = false;

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    if (_messages.isEmpty) {
      final welcome = AppLocalizations.of(context)!.welcomeMessage;
      _messages.add(ChatMessage(text: welcome, isUser: false));
    }
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    _messageController.clear();
    setState(() {
      _messages.add(ChatMessage(text: text, isUser: true));
      _isLoading = true;
    });
    _scrollToBottom();

    try {
      final scrubbedText = PiiScrubber.scrub(text);
      final reply = await MakiApi.instance.askCoach(
        question: scrubbedText,
        sessionId: _sessionId,
      );

      if (mounted) {
        setState(() {
          _messages.add(
            ChatMessage(
              text: reply.answer,
              isUser: false,
              sources: reply.sources,
            ),
          );
        });
      }
    } on MakiApiException catch (error, stackTrace) {
      developer.log(
        'Maki koç isteği tamamlanamadı.',
        error: error.code,
        stackTrace: stackTrace,
        name: 'ChatScreen',
      );
      if (!mounted) return;
      setState(() {
        _messages.add(
          ChatMessage(text: error.userMessage, isUser: false, isError: true),
        );
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
        _scrollToBottom();
      }
    }
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
  }) {
    final theme = Theme.of(context);
    return ActionChip(
      onPressed: _isLoading
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
      body: Column(
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
                        triggerMsg:
                            "Haftalık bütçemi birlikte değerlendirelim.",
                      ),
                      const SizedBox(width: 8),
                      _buildSessionChip(
                        context,
                        label: l10n.sessionDebtStrategy,
                        icon: Icons.calculate_outlined,
                        triggerMsg:
                            "Borçlarım için bir ödeme planı oluşturalım.",
                      ),
                      const SizedBox(width: 8),
                      _buildSessionChip(
                        context,
                        label: l10n.sessionInflationGuide,
                        icon: Icons.trending_up_outlined,
                        triggerMsg: "Enflasyonun bütçeme etkisini inceleyelim.",
                      ),
                      const SizedBox(width: 8),
                      _buildSessionChip(
                        context,
                        label: l10n.sessionSavingsHack,
                        icon: Icons.savings_outlined,
                        triggerMsg: "Bütçeme uygun bir tasarruf önerisi ver.",
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
              itemCount: _messages.length + (_isLoading ? 1 : 0),
              itemBuilder: (context, index) {
                if (index == _messages.length) {
                  return const LoadingBubble();
                }

                final msg = _messages[index];
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
                    onPressed: _isLoading ? null : _sendMessage,
                    icon: Icon(
                      Icons.send_rounded,
                      color: _isLoading
                          ? theme.colorScheme.onSurface.withValues(alpha: 0.3)
                          : theme.colorScheme.primary,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class ChatMessage {
  final String text;
  final bool isUser;
  final bool isError;
  final List<CoachSource> sources;

  ChatMessage({
    required this.text,
    required this.isUser,
    this.isError = false,
    this.sources = const <CoachSource>[],
  });
}

class MessageBubble extends StatelessWidget {
  final ChatMessage message;

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
