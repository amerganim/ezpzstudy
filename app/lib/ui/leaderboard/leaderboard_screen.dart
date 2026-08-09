import 'package:flutter/material.dart';

import '../../app_services.dart';
import '../../data/remote/api_client.dart';
import '../../l10n/strings_bn.dart';
import '../../theme/app_theme.dart';
import '../sync/sync_screen.dart';

/// This week's class leaderboard — the fourth engagement mechanic. Scoped to the
/// student's own school and resetting weekly, so a struggling student competes
/// with ~40 peers, not the nation, and is never permanently last.
class LeaderboardScreen extends StatefulWidget {
  const LeaderboardScreen({super.key});

  @override
  State<LeaderboardScreen> createState() => _LeaderboardScreenState();
}

class _LeaderboardScreenState extends State<LeaderboardScreen> {
  late Future<_LbState> _future;

  @override
  void initState() {
    super.initState();
    _future = _load();
  }

  Future<_LbState> _load() async {
    final sync = AppServices.of(context).sync;
    if (!await sync.isLoggedIn()) return const _LbState.needsLogin();
    final board = await sync.fetchLeaderboard();
    if (board == null) return const _LbState.offline();
    return _LbState.loaded(board);
  }

  Future<void> _reload() async {
    final f = _load();
    setState(() => _future = f);
    await f;
  }

  Future<void> _openSync() async {
    await Navigator.of(context)
        .push(MaterialPageRoute(builder: (_) => const SyncScreen()));
    if (mounted) setState(() => _future = _load());
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text(Bn.classLeaderboard)),
      body: FutureBuilder<_LbState>(
        future: _future,
        builder: (context, snap) {
          if (!snap.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final state = snap.data!;
          switch (state.kind) {
            case _LbKind.needsLogin:
              return _Message(
                icon: Icons.login,
                text: Bn.leaderboardNeedsLogin,
                actionLabel: Bn.loginAndSync,
                onAction: _openSync,
              );
            case _LbKind.offline:
              return const _Message(
                  icon: Icons.wifi_off, text: Bn.leaderboardOffline);
            case _LbKind.loaded:
              final board = state.board!;
              if (!board.scoped) {
                return _Message(
                  icon: Icons.school_outlined,
                  text: Bn.leaderboardNeedsSchool,
                  actionLabel: Bn.syncTitle,
                  onAction: _openSync,
                );
              }
              if (board.entries.isEmpty) {
                return RefreshIndicator(
                  onRefresh: _reload,
                  child: ListView(
                    physics: const AlwaysScrollableScrollPhysics(),
                    children: const [
                      SizedBox(height: 120),
                      _Message(
                          icon: Icons.emoji_events_outlined,
                          text: Bn.leaderboardEmpty),
                    ],
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: _reload,
                child: _Board(board: board),
              );
          }
        },
      ),
    );
  }
}

class _Board extends StatelessWidget {
  final Leaderboard board;
  const _Board({required this.board});

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: EdgeInsets.fromLTRB(
          16, 16, 16, MediaQuery.of(context).padding.bottom + 24),
      children: [
        const Row(
          children: [
            Icon(Icons.emoji_events, color: AppTheme.accent),
            SizedBox(width: 8),
            Text(Bn.leaderboardTitle,
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
          ],
        ),
        const SizedBox(height: 4),
        const Text(Bn.leaderboardWeekly,
            style: TextStyle(fontSize: 13, color: Colors.black54)),
        const SizedBox(height: 16),
        for (final e in board.entries)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _Row(entry: e),
          ),
      ],
    );
  }
}

class _Row extends StatelessWidget {
  final LeaderboardEntry entry;
  const _Row({required this.entry});

  @override
  Widget build(BuildContext context) {
    final highlight = entry.isMe;
    final medal = switch (entry.rank) {
      1 => '🥇',
      2 => '🥈',
      3 => '🥉',
      _ => null,
    };
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        color: highlight
            ? AppTheme.accent.withValues(alpha: 0.12)
            : AppTheme.surfaceTint,
        borderRadius: BorderRadius.circular(12),
        border: highlight
            ? Border.all(color: AppTheme.accent, width: 1.5)
            : null,
      ),
      child: Row(
        children: [
          SizedBox(
            width: 36,
            child: medal != null
                ? Text(medal, style: const TextStyle(fontSize: 22))
                : Text(Bn.digits(entry.rank),
                    style: const TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w700,
                        color: Colors.black54)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              highlight
                  ? '${entry.name ?? Bn.anonymousStudent} (${Bn.you})'
                  : (entry.name ?? Bn.anonymousStudent),
              style: TextStyle(
                fontSize: 17,
                fontWeight: highlight ? FontWeight.w800 : FontWeight.w600,
              ),
            ),
          ),
          Text('${Bn.digits(entry.points)} ${Bn.points}',
              style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.accentDark)),
        ],
      ),
    );
  }
}

class _Message extends StatelessWidget {
  final IconData icon;
  final String text;
  final String? actionLabel;
  final VoidCallback? onAction;
  const _Message({
    required this.icon,
    required this.text,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 56, color: Colors.black38),
            const SizedBox(height: 16),
            Text(text,
                textAlign: TextAlign.center,
                style: const TextStyle(fontSize: 16)),
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 20),
              FilledButton(onPressed: onAction, child: Text(actionLabel!)),
            ],
          ],
        ),
      ),
    );
  }
}

enum _LbKind { needsLogin, offline, loaded }

class _LbState {
  final _LbKind kind;
  final Leaderboard? board;
  const _LbState._(this.kind, this.board);
  const _LbState.needsLogin() : this._(_LbKind.needsLogin, null);
  const _LbState.offline() : this._(_LbKind.offline, null);
  const _LbState.loaded(Leaderboard b) : this._(_LbKind.loaded, b);
}
