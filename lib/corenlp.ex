defmodule CoreNLP do

  @moduledoc """
  This module provides a thin client interface into a Stanford CoreNLP server.
  """

  # Module dependencies.
  require Logger

  @doc """
  Annotate provided text.

  ## Examples

    iex> CoreNLP.annotate("The cat sat.", annotators: "tokenize,ssplit,pos")
    {:ok,
     %{"sentences" => [%{"index" => 0,
          "tokens" => [%{"after" => " ", "before" => "",
             "characterOffsetBegin" => 0, "characterOffsetEnd" => 3, "index" => 1,
             "originalText" => "The", "pos" => "DT", "word" => "The"},
           %{"after" => " ", "before" => " ", "characterOffsetBegin" => 4,
             "characterOffsetEnd" => 7, "index" => 2, "originalText" => "cat",
             "pos" => "NN", "word" => "cat"},
           %{"after" => "", "before" => " ", "characterOffsetBegin" => 8,
             "characterOffsetEnd" => 11, "index" => 3, "originalText" => "sat",
             "pos" => "VBD", "word" => "sat"},
           %{"after" => "", "before" => "", "characterOffsetBegin" => 11,
             "characterOffsetEnd" => 12, "index" => 4, "originalText" => ".",
             "pos" => ".", "word" => "."}]}]}}

  """
  @spec annotate(text :: binary) :: tuple
  def annotate(text) do
    annotate(text, %{})
  end

  @spec annotate(text :: binary, properties :: keyword) :: tuple
  def annotate(text, properties) when is_list(properties) do
    annotate(text, keywords_to_map(properties))
  end

  @spec annotate(text :: binary, properties :: map) :: tuple
  def annotate(text, properties) when is_map(properties) do
    # Force to JSON output.
    Map.put(properties, "outputFormat", "JSON")

    # Construct properties JSON map.  If we have a bad map, let it crash.
    json_props = Poison.encode!(properties)

    endpoint = get_endpoint()
    HTTPoison.post(endpoint, text, [], params: [properties: json_props], recv_timeout: recv_timeout())
    |> process_response(endpoint, properties)
  end

  # Process a successful request.
  defp process_response({:ok, %HTTPoison.Response{body: body}}, _endpoint, _properties) do
    Poison.decode(body)
    |> process_resp_body(body)
  end

  # Process a failed request.
  defp process_response({:error, err}, endpoint, properties) do
    str_props = inspect_str(properties)
    msg = HTTPoison.Error.message(err)
    Logger.error("Failed on query to endpoint '#{endpoint}' with properties: #{str_props}: #{msg}")
    {:error, msg}
  end

  # Process a successfully-decoded JSON body.
  defp process_resp_body({:ok, json_body}, _body) do
    {:ok, json_body}
  end

  # Process a failed JSON decode of response body.
  defp process_resp_body({:error, :invalid}, body) do
    {:error, body}
  end

  defp process_resp_body({:error, {:invalid, _, _}}, body) do
    {:error, body}
  end

  # Shorthand config retrieval functions for CoreNLP server config.  Default to local server on default port.
  # Why not use module attributes? Some deployments require runtime retrieval, attributes are compile-time.
  defp host() do
    Application.get_env(:corenlp, :host, "localhost")
  end

  defp base_path() do
    Application.get_env(:corenlp, :base_path, "/")
  end

  defp port() do
    Application.get_env(:corenlp, :port, 9000)
  end

  defp recv_timeout() do
    Application.get_env(:corenlp, :recv_timeout, 30_000)
  end

  # Encode keyword list into a map; kinda surprised this isn't in a core module somewhere.
  defp keywords_to_map(properties) do
    for x <- properties, into: %{}, do: x
  end

  defp get_endpoint(add_path \\ "") do
    "http://" <> host() <> ":" <> Integer.to_string(port()) <> base_path() <> add_path
  end

  # Inspect item, return as a binary.
  defp inspect_str(item) do
    {:ok, str_io} = StringIO.open("")
    IO.inspect(str_io, item, width: 0)
    {_, {_, item_str}} = StringIO.close(str_io)
    item_str
  end

end
