# docs/PERFORMANCE_PLAN.md
# N.Y Kitchen — Performance Plan

---

## Purpose
Define performance targets and optimization strategies.

---

## Performance Targets

| Operation | Target |
|---|---|
| App launch | < 3 seconds |
| Login | < 2 seconds |
| Menu loading | < 2 seconds |
| Transaction save | < 1 second |
| Receipt generation | < 2 seconds |
| Report generation | < 5 seconds |
| Activity log loading | < 3 seconds |

## Optimization Strategies
- Use SQLite indexes on frequently queried columns (created_at, user_id, status).
- Paginate transaction history and activity logs.
- Load food images lazily.
- Use efficient chart rendering (fl_chart optimizations).
- Minimize unnecessary widget rebuilds (Provider).
- Test performance on minimum-spec target devices.

## Testing Tools
- Flutter DevTools (performance profiling)
- SQLite EXPLAIN QUERY PLAN (query analysis)

---

## TODO
- [ ] Define minimum-spec target Android device
- [ ] Profile all key operations during Phase 10
