defmodule CoreNLP do

  @moduledoc """
  This module provides a thin client interface into a Stanford CoreNLP server.
  """

  # Module dependencies.
  require Logger

  @doc ~S"""
  Annotate provided text with all available annotators.

  Unless you have a server tuned to handle this level of
  processing, it is strongly recommended to use `CoreNLP.annotate/2` to scope the level of processing applied to the provided
  text.
  """
  @spec annotate(text :: binary) :: tuple
  def annotate(text) do
    annotate(text, %{})
  end

  @doc ~S"""
  Annotate provided text with specific processing properties set.

  See the official [Stanford CoreNLP](http://stanfordnlp.github.io/CoreNLP/index.html) documentation for available options.

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
    post_request(endpoint, text, [properties: json_props])
    |> process_post_response(endpoint, properties)
  end

  @doc ~S"""
  Applies a TokensRegex pattern to the provided text.

  See the official [Stanford TokensRegex](http://nlp.stanford.edu/software/tokensregex.shtml) documentation for more information.

  ## Examples

      iex> CoreNLP.tokensregex("The quick brown fox jumps over the lazy dog.", ~S/(?$foxtype [{pos:JJ}]+ ) fox/)
      {:ok,
       %{"sentences" => [%{"0" => %{"$foxtype" => %{"begin" => 1, "end" => 3,
                "text" => "quick brown"}, "begin" => 1, "end" => 4,
              "text" => "quick brown fox"}, "length" => 1}]}}

  """
  @spec tokensregex(text :: binary, pattern :: binary, filter :: boolean) :: tuple
  def tokensregex(text, pattern, filter \\ false) do
    endpoint = get_endpoint("tokensregex")
    params = [pattern: prepare_pattern(pattern), filter: filter]
    post_request(endpoint, text, params)
    |> process_post_response(endpoint, params)
  end

  @doc ~S"""
  Applies a Semgrex pattern to the provided text.

  See the official [Stanford Semgrex](http://nlp.stanford.edu/nlp/javadoc/javanlp/edu/stanford/nlp/semgraph/semgrex/SemgrexPattern.html) documentation for more information.

  ## Examples

      iex> CoreNLP.semgrex("The quick brown fox jumped over the lazy dog.", ~S|{pos:/VB.*/} >nsubj {}=subject >/nmod:.*/ {}=prep_phrase|)
      {:ok,
       %{"sentences" => [%{"0" => %{"$prep_phrase" => %{"begin" => 8, "end" => 9,
                "text" => "dog"},
              "$subject" => %{"begin" => 3, "end" => 4, "text" => "fox"},
              "begin" => 4, "end" => 5, "text" => "jumped"}, "length" => 1}]}}

  """
  @spec semgrex(text :: binary, pattern :: binary, filter :: boolean) :: tuple
  def semgrex(text, pattern, filter \\ false) do
    endpoint = get_endpoint("semgrex")
    params = [pattern: prepare_pattern(pattern), filter: filter]
    post_request(endpoint, text, params)
    |> process_post_response(endpoint, params)
  end

  @doc ~S"""
  Applies a Tregex pattern to the provided text.

  See the official [Stanford Tregex](http://nlp.stanford.edu/nlp/javadoc/javanlp/edu/stanford/nlp/trees/tregex/TregexPattern.html) documentation for more information.

  ## Examples

      iex> CoreNLP.tregex("The quick brown fox jumped over the lazy dog.", "NP < NN=animal")
      {:ok,
       %{"sentences" => [%{"0" => %{"match" => "(NP (DT The) (JJ quick) (JJ brown) (NN fox))\n",
              "namedNodes" => [%{"animal" => "(NN fox)\n"}]},
            "1" => %{"match" => "(NP (DT the) (JJ lazy) (NN dog))\n",
              "namedNodes" => [%{"animal" => "(NN dog)\n"}]}}]}}

  """
  @spec tregex(text :: binary, pattern :: binary) :: tuple
  def tregex(text, pattern) do
    endpoint = get_endpoint("tregex")
    params = [pattern: prepare_pattern(pattern)]
    post_request(endpoint, text, params)
    |> process_post_response(endpoint, params)
  end

  @doc ~S"""
  A simple ping test. Responds with pong if the server is up.

  ## Examples

      iex> CoreNLP.ping()
      {:ok, "pong"}

  """
  def ping() do
    endpoint = get_endpoint("ping")
    HTTPoison.get(endpoint)
    |> process_get_response()
  end

  @doc ~S"""
  A test to let the caller know if the server is alive, but not necessarily ready to respond to requests.

  ## Examples

      iex(2)> CoreNLP.live()
      {:ok, "live"}

  """
  def live() do
    endpoint = get_endpoint("live")
    HTTPoison.get(endpoint)
    |> process_get_response()
  end

  @doc ~S"""
  A test to let the caller know if the server is alive AND ready to respond to requests.

  ## Examples

      iex(3)> CoreNLP.ready()
      {:ok, "ready"}

  """
  def ready() do
    endpoint = get_endpoint("ready")
    HTTPoison.get(endpoint)
    |> process_get_response()
  end

  ############################################################################
  # Internal helper functions
  ############################################################################

  # Send a POST request to the server.
  defp post_request(endpoint, text, params) do
    HTTPoison.post(endpoint, text, [], params: params, recv_timeout: recv_timeout())
  end

  # Process a simple GET request's successful response.
  defp process_get_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}) do
    {:ok, String.trim(body)}
  end

  # Process a simple GET request's non-200 response.
  defp process_get_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}}) do
    {:error, :http, {status_code, String.trim(body)}}
  end

  # Process a failing simple GET request.
  defp process_get_response({:error, err}) do
    msg = HTTPoison.Error.message(err)
    {:error, :http, msg}
  end

  # Process a successful request.
  defp process_post_response({:ok, %HTTPoison.Response{status_code: 200, body: body}}, _endpoint, _properties) do
    Poison.decode(body)
    |> process_post_response_body(body)
  end

  # Process a response that the server replied to, but returned a non-200 response.
  defp process_post_response({:ok, %HTTPoison.Response{status_code: status_code, body: body}}, _endpoint, _properties) do
    {:error, :http, {status_code, String.trim(body)}}
  end

  # Process a failed request.
  defp process_post_response({:error, err}, endpoint, properties) do
    str_props = inspect_str(properties)
    msg = HTTPoison.Error.message(err)
    Logger.error("Failed on query to endpoint '#{endpoint}' with properties: #{str_props}: #{msg}")
    {:error, :http, msg}
  end

  # Process a successfully-decoded JSON body.
  defp process_post_response_body({:ok, json_body}, _body) do
    {:ok, json_body}
  end

  # Process a failed JSON decode of response body.
  defp process_post_response_body({:error, :invalid}, body) do
    {:error, :json, body}
  end

  defp process_post_response_body({:error, {:invalid, _, _}}, body) do
    {:error, :json, body}
  end

  # Encode keyword list into a map; kinda surprised this isn't in a core module somewhere...?
  defp keywords_to_map(properties) do
    for x <- properties, into: %{}, do: x
  end

  # Construct an endpoint URL for a request.
  defp get_endpoint(add_path \\ "") do
    "http://" <> host() <> ":" <> Integer.to_string(port()) <> String.trim_trailing(base_path(), "/") <> "/" <> String.trim_leading(add_path, "/")
  end

  # Inspect item, return as a binary.  Used for debugging/logging.
  defp inspect_str(item) do
    {:ok, str_io} = StringIO.open("")
    IO.inspect(str_io, item, width: 0)
    {_, {_, item_str}} = StringIO.close(str_io)
    item_str
  end

  # Prepare pattern for URL encoding.
  defp prepare_pattern(pattern) do
    # Based on examination of the baked-in CoreNLP Server test page, we need to do this or else the server will not
    # correctly process these characters in a pattern passed via query param.
    pattern
    |> String.replace("&", "\\&")
    |> String.replace("+", "\\+")
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

end
