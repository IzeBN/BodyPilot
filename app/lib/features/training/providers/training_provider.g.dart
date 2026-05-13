// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'training_provider.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$todayScheduleHash() => r'0d1a1eecf388bd43ff1363db3d277876015bfbc9';

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

/// See also [todaySchedule].
@ProviderFor(todaySchedule)
const todayScheduleProvider = TodayScheduleFamily();

/// See also [todaySchedule].
class TodayScheduleFamily extends Family<AsyncValue<List<WorkoutSummary>>> {
  /// See also [todaySchedule].
  const TodayScheduleFamily();

  /// See also [todaySchedule].
  TodayScheduleProvider call(
    String date,
  ) {
    return TodayScheduleProvider(
      date,
    );
  }

  @override
  TodayScheduleProvider getProviderOverride(
    covariant TodayScheduleProvider provider,
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
  String? get name => r'todayScheduleProvider';
}

/// See also [todaySchedule].
class TodayScheduleProvider
    extends AutoDisposeFutureProvider<List<WorkoutSummary>> {
  /// See also [todaySchedule].
  TodayScheduleProvider(
    String date,
  ) : this._internal(
          (ref) => todaySchedule(
            ref as TodayScheduleRef,
            date,
          ),
          from: todayScheduleProvider,
          name: r'todayScheduleProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$todayScheduleHash,
          dependencies: TodayScheduleFamily._dependencies,
          allTransitiveDependencies:
              TodayScheduleFamily._allTransitiveDependencies,
          date: date,
        );

  TodayScheduleProvider._internal(
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
    FutureOr<List<WorkoutSummary>> Function(TodayScheduleRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: TodayScheduleProvider._internal(
        (ref) => create(ref as TodayScheduleRef),
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
  AutoDisposeFutureProviderElement<List<WorkoutSummary>> createElement() {
    return _TodayScheduleProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is TodayScheduleProvider && other.date == date;
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
mixin TodayScheduleRef on AutoDisposeFutureProviderRef<List<WorkoutSummary>> {
  /// The parameter `date` of this provider.
  String get date;
}

class _TodayScheduleProviderElement
    extends AutoDisposeFutureProviderElement<List<WorkoutSummary>>
    with TodayScheduleRef {
  _TodayScheduleProviderElement(super.provider);

  @override
  String get date => (origin as TodayScheduleProvider).date;
}

String _$fullScheduleHash() => r'c9bb9fd76abf80f496c2c8c257e0d02c68560048';

/// See also [fullSchedule].
@ProviderFor(fullSchedule)
final fullScheduleProvider = AutoDisposeFutureProvider<ScheduleData>.internal(
  fullSchedule,
  name: r'fullScheduleProvider',
  debugGetCreateSourceHash:
      const bool.fromEnvironment('dart.vm.product') ? null : _$fullScheduleHash,
  dependencies: null,
  allTransitiveDependencies: null,
);

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
typedef FullScheduleRef = AutoDisposeFutureProviderRef<ScheduleData>;
String _$scheduleExercisesHash() => r'fd2a083470842c71eb0642e3617ba35226afc9fb';

/// See also [scheduleExercises].
@ProviderFor(scheduleExercises)
const scheduleExercisesProvider = ScheduleExercisesFamily();

/// See also [scheduleExercises].
class ScheduleExercisesFamily extends Family<AsyncValue<List<ExerciseEntry>>> {
  /// See also [scheduleExercises].
  const ScheduleExercisesFamily();

  /// See also [scheduleExercises].
  ScheduleExercisesProvider call(
    String scheduleId,
  ) {
    return ScheduleExercisesProvider(
      scheduleId,
    );
  }

  @override
  ScheduleExercisesProvider getProviderOverride(
    covariant ScheduleExercisesProvider provider,
  ) {
    return call(
      provider.scheduleId,
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
  String? get name => r'scheduleExercisesProvider';
}

/// See also [scheduleExercises].
class ScheduleExercisesProvider
    extends AutoDisposeFutureProvider<List<ExerciseEntry>> {
  /// See also [scheduleExercises].
  ScheduleExercisesProvider(
    String scheduleId,
  ) : this._internal(
          (ref) => scheduleExercises(
            ref as ScheduleExercisesRef,
            scheduleId,
          ),
          from: scheduleExercisesProvider,
          name: r'scheduleExercisesProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$scheduleExercisesHash,
          dependencies: ScheduleExercisesFamily._dependencies,
          allTransitiveDependencies:
              ScheduleExercisesFamily._allTransitiveDependencies,
          scheduleId: scheduleId,
        );

  ScheduleExercisesProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.scheduleId,
  }) : super.internal();

  final String scheduleId;

  @override
  Override overrideWith(
    FutureOr<List<ExerciseEntry>> Function(ScheduleExercisesRef provider)
        create,
  ) {
    return ProviderOverride(
      origin: this,
      override: ScheduleExercisesProvider._internal(
        (ref) => create(ref as ScheduleExercisesRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        scheduleId: scheduleId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<List<ExerciseEntry>> createElement() {
    return _ScheduleExercisesProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is ScheduleExercisesProvider && other.scheduleId == scheduleId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, scheduleId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin ScheduleExercisesRef
    on AutoDisposeFutureProviderRef<List<ExerciseEntry>> {
  /// The parameter `scheduleId` of this provider.
  String get scheduleId;
}

class _ScheduleExercisesProviderElement
    extends AutoDisposeFutureProviderElement<List<ExerciseEntry>>
    with ScheduleExercisesRef {
  _ScheduleExercisesProviderElement(super.provider);

  @override
  String get scheduleId => (origin as ScheduleExercisesProvider).scheduleId;
}

String _$workoutDetailHash() => r'0c51a8c8f95f572c80e77046689d4caf84b7c3b8';

/// See also [workoutDetail].
@ProviderFor(workoutDetail)
const workoutDetailProvider = WorkoutDetailFamily();

/// See also [workoutDetail].
class WorkoutDetailFamily extends Family<AsyncValue<WorkoutDetail>> {
  /// See also [workoutDetail].
  const WorkoutDetailFamily();

  /// See also [workoutDetail].
  WorkoutDetailProvider call(
    String workoutId,
  ) {
    return WorkoutDetailProvider(
      workoutId,
    );
  }

  @override
  WorkoutDetailProvider getProviderOverride(
    covariant WorkoutDetailProvider provider,
  ) {
    return call(
      provider.workoutId,
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
  String? get name => r'workoutDetailProvider';
}

/// See also [workoutDetail].
class WorkoutDetailProvider extends AutoDisposeFutureProvider<WorkoutDetail> {
  /// See also [workoutDetail].
  WorkoutDetailProvider(
    String workoutId,
  ) : this._internal(
          (ref) => workoutDetail(
            ref as WorkoutDetailRef,
            workoutId,
          ),
          from: workoutDetailProvider,
          name: r'workoutDetailProvider',
          debugGetCreateSourceHash:
              const bool.fromEnvironment('dart.vm.product')
                  ? null
                  : _$workoutDetailHash,
          dependencies: WorkoutDetailFamily._dependencies,
          allTransitiveDependencies:
              WorkoutDetailFamily._allTransitiveDependencies,
          workoutId: workoutId,
        );

  WorkoutDetailProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.workoutId,
  }) : super.internal();

  final String workoutId;

  @override
  Override overrideWith(
    FutureOr<WorkoutDetail> Function(WorkoutDetailRef provider) create,
  ) {
    return ProviderOverride(
      origin: this,
      override: WorkoutDetailProvider._internal(
        (ref) => create(ref as WorkoutDetailRef),
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        workoutId: workoutId,
      ),
    );
  }

  @override
  AutoDisposeFutureProviderElement<WorkoutDetail> createElement() {
    return _WorkoutDetailProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is WorkoutDetailProvider && other.workoutId == workoutId;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, workoutId.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin WorkoutDetailRef on AutoDisposeFutureProviderRef<WorkoutDetail> {
  /// The parameter `workoutId` of this provider.
  String get workoutId;
}

class _WorkoutDetailProviderElement
    extends AutoDisposeFutureProviderElement<WorkoutDetail>
    with WorkoutDetailRef {
  _WorkoutDetailProviderElement(super.provider);

  @override
  String get workoutId => (origin as WorkoutDetailProvider).workoutId;
}
// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
