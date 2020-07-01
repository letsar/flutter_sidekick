import 'package:flutter/foundation.dart';
import 'package:flutter/widgets.dart';

/// A function that lets [Sidekick]s self supply a [Widget] that is shown during the
/// sidekick's flight from its position to the target's position.
typedef SidekickFlightShuttleBuilder = Widget Function(
  BuildContext flightContext,
  Animation<double> animation,
  SidekickFlightDirection flightDirection,
  BuildContext fromSidekickContext,
  BuildContext toSidekickContext,
);

/// Signature for transforming an animation into another.
typedef SidekickAnimationBuilder = Animation<double> Function(
  Animation<double> animation,
);

typedef _OnFlightEnded = void Function(_SidekickFlight flight);

Animation<double> _sameAnimation(Animation<double> animation) => animation;

/// Direction of the sidekick's flight.
enum SidekickFlightDirection {
  /// A flight from the source to the target.
  ///
  /// The animation goes from 0 to 1.
  ///
  /// If no custom [SidekickFlightShuttleBuilder] is supplied, the
  /// [Sidekick] child is shown in flight.
  toTarget,

  /// A flight from the target to the source.
  ///
  /// The animation goes from 1 to 0.
  ///
  /// If no custom [SidekickFlightShuttleBuilder] is supplied, the target's
  /// [Sidekick] child is shown in flight.
  toSource,
}

// The bounding box for context in global coordinates.
Rect _globalBoundingBoxFor(BuildContext context) {
  final RenderBox box = context.findRenderObject();
  assert(box != null && box.hasSize);
  return MatrixUtils.transformRect(
      box.getTransformTo(null), Offset.zero & box.size);
}

/// A widget that marks its child as being a candidate for sidekick animations.
///
/// [Sidekick] animations are like [Hero] animations but within a route.
///
/// To label a widget as such a feature, wrap it in a [Sidekick] widget.
/// Use a [SidekickController] to animate it.
///
/// /// ## Discussion
///
/// Sidekicks and the parent [Overlay] [Stack] must be axis-aligned for
/// all this to work. The top left and bottom right coordinates of each animated
/// Sidekick will be converted to global coordinates and then from there converted
/// to that [Stack]'s coordinate space, and the entire Sidekick subtree will, for
/// the duration of the animation, be lifted out of its original place, and
/// positioned on that stack. If the [Sidekick] isn't axis aligned, this is going to
/// fail in a rather ugly fashion. Don't rotate your sidekicks!
///
/// To make the animations look good, it's critical that the widget tree for the
/// sidekick in both locations be essentially identical. The widget of the *target*
/// is, by default, used to do the transition: when going from source to target,
/// target's sidekick's widget is placed over source's sidekick's widget. If a
/// [flightShuttleBuilder] is supplied, its output widget is shown during the
/// flight transition instead.
///
/// By default, both source and target's sidekicks are hidden while the
/// transitioning widget is animating in-flight.
/// [placeholderBuilder] can be used to show a custom widget in their place
/// instead once the transition has taken flight.
class Sidekick extends StatefulWidget {
  const Sidekick({
    Key key,
    @required this.tag,
    this.targetTag,
    this.createRectTween,
    this.flightShuttleBuilder,
    this.placeholderBuilder,
    SidekickAnimationBuilder animationBuilder,
    this.keepShowingWidget,
    @required this.child,
  })  : assert(tag != null),
        assert(child != null),
        animationBuilder = animationBuilder ?? _sameAnimation,
        super(key: key);

  /// The identifier for this particular sidekick.
  final Object tag;

  /// The identifier of the target.
  ///
  /// If [null] that means this sidekick is only the target of another sidekick.
  final Object targetTag;

  /// Defines how the destination sidekick's bounds change as it flies from the starting
  /// position to the destination position.
  ///
  /// A sidekick flight begins with the destination sidekick's [child] aligned with the
  /// starting sidekick's child. The [Tween<Rect>] returned by this callback is used
  /// to compute the sidekick's bounds as the flight animation's value goes from 0.0
  /// to 1.0.
  ///
  /// If this property is null, the default, then the value of
  /// [SidekickController.createRectTween] is used. The [SidekickController] created by
  /// [MaterialApp] creates a [MaterialRectAreTween].
  final CreateRectTween createRectTween;

  /// The widget subtree that will "fly" from one the initial position to another.
  ///
  /// The appearance of this subtree should be similar to the appearance of
  /// the subtrees of any other sidekicks in the application with the [targetTag].
  /// Changes in scale and aspect ratio work well in sidekick animations, changes
  /// in layout or composition do not.
  final Widget child;

  /// Optional override to supply a widget that's shown during the sidekick's flight.
  ///
  /// When both the source and destination [Sidekicks]s provide a [flightShuttleBuilder],
  /// the destination's [flightShuttleBuilder] takes precedence.
  ///
  /// If none is provided, the destination Sidekick child is shown in-flight
  /// by default.
  final SidekickFlightShuttleBuilder flightShuttleBuilder;

  /// Placeholder widget left in place as the Sidekicks's child once the flight takes off.
  ///
  /// By default, an empty SizedBox keeping the Sidekick child's original size is
  /// left in place once the Sidekick shuttle has taken flight.
  final TransitionBuilder placeholderBuilder;

  /// Optional override to specified the animation used while flying.
  final SidekickAnimationBuilder animationBuilder;

  /// Keep showing the source "from" widget after it has flown
  final bool keepShowingWidget;

  // Returns a map of all of the sidekicks in context, indexed by sidekick tag.
  static Map<Object, _SidekickState> _allSidekicksFor(BuildContext context) {
    assert(context != null);
    final Map<Object, _SidekickState> result = <Object, _SidekickState>{};
    void visitor(Element element) {
      if (element.widget is Sidekick) {
        final StatefulElement sidekick = element;
        final Sidekick sidekickWidget = element.widget;
        final Object tag = sidekickWidget.tag;
        assert(tag != null);
        assert(() {
          if (result.containsKey(tag)) {
            throw FlutterError(
                'There are multiple sidekicks that share the same tag within a subtree.\n'
                'Within each subtree for which sidekicks are to be animated, '
                'each Sidekick must have a unique non-null tag.\n'
                'In this case, multiple sidekicks had the following tag: $tag\n'
                'Here is the subtree for one of the offending sidekicks:\n'
                '${element.toStringDeep(prefixLineOne: "# ")}');
          }
          return true;
        }());
        final _SidekickState sidekickState = sidekick.state;
        result[tag] = sidekickState;
      }
      element.visitChildren(visitor);
    }

    context.visitChildElements(visitor);
    return result;
  }

  @override
  _SidekickState createState() => _SidekickState();

  @override
  void debugFillProperties(DiagnosticPropertiesBuilder properties) {
    super.debugFillProperties(properties);
    properties.add(DiagnosticsProperty<Object>('tag', tag));
  }
}

class _SidekickState extends State<Sidekick> with TickerProviderStateMixin {
  final GlobalKey _key = GlobalKey();
  Size _placeholderSize;

  void startFlight() {
    assert(mounted);
    final RenderBox box = context.findRenderObject();
    assert(box != null && box.hasSize);
    setState(() {
      _placeholderSize = box.size;
    });
  }

  void endFlight() {
    if (mounted) {
      setState(() {
        _placeholderSize = null;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_placeholderSize != null) {
      if (widget.placeholderBuilder == null) {
        return SizedBox(
          width: _placeholderSize.width,
          height: _placeholderSize.height,
        );
      } else {
        return widget.placeholderBuilder(context, widget.child);
      }
    }
    return KeyedSubtree(
      key: _key,
      child: widget.child,
    );
  }
}

/// Everything known about a sidekick flight that's to be started or diverted.
class _SidekickFlightManifest {
  _SidekickFlightManifest(
      {@required this.type,
      @required this.overlay,
      @required this.rect,
      @required this.fromSidekick,
      @required this.toSidekick,
      @required this.createRectTween,
      @required this.shuttleBuilder,
      @required this.animationController,
      @required this.keepShowingFromWidget})
      : assert((type == SidekickFlightDirection.toTarget &&
                fromSidekick.widget.targetTag == toSidekick.widget.tag) ||
            (type == SidekickFlightDirection.toSource &&
                toSidekick.widget.targetTag == fromSidekick.widget.tag));

  final SidekickFlightDirection type;
  final OverlayState overlay;
  final Rect rect;
  final _SidekickState fromSidekick;
  final _SidekickState toSidekick;
  final CreateRectTween createRectTween;
  final SidekickFlightShuttleBuilder shuttleBuilder;
  final Animation<double> animationController;
  final bool keepShowingFromWidget;

  Object get tag => fromSidekick.widget.tag;

  Object get targetTag => toSidekick.widget.tag;

  Animation<double> get animation {
    return fromSidekick.widget.animationBuilder(animationController);
  }

  @override
  String toString() {
    return '_SidekickFlightManifest($type from $tag to $targetTag';
  }
}

/// Builds the in-flight sidekick widget.
class _SidekickFlight {
  _SidekickFlight(this.onFlightEnded) {
    _proxyAnimation = ProxyAnimation()
      ..addStatusListener(_handleAnimationUpdate);
  }

  final _OnFlightEnded onFlightEnded;

  Tween<Rect> sidekickRectTween;
  Widget shuttle;

  Animation<double> _sidekickOpacity = kAlwaysCompleteAnimation;
  ProxyAnimation _proxyAnimation;
  _SidekickFlightManifest manifest;
  OverlayEntry overlayEntry;
  bool _aborted = false;

  Tween<Rect> _doCreateRectTween(Rect begin, Rect end) {
    final CreateRectTween createRectTween =
        manifest.toSidekick.widget.createRectTween ?? manifest.createRectTween;
    if (createRectTween != null) return createRectTween(begin, end);
    return RectTween(begin: begin, end: end);
  }

  static final Animatable<double> _reverseTween =
      Tween<double>(begin: 1.0, end: 0.0);

  // The OverlayEntry WidgetBuilder callback for the sidekick's overlay.
  Widget _buildOverlay(BuildContext context) {
    assert(manifest != null);
    shuttle ??= manifest.shuttleBuilder(
      context,
      manifest.animation,
      manifest.type,
      manifest.fromSidekick.context,
      manifest.toSidekick.context,
    );
    assert(shuttle != null);

    return AnimatedBuilder(
      animation: _proxyAnimation,
      child: shuttle,
      builder: (BuildContext context, Widget child) {
        final RenderBox toSidekickBox =
            manifest.toSidekick.context?.findRenderObject();
        if (_aborted || toSidekickBox == null || !toSidekickBox.attached) {
          // The toSidekick no longer exists or it's no longer the flight's destination.
          // Continue flying while fading out.
          if (_sidekickOpacity.isCompleted) {
            _sidekickOpacity = _proxyAnimation.drive(
              _reverseTween.chain(CurveTween(
                  curve: Interval(_proxyAnimation.value.clamp(0.0, 1.0), 1.0))),
            );
          }
        } else if (toSidekickBox.hasSize) {
          // The toSidekick has been laid out. If it's no longer where the sidekick animation is
          // supposed to end up then recreate the sidekickRect tween.
          final Offset toSidekickOrigin =
              toSidekickBox.localToGlobal(Offset.zero);
          if (toSidekickOrigin != sidekickRectTween.end.topLeft) {
            final Rect sidekickRectEnd =
                toSidekickOrigin & sidekickRectTween.end.size;
            sidekickRectTween =
                _doCreateRectTween(sidekickRectTween.begin, sidekickRectEnd);
          }
        }

        final Rect rect = sidekickRectTween.evaluate(_proxyAnimation);
        final Size size = manifest.rect.size;
        final RelativeRect offsets = RelativeRect.fromSize(rect, size);

        return Positioned(
          left: offsets.left,
          top: offsets.top,
          width: rect.width,
          height: rect.height,
          child: IgnorePointer(
            child: RepaintBoundary(
              child: Opacity(
                opacity: _sidekickOpacity.value,
                child: child,
              ),
            ),
          ),
        );
      },
    );
  }

  void _handleAnimationUpdate(AnimationStatus status) {
    if (status == AnimationStatus.completed ||
        status == AnimationStatus.dismissed) {
      _proxyAnimation.parent = null;

      assert(overlayEntry != null);
      overlayEntry.remove();
      overlayEntry = null;

      manifest.keepShowingFromWidget ? manifest.fromSidekick.endFlight() : null;
      manifest.toSidekick.endFlight();
      onFlightEnded(this);
    }
  }

  // The simple case: we're either starting a forward or a reverse animation.
  void start(_SidekickFlightManifest initialManifest) {
    assert(!_aborted);
    manifest = initialManifest;

    if (manifest.type == SidekickFlightDirection.toSource)
      _proxyAnimation.parent = ReverseAnimation(manifest.animation);
    else
      _proxyAnimation.parent = manifest.animation;

    manifest.fromSidekick.startFlight();
    manifest.toSidekick.startFlight();

    sidekickRectTween = _doCreateRectTween(
      _globalBoundingBoxFor(manifest.fromSidekick.context),
      _globalBoundingBoxFor(manifest.toSidekick.context),
    );

    overlayEntry = OverlayEntry(builder: _buildOverlay);
    manifest.overlay.insert(overlayEntry);
  }

  // While this flight's sidekick was in transition a new flight order occured.
  // Redirect the in-flight sidekick to the new destination.
  void divert(_SidekickFlightManifest newManifest) {
    assert(manifest.tag == newManifest.tag);

    if (manifest.type == SidekickFlightDirection.toTarget &&
        newManifest.type == SidekickFlightDirection.toSource) {
      assert(newManifest.animation.status == AnimationStatus.reverse);
      assert(manifest.fromSidekick == newManifest.toSidekick);
      assert(manifest.toSidekick == newManifest.fromSidekick);

      // The same sidekickRect tween is used in reverse, rather than creating
      // a new sidekickRect with _doCreateRectTween(sidekickRect.end, sidekickRect.begin).
      // That's because tweens like MaterialRectArcTween may create a different
      // path for swapped begin and end parameters. We want the toSource flight
      // path to be the same (in reverse) as the toTarget flight path.
      _proxyAnimation.parent = ReverseAnimation(newManifest.animation);
      sidekickRectTween = ReverseTween<Rect>(sidekickRectTween);
    } else if (manifest.type == SidekickFlightDirection.toSource &&
        newManifest.type == SidekickFlightDirection.toTarget) {
      assert(newManifest.animation.status == AnimationStatus.forward);
      assert(manifest.toSidekick == newManifest.fromSidekick);

      _proxyAnimation.parent = newManifest.animation.drive(
        Tween<double>(
          begin: manifest.animation.value,
          end: 1.0,
        ),
      );

      if (manifest.fromSidekick != newManifest.toSidekick) {
        manifest.fromSidekick.endFlight();
        newManifest.toSidekick.startFlight();
        sidekickRectTween = _doCreateRectTween(sidekickRectTween.end,
            _globalBoundingBoxFor(newManifest.toSidekick.context));
      } else {
        // TODO(hansmuller): Use ReverseTween here per github.com/flutter/flutter/pull/12203.
        sidekickRectTween =
            _doCreateRectTween(sidekickRectTween.end, sidekickRectTween.begin);
      }
    } else {
      assert(manifest.fromSidekick != newManifest.fromSidekick);
      assert(manifest.toSidekick != newManifest.toSidekick);

      sidekickRectTween = _doCreateRectTween(
          sidekickRectTween.evaluate(_proxyAnimation),
          _globalBoundingBoxFor(newManifest.toSidekick.context));
      shuttle = null;

      if (newManifest.type == SidekickFlightDirection.toSource)
        _proxyAnimation.parent = ReverseAnimation(newManifest.animation);
      else
        _proxyAnimation.parent = newManifest.animation;

      manifest.fromSidekick.endFlight();
      manifest.toSidekick.endFlight();

      // Let the sidekicks rebuild with their placeholders.
      newManifest.fromSidekick.startFlight();
      newManifest.toSidekick.startFlight();

      // Let the transition overlay also rebuild since
      // we cleared the old shuttle.
      overlayEntry.markNeedsBuild();
    }

    _aborted = false;
    manifest = newManifest;
  }

  void abort() {
    _aborted = true;
  }

  @override
  String toString() {
    final Object tag = manifest.tag;
    final Object targetTag = manifest.targetTag;
    return 'SidekickFlight(from: $tag, to: $targetTag, ${_proxyAnimation.parent})';
  }
}

/// Manages the [Sidekick] transitions.
class SidekickController extends Animation<double> {
  /// Creates a sidekick controller with the given [RectTween] constructor if any.
  ///
  /// The [createRectTween] argument is optional. If null, the controller uses a
  /// linear [Tween<Rect>].
  SidekickController({
    this.createRectTween,
    Duration duration = const Duration(milliseconds: 300),
    @required TickerProvider vsync,
  })  : assert(vsync != null),
        assert(duration != null),
        _controller = AnimationController(
          vsync: vsync,
          duration: duration,
        );

  /// Used to create [RectTween]s that interpolate the position of sidekicks in flight.
  ///
  /// If null, the controller uses a linear [RectTween].
  final CreateRectTween createRectTween;

  final AnimationController _controller;

  @override
  void addListener(VoidCallback listener) {
    _controller.addListener(listener);
  }

  @override
  void removeListener(VoidCallback listener) {
    _controller.removeListener(listener);
  }

  @override
  void addStatusListener(AnimationStatusListener listener) {
    _controller.addStatusListener(listener);
  }

  @override
  void removeStatusListener(AnimationStatusListener listener) {
    _controller.removeStatusListener(listener);
  }

  /// The current status of this animation.
  AnimationStatus get status => _controller.status;

  /// The current value of the animation.
  @override
  double get value => _controller.value;

  @mustCallSuper
  void dispose() {
    _controller?.dispose();
  }

  // All of the sidekicks that are currently in the overlay and in motion.
  // Indexed by the sidekick tag.
  final Map<Object, _SidekickFlight> _flights = <Object, _SidekickFlight>{};

  /// Starts the transition animations for the given [direction].
  ///
  /// If [direction] is [SidekickFlightDirection.toTarget] calls [moveToTarget].
  /// If [direction] is [SidekickFlightDirection.toSource] calls [moveToSource].
  TickerFuture move(
    BuildContext context,
    SidekickFlightDirection direction, {
    List<Object> tags,
  }) {
    assert(direction != null);
    if (direction == SidekickFlightDirection.toTarget) {
      return moveToTarget(context, tags: tags);
    } else {
      return moveToSource(context, tags: tags);
    }
  }

  /// Starts the transition animations that moves the [Sidekick]s with the
  /// specified [tags] to their target.
  ///
  /// If [tags] is null, moves all the [Sidekick] to their target.
  TickerFuture moveToTarget(
    BuildContext context, {
    List<Object> tags,
  }) {
    _controller.reset();
    if (status == AnimationStatus.forward ||
        status == AnimationStatus.completed) {
      return TickerFuture.complete();
    }

    WidgetsBinding.instance.addPostFrameCallback((Duration value) {
      _startSidekickTransition(context, SidekickFlightDirection.toTarget, tags);
    });
    return _controller.forward();
  }

  /// Starts the transition animations that moves [Sidekick]s to the ones
  /// with the specified [tags].
  ///
  /// If [tags] is null, moves all the [Sidekick] to their source.
  TickerFuture moveToSource(
    BuildContext context, {
    List<Object> tags,
  }) {
    _controller.value = 1.0;
    if (status == AnimationStatus.reverse ||
        status == AnimationStatus.dismissed) {
      return TickerFuture.complete();
    }

    WidgetsBinding.instance.addPostFrameCallback((Duration value) {
      _startSidekickTransition(context, SidekickFlightDirection.toSource, tags);
    });
    return _controller.reverse();
  }

  void _startSidekickTransition(
    BuildContext context,
    SidekickFlightDirection flightType,
    List<Object> tags,
  ) {
    final Rect rect = _globalBoundingBoxFor(context);

    final Map<Object, _SidekickState> sidekicks =
        Sidekick._allSidekicksFor(context);

    for (Object tag in tags ?? sidekicks.keys) {
      final _SidekickState sidekick = sidekicks[tag];
      if (sidekick != null) {
        Object targetTag = sidekick.widget.targetTag;
        if (flightType == SidekickFlightDirection.toSource) {
          final Object tempTag = tag;
          tag = targetTag;
          targetTag = tempTag;
        }

        if (sidekicks[tag] != null) {
          final Sidekick fromSidekick = sidekicks[tag].widget;
          final Sidekick toSidekick = sidekicks[targetTag]?.widget;

          if (toSidekick != null) {
            final SidekickFlightShuttleBuilder fromShuttleBuilder =
                fromSidekick.flightShuttleBuilder;
            final SidekickFlightShuttleBuilder toShuttleBuilder =
                toSidekick.flightShuttleBuilder;
            final bool keepShowingFromWidget = fromSidekick?.keepShowingWidget;

            final _SidekickFlightManifest manifest = _SidekickFlightManifest(
                type: flightType,
                overlay: Overlay.of(context),
                rect: rect,
                fromSidekick: sidekicks[tag],
                toSidekick: sidekicks[targetTag],
                createRectTween: createRectTween,
                shuttleBuilder: toShuttleBuilder ??
                    fromShuttleBuilder ??
                    _defaultSidekickFlightShuttleBuilder,
                animationController: _controller.view,
                keepShowingFromWidget: keepShowingFromWidget ?? false);

            if (_flights[tag] != null) {
              _flights[tag].divert(manifest);
            } else {
              _flights[tag] = _SidekickFlight(_handleFlightEnded)
                ..start(manifest);
            }
          } else if (_flights[tag] != null) {
            _flights[tag].abort();
          }
        }
      }
    }
  }

  void _handleFlightEnded(_SidekickFlight flight) {
    _flights.remove(flight.manifest.tag);
  }

  static final SidekickFlightShuttleBuilder
      _defaultSidekickFlightShuttleBuilder = (
    BuildContext flightContext,
    Animation<double> animation,
    SidekickFlightDirection flightDirection,
    BuildContext fromSidekickContext,
    BuildContext toSidekickContext,
  ) {
    final Sidekick toSidekick = toSidekickContext.widget;
    return toSidekick.child;
  };
}
