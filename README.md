# CoreNLP

The **CoreNLP** package is a thin Elixir client for the [Stanford CoreNLP](http://stanfordnlp.github.io/CoreNLP/index.html) Server.

Since the Stanford offering is written in Java, the recommended integration for non-JVM languages is to stand up a 
CoreNLP dedicated server and hit it from a client interface.  This package provides that interface for the Elixir 
ecosystem.

## Installation

If [available in Hex](https://hex.pm/packages/corenlp), the package can be installed
by adding `corenlp` to your list of dependencies in `mix.exs`:

```elixir
def deps do
  [{:corenlp, "~> 0.1.0"}]
end
```

The following are configuration settings used by this application to point to your CoreNLP server, with their defaults shown:

```elixir
config :corenlp,
  host:          "localhost",
  base_path:     "/",
  port:          9000,
  recv_timeout:  30_000
```

Refer to the [Stanford CoreNLP Server](http://stanfordnlp.github.io/CoreNLP/corenlp-server.html) page for detailed 
information regarding standing up a dedicated server (including a local instance for dev/testing).

## Usage

For detailed usage information regarding options that can be passed into the various calls, please consult the 
[Stanford CoreNLP Server](http://stanfordnlp.github.io/CoreNLP/corenlp-server.html) documentation.

### Annotations

```elixir
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
```

### TokensRegex

```elixir
iex> CoreNLP.tokensregex("The quick brown fox jumps over the lazy dog.", ~S/(?$foxtype [{pos:JJ}]+ ) fox/)
{:ok,
 %{"sentences" => [%{"0" => %{"$foxtype" => %{"begin" => 1, "end" => 3,
          "text" => "quick brown"}, "begin" => 1, "end" => 4,
        "text" => "quick brown fox"}, "length" => 1}]}}
```

### Semgrex

```elixir
iex> CoreNLP.semgrex("The quick brown fox jumped over the lazy dog.", ~S|{pos:/VB.*/} >nsubj {}=subject >/nmod:.*/ {}=prep_phrase|)
{:ok,
 %{"sentences" => [%{"0" => %{"$prep_phrase" => %{"begin" => 8, "end" => 9,
          "text" => "dog"},
        "$subject" => %{"begin" => 3, "end" => 4, "text" => "fox"},
        "begin" => 4, "end" => 5, "text" => "jumped"}, "length" => 1}]}}
```

### Tregex

```elixir
iex> CoreNLP.tregex("The quick brown fox jumped over the lazy dog.", ~S|NP < NN=animal|)
{:ok,
 %{"sentences" => [%{"0" => %{"match" => "(NP (DT The) (JJ quick) (JJ brown) (NN fox))\n",
        "namedNodes" => [%{"animal" => "(NN fox)\n"}]},
      "1" => %{"match" => "(NP (DT the) (JJ lazy) (NN dog))\n",
        "namedNodes" => [%{"animal" => "(NN dog)\n"}]}}]}}
```

## Contributing

All requests will be entertained, but the purpose of this package is to focus on providing services surrounding the 
Stanford CoreNLP Server specifically, and not to delve into the broader topic of NLP which will be left to other packages.

Documentation can be generated with [ExDoc](https://github.com/elixir-lang/ex_doc)
and published on [HexDocs](https://hexdocs.pm). Once published, the docs can
be found at [https://hexdocs.pm/corenlp](https://hexdocs.pm/corenlp).

