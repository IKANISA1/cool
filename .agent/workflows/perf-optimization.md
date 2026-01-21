---
description: Systematic performance optimization workflow
---

# Performance Optimization Workflow

Goal: Optimize {feature/screen} for production-grade performance

## Phase 1: Baseline Measurement
1. Run app in profile mode:
   ```bash
   flutter run --profile
   ```
2. Open Flutter DevTools:
   ```bash
   flutter pub global run devtools
   ```
3. Record baseline metrics:
   - **Startup time**: Cold start to first frame
   - **Frame rendering**: Jank rate (frames >16ms)
   - **Memory usage**: Peak and steady-state
   - **Network**: Request count and payload size
4. Take performance trace (Timeline)
5. Document baseline in `perf-baseline-{date}.md`

## Phase 2: Identify Bottlenecks
1. Analyze DevTools Timeline:
   - Red frames = jank (>16ms)
   - Look for long build/paint phases
2. Common issues to find:
   - **Slow widgets**: Build time >16ms
   - **Unnecessary rebuilds**: Parent rebuilding children
   - **Large images**: Unoptimized assets
   - **Blocking operations**: Sync I/O on main thread
   - **Expensive layouts**: Nested ListView/GridView
3. Prioritize by impact (high jank first)

## Phase 3: Apply Optimizations

### Widget Optimizations
- [ ] Add `const` constructors where possible
- [ ] Use `RepaintBoundary` for isolated animations
- [ ] Split large widgets into smaller components
- [ ] Use `ValueListenableBuilder` for granular rebuilds

### List Optimizations
- [ ] Use `ListView.builder` for long lists
- [ ] Add `itemExtent` when item height is fixed
- [ ] Implement pagination for large datasets
- [ ] Use `AutomaticKeepAliveClientMixin` sparingly

### Image Optimizations
- [ ] Use `CachedNetworkImage` for remote images
- [ ] Resize images to display size
- [ ] Use WebP format where supported
- [ ] Implement progressive loading

### Async Optimizations
- [ ] Move heavy work to `compute()` isolates
- [ ] Debounce rapid events (search, scroll)
- [ ] Cancel pending requests on dispose
- [ ] Prefetch data before navigation

### State Management
- [ ] Minimize provider scope
- [ ] Use `select` for granular subscriptions
- [ ] Avoid unnecessary state updates

## Phase 4: Measure Improvements
1. Run profiling again with same conditions
2. Compare to baseline:
   | Metric | Before | After | Improvement |
   |--------|--------|-------|-------------|
   | Startup | Xs | Ys | Z% faster |
   | Jank rate | X% | Y% | Z% reduction |
   | Memory | XMB | YMB | ZMB saved |
3. Document in `perf-optimized-{date}.md`

## Phase 5: Validate
1. Test on low-end device (Android Go, old iPhone)
2. Test on slow network (3G simulation)
3. Load test with realistic data volume
4. Verify no functional regressions

## Success Criteria
- [ ] Startup time < 3s
- [ ] Frame rate >= 60fps (no jank)
- [ ] Memory < 150MB steady-state
- [ ] APK size < 25MB

## Artifacts
- `perf-baseline-{date}.md`
- `perf-optimized-{date}.md`
- Before/after comparison charts
- DevTools timeline screenshots
