// dartrix_config_test.dart — DartrixConfig contract

import 'package:dartrix/dartrix.dart';
import 'package:test/test.dart';

void main() {
  group('DartrixConfig.all', () {
    test('treats every feature name as active', () {
      final cfg = DartrixConfig.all();
      expect(cfg.isFeatureActive('anything'), isTrue);
      expect(cfg.isFeatureActive('newBranch'), isTrue);
      expect(cfg.isFeatureActive('a-name-that-does-not-exist'), isTrue);
    });

    test('exposes empty activeFeatureNames (no filtering)', () {
      expect(DartrixConfig.all().activeFeatureNames, isEmpty);
    });

    test('exposes null activeProfile', () {
      expect(DartrixConfig.all().activeProfile, isNull);
    });
  });

  group('DartrixConfig.fromFeatures', () {
    test('only listed features are active', () {
      final cfg =
          DartrixConfig.fromFeatures({'newBranch', 'promote'});
      expect(cfg.isFeatureActive('newBranch'), isTrue);
      expect(cfg.isFeatureActive('promote'), isTrue);
      expect(cfg.isFeatureActive('refresh'), isFalse);
    });

    test('exposes the supplied profile name', () {
      final cfg = DartrixConfig.fromFeatures(
        {'newBranch'},
        profile: 'liitx',
      );
      expect(cfg.activeProfile, equals('liitx'));
    });

    test('empty feature set means no features are active', () {
      final cfg = DartrixConfig.fromFeatures({});
      expect(cfg.isFeatureActive('newBranch'), isFalse);
      expect(cfg.activeFeatureNames, isEmpty);
    });
  });
}
