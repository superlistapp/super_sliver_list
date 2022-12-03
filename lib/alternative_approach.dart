class LazyLoadingList extends SliverMultiBoxAdaptorWidget {
  // The number of children to load at a time.
  final int batchSize;

  // The number of children to pre-emptively load ahead of the user's scrolling.
  final int preloadBatchSize;

  LazyLoadingList({
    super.key,
    required super.delegate,
    this.batchSize = 20,
    this.preloadBatchSize = 10,
  });

  @override
  SliverMultiBoxAdaptorElement createElement() =>
      SliverMultiBoxAdaptorElement(this, replaceMovedChildren: true);

  @override
  RenderSliverMultiBoxAdaptor createRenderObject(BuildContext context) {
    final SliverMultiBoxAdaptorElement element =
        context as SliverMultiBoxAdaptorElement;
    return _RenderLazyLoadingList(
      childManager: element,
      batchSize: batchSize,
      preloadBatchSize: preloadBatchSize,
    );
  }
}

class _RenderLazyLoadingList extends RenderSliverMultiBoxAdaptor {
  _RenderLazyLoadingList({
    required super.childManager,
    this.batchSize = 20,
    this.preloadBatchSize = 10,
  });

  // The number of children to load at a time.
  final int batchSize;

  // The number of children to pre-emptively load ahead of the user's scrolling.
  final int preloadBatchSize;

  // The index of the first child that is currently loaded.
  int firstLoadedIndex = 0;

  // The index of the last child that is currently loaded.
  int lastLoadedIndex = 0;

  @override
  void performLayout() {
    // Check if we need to load more children.
    if (lastLoadedIndex < childManager.childCount - 1 &&
        lastLoadedIndex < firstLoadedIndex + batchSize + preloadBatchSize) {
      // Load the next batch of children.
      for (var i = lastLoadedIndex + 1; i <= lastLoadedIndex + batchSize; i++) {
        final child = childManager.createChild(i, after: childAfter(lastChild));
        childManager.children.add(child);
        lastLoadedIndex++;
      }
    }

    // Lay out the children that are currently loaded.
    for (var i = firstLoadedIndex; i <= lastLoadedIndex; i++) {
      final child = childManager.children[i];
      child.layout(constraints.asBoxConstraints(), parentUsesSize: true);
    }

    // Check if we need to unload any children.
    if (firstLoadedIndex > 0 && firstLoadedIndex > lastLoadedIndex - batchSize) {
      // Unload the first batch of children.
      for (var i = 0; i < batchSize; i++) {
        final child = childManager.children.first;
        childManager.removeChild(child);
        firstLoadedIndex--;
      }
    }
  }
}
