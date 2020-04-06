defmodule StoreHall.AlertsWatcher do
  use GenServer
  alias StoreHall.AlertsMail

  # 24 hours
  @interval 24 * 60 * 60 * 1000

  def start_link(_) do
    GenServer.start_link(__MODULE__, %{})
  end

  def init(state) do
    # send now
    Process.send_after(self(), :alert, 1000)

    # schedule on interval
    :timer.send_interval(@interval, :alert)
    {:ok, state}
  end

  def handle_info(:alert, state) do
    AlertsMail.check_alerts()

    {:noreply, state}
  end
end
