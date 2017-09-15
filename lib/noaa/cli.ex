defmodule Noaa.CLI do
  import Noaa.TableFormatter, only: [ print_table_for_columns: 2 ]

  @moduledoc """
  Handle the command line parsing and the dispatch
  to the various functions that end up generating a
  table of the weather forecast
  """

  def run(argv) do
    argv
    |> parse_args
    |> process
  end
  
  def parse_args(argv) do
    parse = OptionParser.parse(argv, switches: [ help: :boolean ],
                               aliases: [ h: :help ])
    case parse do
      { [ help: true], _, _ } -> :help
      _ -> :help
    end
  end

  def process(:help) do
    IO.puts """
    usage: noaa
    """
    System.halt(0)
  end

  def process(_) do
    Noaa.Weather.fetch
    |> decode_response
    |> print_table_for_columns(["number", "created_at", "title"])
  end

  def decode_response({:ok, body}), do: body

  def decode_response({:error, error}) do
    {_, message} = List.keyfind(error, "message", 0)
    IO.puts "Error fetching from NOAA: #{message}"
    System.halt(2)
  end
end
