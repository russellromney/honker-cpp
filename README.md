# honker-cpp

C++17 binding for [honker](https://honker.dev) — durable queues, streams, pub/sub, and scheduler on SQLite.

## Architecture

- **Zig shim** (`src/honker.zig`) — C ABI layer over SQLite + the honker extension. Exposes `honker_cpp_*` functions that wrap SQL calls.
- **C++ header** (`include/honker.hpp`) — RAII wrappers around the Zig shim. Move-only types, throws `honker::Error` on failure.
- **Tests** — `test/test_basic.cpp` (smoke test) and `test/test_parity.cpp` (24 tests covering transactions, streams, scheduler, locks, rate limits, results, notify/listen).

## Requirements

- Zig 0.16+
- C++17 compiler
- The honker extension (`libhonker_ext.dylib` or `.so`)

SQLite is vendored (see `vendor/sqlite3/`) — no external SQLite dependency needed.

## Quick start

```bash
git clone https://github.com/russellromney/honker-cpp.git
cd honker-cpp

# Build the honker extension (or download a prebuilt release)
# If you have the main honker repo:
#   cargo build --release -p honker-extension
# Then point zig build at it:

zig build test -Dhonker-ext=/path/to/libhonker_ext.dylib
```

## Usage

```cpp
#include "honker.hpp"

int main() {
    honker::Database db{"app.db", "./libhonker_ext.dylib"};

    auto q = db.queue("emails");
    auto id = q.enqueue(R"({"to":"alice@example.com"})");

    auto job = q.claim_one("worker-1");
    if (job) {
        job->ack();
    }

    auto s = db.stream("events");
    s.publish(R"({"user_id":42})");

    auto lock = db.try_lock("backup", "worker-1", 60);
    if (lock) {
        // do work
    }
}
```

## API surface

- `Database` — open/close, queue/stream/scheduler factories, locks, rate limits, results, notify/listen
- `Transaction` — `BEGIN IMMEDIATE` / `COMMIT` / `ROLLBACK`; RAII rollback on uncommitted destruction
- `Queue` — `enqueue`, `enqueue_tx`, `claim_one`, `claim_batch`, `ack`, `ack_batch`, `retry`, `fail`, `heartbeat`, `sweep_expired`
- `Stream` — `publish`, `publish_tx`, `read_since`, `read_from_consumer`, `save_offset`, `save_offset_tx`, `get_offset`, `subscribe`
- `Scheduler` — `add`, `remove`, `tick`, `soonest`, `run` (leader-elected with heartbeat)
- `Lock` — RAII advisory lock with `release` and `heartbeat`
- `Subscription` — poll-based listen iterator for `notify` channels

## License

Apache 2.0. See [LICENSE](LICENSE).
