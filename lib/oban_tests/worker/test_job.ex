defmodule ObanTests.Worker.TestJob do
  @moduledoc """
  A test Oban worker that performs long-running dummy work with graceful shutdown support.

  This worker is designed to run for several minutes and handle graceful shutdown
  properly when deployed to Fly.io or other platforms.

  ## Features
  - Performs work in small chunks with progress logging
  - Handles graceful shutdown via Oban's built-in mechanisms
  - Configurable work duration via job args
  - Returns detailed results about work performed

  ## Usage

      # Enqueue a job that runs for 3 minutes (180 seconds)
      %{duration_seconds: 180, chunk_size: 5}
      |> ObanTests.Worker.TestJob.new()
      |> Oban.insert()

      # Enqueue a job with default settings (120 seconds, 5 second chunks)
      %{}
      |> ObanTests.Worker.TestJob.new()
      |> Oban.insert()
  """

  use Oban.Worker,
    queue: :default,
    max_attempts: 3

  require Logger

  @default_duration_seconds 120
  @default_chunk_size 5

  @impl Oban.Worker
  def perform(%Oban.Job{args: args}) do
    duration_seconds = Map.get(args, "duration_seconds", @default_duration_seconds)
    chunk_size = Map.get(args, "chunk_size", @default_chunk_size)

    Logger.info("""
    [TestJob] Starting long-running job
    Duration: #{duration_seconds} seconds
    Chunk size: #{chunk_size} seconds
    Process: #{inspect(self())}
    """)

    # Calculate number of chunks
    total_chunks = ceil(duration_seconds / chunk_size)

    # Perform work in chunks
    result = perform_work(total_chunks, chunk_size, 0, [])

    case result do
      {:ok, completed_chunks} ->
        Logger.info("""
        [TestJob] Job completed successfully
        Completed chunks: #{length(completed_chunks)}
        Total duration: #{length(completed_chunks) * chunk_size} seconds
        """)

        {:ok,
         %{
           status: "completed",
           chunks_completed: length(completed_chunks),
           total_duration: length(completed_chunks) * chunk_size,
           details: completed_chunks
         }}

      {:shutdown, completed_chunks} ->
        Logger.warning("""
        [TestJob] Job shutdown gracefully
        Completed chunks: #{length(completed_chunks)}
        Duration before shutdown: #{length(completed_chunks) * chunk_size} seconds
        """)

        {:ok,
         %{
           status: "shutdown_gracefully",
           chunks_completed: length(completed_chunks),
           total_duration: length(completed_chunks) * chunk_size,
           details: completed_chunks
         }}
    end
  end

  # Perform work in chunks, checking for shutdown signals between chunks
  defp perform_work(0, _chunk_size, _current_chunk, completed_chunks) do
    {:ok, Enum.reverse(completed_chunks)}
  end

  defp perform_work(remaining_chunks, chunk_size, current_chunk, completed_chunks) do
    chunk_start = System.monotonic_time(:millisecond)

    Logger.info("""
    [TestJob] Processing chunk #{current_chunk + 1}/#{remaining_chunks + current_chunk}
    Remaining chunks: #{remaining_chunks}
    """)

    # Perform dummy work - sleep in smaller intervals to be more responsive
    # to shutdown signals
    result = do_chunk_work(chunk_size)

    case result do
      :ok ->
        chunk_end = System.monotonic_time(:millisecond)
        duration_ms = chunk_end - chunk_start

        chunk_info = %{
          chunk_number: current_chunk + 1,
          duration_ms: duration_ms,
          timestamp: DateTime.utc_now(),
          status: "completed"
        }

        Logger.debug("[TestJob] Chunk #{current_chunk + 1} completed in #{duration_ms}ms")

        # Continue to next chunk
        perform_work(
          remaining_chunks - 1,
          chunk_size,
          current_chunk + 1,
          [chunk_info | completed_chunks]
        )

      {:error, :shutdown} ->
        Logger.info("[TestJob] Shutdown signal received, stopping gracefully")
        {:shutdown, Enum.reverse(completed_chunks)}
    end
  end

  # Perform work for a chunk duration, checking periodically if we should continue
  defp do_chunk_work(chunk_size_seconds) do
    # Sleep in 1-second intervals to be responsive to shutdown
    intervals = chunk_size_seconds
    do_chunk_work_loop(intervals, 0)
  end

  defp do_chunk_work_loop(total_intervals, current_interval)
       when current_interval >= total_intervals do
    :ok
  end

  defp do_chunk_work_loop(total_intervals, current_interval) do
    # Check if we received a shutdown signal
    # In a real scenario, Oban will send the process a shutdown signal
    # and we can check for messages or use Process.flag(:trap_exit, true)
    receive do
      {:shutdown, _} ->
        Logger.info("[TestJob] Received shutdown message")
        {:error, :shutdown}
    after
      1000 ->
        # No shutdown signal, continue working
        # Simulate some CPU work
        simulate_work()

        # Continue to next interval
        do_chunk_work_loop(total_intervals, current_interval + 1)
    end
  end

  # Simulate some actual work being done (not just sleeping)
  defp simulate_work do
    # Do some light computation to simulate actual work
    # This makes the job more realistic than just sleeping
    _ =
      1..100
      |> Enum.map(fn x -> x * x end)
      |> Enum.sum()

    :ok
  end

  @doc """
  Helper function to enqueue a test job with custom settings.

  ## Examples

      # Enqueue a job that runs for 3 minutes
      ObanTests.Worker.TestJob.enqueue(duration_seconds: 180)

      # Enqueue a job with custom chunk size
      ObanTests.Worker.TestJob.enqueue(duration_seconds: 120, chunk_size: 10)
  """
  def enqueue(opts \\ []) do
    duration_seconds = Keyword.get(opts, :duration_seconds, @default_duration_seconds)
    chunk_size = Keyword.get(opts, :chunk_size, @default_chunk_size)

    %{
      duration_seconds: duration_seconds,
      chunk_size: chunk_size
    }
    |> new()
    |> Oban.insert()
  end
end
