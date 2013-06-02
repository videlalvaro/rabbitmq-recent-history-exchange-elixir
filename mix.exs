defmodule RabbitmqEecentHistoryExchangeElixir.Mixfile do
  use Mix.Project

  def project do
    [ app: :rabbitmq_recent_history_exchange_elixir,
      version: "0.0.1",
      deps: deps ]
  end

  # Configuration for the OTP application
  def application do
    [
     applications: [:rabbit, :mnesia]
    ]
  end

  # Returns the list of dependencies in the format:
  defp deps do
    []
  end
end
