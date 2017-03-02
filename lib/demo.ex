defmodule Demo do
  use Application

  @interface :wlan0

  # See http://elixir-lang.org/docs/stable/elixir/Application.html
  # for more information on OTP Applications
  def start(_type, _args) do
    import Supervisor.Spec, warn: false

    # Define workers and child supervisors to be supervised
    children = [
      worker(Task, [fn -> init_kernel_modules() end], restart: :transient, id: Nerves.Init.KernelModules),
      worker(Task, [fn -> init_wifi_network() end], restart: :transient, id: Nerves.Init.WifiNetwork),
      worker(NetworkManager, [@interface], restart: :transient, id: Nerves.Init.NetworkManager),
      # worker(Demo.Worker, [arg1, arg2, arg3]),
    ]

    # See http://elixir-lang.org/docs/stable/elixir/Supervisor.html
    # for other strategies and supported options
    opts = [strategy: :one_for_one, name: Demo.Supervisor]
    Supervisor.start_link(children, opts)
  end

  def init_kernel_modules, do: System.cmd "modprobe", ["brcmfmac"]

  def init_wifi_network() do
    Nerves.InterimWiFi.setup @interface, Application.get_env(:demo, @interface)
  end

end
