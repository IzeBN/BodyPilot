// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'journal_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$journalDayHash() => r'22afdd89569203d17cc86f8e11f8c910840f724d';

/// Copied from Dart SDK
class _SystemHash {
  _SystemHash._();

  static int combine(int hash, int value) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + value);
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x0007ffff & hash) << 10));
    return hash ^ (hash >> 6);
  }

  static int finish(int hash) {
    // ignore: parameter_assignments
    hash = 0x1fffffff & (hash + ((0x03ffffff & hash) << 3));
    // ignore: parameter_assignments
    hash = hash ^ (hash >> 11);
    return 0x1fffffff & (hash + ((0x00003fff & hash) << 15));
  }
}

/// See also [journalDay].
@ProviderFor(journalDay)
const journalDayProvider = JournalDayFamily();

/// See also [journalDay].
class JournalDayFamily extends Family<AsyncValue<JournalDay>> {
  /// See also [journalDay].
  const JournalDayFamily();

  /// See also [journalDay].
  JournalDayProvider call(
    String date,
  ) {
    return JournalDayProvider(
      date,
    );
  }

  @override
  JournalDayProvider getProviderOverride(
    covariant JournalDayProvider provider,
  ) {
    return call(
      provider.date,
    );
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'journalDayProvider';
}

/// See also [journalDay].
class JournalDayProvider extends AutoDisposeFutureProvider<JournalDay> {
  /// See also [journalDay].
  JournalDayProvider(
    String date,
  ) : this._internal(
          (ref) => journalDay(
            ref as JournalDayRef,
            date,
          ),
          from: journalDayProvider,
          name: r'journalDayProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$journalDayHash,
          dependencies: JournalDayFamily._dependencies,
          allTransitiveDependencies:
              JournalDayFamily._allTransitiveDependencies,
          date: date,
        );

  JournalDayProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.date,
  }) : super.internal();

  final String date;

  @override
  Override overrideWith(
    FutureOr<JournalDay> Function(JournalDayRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: JournalDayProvider._internal(
        (ref) => create(ref as JournalDayRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        date: date,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<JournalDay> createElement() {
    return _JournalDayProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is JournalDayProvider && other.date == date;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, date.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin JournalDayRef on AutoDisposeFutureProviderRef<JournalDay> {
  /// The parameter `date` of this provider.
  String get date;
}

class _JournalDayProviderElement
    extends AutoDisposeFutureProviderElement<JournalDay> with JournalDayRef {
  _JournalDayProviderElement(super.provider);

  @override
  String get date => (origin as JournalDayProvider).date;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
