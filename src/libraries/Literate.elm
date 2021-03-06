module Literate
    exposing
        ( LiteratePuzzle
        , Segment(..)
        , Index
        , literate
        , update
        , toHtml
        , Msg
        , tagMsg
        )

{-| A library to write tutorials with interactive examples mixed in.

@docs LiteratePuzzle

The `LiteratePuzzle` takes quite a few type parameters, here is why:

Your tutorial text can depend on the `config` type, this is useful when you
explain keybindings or other global data that might change while the documentation is read.
Inside the tutorials are interactive examples, to help you manage them the LiteratePuzzle
needs to know their type, this is why it asks for a `example` type.
And finally, there is no interactivity without passing messages of a known `msg` type.

# Writing literate puzzles

Literate puzzles can contain a mix of both markdown and html.
As noted above, both may depend on some configuration data.

@docs Segment, literate

**Warning:** Configuration dependent markdown is fully parsed on each `toHtml`,
so keep it short.

# Rendering literate puzzles to Html

To output Html, the LiteratePuzzle needs to know how it should treat examples.
There are two things to consider here:

  - How to render an example to Html.
  - How to wire messages from the examples back to your program while remembering
    which example fired it.

@docs RenderConfig, toHtml

# Updating examples inside the literate puzzle

@docs updateExample

The name is inspired by “literate programming”, where a program is written
as an explanation of the program logic in a natural language,
mixed with snippets of source code. Here puzzles take the place of the code.
-}

import Html exposing (Html, div, text)
import Html.Attributes exposing (style)
import Html.Events exposing (onClick)
import Markdown
import List.Extra as List


{-| Encodes a LiteratePuzzle.
-}
type alias LiteratePuzzle config example msg =
    List (ProcessedSegment config example msg)


{-| The Index type is used to adress segments and propperly route exampleMessages.
-}
type alias Index =
    Int


type Msg example exampleMsg
    = UpdateExample Index exampleMsg
    | ReplaceExample Index example


{-| Specify how examples are rendered and messages are treated.
-}
type alias ExampleView example msg =
    Index -> example -> Html msg


{-| Use the tagMsg function to route an exampleMsg to a specific example
-}
tagMsg : Index -> exampleMsg -> Msg example exampleMsg
tagMsg index exampleMsg =
    UpdateExample index exampleMsg


{-| A literate puzzle is a sequence of segments. Some of the segments might
be generated from `config` data.
-}
type Segment config example msg
    = StaticMarkdown String
    | StaticHtml (Html msg)
    | DynamicMarkdown (config -> String)
    | DynamicHtml (config -> Html msg)
    | InlineExample example


type ProcessedSegment config example msg
    = Static (Html msg)
    | Dynamic (config -> Html msg)
    | Interactive example


processSegment : Segment config example msg -> ProcessedSegment config example msg
processSegment segment =
    case segment of
        StaticMarkdown string ->
            Static (Markdown.toHtml [] string)

        StaticHtml html ->
            Static html

        DynamicMarkdown generateMarkdown ->
            Dynamic (generateMarkdown >> Markdown.toHtml [])

        DynamicHtml generateHtml ->
            Dynamic generateHtml

        InlineExample example ->
            Interactive example


{-| Turn a list of segments into a LiteratePuzzle. This converts all static markdown to Html.
-}
literate : List (Segment config example msg) -> LiteratePuzzle config example msg
literate =
    List.map processSegment


update :
    Msg example exampleMsg
    -> (exampleMsg -> example -> example)
    -> LiteratePuzzle config example msg
    -> LiteratePuzzle config example msg
update message updateFunction puzzle =
    case message of
        UpdateExample index exampleMsg ->
            updateExample index (updateFunction exampleMsg) puzzle

        ReplaceExample index newExample ->
            updateExample index (\_ -> newExample) puzzle


{-| Try to update an example at a specific position.
Do nothing if there is no example at the specified position.
-}
updateExample :
    Index
    -> (example -> example)
    -> LiteratePuzzle config example msg
    -> LiteratePuzzle config example msg
updateExample index updateFunction puzzle =
    let
        internalUpdateFunction segment =
            case segment of
                Interactive example ->
                    Interactive (updateFunction example)

                anythingElse ->
                    anythingElse
    in
        List.updateAt index internalUpdateFunction puzzle
            |> Maybe.withDefault puzzle


{-| Turn a LiteratePuzzle into an HTML element.
-}
toHtml :
    ExampleView example msg
    -> config
    -> LiteratePuzzle config example msg
    -> Html msg
toHtml render config puzzle =
    div [ Html.Attributes.id "outer-text-container" ]
        [ div [ Html.Attributes.id "inner-text-container" ]
            (List.indexedMap
                (segmentToHtml render config)
                puzzle
            )
        ]


segmentToHtml :
    ExampleView example msg
    -> config
    -> Int
    -> ProcessedSegment config example msg
    -> Html msg
segmentToHtml render config index segment =
    case segment of
        Static html ->
            html

        Dynamic generateHtml ->
            generateHtml config

        Interactive example ->
            render index example
