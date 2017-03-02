# ElixirDaze 2017 pi3 wifi/logging/remsh/cell demo

This repo is the result of the live coding demo I gave at ElixirDaze 2017.    It gets wifi, erlang distribution, remote shell, multicast logging, and cell discovery and metadata working on a pi3.

This README contains the notes I used when live coding the demo here.   The repo here is the result of following this script in a blank directory.

Works for raspberry pi3 only.

If you want it to work for you, make sure you pick proper values for the wifi config in config/config.exs

To start your Nerves app:

  * Install dependencies with `mix deps.get`
  * Create firmware with `mix firmware`
  * Burn to an SD card with `mix firmware.burn`

## Learn more

  * Official docs: https://hexdocs.pm/nerves/getting-started.html
  * Official website: http://www.nerves-project.org/
  * Discussion Slack elixir-lang #nerves ([Invite](https://elixir-slackin.herokuapp.com/))
  * Source: https://github.com/nerves-project/nerves

# Demo Notes

## PART 1 - Starting from scratch

```bash
# mix nerves.new demo
# mix nerves.new demo -- target rpi3
```

#### in mix.exs
```elixir
# deps
{:nerves_interim_wifi, "~> 0.1"},
{:nerves_firmware_http, "~> 0.3"}

# change from applications to extra_applications
# to allow deps into release.
extra_applications: [:logger, :runtime_tools]
```
#### in lib/demo.ex
```elixir
@interface :wlan0

...

worker(Task, [fn -> init_kernel_modules() end], restart: :transient, id: Nerves.Init.KernelModules),
worker(Task, [fn -> init_wifi_network() end], restart: :transient, id: Nerves.Init.WifiNetwork),

...

def init_kernel_modules, do: System.cmd "modprobe", ["brcmfmac"]

def init_wifi_network() do
  Nerves.InterimWiFi.setup @interface, Application.get_env(:demo, @interface)
end
```

#### config/config.exs
```
config :demo, :wlan0, ssid: "yourssid",  key_mgmt: :"WPA-PSK",  psk: "yourwifipassword"
```
## PART 2 - Logging

#### mix.exs
```elixir
{:logger_multicast_backend, "~> 0.2"},
```

#### config.exs
```elixir
config :logger,
        backends: [ :console, LoggerMulticastBackend ],
        level: :debug,
        format: "$time $metadata[$level] $message\n"
```

#### watching log during an update

```bash
#leave open in a separate terminal session
$ cell watch

# in another terminal session
$ mix firmware.build
$ mix firmware.push 192.168.1.101 (or whatever) --target rpi3

# should see log show up in first session
$ curl "http://192.168.0.101:8988/firmware"
```

## Erlang Distribution

#### config.exs

```elixir
config :nerves_cell, Mix.Project.config
```

#### mix.ex

```elixir

# module variables
@architecture System.get_env("NERVES_ARCHITECURE") || "unknown"
@timestamp DateTime.to_unix(DateTime.utc_now)
@version "0.1.2-dev-#{@timestamp}"
...

# to project

version: @version,  # remove previous version
architecture: @architecture,
product: "ElixirDaze Demo",
descripton: """
Not sure exactly what it does, but it does something!
A sample project For the Raspberry Pi 3.
""",
author: "Garth Hitchens",
tags: "development",

# to deps
{:nerves_cell, github: "ghitchens/nerves_cell"},
```
#### lib/demo.ex
```elixir

worker(NetworkManager, [@interface], restart: :transient, id: Nerves.Init.NetworkManager),
```

#### rel/vm.args (above -extra)
```
-setcookie democookie
```
#### lib/network_manager.ex

Add the following code to a new file lib/network_manager.ex

```elixir
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
```

#### SHELL Excercises for remsh, observer, and cell

```bash
iex --name "me@mynode" --cookie democookie --remsh "demo@192.168.0.101"
iex --name "me@mynode" --cookie democookie -e ":observer.start()"
cell list
cell info <id>
```
