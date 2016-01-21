defmodule EvercamMedia.Snapshot.Streamer do
  @moduledoc """
  TODO
  """

  use Calendar
  use GenServer
  alias EvercamMedia.Util
  alias EvercamMedia.Repo
  alias EvercamMedia.Snapshot.CamClient
  alias EvercamMedia.Snapshot.DBHandler
  alias EvercamMedia.Snapshot.StreamerSupervisor
  import EvercamMedia.Schedule
  import CloudRecording
  require Logger

  ################
  ## Client API ##
  ################

  @doc """
  Start the Snapshot streamer for a given camera.
  """
  def start_link(camera_exid) do
    streamer_id = String.to_atom("#{camera_exid}_streamer")
    GenServer.start_link(__MODULE__, camera_exid, name: streamer_id)
  end

  ######################
  ## Server Callbacks ##
  ######################

  @doc """
  Initialize the camera streamer
  """
  def init(camera_exid) do
  alias EvercamMedia.Repo
    camera =
      camera_exid
      |> Camera.get
      |> Repo.preload(:cloud_recordings)
      |> Repo.preload([vendor_model: :vendor])

    Task.start_link(fn -> loop(camera) end)
    {:ok, camera_exid}
  end

  def loop(camera) do
    cond do
      length(subscribers(camera.exid)) == 0 ->
        Logger.debug "[#{camera.exid}] Shutting down streamer, no subscribers"
        StreamerSupervisor.stop_streamer(camera.exid)
      scheduled_now?(camera) && sleep(camera.cloud_recordings) == 1000 ->
        Logger.debug "[#{camera.exid}] Shutting down streamer, already streaming"
        StreamerSupervisor.stop_streamer(camera.exid)
      true ->
        Logger.debug "[#{camera.exid}] Streaming ..."
        spawn fn -> stream(camera) end
    end

    :timer.sleep 1000
    loop(camera)
  end

  def stream(camera) do
    timestamp = DateTime.now_utc |> DateTime.Format.unix
    response = camera |> construct_args |> CamClient.fetch_snapshot

    case response do
      {:ok, data} ->
        Util.broadcast_snapshot(camera.exid, data, timestamp)
        DBHandler.update_camera_status(camera.exid, timestamp, true)
      {:error, error} ->
        DBHandler.parse_snapshot_error(camera.exid, timestamp, error)
    end
  end

  def subscribers(camera_exid) do
    Phoenix.PubSub.Local.subscribers(EvercamMedia.PubSub, "cameras:#{camera_exid}", 0)
  end

  defp construct_args(camera) do
    %{
      url: Camera.snapshot_url(camera),
      vendor_exid: Camera.vendor_exid(camera),
      username: Camera.username(camera),
      password: Camera.password(camera)
    }
  end
end
