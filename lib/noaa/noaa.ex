defmodule Noaa.Weather do
  import Noaa.TableFormatter, only: [ print_table_for_columns: 2 ]
  require Logger
  require Record
  Record.defrecord :xmlText, Record.extract(:xmlText, from_lib: "xmerl/include/xmerl.hrl")
  Record.defrecord :xmlElement, Record.extract(:xmlElement, from_lib: "xmerl/include/xmerl.hrl")

  @url Application.get_env(:noaa, :url)
  @user_agent [ { "User-agent", "Elixir trodriguez91@icloud.com" } ]

  def fetch do
    Logger.info "Fetching Phoenix weather"
    @url
    |> HTTPoison.get(@user_agent)
    |> handle_response
  end

  def handle_response({ :ok, %{status_code: 200, body: body} }) do
    Logger.info "successful response"
    { :ok, process(body) }
  end

  def process(body) do
    forecasts = forecasts(body)
    days = days(body)
    days_and_forecasts = Enum.zip(days, forecasts)
    rows = days_and_forecasts
    |> Enum.map(&Tuple.to_list/1)
    reduced_rows = for row <- rows do
      Enum.reduce(row, fn x, acc -> Map.merge(x, acc) end)
    end
    print_table_for_columns(reduced_rows, [:day, :forecast])
  end

  def days(body) do
    days_tuples = body
           |> parse
           |> all(".//time-layout[1]/*/@period-name")
    days = for day_tuple <- days_tuples do
      {_,_,_,_,_,_,_,_,day,_} = day_tuple
      day
    end
    Enum.map(days, fn current_value -> %{day: current_value} end)
  end

  def forecasts(body) do
    collected_weather_conditions = body
                                   |> parse
                                   |> all(".//wordedForecast/*/text()")
      condition_texts = for condition <- collected_weather_conditions do
      {_,_,_,_,text,_} = condition
      text
    end
    Enum.slice(condition_texts, 1..-1)
    |> Enum.map(fn current_value -> %{forecast: current_value} end)
  end

  def parse(body, options \\ [quiet: true]) do
    {doc, []} =
      body
      |> :binary.bin_to_list
      |> :xmerl_scan.string(options)
    doc
  end

  def handle_response({ _, %{status_code: status, body: body} }) do
    Logger.error "Error #{status} returned"
    { :error, body }
  end

  def xpath(nil, _), do: []
  def xpath(node, path) do
    :xmerl_xpath.string(to_char_list(path), node)
  end

  def all(node, path) do
    for child_element <- xpath(node, path) do
      child_element
    end
  end

  def text(node), do: node |> xpath('./text()') |> extract_text

  def extract_text([xmlText(value: value)]) do
    Logger.debug "value: #{value}"
    List.to_string(value)
  end

  def extract_text(values) do
    for value <- values do
      xmlText(value: worded_forecast) = value
      IO.puts worded_forecast
    end
    nil
  end

end
