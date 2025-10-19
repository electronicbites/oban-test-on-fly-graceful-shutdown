defmodule ObanTests.Worker.TestHelper do
  @moduledoc """
  Helper functions for manually testing the TestJob worker.

  This module provides convenience functions to enqueue test jobs
  and check their status.
  """

  alias ObanTests.Worker.TestJob

  @doc """
  Enqueues a quick test job (30 seconds).

  ## Examples

      iex> ObanTests.Worker.TestHelper.enqueue_quick()
      {:ok, %Oban.Job{}}
  """
  def enqueue_quick do
    TestJob.enqueue(duration_seconds: 30, chunk_size: 5)
  end

  @doc """
  Enqueues a medium test job (2 minutes).

  ## Examples

      iex> ObanTests.Worker.TestHelper.enqueue_medium()
      {:ok, %Oban.Job{}}
  """
  def enqueue_medium do
    TestJob.enqueue(duration_seconds: 120, chunk_size: 5)
  end

  @doc """
  Enqueues a long test job (5 minutes).

  ## Examples

      iex> ObanTests.Worker.TestHelper.enqueue_long()
      {:ok, %Oban.Job{}}
  """
  def enqueue_long do
    TestJob.enqueue(duration_seconds: 300, chunk_size: 10)
  end

  @doc """
  Enqueues a custom test job.

  ## Examples

      iex> ObanTests.Worker.TestHelper.enqueue_custom(180, 15)
      {:ok, %Oban.Job{}}
  """
  def enqueue_custom(duration_seconds, chunk_size) do
    TestJob.enqueue(duration_seconds: duration_seconds, chunk_size: chunk_size)
  end

  @doc """
  Enqueues multiple test jobs at once.

  ## Examples

      iex> ObanTests.Worker.TestHelper.enqueue_multiple(3, duration_seconds: 60)
      [ok: %Oban.Job{}, ok: %Oban.Job{}, ok: %Oban.Job{}]
  """
  def enqueue_multiple(count, opts \\ []) do
    1..count
    |> Enum.map(fn _ -> TestJob.enqueue(opts) end)
  end
end
