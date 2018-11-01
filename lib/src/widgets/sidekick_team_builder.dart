import 'package:flutter/widgets.dart';
import 'package:flutter_sidekick/src/widgets/sidekick.dart';

typedef SidekickTeamWidgetBuilder<T> = Widget Function(
  BuildContext context,
  List<SidekickBuilderDelegate<T>> sourceBuilderDelegates,
  List<SidekickBuilderDelegate<T>> targetBuilderDelegates,
);

class _SidekickLetter<T> {
  _SidekickLetter(
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

class SidekickTeamBuilder<T> extends StatefulWidget {
  SidekickTeamBuilder({
    Key key,
    @required this.builder,
    this.initialSourceList,
    this.initialTargetList,
    this.animationDuration = const Duration(milliseconds: 300),
  }) : assert(animationDuration != null);

  final SidekickTeamWidgetBuilder<T> builder;
  final List<T> initialSourceList;
  final List<T> initialTargetList;
  final Duration animationDuration;

  static SidekickTeamBuilderState<T> of<T>(BuildContext context) {
    assert(context != null);
    final SidekickTeamBuilderState<T> result =
        context.ancestorStateOfType(TypeMatcher<SidekickTeamBuilderState<T>>());
    return result;
  }

  @override
  SidekickTeamBuilderState createState() => SidekickTeamBuilderState<T>();
}

class SidekickTeamBuilderState<T> extends State<SidekickTeamBuilder<T>>
    with TickerProviderStateMixin {
  static const String _sourceListPrefix = 's_';
  static const String _targetListPrefix = 't_';
  static int _nextId = 0;
  int _id;
  bool _allInFlight;
  SidekickController _sidekickController;
  List<_SidekickLetter<T>> _sourceList;
  List<_SidekickLetter<T>> _targetList;

  List<T> get sourceList => _sourceList.map((item) => item.message).toList();
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
    _sourceList = List<_SidekickLetter<T>>();
    _targetList = List<_SidekickLetter<T>>();
    _initList(_sourceList, widget.initialSourceList, _sourceListPrefix);
    _initList(_targetList, widget.initialTargetList, _targetListPrefix);
  }

  void _initList(
      List<_SidekickLetter<T>> list, List<T> initialList, String prefix) {
    if (initialList != null) {
      for (var i = 0; i < initialList.length; i++) {
        final String id = '$prefix$i';
        list.add(_SidekickLetter(
          id,
          initialList[i],
          this,
          widget.animationDuration,
        ));
      }
    }
  }

  void moveAll(SidekickFlightDirection direction, {VoidCallback callback}) {
    assert(direction != null);
    if (!_allInFlight) {
      _allInFlight = true;
      final List<_SidekickLetter> source = _getSource(direction);
      final List<_SidekickLetter> target = _getTarget(direction);

      setState(() {
        source.forEach((letter) => letter.startFlight(direction));
        target.addAll(source);
      });

      _sidekickController
          .move(
        context,
        direction,
        tags: source.map((letter) => _getTag(letter)).toList(),
      )
          .then((_) {
        setState(() {
          source.forEach((letter) => letter.endFlight(direction));
          source.clear();
        });
        _allInFlight = false;
        callback?.call();
      });
    }
  }

  void move(T message, {VoidCallback callback}) {
    final _SidekickLetter<T> sourceLetter =
        _getFirstLetterInList(_sourceList, message);
    final _SidekickLetter<T> targetLetter =
        _getFirstLetterInList(_targetList, message);

    SidekickFlightDirection direction;
    _SidekickLetter<T> letter;
    if (sourceLetter != null) {
      direction = SidekickFlightDirection.toTarget;
      letter = sourceLetter;
    } else if (targetLetter != null) {
      direction = SidekickFlightDirection.toSource;
      letter = targetLetter;
    }
    assert(direction != null);
    assert(letter != null);

    if (!letter.inFlight) {
      letter.startFlight(direction);
      final List<_SidekickLetter> source = _getSource(direction);
      final List<_SidekickLetter> target = _getTarget(direction);

      setState(() {
        target.add(letter);
      });
      letter.controller
          .move(context, direction, tags: [_getTag(letter)]).then((_) {
        setState(() {
          letter.endFlight(direction);
          source.remove(letter);
        });
        callback?.call();
      });
    }
  }

  List<_SidekickLetter<T>> _getSource(SidekickFlightDirection direction) {
    return direction == SidekickFlightDirection.toTarget
        ? _sourceList
        : _targetList;
  }

  List<_SidekickLetter<T>> _getTarget(SidekickFlightDirection direction) {
    return direction == SidekickFlightDirection.toTarget
        ? _targetList
        : _sourceList;
  }

  _SidekickLetter<T> _getFirstLetterInList(
      List<_SidekickLetter<T>> list, T message) {
    return list.firstWhere((letter) => identical(letter.message, message),
        orElse: () => null);
  }

  @override
  Widget build(BuildContext context) {
    return Builder(
      builder: (context) {
        return widget.builder(
            context,
            _sourceList
                .map((letter) => _buildSidekickBuilder(context, letter, true))
                .toList(),
            _targetList
                .map((letter) => _buildSidekickBuilder(context, letter, false))
                .toList());
      },
    );
  }

  SidekickBuilderDelegate<T> _buildSidekickBuilder(
      BuildContext context, _SidekickLetter<T> letter, bool isSource) {
    return SidekickBuilderDelegate._internal(
      letter,
      _getTag(letter, isSource: isSource),
      isSource ? _getTag(letter, isSource: false) : null,
      isSource,
    );
  }

  String _getTag(_SidekickLetter<T> letter, {bool isSource = true}) {
    final String prefix = isSource ? 'source_' : 'target_';
    return '${_id}_$prefix${letter.id}';
  }

  @override
  void dispose() {
    _sidekickController?.dispose();
    _sourceList.forEach((letter) => letter.dispose());
    _targetList.forEach((letter) => letter.dispose());
    super.dispose();
  }
}

class SidekickBuilderDelegate<T> {
  SidekickBuilderDelegate._internal(
    this._letter,
    this._tag,
    this._targetTag,
    this._isSource,
  );

  final _SidekickLetter<T> _letter;
  final String _tag;
  final String _targetTag;
  final bool _isSource;
  T get message => _letter.message;

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
        key: ObjectKey(_letter),
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
    if (_letter.inFlightToTheSource && _isSource ||
        _letter.inFlightToTheTarget && !_isSource) {
      return 0.0;
    } else {
      return 1.0;
    }
  }
}
