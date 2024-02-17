import "dart:math" as math;

import "package:flutter/widgets.dart";

import "super_sliver_list.dart";

/// A scrollable list of widgets arranged linearly.
///
/// {@youtube 560 315 https://www.youtube.com/watch?v=KJpkjHGiI5A}
///
/// This is a drop-in replacement Flutter [ListView] that provides much better
/// performance with large number of children with variable extents
/// (unlike the original [ListView] the performance does not depend
/// on the number of children and can easily handle tens or hundreds of thousands
/// of children without having to specify hardcoded extent or prototype child).
///
/// It also provides a way to jump to a specific item in the list, even if
/// this item is not currently visible or have not been laid out.
///
/// [ListView] is the most commonly used scrolling widget. It displays its
/// children one after another in the scroll direction. In the cross axis, the
/// children are required to fill the [ListView].
///
/// There are four options for constructing a [ListView]:
///
///  1. The default constructor takes an explicit [List<Widget>] of children. This
///     constructor is appropriate for list views with a small number of
///     children because constructing the [List] requires doing work for every
///     child that could possibly be displayed in the list view instead of just
///     those children that are actually visible.
///
///  2. The [SuperListView.builder] constructor takes an [IndexedWidgetBuilder], which
///     builds the children on demand. This constructor is appropriate for list views
///     with a large (or infinite) number of children because the builder is called
///     only for those children that are actually visible.
///
///  3. The [SuperListView.separated] constructor takes two [IndexedWidgetBuilder]s:
///     `itemBuilder` builds child items on demand, and `separatorBuilder`
///     similarly builds separator children which appear in between the child items.
///     This constructor is appropriate for list views with a fixed number of children.
///
///  4. The [SuperListView.custom] constructor takes a [SliverChildDelegate], which provides
///     the ability to customize additional aspects of the child model. For example,
///     a [SliverChildDelegate] can control the algorithm used to estimate the
///     size of children that are not actually visible.
///
/// To control the initial scroll offset of the scroll view, provide a
/// [controller] with its [ScrollController.initialScrollOffset] property set.
///
/// By default, [SuperListView] will automatically pad the list's scrollable
/// extremities to avoid partial obstructions indicated by [MediaQuery]'s
/// padding. To avoid this behavior, override with a zero [padding] property.
///
/// {@tool snippet}
/// This example uses the default constructor for [SuperListView] which takes an
/// explicit [List<Widget>] of children. This [SuperListView]'s children are made up
/// of [SuperListView]s with [Text].
///
/// ![A SuperListView of 3 amber colored containers with sample text.](https://flutter.github.io/assets-for-api-docs/assets/widgets/list_view.png)
///
/// ```dart
/// SuperListView(
///   padding: const EdgeInsets.all(8),
///   children: <Widget>[
///     Container(
///       height: 50,
///       color: Colors.amber[600],
///       child: const Center(child: Text('Entry A')),
///     ),
///     Container(
///       height: 50,
///       color: Colors.amber[500],
///       child: const Center(child: Text('Entry B')),
///     ),
///     Container(
///       height: 50,
///       color: Colors.amber[100],
///       child: const Center(child: Text('Entry C')),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// This example mirrors the previous one, creating the same list using the
/// [SuperListView.builder] constructor. Using the [IndexedWidgetBuilder], children
/// are built lazily and can be infinite in number.
///
/// ![A SuperListView of 3 amber colored containers with sample text.](https://flutter.github.io/assets-for-api-docs/assets/widgets/list_view_builder.png)
///
/// ```dart
/// final List<String> entries = <String>['A', 'B', 'C'];
/// final List<int> colorCodes = <int>[600, 500, 100];
///
/// Widget build(BuildContext context) {
///   return SuperListView.builder(
///     padding: const EdgeInsets.all(8),
///     itemCount: entries.length,
///     itemBuilder: (BuildContext context, int index) {
///       return Container(
///         height: 50,
///         color: Colors.amber[colorCodes[index]],
///         child: Center(child: Text('Entry ${entries[index]}')),
///       );
///     }
///   );
/// }
/// ```
/// {@end-tool}
///
/// {@tool snippet}
/// This example continues to build from our the previous ones, creating a
/// similar list using [SuperListView.separated]. Here, a [Divider] is used as a
/// separator.
///
/// ![A ListView of 3 amber colored containers with sample text and a Divider
/// between each of them.](https://flutter.github.io/assets-for-api-docs/assets/widgets/list_view_separated.png)
///
/// ```dart
/// final List<String> entries = <String>['A', 'B', 'C'];
/// final List<int> colorCodes = <int>[600, 500, 100];
///
/// Widget build(BuildContext context) {
///   return SuperListView.separated(
///     padding: const EdgeInsets.all(8),
///     itemCount: entries.length,
///     itemBuilder: (BuildContext context, int index) {
///       return Container(
///         height: 50,
///         color: Colors.amber[colorCodes[index]],
///         child: Center(child: Text('Entry ${entries[index]}')),
///       );
///     },
///     separatorBuilder: (BuildContext context, int index) => const Divider(),
///   );
/// }
/// ```
/// {@end-tool}
///
/// ## Child elements' lifecycle
///
/// ### Creation
///
/// While laying out the list, visible children's elements, states and render
/// objects will be created lazily based on existing widgets (such as when using
/// the default constructor) or lazily provided ones (such as when using the
/// [SuperListView.builder] constructor).
///
/// ### Destruction
///
/// When a child is scrolled out of view, the associated element subtree,
/// states and render objects are destroyed. A new child at the same position
/// in the list will be lazily recreated along with new elements, states and
/// render objects when it is scrolled back.
///
/// ### Destruction mitigation
///
/// In order to preserve state as child elements are scrolled in and out of
/// view, the following options are possible:
///
///  * Moving the ownership of non-trivial UI-state-driving business logic
///    out of the list child subtree. For instance, if a list contains posts
///    with their number of upvotes coming from a cached network response, store
///    the list of posts and upvote number in a data model outside the list. Let
///    the list child UI subtree be easily recreate-able from the
///    source-of-truth model object. Use [StatefulWidget]s in the child
///    widget subtree to store instantaneous UI state only.
///
///  * Letting [KeepAlive] be the root widget of the list child widget subtree
///    that needs to be preserved. The [KeepAlive] widget marks the child
///    subtree's top render object child for keepalive. When the associated top
///    render object is scrolled out of view, the list keeps the child's render
///    object (and by extension, its associated elements and states) in a cache
///    list instead of destroying them. When scrolled back into view, the render
///    object is repainted as-is (if it wasn't marked dirty in the interim).
///
///    This only works if `addAutomaticKeepAlives` and `addRepaintBoundaries`
///    are false since those parameters cause the [ListView] to wrap each child
///    widget subtree with other widgets.
///
///  * Using [AutomaticKeepAlive] widgets (inserted by default when
///    `addAutomaticKeepAlives` is true). [AutomaticKeepAlive] allows descendant
///    widgets to control whether the subtree is actually kept alive or not.
///    This behavior is in contrast with [KeepAlive], which will unconditionally keep
///    the subtree alive.
///
///    As an example, the [EditableText] widget signals its list child element
///    subtree to stay alive while its text field has input focus. If it doesn't
///    have focus and no other descendants signaled for keepalive via a
///    [KeepAliveNotification], the list child element subtree will be destroyed
///    when scrolled away.
///
///    [AutomaticKeepAlive] descendants typically signal it to be kept alive
///    by using the [AutomaticKeepAliveClientMixin], then implementing the
///    [AutomaticKeepAliveClientMixin.wantKeepAlive] getter and calling
///    [AutomaticKeepAliveClientMixin.updateKeepAlive].
///
/// ## Transitioning to [CustomScrollView]
///
/// A [SuperListView] is basically a [CustomScrollView] with a single [SuperSliverList] in
/// its [CustomScrollView.slivers] property.
///
/// If [ListView] is no longer sufficient, for example because the scroll view
/// is to have both a list and a grid, or because the list is to be combined
/// with a [SliverAppBar], etc, it is straight-forward to port code from using
/// [SuperListView] to using [CustomScrollView] directly.
///
/// The [key], [scrollDirection], [reverse], [controller], [primary], [physics],
/// and [shrinkWrap] properties on [SuperListView] map directly to the identically
/// named properties on [CustomScrollView].
///
/// The [childrenDelegate] property on [ListView] corresponds to the
/// [SliverList.delegate] property. The [SuperListView] constructor's `children`
/// argument corresponds to the [childrenDelegate] being a
/// [SliverChildListDelegate] with that same argument.
/// The [ListView.builder] constructor's `itemBuilder` and `itemCount`
///  arguments correspond to the [childrenDelegate] being a
/// [SliverChildBuilderDelegate] with the equivalent arguments.
///
/// The [padding] property corresponds to having a [SliverPadding] in the
/// [CustomScrollView.slivers] property instead of the list itself, and having
/// the [SliverList] instead be a child of the [SliverPadding].
///
/// [CustomScrollView]s don't automatically avoid obstructions from [MediaQuery]
/// like [ListView]s do. To reproduce the behavior, wrap the slivers in
/// [SliverSafeArea]s.
///
/// Once code has been ported to use [CustomScrollView], other slivers, such as
/// [SliverGrid] or [SliverAppBar], can be put in the [CustomScrollView.slivers]
/// list.
///
/// {@tool snippet}
///
/// Here are two brief snippets showing a [SuperListView] and its equivalent using
/// [CustomScrollView]:
///
/// ```dart
/// SuperListView(
///   padding: const EdgeInsets.all(20.0),
///   children: const <Widget>[
///     Text("I'm dedicating every day to you"),
///     Text('Domestic life was never quite my style'),
///     Text('When you smile, you knock me out, I fall apart'),
///     Text('And I thought I was so smart'),
///   ],
/// )
/// ```
/// {@end-tool}
/// {@tool snippet}
///
/// ```dart
/// CustomScrollView(
///   slivers: <Widget>[
///     SliverPadding(
///       padding: const EdgeInsets.all(20.0),
///       sliver: SuperSliverList(
///         delegate: SliverChildListDelegate(
///           <Widget>[
///             const Text("I'm dedicating every day to you"),
///             const Text('Domestic life was never quite my style'),
///             const Text('When you smile, you knock me out, I fall apart'),
///             const Text('And I thought I was so smart'),
///           ],
///         ),
///       ),
///     ),
///   ],
/// )
/// ```
/// {@end-tool}
///
/// ## Special handling for an empty list
///
/// A common design pattern is to have a custom UI for an empty list. The best
/// way to achieve this in Flutter is just conditionally replacing the
/// [ListView] at build time with whatever widgets you need to show for the
/// empty list state:
///
/// {@tool snippet}
///
/// Example of simple empty list interface:
///
/// ```dart
/// Widget build(BuildContext context) {
///   return Scaffold(
///     appBar: AppBar(title: const Text('Empty List Test')),
///     body: itemCount > 0
///       ? ListView.builder(
///           itemCount: itemCount,
///           itemBuilder: (BuildContext context, int index) {
///             return ListTile(
///               title: Text('Item ${index + 1}'),
///             );
///           },
///         )
///       : const Center(child: Text('No items')),
///   );
/// }
/// ```
/// {@end-tool}
///
/// ## Selection of list items
///
/// [ListView] has no built-in notion of a selected item or items. For a small
/// example of how a caller might wire up basic item selection, see
/// [ListTile.selected].
///
/// {@tool dartpad}
/// This example shows a custom implementation of [ListTile] selection in a [ListView] or [GridView].
/// Long press any [ListTile] to enable selection mode.
///
/// ** See code in examples/api/lib/widgets/scroll_view/list_view.0.dart **
/// {@end-tool}
///
/// {@macro flutter.widgets.BoxScroll.scrollBehaviour}
///
/// {@macro flutter.widgets.ScrollView.PageStorage}
///
/// See also:
///
///  * [SingleChildScrollView], which is a scrollable widget that has a single
///    child.
///  * [PageView], which is a scrolling list of child widgets that are each the
///    size of the viewport.
///  * [GridView], which is a scrollable, 2D array of widgets.
///  * [CustomScrollView], which is a scrollable widget that creates custom
///    scroll effects using slivers.
///  * [ListBody], which arranges its children in a similar manner, but without
///    scrolling.
///  * [ScrollNotification] and [NotificationListener], which can be used to watch
///    the scroll position without using a [ScrollController].
///  * The [catalog of layout widgets](https://flutter.dev/widgets/layout/).
///  * Cookbook: [Use lists](https://flutter.dev/docs/cookbook/lists/basic-list)
///  * Cookbook: [Work with long lists](https://flutter.dev/docs/cookbook/lists/long-lists)
///  * Cookbook: [Create a horizontal list](https://flutter.dev/docs/cookbook/lists/horizontal-list)
///  * Cookbook: [Create lists with different types of items](https://flutter.dev/docs/cookbook/lists/mixed-list)
///  * Cookbook: [Implement swipe to dismiss](https://flutter.dev/docs/cookbook/gestures/dismissible)
class SuperListView extends BoxScrollView {
  SuperListView({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    List<Widget> children = const <Widget>[],
    int? semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    this.extentController,
    this.extentEstimationProvider,
    this.extentPrecalculationPolicy,
    this.delayPopulatingCacheArea = false,
  })  : childrenDelegate = SliverChildListDelegate(
          children,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        ),
        super(
          semanticChildCount: semanticChildCount ?? children.length,
        );

  /// Creates a scrollable, linear array of widgets that are created on demand.
  ///
  /// This constructor is appropriate for list views with a large (or infinite)
  /// number of children because the builder is called only for those children
  /// that are actually visible.
  ///
  /// Providing a non-null `itemCount` improves the ability of the [SuperListView] to
  /// estimate the maximum scroll extent.
  ///
  /// The `itemBuilder` callback will be called only with indices greater than
  /// or equal to zero and less than `itemCount`.
  ///
  /// {@template flutter.widgets.ListView.builder.itemBuilder}
  /// It is legal for `itemBuilder` to return `null`. If it does, the scroll view
  /// will stop calling `itemBuilder`, even if it has yet to reach `itemCount`.
  /// By returning `null`, the [ScrollPosition.maxScrollExtent] will not be accurate
  /// unless the user has reached the end of the [ScrollView]. This can also cause the
  /// [Scrollbar] to grow as the user scrolls.
  ///
  /// For more accurate [ScrollMetrics], consider specifying `itemCount`.
  /// {@endtemplate}
  ///
  /// The `itemBuilder` should always create the widget instances when called.
  /// Avoid using a builder that returns a previously-constructed widget; if the
  /// list view's children are created in advance, or all at once when the
  /// [ListView] itself is created, it is more efficient to use the [ListView]
  /// constructor. Even more efficient, however, is to create the instances on
  /// demand using this constructor's `itemBuilder` callback.
  ///
  /// {@macro flutter.widgets.PageView.findChildIndexCallback}
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
  /// `addSemanticIndexes` argument corresponds to the
  /// [SliverChildBuilderDelegate.addSemanticIndexes] property. None may be
  /// null.
  SuperListView.builder({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    int? itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    int? semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    this.extentController,
    this.extentEstimationProvider,
    this.extentPrecalculationPolicy,
    this.delayPopulatingCacheArea = false,
  })  : assert(itemCount == null || itemCount >= 0),
        assert(semanticChildCount == null || semanticChildCount <= itemCount!),
        childrenDelegate = SliverChildBuilderDelegate(
          itemBuilder,
          findChildIndexCallback: findChildIndexCallback,
          childCount: itemCount,
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
        ),
        super(
          semanticChildCount: semanticChildCount ?? itemCount,
        );

  /// Creates a fixed-length scrollable linear array of list "items" separated
  /// by list item "separators".
  ///
  /// This constructor is appropriate for list views with a large number of
  /// item and separator children because the builders are only called for
  /// the children that are actually visible.
  ///
  /// The `itemBuilder` callback will be called with indices greater than
  /// or equal to zero and less than `itemCount`.
  ///
  /// Separators only appear between list items: separator 0 appears after item
  /// 0 and the last separator appears before the last item.
  ///
  /// The `separatorBuilder` callback will be called with indices greater than
  /// or equal to zero and less than `itemCount - 1`.
  ///
  /// The `itemBuilder` and `separatorBuilder` callbacks should always
  /// actually create widget instances when called. Avoid using a builder that
  /// returns a previously-constructed widget; if the list view's children are
  /// created in advance, or all at once when the [ListView] itself is created,
  /// it is more efficient to use the [ListView] constructor.
  ///
  /// {@macro flutter.widgets.ListView.builder.itemBuilder}
  ///
  /// {@macro flutter.widgets.PageView.findChildIndexCallback}
  ///
  /// {@tool snippet}
  ///
  /// This example shows how to create [ListView] whose [ListTile] list items
  /// are separated by [Divider]s.
  ///
  /// ```dart
  /// ListView.separated(
  ///   itemCount: 25,
  ///   separatorBuilder: (BuildContext context, int index) => const Divider(),
  ///   itemBuilder: (BuildContext context, int index) {
  ///     return ListTile(
  ///       title: Text('item $index'),
  ///     );
  ///   },
  /// )
  /// ```
  /// {@end-tool}
  ///
  /// The `addAutomaticKeepAlives` argument corresponds to the
  /// [SliverChildBuilderDelegate.addAutomaticKeepAlives] property. The
  /// `addRepaintBoundaries` argument corresponds to the
  /// [SliverChildBuilderDelegate.addRepaintBoundaries] property. The
  /// `addSemanticIndexes` argument corresponds to the
  /// [SliverChildBuilderDelegate.addSemanticIndexes] property. None may be
  /// null.
  SuperListView.separated({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required NullableIndexedWidgetBuilder itemBuilder,
    ChildIndexGetter? findChildIndexCallback,
    required IndexedWidgetBuilder separatorBuilder,
    required int itemCount,
    bool addAutomaticKeepAlives = true,
    bool addRepaintBoundaries = true,
    bool addSemanticIndexes = true,
    super.cacheExtent,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    this.extentController,
    this.extentEstimationProvider,
    this.extentPrecalculationPolicy,
    this.delayPopulatingCacheArea = false,
  })  : assert(itemCount >= 0),
        childrenDelegate = SliverChildBuilderDelegate(
          (BuildContext context, int index) {
            final int itemIndex = index ~/ 2;
            if (index.isEven) {
              return itemBuilder(context, itemIndex);
            }
            return separatorBuilder(context, itemIndex);
          },
          findChildIndexCallback: findChildIndexCallback,
          childCount: _computeActualChildCount(itemCount),
          addAutomaticKeepAlives: addAutomaticKeepAlives,
          addRepaintBoundaries: addRepaintBoundaries,
          addSemanticIndexes: addSemanticIndexes,
          semanticIndexCallback: (Widget widget, int index) {
            return index.isEven ? index ~/ 2 : null;
          },
        ),
        super(
          semanticChildCount: itemCount,
        );

  /// Creates a scrollable, linear array of widgets with a custom child model.
  ///
  /// For example, a custom child model can control the algorithm used to
  /// estimate the size of children that are not actually visible.
  ///
  /// {@tool dartpad}
  /// This example shows a [ListView] that uses a custom [SliverChildBuilderDelegate] to support child
  /// reordering.
  ///
  /// ** See code in examples/api/lib/widgets/scroll_view/list_view.1.dart **
  /// {@end-tool}
  const SuperListView.custom({
    super.key,
    super.scrollDirection,
    super.reverse,
    super.controller,
    super.primary,
    super.physics,
    super.shrinkWrap,
    super.padding,
    required this.childrenDelegate,
    super.cacheExtent,
    super.semanticChildCount,
    super.dragStartBehavior,
    super.keyboardDismissBehavior,
    super.restorationId,
    super.clipBehavior,
    this.extentController,
    this.extentEstimationProvider,
    this.extentPrecalculationPolicy,
    this.delayPopulatingCacheArea = false,
  });

  /// A delegate that provides the children for the [ListView].
  ///
  /// The [ListView.custom] constructor lets you specify this delegate
  /// explicitly. The [ListView] and [ListView.builder] constructors create a
  /// [childrenDelegate] that wraps the given [List] and [IndexedWidgetBuilder],
  /// respectively.
  final SliverChildDelegate childrenDelegate;

  /// When set provides access to extents of individual children.
  /// [ExtentController] can also be used to jump to a specific item in the list.
  final ExtentController? extentController;

  /// Optional method that can be used to override default estimated extent for
  /// each item. Initially all extents are estimated and then as the items are laid
  /// out, either through scrolling or [extentPrecalculationPolicy], the actual
  /// extents are calculated and the scroll offset is adjusted to account for
  /// the difference between estimated and actual extents.
  final ExtentEstimationProvider? extentEstimationProvider;

  /// Optional policy that can be used to asynchronously precalculate the extents
  /// of the items in the list. This can be useful allow precise scrolling on small
  /// lists where the difference between estimated and actual extents may be noticeable
  /// when interacting with the scrollbar. For larger lists precalculating extent
  /// has diminished benefits since the error for each item does not impact the
  /// overall scroll position as much.
  final ExtentPrecalculationPolicy? extentPrecalculationPolicy;

  /// Whether the items in cache area should be built delayed.
  /// This is an optimization that kicks in during fast scrolling, when
  /// all items are being replaced on every frame.
  /// With [delayPopulatingCacheArea] set to `true`, the items in cache area
  /// are only built after the scrolling slows down.
  final bool delayPopulatingCacheArea;

  @override
  Widget buildChildLayout(BuildContext context) {
    return SuperSliverList(
      delegate: childrenDelegate,
      extentController: extentController,
    );
  }

  // Helper method to compute the actual child count for the separated constructor.
  static int _computeActualChildCount(int itemCount) {
    return math.max(0, itemCount * 2 - 1);
  }
}
