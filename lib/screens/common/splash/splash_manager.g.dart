// GENERATED CODE - DO NOT MODIFY BY HAND

part of 'splash_manager.dart';

// **************************************************************************
// RiverpodGenerator
// **************************************************************************

String _$onboardingStateHash() => r'b1eca01032793e1fef0b61c877b788251cfc4e8e';

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

abstract class _$OnboardingState
    extends BuildlessAutoDisposeAsyncNotifier<OnboardingStep> {
  late final String userId;
  late final String userRole;

  FutureOr<OnboardingStep> build(String userId, String userRole);
}

/// See also [OnboardingState].
@ProviderFor(OnboardingState)
const onboardingStateProvider = OnboardingStateFamily();

/// See also [OnboardingState].
class OnboardingStateFamily extends Family<AsyncValue<OnboardingStep>> {
  /// See also [OnboardingState].
  const OnboardingStateFamily();

  /// See also [OnboardingState].
  OnboardingStateProvider call(String userId, String userRole) {
    return OnboardingStateProvider(userId, userRole);
  }

  @override
  OnboardingStateProvider getProviderOverride(
    covariant OnboardingStateProvider provider,
  ) {
    return call(provider.userId, provider.userRole);
  }

  static const Iterable<ProviderOrFamily>? _dependencies = null;

  @override
  Iterable<ProviderOrFamily>? get dependencies => _dependencies;

  static const Iterable<ProviderOrFamily>? _allTransitiveDependencies = null;

  @override
  Iterable<ProviderOrFamily>? get allTransitiveDependencies =>
      _allTransitiveDependencies;

  @override
  String? get name => r'onboardingStateProvider';
}

/// See also [OnboardingState].
class OnboardingStateProvider
    extends
        AutoDisposeAsyncNotifierProviderImpl<OnboardingState, OnboardingStep> {
  /// See also [OnboardingState].
  OnboardingStateProvider(String userId, String userRole)
    : this._internal(
        () =>
            OnboardingState()
              ..userId = userId
              ..userRole = userRole,
        from: onboardingStateProvider,
        name: r'onboardingStateProvider',
        debugGetCreateSourceHash:
            const bool.fromEnvironment('dart.vm.product')
                ? null
                : _$onboardingStateHash,
        dependencies: OnboardingStateFamily._dependencies,
        allTransitiveDependencies:
            OnboardingStateFamily._allTransitiveDependencies,
        userId: userId,
        userRole: userRole,
      );

  OnboardingStateProvider._internal(
    super._createNotifier, {
    required super.name,
    required super.dependencies,
    required super.allTransitiveDependencies,
    required super.debugGetCreateSourceHash,
    required super.from,
    required this.userId,
    required this.userRole,
  }) : super.internal();

  final String userId;
  final String userRole;

  @override
  FutureOr<OnboardingStep> runNotifierBuild(
    covariant OnboardingState notifier,
  ) {
    return notifier.build(userId, userRole);
  }

  @override
  Override overrideWith(OnboardingState Function() create) {
    return ProviderOverride(
      origin: this,
      override: OnboardingStateProvider._internal(
        () =>
            create()
              ..userId = userId
              ..userRole = userRole,
        from: from,
        name: null,
        dependencies: null,
        allTransitiveDependencies: null,
        debugGetCreateSourceHash: null,
        userId: userId,
        userRole: userRole,
      ),
    );
  }

  @override
  AutoDisposeAsyncNotifierProviderElement<OnboardingState, OnboardingStep>
  createElement() {
    return _OnboardingStateProviderElement(this);
  }

  @override
  bool operator ==(Object other) {
    return other is OnboardingStateProvider &&
        other.userId == userId &&
        other.userRole == userRole;
  }

  @override
  int get hashCode {
    var hash = _SystemHash.combine(0, runtimeType.hashCode);
    hash = _SystemHash.combine(hash, userId.hashCode);
    hash = _SystemHash.combine(hash, userRole.hashCode);

    return _SystemHash.finish(hash);
  }
}

@Deprecated('Will be removed in 3.0. Use Ref instead')
// ignore: unused_element
mixin OnboardingStateRef
    on AutoDisposeAsyncNotifierProviderRef<OnboardingStep> {
  /// The parameter `userId` of this provider.
  String get userId;

  /// The parameter `userRole` of this provider.
  String get userRole;
}

class _OnboardingStateProviderElement
    extends
        AutoDisposeAsyncNotifierProviderElement<OnboardingState, OnboardingStep>
    with OnboardingStateRef {
  _OnboardingStateProviderElement(super.provider);

  @override
  String get userId => (origin as OnboardingStateProvider).userId;
  @override
  String get userRole => (origin as OnboardingStateProvider).userRole;
}

// ignore_for_file: type=lint
// ignore_for_file: subtype_of_sealed_class, invalid_use_of_internal_member, invalid_use_of_visible_for_testing_member, deprecated_member_use_from_same_package
