# honker-cpp

C++17 binding for [Honker](https://github.com/russellromney/honker): durable queues, streams, pub/sub, and time-trigger scheduling on SQLite.

Full docs:

- [Main repo](https://github.com/russellromney/honker)
- [Docs](https://honker.dev)

## Requirements

- Zig 0.16+
- C++17 compiler
- Honker SQLite extension

## Quick start

```cpp
#include "honker.hpp"

int main() {
    honker::Database db{"app.db", "./libhonker_ext.dylib"};
    auto q = db.queue("emails");

    q.enqueue(R"({"to":"alice@example.com"})");

    if (auto job = q.claim_one("worker-1")) {
        send_email(job->payload);
        job->ack();
    }
}
```

Delayed jobs use `run_at` options on enqueue. Recurring schedules use schedule expressions:

```cpp
auto sched = db.scheduler();
sched.add("fast", "emails", "@every 1s", R"({"kind":"tick"})");
```

Supported schedule forms:

- `0 3 * * *`
- `*/2 * * * * *`
- `@every 1s`

For full API docs, streams, notify/listen, and SQL details, see the main repo and docs site.
