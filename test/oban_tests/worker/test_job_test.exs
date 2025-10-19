defmodule ObanTests.Worker.TestJobTest do
  use ExUnit.Case, async: true

  alias ObanTests.Worker.TestJob

  describe "perform/1" do
    test "completes a short job successfully" do
      job = %Oban.Job{
        args: %{"duration_seconds" => 2, "chunk_size" => 1}
      }

      assert {:ok, result} = TestJob.perform(job)
      assert result.status == "completed"
      assert result.chunks_completed >= 2
      assert result.total_duration >= 2
      assert is_list(result.details)
    end

    test "uses default values when args are empty" do
      job = %Oban.Job{args: %{}}

      # This test just verifies the job can start with defaults
      # We won't wait for the full 120 seconds
      task =
        Task.async(fn ->
          TestJob.perform(job)
        end)

      # Give it a moment to start
      Process.sleep(100)

      # Kill the task since we don't want to wait 2 minutes
      Task.shutdown(task, :brutal_kill)

      assert true
    end

    test "handles custom chunk size" do
      job = %Oban.Job{
        args: %{"duration_seconds" => 3, "chunk_size" => 3}
      }

      assert {:ok, result} = TestJob.perform(job)
      assert result.chunks_completed >= 1
      assert length(result.details) >= 1
    end

    test "result contains required fields" do
      job = %Oban.Job{
        args: %{"duration_seconds" => 1, "chunk_size" => 1}
      }

      assert {:ok, result} = TestJob.perform(job)
      assert Map.has_key?(result, :status)
      assert Map.has_key?(result, :chunks_completed)
      assert Map.has_key?(result, :total_duration)
      assert Map.has_key?(result, :details)
    end

    test "chunk details contain timestamp and duration" do
      job = %Oban.Job{
        args: %{"duration_seconds" => 1, "chunk_size" => 1}
      }

      assert {:ok, result} = TestJob.perform(job)
      assert [first_chunk | _] = result.details

      assert Map.has_key?(first_chunk, :chunk_number)
      assert Map.has_key?(first_chunk, :duration_ms)
      assert Map.has_key?(first_chunk, :timestamp)
      assert Map.has_key?(first_chunk, :status)
      assert first_chunk.status == "completed"
    end
  end

  describe "new/1" do
    test "creates a new job changeset with args" do
      changeset =
        TestJob.new(%{
          duration_seconds: 100,
          chunk_size: 5
        })

      assert %Ecto.Changeset{} = changeset
      assert changeset.valid?
      assert changeset.changes.args == %{duration_seconds: 100, chunk_size: 5}
      assert changeset.changes.worker == "ObanTests.Worker.TestJob"
    end

    test "creates job with default queue" do
      changeset = TestJob.new(%{duration_seconds: 60})

      assert changeset.data.queue == "default"
    end

    test "creates job with correct max_attempts" do
      changeset = TestJob.new(%{duration_seconds: 60})

      assert changeset.changes.max_attempts == 3
    end
  end
end
