# Fork divergences

This is a fork of [superlistapp/super_sliver_list](https://github.com/superlistapp/super_sliver_list),
consumed by the thefuseapp mobile client as the engine behind
`ExtendedListView.indexed` / `.indexedSliver`.

Upstream has not published since 2024-07. Verified to compile clean against
Flutter 3.38.9 (0 errors in `lib/`).

**Keep this file up to date.** Each entry below is a deliberate change that an
upstream sync will conflict with or silently revert. Re-apply and re-verify after
every rebase or merge from upstream.

---

## 1. `ListController.getOffsetToReveal` promoted to public API

*File:* `lib/src/super_sliver_list.dart`

Upstream annotates this method `@visibleForTesting`. We removed the annotation
and documented the method.

**Why:** it is the only way to obtain an item's position. `visibleRange` reports
indices only, and `unobstructedVisibleRange` is derived from
`SliverConstraints.overlap`, which a *floating* header does not produce —
verified: with a floating header it returns the same range as `visibleRange` at
every scroll offset, and it can never account for chrome drawn outside the
scroll view.

The client needs item geometry to answer "which is the topmost item not hidden
behind the app bar / status-bar cover?", used to label the space stream's
floating date header. Without this, the label keeps naming an item that has
already scrolled out of sight.

The method is a pure read of already-computed extent data with no side effects,
so widening its visibility carries no behavioural risk.

**Client call site:** `lib/src/widgets/extended_list_view.dart` —
`IndexedListController.firstIndexBelow`. Deliberately the only call site; keep it
that way so this divergence stays cheap to maintain.

**On upstream sync:** re-check whether upstream has made it public or added an
equivalent. If so, drop this divergence and delete this section.

---

## Known gaps (not yet diverged)

- **No `initialScrollIndex`.** `SuperListView` cannot open at a given item, so
  the client jumps after first layout, which costs one frame — a list opened at a
  non-zero index paints at the top before settling. Visible on deep-linked
  comments and space events. Patching this natively is the highest-value
  follow-up.
