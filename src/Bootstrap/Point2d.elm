--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- This Source Code Form is subject to the terms of the Mozilla Public        --
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,  --
-- you can obtain one at http://mozilla.org/MPL/2.0/.                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


module Bootstrap.Point2d exposing
    ( coordinates
    , fromCoordinates
    )

import Geometry.Types exposing (..)
import Quantity exposing (Quantity)


fromCoordinates : ( Quantity Float units, Quantity Float units ) -> Point2d coordinates units
fromCoordinates givenCoordinates =
    Point2d givenCoordinates


coordinates : Point2d coordinates units -> ( Quantity Float units, Quantity Float units )
coordinates (Point2d pointCoordinates) =
    pointCoordinates
