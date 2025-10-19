# Oban TestJob Worker

This directory contains a test Oban worker designed to demonstrate graceful shutdown behavior on Fly.io and other deployment platforms.

## Overview

The `TestJob` worker performs long-running dummy work (configurable duration) and handles graceful shutdown properly. It's designed to:

- Run for several minutes (configurable)
- Process work in chunks with progress logging
- Handle graceful shutdown when receiving termination signals
- Return detailed results about work performed

## Features

### Graceful Shutdown
- Oban is configured with a `shutdown_grace_period` of 5 minutes
- The worker checks for shutdown signals between work chunks
- When shutdown is initiated, the worker completes its current chunk and exits cleanly
- Returns information about how much work was completed before shutdown

### Progress Tracking
- Work is performed in configurable chunks (default 5 seconds)
- Each chunk completion is logged with timing information
- Final result includes details about all completed chunks

### Configurable Duration
- Default: 120 seconds (2 minutes)
- Can be configured per job via arguments
- Chunk size is also configurable

## Usage

### Using IEx Console

```elixir
# Start the app
iex -S mix

# Enqueue a quick test (30 seconds)
ObanTests.Worker.TestHelper.enqueue_quick()

# Enqueue a medium test (2 minutes)
ObanTests.Worker.TestHelper.enqueue_medium()

# Enqueue a long test (5 minutes)
ObanTests.Worker.TestHelper.enqueue_long()

# Enqueue a custom duration job
ObanTests.Worker.TestHelper.enqueue_custom(180, 10)
# Runs for 180 seconds with 10-second chunks

# Enqueue multiple jobs
ObanTests.Worker.TestHelper.enqueue_multiple(3, duration_seconds: 60)
```

### Direct Usage

```elixir
# Using the worker directly with custom args
%{duration_seconds: 180, chunk_size: 5}
|> ObanTests.Worker.TestJob.new()
|> Oban.insert()

# Or use the convenience function
ObanTests.Worker.TestJob.enqueue(duration_seconds: 240, chunk_size: 10)
```

## Testing Graceful Shutdown

### Locally

1. Start the application:
```bash
iex -S mix phx.server
```

2. Enqueue a long-running job:
```elixir
ObanTests.Worker.TestHelper.enqueue_long()
```

3. While the job is running, stop the application with Ctrl+C twice (or once and choose 'a' for abort)

4. Watch the logs - you should see:
   - Job processing chunks
   - Shutdown signal received
   - Graceful shutdown message
   - Job marked as completed with partial work done

### On Fly.io

1. Deploy the application to Fly.io:
```bash
fly deploy
```

2. SSH into the running instance:
```bash
fly ssh console
```

3. Attach to the running Elixir application:
```bash
/app/bin/oban_tests remote
```

4. Enqueue a test job:
```elixir
ObanTests.Worker.TestHelper.enqueue_long()
```

5. In another terminal, trigger a restart:
```bash
fly apps restart oban_tests
```

6. Watch the logs to see graceful shutdown:
```bash
fly logs
```

You should see the worker complete its current chunk and shut down gracefully.

## Configuration

### Oban Configuration (`config/config.exs`)

```elixir
config :oban_tests, Oban,
  engine: Oban.Engines.Lite,
  queues: [default: 10],
  shutdown_grace_period: :timer.minutes(5)
```

- `engine: Oban.Engines.Lite` - Uses in-memory storage (no database required)
- `queues: [default: 10]` - Process up to 10 jobs concurrently in the default queue
- `shutdown_grace_period: :timer.minutes(5)` - Wait up to 5 minutes for jobs to complete during shutdown

### Worker Configuration

The worker itself is configured with:

```elixir
use Oban.Worker,
  queue: :default,
  max_attempts: 3,
  timeout: :timer.minutes(10)
```

- `queue: :default` - Uses the default queue
- `max_attempts: 3` - Retry failed jobs up to 3 times
- `timeout: :timer.minutes(10)` - Kill the job if it runs longer than 10 minutes

## Fly.io Deployment Considerations

### Shutdown Grace Period

Fly.io gives your app 30 seconds by default to shut down gracefully. To extend this, update your `fly.toml`:

```toml
[processes]
  grace_period = "5m"  # Match or exceed Oban's shutdown_grace_period
```

### Health Checks

Ensure health checks don't interfere with long-running jobs. In `fly.toml`:

```toml
[http_service]
  internal_port = 4000
  force_https = true
  auto_stop_machines = false  # Prevent auto-scaling from killing jobs
  auto_start_machines = true
  min_machines_running = 1

  [http_service.checks]
    interval = "10s"
    timeout = "2s"
    grace_period = "5s"
```

## Monitoring

### Log Output

The worker produces structured logs:

```
[TestJob] Starting long-running job
Duration: 180 seconds
Chunk size: 5 seconds
Process: #PID<0.1234.0>

[TestJob] Processing chunk 1/36
Remaining chunks: 36

[TestJob] Processing chunk 2/36
Remaining chunks: 35

... (during shutdown) ...

[TestJob] Received shutdown message
[TestJob] Job shutdown gracefully
Completed chunks: 15
Duration before shutdown: 75 seconds
```

### Result Structure

When a job completes (either fully or via graceful shutdown), it returns:

```elixir
{:ok, %{
  status: "completed",  # or "shutdown_gracefully"
  chunks_completed: 36,
  total_duration: 180,
  details: [
    %{
      chunk_number: 1,
      duration_ms: 5001,
      timestamp: ~U[2024-01-15 10:30:00Z],
      status: "completed"
    },
    # ... more chunks
  ]
}}
```

## Architecture Notes

### Why Chunks?

Processing work in chunks allows the worker to:
- Check for shutdown signals periodically
- Provide progress feedback
- Ensure responsiveness to system signals
- Resume work more easily (in a real scenario with checkpointing)

### Shutdown Flow

1. System sends shutdown signal (SIGTERM)
2. Oban's supervisor begins graceful shutdown
3. Oban stops accepting new jobs
4. Worker receives shutdown message in its receive loop
5. Worker completes current chunk
6. Worker returns with shutdown status
7. Oban waits for all workers (up to grace period)
8. System exits cleanly

## Troubleshooting

### Job Times Out
- Increase the worker's `timeout` option
- Reduce the `duration_seconds` when enqueueing
- Check if the system is under heavy load

### Shutdown Takes Too Long
- Reduce chunk size for more frequent shutdown checks
- Ensure `shutdown_grace_period` is set appropriately
- Check Fly.io's grace period configuration

### Jobs Not Processing
- Verify Oban is started in the supervision tree
- Check queue configuration
- Ensure jobs are being inserted successfully
- Check logs for Oban errors

## Future Enhancements

Potential improvements for production use:

1. **Database Persistence**: Replace `Oban.Engines.Lite` with Postgres for persistence across restarts
2. **Checkpointing**: Save progress at each chunk to resume interrupted jobs
3. **Metrics**: Add Telemetry events for monitoring job performance
4. **Alerting**: Notify when jobs are shut down before completion
5. **Real Work**: Replace dummy work with actual business logic