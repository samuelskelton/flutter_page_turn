import 'package:flutter/material.dart';
import 'src/builders/index.dart';

class PageTurn extends StatefulWidget {
  PageTurn({
    Key? key,
    this.duration = const Duration(milliseconds: 450),
    this.cutoff = 0.6,
    this.backgroundColor = Colors.transparent,
    this.children = const [],
    this.initialIndex = 0,
    this.lastPage,
    this.showDragCutoff = false,
    required this.pageNotifier,
  }) : super(key: key);

  final Color backgroundColor;
  final List<Widget> children;
  final Duration duration;
  final int initialIndex;
  final Widget? lastPage;
  final bool showDragCutoff;
  final double cutoff;
  final ValueNotifier<int> pageNotifier;

  @override
  PageTurnState createState() => PageTurnState();
}

class PageTurnState extends State<PageTurn> with TickerProviderStateMixin {
  int _pageNumber = 0;
  int get pageNumber => _pageNumber;
  set pageNumber(int index) {
    _pageNumber = index;
    pageNotifier.value = index;
  }

  List<Widget> pages = [];

  List<AnimationController> _controllers = [];
  bool? _isForward;
  ValueNotifier pageNotifier = ValueNotifier<int>(0);

  @override
  void didUpdateWidget(PageTurn oldWidget) {
    if (oldWidget.children != widget.children) {
      _setUp();
    }
    if (oldWidget.duration != widget.duration) {
      _setUp();
    }
    if (oldWidget.backgroundColor != widget.backgroundColor) {
      _setUp();
    }
    super.didUpdateWidget(oldWidget);
  }

  @override
  void dispose() {
    _controllers.forEach((c) => c.dispose());
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    _setUp();
  }

  void _setUp() {
    _controllers.clear();
    pages.clear();
    for (var i = 0; i < widget.children.length; i++) {
      final _controller = AnimationController(
        value: 1,
        duration: widget.duration,
        vsync: this,
      );
      _controllers.add(_controller);
      final _child = Container(
        child: PageTurnWidget(
          backgroundColor: widget.backgroundColor,
          amount: _controller,
          child: widget.children[i],
        ),
      );
      pages.add(_child);
    }
    pages = pages.reversed.toList();
    pageNumber = widget.initialIndex;
    pageNotifier = widget.pageNotifier;
  }

  bool get _isLastPage => pages.length - 1 == pageNumber;

  bool get _isFirstPage => pageNumber == 0;

  void _turnPage(DragUpdateDetails details, BoxConstraints dimens) {
    final _ratio = details.delta.dx / dimens.maxWidth;
    if (_isForward == null) {
      if (details.delta.dx > 0) {
        _isForward = false;
      } else {
        _isForward = true;
      }
    }
    if (_isForward! || pageNumber == 0) {
      _controllers[pageNumber].value += _ratio;
    } else {
      _controllers[pageNumber - 1].value += _ratio;
    }
  }

  Future<void> _onDragFinish() async {
    if (_isForward != null) {
      if (_isForward!) {
        if (!_isLastPage &&
            _controllers[pageNumber].value <= (widget.cutoff + 0.15)) {
          await nextPage();
        } else {
          await _controllers[pageNumber].forward();
        }
      } else if (pageNumber > 0) {
        print(
            'Val:${_controllers[pageNumber - 1].value} -> ${widget.cutoff + 0.28}');
        if (!_isFirstPage &&
            _controllers[pageNumber - 1].value >= widget.cutoff) {
          await previousPage();
        } else {
          if (_isFirstPage) {
            await _controllers[pageNumber].forward();
            // pageNotifier.value--;
          } else {
            await _controllers[pageNumber - 1].reverse();
            // pageNotifier.value--;
          }
        }
      }
    }
    _isForward = null;
  }

  Future<void> nextPage() async {
    await _controllers[pageNumber].reverse();
    if (mounted)
      setState(() {
        pageNumber++;
        // pageNotifier.value++;
      });
  }

  Future<void> previousPage() async {
    await _controllers[pageNumber - 1].forward();
    if (mounted)
      setState(() {
        pageNumber--;
        // pageNotifier.value--;
      });
  }

  Future<void> goToPage(int index) async {
    if (mounted)
      setState(() {
        pageNumber = index;
      });
    for (var i = 0; i < _controllers.length; i++) {
      if (i == index) {
        _controllers[i].forward();
      } else if (i < index) {
        _controllers[i].reverse();
      } else {
        if (_controllers[i].status == AnimationStatus.reverse)
          _controllers[i].value = 1;
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: LayoutBuilder(
        builder: (context, dimens) => GestureDetector(
          behavior: HitTestBehavior.opaque,
          onHorizontalDragCancel: () => _isForward = null,
          onHorizontalDragUpdate: (details) => _turnPage(details, dimens),
          onHorizontalDragEnd: (details) => _onDragFinish(),
          child: Stack(
            fit: StackFit.expand,
            children: <Widget>[
              if (widget.lastPage != null) widget.lastPage!,
              ...pages,
              Positioned.fill(
                child: Flex(
                  direction: Axis.horizontal,
                  children: <Widget>[
                    Flexible(
                      flex: (widget.cutoff * 10).round(),
                      child: Container(
                        color: widget.showDragCutoff
                            ? Colors.blue.withAlpha(100)
                            : null,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isFirstPage ? null : previousPage,
                        ),
                      ),
                    ),
                    Flexible(
                      flex: 10 - (widget.cutoff * 10).round(),
                      child: Container(
                        color: widget.showDragCutoff
                            ? Colors.red.withAlpha(100)
                            : null,
                        child: GestureDetector(
                          behavior: HitTestBehavior.opaque,
                          onTap: _isLastPage ? null : nextPage,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
