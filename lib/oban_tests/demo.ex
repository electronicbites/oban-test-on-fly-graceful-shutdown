defmodule ObanTests.Demo do
  @moduledoc """
  Demo script for testing the Oban TestJob worker.

  This module provides interactive demonstrations of the worker's
  graceful shutdown behavior.
  """

  require Logger
  alias ObanTests.Worker.TestHelper

  @doc """
  Runs a quick demo (30 seconds) to showcase the worker.

  ## Examples

      iex> ObanTests.Demo.quick()
      :ok
  """
  def quick do
    Logger.info("""
    ========================================
    QUICK DEMO - 30 seconds
    ========================================
    This will enqueue a job that runs for 30 seconds.
    Watch the logs to see chunk processing.

    To test graceful shutdown:
    1. Let it run for ~15 seconds
    2. Press Ctrl+C twice to stop
    3. Observe graceful shutdown in logs
    ========================================
    """)

    case TestHelper.enqueue_quick() do
      {:ok, job} ->
        Logger.info("✓ Job enqueued successfully: #{job.id}")
        Logger.info("  Duration: 30 seconds")
        Logger.info("  Chunk size: 5 seconds")
        Logger.info("  Worker: #{job.worker}")
        :ok

      {:error, reason} ->
        Logger.error("✗ Failed to enqueue job: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Runs a full demo (5 minutes) to test graceful shutdown.

  ## Examples

      iex> ObanTests.Demo.full()
      :ok
  """
  def full do
    Logger.info("""
    ========================================
    FULL DEMO - 5 minutes
    ========================================
    This will enqueue a job that runs for 5 minutes.

    RECOMMENDED ACTIONS:
    1. Let it run for 1-2 minutes
    2. Trigger a shutdown (Ctrl+C or restart)
    3. Observe graceful shutdown handling
    4. Check job result for partial completion

    The job will process work in 10-second chunks,
    saving progress after each chunk.
    ========================================
    """)

    case TestHelper.enqueue_long() do
      {:ok, job} ->
        Logger.info("✓ Job enqueued successfully: #{job.id}")
        Logger.info("  Duration: 300 seconds (5 minutes)")
        Logger.info("  Chunk size: 10 seconds")
        Logger.info("  Expected chunks: 30")
        :ok

      {:error, reason} ->
        Logger.error("✗ Failed to enqueue job: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Runs a stress test with multiple concurrent jobs.

  ## Examples

      iex> ObanTests.Demo.stress_test(3)
      :ok
  """
  def stress_test(job_count \\ 3) do
    Logger.info("""
    ========================================
    STRESS TEST - #{job_count} concurrent jobs
    ========================================
    This will enqueue #{job_count} jobs running concurrently.
    Each job runs for 2 minutes with 5-second chunks.

    This tests:
    - Concurrent job processing
    - Resource management
    - Graceful shutdown with multiple jobs
    ========================================
    """)

    results = TestHelper.enqueue_multiple(job_count, duration_seconds: 120, chunk_size: 5)

    success_count =
      Enum.count(results, fn
        {:ok, _} -> true
        _ -> false
      end)

    Logger.info("✓ Enqueued #{success_count}/#{job_count} jobs successfully")

    Enum.each(results, fn
      {:ok, job} ->
        Logger.info("  - Job #{job.id}: 120s duration, 5s chunks")

      {:error, reason} ->
        Logger.error("  - Failed: #{inspect(reason)}")
    end)

    :ok
  end

  @doc """
  Demonstrates custom job configuration.

  ## Examples

      iex> ObanTests.Demo.custom(duration: 90, chunk_size: 15)
      :ok
  """
  def custom(opts \\ []) do
    duration = Keyword.get(opts, :duration, 60)
    chunk_size = Keyword.get(opts, :chunk_size, 10)
    chunks = ceil(duration / chunk_size)

    Logger.info("""
    ========================================
    CUSTOM DEMO
    ========================================
    Duration: #{duration} seconds
    Chunk size: #{chunk_size} seconds
    Expected chunks: #{chunks}
    ========================================
    """)

    case TestHelper.enqueue_custom(duration, chunk_size) do
      {:ok, job} ->
        Logger.info("✓ Custom job enqueued: #{job.id}")
        :ok

      {:error, reason} ->
        Logger.error("✗ Failed to enqueue: #{inspect(reason)}")
        {:error, reason}
    end
  end

  @doc """
  Shows interactive menu for demo selection.
  """
  def menu do
    IO.puts("""

    ╔═══════════════════════════════════════════════════════════╗
    ║           OBAN GRACEFUL SHUTDOWN DEMO                     ║
    ╚═══════════════════════════════════════════════════════════╝

    Available demos:

    1. Quick Demo (30 seconds)
       → ObanTests.Demo.quick()

    2. Full Demo (5 minutes)
       → ObanTests.Demo.full()

    3. Stress Test (3 concurrent jobs)
       → ObanTests.Demo.stress_test(3)

    4. Custom Demo
       → ObanTests.Demo.custom(duration: 90, chunk_size: 15)

    ───────────────────────────────────────────────────────────

    Testing Graceful Shutdown:

    1. Run any demo above
    2. Let it process for a while
    3. Stop the application:
       - Press Ctrl+C twice, OR
       - In IEx: Application.stop(:oban_tests)
    4. Watch the logs for graceful shutdown messages

    ───────────────────────────────────────────────────────────

    Helper functions:

    • Check Oban status:
      Supervisor.which_children(ObanTests.Supervisor)

    • View this menu again:
      ObanTests.Demo.menu()

    ╚═══════════════════════════════════════════════════════════╝
    """)

    :ok
  end

  @doc """
  Runs a shutdown simulation test.

  This starts a job and programmatically triggers shutdown after a delay.
  Useful for automated testing.
  """
  def shutdown_simulation(run_duration_ms \\ 15_000) do
    Logger.info("""
    ========================================
    SHUTDOWN SIMULATION
    ========================================
    This will:
    1. Start a 60-second job
    2. Wait #{div(run_duration_ms, 1000)} seconds
    3. Trigger graceful shutdown
    4. Show results
    ========================================
    """)

    # Enqueue the job
    {:ok, job} = TestHelper.enqueue_custom(60, 5)
    Logger.info("✓ Job started: #{job.id}")

    # Wait for specified duration
    Logger.info("⏳ Running for #{div(run_duration_ms, 1000)} seconds...")
    Process.sleep(run_duration_ms)

    # Trigger shutdown
    Logger.info("🛑 Initiating graceful shutdown...")

    # Note: This is a simulation. In production, Fly.io or your platform
    # would send SIGTERM to the process.
    Logger.info("""

    In production, this is where the system would:
    1. Receive SIGTERM from the platform
    2. Oban would stop accepting new jobs
    3. Running jobs would receive shutdown signal
    4. Jobs would complete current chunk
    5. System would exit after grace period

    To test real shutdown, use Ctrl+C or platform restart.
    """)

    :ok
  end

  @doc """
  Prints helpful information about the worker and configuration.
  """
  def info do
    oban_config = Application.get_env(:oban_tests, Oban, [])

    IO.puts("""

    ╔═══════════════════════════════════════════════════════════╗
    ║           OBAN TESTJOB CONFIGURATION                      ║
    ╚═══════════════════════════════════════════════════════════╝

    Oban Configuration:
    ──────────────────────────────────────────────────────────
    Engine:              #{inspect(Keyword.get(oban_config, :engine))}
    Queues:              #{inspect(Keyword.get(oban_config, :queues))}
    Shutdown Grace:      #{format_time(Keyword.get(oban_config, :shutdown_grace_period, 0))}

    Worker Configuration:
    ──────────────────────────────────────────────────────────
    Module:              ObanTests.Worker.TestJob
    Queue:               default
    Max Attempts:        3
    Default Duration:    120 seconds
    Default Chunk Size:  5 seconds

    How It Works:
    ──────────────────────────────────────────────────────────
    1. Job is divided into chunks (default 5s each)
    2. After each chunk, worker checks for shutdown signal
    3. On shutdown, worker completes current chunk
    4. Returns results showing completed work
    5. Partial results are captured in job metadata

    Testing on Fly.io:
    ──────────────────────────────────────────────────────────
    1. Deploy: fly deploy
    2. SSH: fly ssh console
    3. Console: /app/bin/oban_tests remote
    4. Run: ObanTests.Demo.full()
    5. Restart: fly apps restart (in another terminal)
    6. Watch: fly logs

    ╚═══════════════════════════════════════════════════════════╝
    """)

    :ok
  end

  # Helper to format milliseconds into human-readable time
  defp format_time(ms) when is_integer(ms) do
    cond do
      ms >= 60_000 -> "#{div(ms, 60_000)} minutes"
      ms >= 1_000 -> "#{div(ms, 1_000)} seconds"
      true -> "#{ms} milliseconds"
    end
  end

  defp format_time(_), do: "not configured"
end
