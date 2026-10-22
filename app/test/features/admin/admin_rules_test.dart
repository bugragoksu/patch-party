import 'package:baglanti_agi/core/domain/models.dart';
import 'package:baglanti_agi/features/admin/domain/admin_rules.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('allowedTransitions', () {
    test('matches the server table without ended -> archived', () {
      expect(allowedTransitions(EventState.draft), [EventState.lobby]);
      expect(allowedTransitions(EventState.lobby), [
        EventState.live,
        EventState.draft,
      ]);
      expect(allowedTransitions(EventState.live), [
        EventState.lobby,
        EventState.ended,
      ]);
      expect(allowedTransitions(EventState.ended), [EventState.live]);
      expect(allowedTransitions(EventState.archived), isEmpty);
    });

    test('never offers archived (purge only) or a self-transition', () {
      for (final from in EventState.values) {
        final to = allowedTransitions(from);
        expect(to, isNot(contains(EventState.archived)));
        expect(to, isNot(contains(from)));
      }
    });

    test('only lobby -> live asks for a duration', () {
      expect(needsDuration(EventState.lobby, EventState.live), isTrue);
      expect(needsDuration(EventState.ended, EventState.live), isFalse);
      expect(needsDuration(EventState.live, EventState.ended), isFalse);
    });

    test('live duration must be 1..120 whole minutes', () {
      expect(parseLiveDuration('15'), 15);
      expect(parseLiveDuration(' 120 '), 120);
      expect(parseLiveDuration('1'), 1);
      expect(parseLiveDuration('0'), isNull);
      expect(parseLiveDuration('121'), isNull);
      expect(parseLiveDuration('7.5'), isNull);
      expect(parseLiveDuration(''), isNull);
    });
  });

  group('suspicionReasons', () {
    const joined = 1000000;
    int min(int m) => joined + m * 60000;

    test('clean player is not flagged', () {
      expect(
        suspicionReasons(
          connectionCount: 6,
          failures: 1,
          joinedAtMs: joined,
          nowMs: min(10),
        ),
        isEmpty,
      );
    });

    test('five or more failures are flagged', () {
      expect(
        suspicionReasons(
          connectionCount: 0,
          failures: 5,
          joinedAtMs: joined,
          nowMs: min(10),
        ),
        [SuspicionReason.failures],
      );
      expect(
        suspicionReasons(
          connectionCount: 0,
          failures: 4,
          joinedAtMs: joined,
          nowMs: min(10),
        ),
        isEmpty,
      );
    });

    test('more than one connection per 30 s is flagged', () {
      // 5 minutes allow 10 connections.
      expect(
        suspicionReasons(
          connectionCount: 10,
          failures: 0,
          joinedAtMs: joined,
          nowMs: min(5),
        ),
        isEmpty,
      );
      expect(
        suspicionReasons(
          connectionCount: 11,
          failures: 0,
          joinedAtMs: joined,
          nowMs: min(5),
        ),
        [SuspicionReason.tooFast],
      );
    });

    test('speed rule waits for a minimum number of connections', () {
      expect(
        suspicionReasons(
          connectionCount: 4,
          failures: 0,
          joinedAtMs: joined,
          nowMs: joined + 1000,
        ),
        isEmpty,
      );
    });

    test('a missing join time does not divide by zero', () {
      expect(
        suspicionReasons(
          connectionCount: 50,
          failures: 0,
          joinedAtMs: 0,
          nowMs: min(1),
        ),
        isEmpty,
      );
    });

    test('both reasons can apply', () {
      expect(
        suspicionReasons(
          connectionCount: 20,
          failures: 9,
          joinedAtMs: joined,
          nowMs: min(2),
        ),
        [SuspicionReason.failures, SuspicionReason.tooFast],
      );
    });
  });

  group('SettingsDraft', () {
    const current = EventSettings(prizes: ['Kulaklık']);
    SettingsDraft draft({
      String displayName = 'Bağlantı Ağı',
      String subtitle = '',
      List<String> prizes = const ['Kulaklık', '', ''],
      String cooldownSec = '15',
      String requestTtlSec = '45',
      String maxConnPerPlayer = '60',
      String maxPlayers = '200',
      bool appCheckEnforce = false,
      bool badges = true,
      bool playerRank = true,
    }) => SettingsDraft(
      displayName: displayName,
      subtitle: subtitle,
      prizes: prizes,
      cooldownSec: cooldownSec,
      requestTtlSec: requestTtlSec,
      maxConnPerPlayer: maxConnPerPlayer,
      maxPlayers: maxPlayers,
      appCheckEnforce: appCheckEnforce,
      badges: badges,
      playerRank: playerRank,
    );

    test('fromSettings round-trips into an empty patch', () {
      final d = SettingsDraft.fromSettings(current);
      expect(d.prizes, ['Kulaklık', '', '']);
      expect(d.validate(), isEmpty);
      expect(d.patchAgainst(current), isEmpty);
    });

    test('number ranges follow the server schema', () {
      Map<SettingsField, String> errs(SettingsDraft d) => d.validate();
      expect(errs(draft(cooldownSec: '0')), isEmpty);
      expect(errs(draft(cooldownSec: '600')), isEmpty);
      expect(
        errs(draft(cooldownSec: '601')),
        contains(SettingsField.cooldownSec),
      );
      expect(
        errs(draft(cooldownSec: '-1')),
        contains(SettingsField.cooldownSec),
      );
      expect(
        errs(draft(requestTtlSec: '9')),
        contains(SettingsField.requestTtlSec),
      );
      expect(errs(draft(requestTtlSec: '300')), isEmpty);
      expect(
        errs(draft(maxConnPerPlayer: '0')),
        contains(SettingsField.maxConnPerPlayer),
      );
      expect(
        errs(draft(maxConnPerPlayer: '501')),
        contains(SettingsField.maxConnPerPlayer),
      );
      expect(errs(draft(maxPlayers: '1000')), isEmpty);
      expect(
        errs(draft(maxPlayers: '1001')),
        contains(SettingsField.maxPlayers),
      );
      expect(
        errs(draft(maxPlayers: 'abc')),
        contains(SettingsField.maxPlayers),
      );
      expect(
        errs(draft(maxPlayers: '2.5')),
        contains(SettingsField.maxPlayers),
      );
    });

    test('text limits follow the server schema', () {
      expect(
        draft(displayName: '  ').validate(),
        contains(SettingsField.displayName),
      );
      expect(
        draft(displayName: 'a' * 41).validate(),
        contains(SettingsField.displayName),
      );
      expect(draft(displayName: 'a' * 40).validate(), isEmpty);
      expect(
        draft(subtitle: 'a' * 81).validate(),
        contains(SettingsField.subtitle),
      );
      expect(
        draft(prizes: ['a' * 121, '', '']).validate(),
        contains(SettingsField.prizes),
      );
      expect(
        draft(prizes: ['a', 'b', 'c', 'd']).validate(),
        contains(SettingsField.prizes),
      );
    });

    test('patch carries only changed fields, trimmed', () {
      final patch = draft(
        displayName: ' DevFest ',
        prizes: ['Kulaklık', ' Kupa ', ''],
        cooldownSec: '20',
        badges: false,
      ).patchAgainst(current);
      expect(patch, {
        'displayName': 'DevFest',
        'prizes': ['Kulaklık', 'Kupa'],
        'cooldownSec': 20,
        'features': {'badges': false},
      });
    });

    test('blank prize lines are dropped', () {
      final patch = draft(prizes: const ['', '', '']).patchAgainst(current);
      expect(patch, {'prizes': <String>[]});
    });
  });

  group('connectionsPerMinute', () {
    test('needs a previous sample', () {
      expect(
        connectionsPerMinute(
          previousCount: null,
          previousAtMs: null,
          count: 10,
          atMs: 1,
        ),
        isNull,
      );
    });

    test('is the count delta over elapsed minutes', () {
      expect(
        connectionsPerMinute(
          previousCount: 100,
          previousAtMs: 0,
          count: 106,
          atMs: 15000,
        ),
        24,
      );
    });

    test('never goes negative (e.g. after a purge)', () {
      expect(
        connectionsPerMinute(
          previousCount: 10,
          previousAtMs: 0,
          count: 0,
          atMs: 15000,
        ),
        0,
      );
    });
  });
}
