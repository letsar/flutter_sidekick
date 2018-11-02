import 'package:flutter/widgets.dart';
import 'package:flutter_sidekick/src/widgets/sidekick.dart';

/// Signature for building a sidekick team.
typedef SidekickTeamWidgetBuilder<T> = Widget Function(
  BuildContext context,
  List<SidekickBuilderDelegate<T>> sourceBuilderDelegates,
  List<SidekickBuilderDelegate<T>> targetBuilderDelegates,
);

class _SidekickMission<T> {
  _SidekickMission(
    this.id,
    this.message,
    TickerProvider vsync,
    Duration duration,
  ) : controller = SidekickController(vsync: vsync, duration: duration);

  final String id;
  final T message;
  final SidekickController controller;
  bool inFlightToTheSource = false;
  bool inFlightToTheTarget = false;
  bool get inFlight => inFlightToTheSource || inFlightToTheTarget;

  void startFlight(SidekickFlightDirection direction) =>
      _setInFlight(direction, true);
  void endFlight(SidekickFlightDirection direction) =>
      _setInFlight(direction, false);

  void _setInFlight(SidekickFlightDirection direction, bool inFlight) {
    if (direction == SidekickFlightDirection.toTarget) {
      inFlightToTheTarget = inFlight;
    } else {
      inFlightToTheSource = inFlight;
    }
  }

  void dispose() {
    controller?.dispose();
  }
}

/// A widget used to animate widgets from one container to another.
///
/// This is useful when you have two widgets that contains multiple
/// widgets and you want to be able to animate some widgets from one
/// container (the source) to the other (the target) and vice-versa.
class SidekickTeamBuilder<T> extends StatefulWidget {
  SidekickTeamBuilder({
    Key key,
    @required this.builder,
    this.initialSourceList,
    this.initialTargetList,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : assert(animationDuration != null);

  /// The builder used to create the containers.
  final SidekickTeamWidgetBuilder<T> builder;

  /// The initial items contained in the source container.
  final List<T> initialSourceList;

  /// The initial items contained in the target container.
  final List<T> initialTargetList;

  /// The duration of the flying animation.
  final Duration animationDuration;

  /// The state from the closest instance of this class that encloses the given context.
  static SidekickTeamBuilderState<T> of<T>(BuildContext context) {
    assert(context != null);
    final SidekickTeamBuilderState<T> result =
        context.ancestorStateOfType(TypeMatcher<SidekickTeamBuilderState<T>>());
    return result;
  }

  @override
  SidekickTeamBuilderState<T> createState() => SidekickTeamBuilderState<T>();
}

/// State for [SidekickTeamBuilder].
///
/// Can animate widgets from one container to the other.
class SidekickTeamBuilderState<T> extends State<SidekickTeamBuilder<T>>
    with TickerProviderStateMixin {
  static const String _sourceListPrefix = 's_';
  static const String _targetListPrefix = 't_';
  static int _nextId = 0;
  int _id;
  bool _allInFlight;
  SidekickController _sidekickController;
  List<_SidekickMission<T>> _sourceList;
  List<_SidekickMission<T>> _targetList;

  /// The items contained in the container labeled as the 'source'.
  List<T> get sourceList => _sourceList.map((item) => item.message).toList();

  /// The items contained in the container labeled as the 'target'.
  List<T> get targetList => _targetList.map((item) => item.message).toList();

  @override
  void initState() {
    super.initState();
    _id = ++_nextId;
    _allInFlight = false;
    _sidekickController = SidekickController(
      vsync: this,
      duration: widget.animationDuration,
    );
    _sourceList = List<_SidekickMission<T>>();
    _targetList = List<_SidekickMission<T>>();
    _initList(_sourceList, widget.initialSourceList, _sourceListPrefix);
    _initList(_targetList, widget.initialTargetList, _targetListPrefix);
  }

  void _initList(
      List<_SidekickMission<T>> list, List<T> initialList, String prefix) {
    if (initialList != null) {
      for (var i = 0; i < initialList.length; i++) {
        final String id = '$prefix$i';
        list.add(_SidekickMission(
          id,
          initialList[i],
          this,
          widget.animationDuration,
        ));
      }
    }
  }

  /// Moves all the widgets from a container to the other, respecting the given [direction].
  ///
  /// The optional [callback] is called when the animation completes.
  void moveAll(SidekickFlightDirection direction, {VoidCallback callback}) {
    assert(direction != null);
    if (!_allInFlight) {
      _allInFlight = true;
      final List<_SidekickMission> source = _getSource(direction);
      final List<_SidekickMission> target = _getTarget(direction);

      setState(() {
        source.forEach((mission) => mission.startFlight(direction));
        target.addAll(source);
      });

      _sidekickController
          .move(
        context,
        direction,
        tags: source.map((mission) => _getTag(mission)).toList(),
      )
          .then((_) {
        setState(() {
          source.forEach((mission) => mission.endFlight(direction));
          source.clear();
        });
        _allInFlight = false;
        callback?.call();
      });
    }
  }

  /// Moves the widget containing the specifed [message] from its position to its
  /// position in the other container.
  ///
  /// The optional [callback] is called when the animation completes.
  void move(T message, {VoidCallback callback}) {
    final _SidekickMission<T> sourceMission =
        _getFirstMissionInList(_sourceList, message);
    final _SidekickMission<T> targetMission =
        _getFirstMissionInList(_targetList, message);

    SidekickFlightDirection direction;
    _SidekickMission<T> mission;
    if (sourceMission != null) {
      direction = SidekickFlightDirection.toTarget;
      mission = sourceMission;
    } else if (targetMission != null) {
      direction = SidekickFlightDirection.toSource;
      mission = targetMission;
    }
    assert(direction != null);
    assert(mission != null);

    if (!mission.inFlight) {
      mission.startFlight(direction);
      final List<_SidekickMission> source = _getSource(direction);
      final List<_SidekickMission> target = _getTarget(direction);

      setState(() {
        target.add(mission);
      });
      mission.controller
          .move(context, direction, tags: [_getTag(mission)]).then((_) {
        setState(() {
          mission.endFlight(direction);
          source.remove(mission);
        });
        callback?.call();
      });
    }
  }

  List<_SidekickMission<T>> _getSource(SidekickFlightDirection direction) {
    return direction == SidekickFlightDirection.toTarget
        ? _sourceList
        : _targetList;
  }

  List<_SidekickMission<T>> _getTarget(SidekickFlightDirection direction) {
    return direction == SidekickFlightDirection.toTarget
        ? _targetList
        : _sourceList;
  }

  _SidekickMission<T> _getFirstMissionInList(
      List<_SidekickMission<T>> list, T message) {
    return list.firstWhere((mission) => identical(mission.message, message),
        orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return widget.builder(
            context,
            _sourceList
                .map((mission) => _buildSidekickBuilder(
                      context,
                      mission,
                      true,
                    ))
                .toList(),
            _targetList
                .map((mission) => _buildSidekickBuilder(
                      context,
                      mission,
                      false,
                    ))
                .toList());
      },
    );
  }

  SidekickBuilderDelegate<T> _buildSidekickBuilder(
      BuildContext context, _SidekickMission<T> mission, bool isSource) {
    return SidekickBuilderDelegate._internal(
      this,
      mission,
      _getTag(mission, isSource: isSource),
      isSource ? _getTag(mission, isSource: false) : null,
      isSource,
    );
  }

  String _getTag(_SidekickMission<T> mission, {bool isSource = true}) {
    final String prefix = isSource ? 'source_' : 'target_';
    return '${_id}_$prefix${mission.id}';
  }

  @override
  void dispose() {
    _sidekickController?.dispose();
    _sourceList.forEach((mission) => mission.dispose());
    _targetList.forEach((mission) => mission.dispose());
    super.dispose();
  }
}

/// A delegate used to build a [Sidekick] and its child.
class SidekickBuilderDelegate<T> {
  SidekickBuilderDelegate._internal(
    this.state,
    this._mission,
    this._tag,
    this._targetTag,
    this._isSource,
  );

  /// The state of the [SidekickTeamBuilder] that created this delegate.
  final SidekickTeamBuilderState<T> state;

  final _SidekickMission<T> _mission;
  final String _tag;
  final String _targetTag;
  final bool _isSource;

  /// The message transferred by the [Sidekick].
  T get message => _mission.message;

  /// Builds the [Sidekick] widget and its child.
  Widget build(
    BuildContext context,
    Widget child, {
    CreateRectTween createRectTween,
    SidekickFlightShuttleBuilder flightShuttleBuilder,
    TransitionBuilder placeholderBuilder,
    SidekickAnimationBuilder animationBuilder,
  }) {
    return Opacity(
      opacity: _getOpacity(),
      child: Sidekick(
        key: ObjectKey(_mission),
        tag: _tag,
        targetTag: _targetTag,
        animationBuilder: animationBuilder,
        createRectTween: createRectTween,
        flightShuttleBuilder: flightShuttleBuilder,
        placeholderBuilder: placeholderBuilder,
        child: child,
      ),
    );
  }

  double _getOpacity() {
    if (_mission.inFlightToTheSource && _isSource ||
        _mission.inFlightToTheTarget && !_isSource) {
      return 0.0;
    } else {
      return 1.0;
    }
  }
}
