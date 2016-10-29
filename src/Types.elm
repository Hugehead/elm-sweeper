module Types exposing (..)

{- This modul collects shared types. -}

import Grid exposing (Grid, Direction, Coordinate)
import Cell exposing (Cell)


type MouseButton
    = LeftButton
    | RightButton


type alias GameModel =
    { level : Grid Cell
    , mistakes : Int
    }


type Route
    = MainMenu
    | InGame



-- Messages


type Msg
    = Reveal MouseButton Coordinate
    | ToggleOverlay Coordinate Bool
    | ToggleEnabled Coordinate Bool
    | FlipControlls
    | SetRoute Route
    | PasteBoxEdit String
    | NewLevel (Grid Cell)