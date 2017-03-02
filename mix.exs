defmodule Demo.Mixfile do
  use Mix.Project

  @target System.get_env("NERVES_TARGET") || "rpi3"
  @architecture System.get_env("NERVES_ARCHITECURE") || "unknown"
  @timestamp DateTime.to_unix(DateTime.utc_now)
  @version "0.1.2-dev-#{@timestamp}"

  def project do
    [app: :demo,
     target: @target,
     archives: [nerves_bootstrap: "~> 0.2.1"],
     version: @version,  # remove previous version
     architecture: @architecture,
     product: "ElixirDaze Demo",
     descripton: """
     Not sure exactly what it does, but it does something!
     A sample project For the Raspberry Pi 3.
     """,
     author: "Garth Hitchens",
     tags: "development",

     deps_path: "deps/#{@target}",
     build_path: "_build/#{@target}",

     build_embedded: Mix.env == :prod,
     start_permanent: Mix.env == :prod,
     aliases: aliases(),
     deps: deps() ++ system(@target)]
  end

  # Configuration for the OTP application.
  #
  # Type `mix help compile.app` for more information.
  def application do
    [mod: {Demo, []},
     extra_applications: [:logger, :runtime_tools]]
  end

  def deps do
    [{:nerves, "~> 0.4.0"},
    {:logger_multicast_backend, "~> 0.2"},
    {:nerves_cell, github: "ghitchens/nerves_cell"},
    {:nerves_interim_wifi, "~> 0.1"},
    {:nerves_firmware_http, "~> 0.3"}]
  end

  def system(target) do
    [{:"nerves_system_#{target}", ">= 0.0.0"}]
  end

  def aliases do
    ["deps.precompile": ["nerves.precompile", "deps.precompile"],
     "deps.loadpaths":  ["deps.loadpaths", "nerves.loadpaths"]]
  end

end
