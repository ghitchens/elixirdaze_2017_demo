defmodule NetworkManager do
  use GenServer
  require Logger

  @app Mix.Project.config[:app]

  def start_link(iface) do
    Logger.info "Starting #{__MODULE__}"
    GenServer.start_link(__MODULE__, iface)
  end

  def init(iface) do
    iface = to_string(iface)
    Logger.info "#{__MODULE__} on #{iface}"
    Logger.info "epmd: " <> inspect(:os.cmd 'epmd -daemon')
    {:ok, pid} = Registry.register(Nerves.Udhcpc, iface, [])
    {:ok, %{registry: pid, iface: iface}}
  end

  def handle_info({Nerves.Udhcpc, event, %{ipv4_address: ip}}, s)
    when event in [:bound, :renew] do
    Logger.info "node restarting (IP Address Changed)"
    :net_kernel.stop()
    :net_kernel.start([:"#{@app}@#{ip}"])
    Logger.info "node at #{@app}@#{ip} with cookie #{Node.get_cookie()}"
    Nerves.Cell.setup()
    {:noreply, s}
  end

  def handle_info(event, s) do
    Logger.debug "got event #{inspect event}, #{inspect s}"
    {:noreply, s}
  end
end
