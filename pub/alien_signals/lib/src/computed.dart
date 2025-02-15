import 'effect.dart';
import 'effect_scope.dart';
import 'system.dart';
import 'types.dart';

/// {@template alien_signals.computed}
/// Creates a computed read-only signal
///
/// - [getter] A function that computes the value of the signal. It receives the old value as a parameter and returns the new value.
///
/// Example:
/// ```dart
/// final count = signal(0);
/// final total = computed<int>((oldValue) {
///   return (oldValue ?? 0) + count.get();
/// });
/// ```
/// {@endtemplate}
Computed<T> computed<T>(T Function(T? oldValue) getter) {
  return Computed<T>(getter);
}

/// The [computed] returns class.
class Computed<T> implements IComputed, ISignal<T> {
  /// {@macro alien_signals.computed}
  Computed(this.getter);

  /// A function that computes the value of the signal.
  /// It receives the old value as a parameter and returns the new value.
  final T Function(T? oldValue) getter;

  /// The current value of the computed signal.
  T? currentValue;

  @override
  Link? deps;

  @override
  Link? depsTail;

  @override
  SubscriberFlags flags = SubscriberFlags.dirty;

  @override
  Link? subs;

  @override
  Link? subsTail;

  @override
  T get() {
    final flags = this.flags;
    if (flags & (SubscriberFlags.toCheckDirty | SubscriberFlags.dirty) != 0 &&
        isDirty(this, flags) &&
        update() &&
        subs != null) {
      shallowPropagate(subs);
    }

    if (activeSub != null) {
      link(this, activeSub!);
    } else if (activeEffectScope != null) {
      link(this, activeEffectScope!);
    }

    return currentValue as T;
  }

  @override
  bool update() {
    final prevSub = activeSub;

    setActiveSub(this);
    startTrack(this);

    try {
      final oldValue = currentValue;
      final newValue = getter(oldValue);
      if (oldValue != newValue) {
        this.currentValue = newValue;
        return true;
      }

      return false;
    } finally {
      setActiveSub(prevSub);
      endTrack(this);
    }
  }
}
