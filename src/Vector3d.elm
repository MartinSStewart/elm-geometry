--------------------------------------------------------------------------------
--------------------------------------------------------------------------------
-- This Source Code Form is subject to the terms of the Mozilla Public        --
-- License, v. 2.0. If a copy of the MPL was not distributed with this file,  --
-- you can obtain one at http://mozilla.org/MPL/2.0/.                         --
--------------------------------------------------------------------------------
--------------------------------------------------------------------------------


module Vector3d exposing
    ( Vector3d
    , zero
    , xyz, xyzIn, from, withLength, on, xyOn, rThetaOn, perpendicularTo, interpolateFrom
    , fromTuple, toTuple, fromRecord, toRecord
    , xComponent, yComponent, zComponent, componentIn, length, direction
    , equalWithin, lexicographicComparison
    , plus, minus, dot, cross
    , reverse, normalize, scaleBy, rotateAround, mirrorAcross, projectionIn, projectOnto
    , relativeTo, placeIn, projectInto
    )

{-| A `Vector3d` represents a quantity such as a displacement or velocity in 3D,
and is defined by its X, Y and Z components. This module contains a variety of
vector-related functionality, such as

  - Adding or subtracting vectors
  - Finding the lengths of vectors
  - Rotating vectors
  - Converting vectors between different coordinate systems

Note that unlike in many other geometry packages where vectors are used as a
general-purpose data type, `elm-geometry` has separate data types for vectors,
directions and points. In most code it is actually more common to use `Point3d`
and `Direction3d` than `Vector3d`, and much code can avoid working directly with
`Vector3d` values at all!

@docs Vector3d


# Predefined vectors

@docs zero

Although there are no predefined constants for the vectors with components
(1,&nbsp;0,&nbsp;0), (0,&nbsp;1,&nbsp;0) and (0,&nbsp;0,&nbsp;1), in most cases
you will actually want their `Direction3d` versions [`Direction3d.x`](Direction3d#x),
[`Direction3d.y`](Direction3d#y) and [`Direction3d.z`](Direction3d#z).


# Constructors

@docs xyz, xyzIn, from, withLength, on, xyOn, rThetaOn, perpendicularTo, interpolateFrom


# Interop

These functions are useful for interoperability with other Elm code that uses
plain `Float` tuples or records to represent vectors. The resulting `Vector3d`
values will have [unitless](https://package.elm-lang.org/packages/ianmackenzie/elm-units/latest/Quantity#unitless-quantities)
components.

@docs fromTuple, toTuple, fromRecord, toRecord


# Properties

@docs xComponent, yComponent, zComponent, componentIn, length, squaredLength, direction


# Comparison

@docs equalWithin, lexicographicComparison


# Arithmetic

@docs plus, minus, dot, cross


# Transformations

Note that for all transformations, only the orientation of the given axis or
plane is relevant, since vectors are position-independent. Think of transforming
a vector as placing its tail on the relevant axis or plane and then transforming
its tip.

@docs reverse, normalize, scaleBy, rotateAround, mirrorAcross, projectionIn, projectOnto


# Coordinate conversions

Like other transformations, coordinate transformations of vectors depend only on
the orientations of the relevant frames/sketch planes, not their positions.

For the examples, assume the following definition of a local coordinate frame,
one that is rotated 30 degrees counterclockwise around the Z axis from the
global XYZ frame:

    rotatedFrame =
        Frame3d.atOrigin |> Frame3d.rotateAround Axis3d.z (degrees 30)

@docs relativeTo, placeIn, projectInto

-}

import Angle exposing (Angle)
import Float.Extra as Float
import Geometry.Types as Types exposing (Axis3d, Direction3d, Frame3d, Plane3d, Point3d, SketchPlane3d)
import Quantity exposing (Cubed, Product, Quantity(..), Squared, Unitless)
import Quantity.Extra as Quantity
import Vector2d exposing (Vector2d)


{-| -}
type alias Vector3d units coordinates =
    Types.Vector3d units coordinates


{-| The zero vector.

    Vector3d.zero
    --> Vector3d.fromComponents ( 0, 0, 0 )

-}
zero : Vector3d units coordinates
zero =
    Types.Vector3d
        { x = 0
        , y = 0
        , z = 0
        }


{-| Construct a vector from its X, Y and Z components.

    vector =
        Vector3d.fromComponents ( 2, 1, 3 )

-}
xyz : Quantity Float units -> Quantity Float units -> Quantity Float units -> Vector3d units coordinates
xyz (Quantity x) (Quantity y) (Quantity z) =
    Types.Vector3d
        { x = x
        , y = y
        , z = z
        }


{-| Construct a vector given its local components within a particular frame:

    frame =
        Frame3d.atOrigin
            |> Frame3d.rotateAround Axis3d.z
                (Angle.degrees 45)

    Vector3d.fromComponentsIn frame
        ( Speed.feetPerSecond 1
        , Speed.feetPerSecond 0
        , Speed.feetPerSecond 2
        )
    --> Vector3d.fromComponents
    -->     ( Speed.feetPerSecond 0.7071
    -->     , Speed.feetPerSecond 0.7071
    -->     , Speed.feetPerSecond 2
    -->     )

-}
xyzIn : Frame3d units globalCoordinates { defines : localCoordinates } -> Quantity Float units -> Quantity Float units -> Quantity Float units -> Vector3d units globalCoordinates
xyzIn (Types.Frame3d frame) (Quantity x) (Quantity y) (Quantity z) =
    let
        (Types.Direction3d i) =
            frame.xDirection

        (Types.Direction3d j) =
            frame.yDirection

        (Types.Direction3d k) =
            frame.zDirection
    in
    Types.Vector3d
        { x = x * i.x + y * j.x + z * k.x
        , y = x * i.y + y * j.y + z * k.y
        , z = x * i.z + y * j.z + z * k.z
        }


{-| Construct a vector from the first given point to the second.

    startPoint =
        Point3d.fromCoordinates ( 1, 1, 1 )

    endPoint =
        Point3d.fromCoordinates ( 4, 5, 6 )

    Vector3d.from startPoint endPoint
    --> Vector3d.fromComponents ( 3, 4, 5 )

-}
from : Point3d units coordinates -> Point3d units coordinates -> Vector3d units coordinates
from (Types.Point3d p1) (Types.Point3d p2) =
    Types.Vector3d
        { x = p2.x - p1.x
        , y = p2.y - p1.y
        , z = p2.z - p1.z
        }


{-| Construct a vector with the given length in the given direction.

    Vector3d.withLength 5 Direction3d.y
    --> Vector3d.fromComponents ( 0, 5, 0 )

-}
withLength : Quantity Float units -> Direction3d coordinates -> Vector3d units coordinates
withLength (Quantity a) (Types.Direction3d d) =
    Types.Vector3d
        { x = a * d.x
        , y = a * d.y
        , z = a * d.z
        }


{-| Construct a 3D vector lying _on_ a sketch plane by providing a 2D vector
specified in XY coordinates _within_ the sketch plane.

    vector2d =
        Vector2d.fromComponents ( 2, 3 )

    Vector3d.on SketchPlane3d.xy vector2d
    --> Vector3d.fromComponents ( 2, 3, 0 )

    Vector3d.on SketchPlane3d.yz vector2d
    --> Vector3d.fromComponents ( 0, 2, 3 )

    Vector3d.on SketchPlane3d.zx vector2d
    --> Vector3d.fromComponents ( 3, 0, 2 )

A slightly more complex example:

    tiltedSketchPlane =
        SketchPlane3d.xy
            |> SketchPlane3d.rotateAround Axis3d.x
                (degrees 45)

    Vector3d.on tiltedSketchPlane <|
        Vector2d.fromComponents ( 1, 1 )
    --> Vector3d.fromComponents ( 1, 0.7071, 0.7071 )

-}
on : SketchPlane3d units coordinates3d { defines : coordinates2d } -> Vector2d units coordinates2d -> Vector3d units coordinates3d
on (Types.SketchPlane3d sketchPlane) (Types.Vector2d v) =
    let
        (Types.Direction3d i) =
            sketchPlane.xDirection

        (Types.Direction3d j) =
            sketchPlane.yDirection
    in
    Types.Vector3d
        { x = v.x * i.x + v.y * j.x
        , y = v.x * i.y + v.y * j.y
        , z = v.x * i.z + v.y * j.z
        }


{-| Construct a 3D vector lying on a sketch plane by providing its 2D components within the sketch
plane:

    Vector3d.fromComponentsOn SketchPlane3d.xy
        (meters 2)
        (meters 3)
    --> Vector3d.fromComponents
    -->     (meters 2)
    -->     (meters 3)
    -->     (meters 0)

    Vector3d.fromComponentsOn SketchPlane3d.zx
        (meters 2)
        (meters 3)
    --> Vector3d.fromComponents
    -->     (meters 3)
    -->     (meters 0)
    -->     (meters 2)

-}
xyOn : SketchPlane3d units coordinates3d { defines : coordinates2d } -> Quantity Float units -> Quantity Float units -> Vector3d units coordinates3d
xyOn (Types.SketchPlane3d sketchPlane) (Quantity x) (Quantity y) =
    let
        (Types.Direction3d i) =
            sketchPlane.xDirection

        (Types.Direction3d j) =
            sketchPlane.yDirection
    in
    Types.Vector3d
        { x = x * i.x + y * j.x
        , y = x * i.y + y * j.y
        , z = x * i.z + y * j.z
        }


{-| TODO
-}
rThetaOn : SketchPlane3d units coordinates3d { defines : coordinates2d } -> Quantity Float units -> Angle -> Vector3d units coordinates3d
rThetaOn (Types.SketchPlane3d sketchPlane) (Quantity r) (Quantity theta) =
    let
        (Types.Direction3d i) =
            sketchPlane.xDirection

        (Types.Direction3d j) =
            sketchPlane.yDirection

        x =
            r * cos theta

        y =
            r * sin theta
    in
    Types.Vector3d
        { x = x * i.x + y * j.x
        , y = x * i.y + y * j.y
        , z = x * i.z + y * j.z
        }


{-| Construct an arbitrary vector perpendicular to the given vector. The exact
length and direction of the resulting vector are not specified, but it is
guaranteed to be perpendicular to the given vector and non-zero (unless the
given vector is itself zero).

    Vector3d.perpendicularTo
        (Vector3d.fromComponents ( 3, 0, 0 ))
    --> Vector3d.fromComponents ( 0, 0, -3 )

    Vector3d.perpendicularTo
        (Vector3d.fromComponents ( 1, 2, 3 ))
    --> Vector3d.fromComponents ( 0, -3, 2 )

    Vector3d.perpendicularTo Vector3d.zero
    --> Vector3d.zero

-}
perpendicularTo : Vector3d units coordinates -> Vector3d units coordinates
perpendicularTo (Types.Vector3d v) =
    let
        absX =
            abs v.x

        absY =
            abs v.y

        absZ =
            abs v.z
    in
    if absX <= absY then
        if absX <= absZ then
            Types.Vector3d { x = 0, y = -v.z, z = v.y }

        else
            Types.Vector3d { x = -v.y, y = v.x, z = 0 }

    else if absY <= absZ then
        Types.Vector3d { x = v.z, y = 0, z = -v.x }

    else
        Types.Vector3d { x = -v.y, z = v.x, y = 0 }


{-| Construct a vector by interpolating from the first given vector to the
second, based on a parameter that ranges from zero to one.

    startVector =
        Vector3d.fromComponents ( 1, 2, 4 )

    endVector =
        Vector3d.fromComponents ( 1, 3, 8 )

    Vector3d.interpolateFrom startVector endVector 0.25
    --> Vector3d.fromComponents ( 1, 2.25, 5 )

Partial application may be useful:

    interpolatedVector : Float -> Vector3d
    interpolatedVector =
        Vector3d.interpolateFrom startVector endVector

    List.map interpolatedVector [ 0, 0.5, 1 ]
    --> [ Vector3d.fromComponents ( 1, 2, 4 )
    --> , Vector3d.fromComponents ( 1, 2, 6 )
    --> , Vector3d.fromComponents ( 1, 2, 8 )
    --> ]

You can pass values less than zero or greater than one to extrapolate:

    interpolatedVector -0.5
    --> Vector3d.fromComponents ( 1, 2, 2 )

    interpolatedVector 1.25
    --> Vector3d.fromComponents ( 1, 2, 9 )

-}
interpolateFrom : Vector3d units coordinates -> Vector3d units coordinates -> Float -> Vector3d units coordinates
interpolateFrom (Types.Vector3d v1) (Types.Vector3d v2) t =
    if t <= 0.5 then
        Types.Vector3d
            { x = v1.x + t * (v2.x - v1.x)
            , y = v1.y + t * (v2.y - v1.y)
            , z = v1.z + t * (v2.z - v1.z)
            }

    else
        Types.Vector3d
            { x = v2.x + (1 - t) * (v1.x - v2.x)
            , y = v2.y + (1 - t) * (v1.y - v2.y)
            , z = v2.z + (1 - t) * (v1.z - v2.z)
            }


{-| Construct a `Vector3d` from a tuple of `Float` values, by specifying what units those values are
in.

    Vector3d.fromTuple Length.meters ( 2, 3, 1 )
    --> Vector3d.fromComponents
    -->     (Length.meters 2)
    -->     (Length.meters 3)
    -->     (Length.meters 1)

-}
fromTuple : (Float -> Quantity Float units) -> ( Float, Float, Float ) -> Vector3d units coordinates
fromTuple toQuantity ( x, y, z ) =
    xyz (toQuantity x) (toQuantity y) (toQuantity z)


{-| Convert a `Vector3d` to a tuple of `Float` values, by specifying what units you want the result
to be in.

    vector =
        Vector3d.fromComponents
            (Length.feet 2)
            (Length.feet 3)
            (Length.feet 1)

    Vector3d.toTuple Length.inInches vector
    --> ( 24, 36, 12 )

-}
toTuple : (Quantity Float units -> Float) -> Vector3d units coordinates -> ( Float, Float, Float )
toTuple fromQuantity vector =
    ( fromQuantity (xComponent vector)
    , fromQuantity (yComponent vector)
    , fromQuantity (zComponent vector)
    )


{-| Construct a `Vector3d` from a record with `Float` fields, by specifying what units those fields
are in.

    Vector3d.fromRecord Length.inches { x = 24, y = 36, z = 12 }
    --> Vector3d.fromComponents
    -->     (Length.feet 2)
    -->     (Length.feet 3)
    -->     (Length.feet 1)

-}
fromRecord : (Float -> Quantity Float units) -> { x : Float, y : Float, z : Float } -> Vector3d units coordinates
fromRecord toQuantity { x, y, z } =
    xyz (toQuantity x) (toQuantity y) (toQuantity z)


{-| Convert a `Vector3d` to a record with `Float` fields, by specifying what units you want the
result to be in.

    vector =
        Vector3d.fromComponents
            (Length.meters 2)
            (Length.meters 3)
            (Length.meters 1)

    Vector3d.toRecord Length.inCentimeters vector
    --> { x = 200, y = 300, z = 100 }

-}
toRecord : (Quantity Float units -> Float) -> Vector3d units coordinates -> { x : Float, y : Float, z : Float }
toRecord fromQuantity vector =
    { x = fromQuantity (xComponent vector)
    , y = fromQuantity (yComponent vector)
    , z = fromQuantity (zComponent vector)
    }


{-| Get the X component of a vector.

    Vector3d.fromComponents ( 1, 2, 3 )
        |> Vector3d.xComponent
    --> 1

-}
xComponent : Vector3d units coordinates -> Quantity Float units
xComponent (Types.Vector3d v) =
    Quantity v.x


{-| Get the Y component of a vector.

    Vector3d.fromComponents ( 1, 2, 3 )
        |> Vector3d.yComponent
    --> 2

-}
yComponent : Vector3d units coordinates -> Quantity Float units
yComponent (Types.Vector3d v) =
    Quantity v.y


{-| Get the Z component of a vector.

    Vector3d.fromComponents ( 1, 2, 3 )
        |> Vector3d.zComponent
    --> 3

-}
zComponent : Vector3d units coordinates -> Quantity Float units
zComponent (Types.Vector3d v) =
    Quantity v.z


{-| Find the component of a vector in an arbitrary direction, for example

    verticalSpeed =
        Vector3d.componentIn upDirection velocity

This is more general and flexible than using `xComponent`, `yComponent` or
`zComponent`, all of which can be expressed in terms of `componentIn`; for
example,

    Vector3d.zComponent vector

is equivalent to

    Vector3d.componentIn Direction3d.z vector

-}
componentIn : Direction3d coordinates -> Vector3d units coordinates -> Quantity Float units
componentIn (Types.Direction3d d) (Types.Vector3d v) =
    Quantity (v.x * d.x + v.y * d.y + v.z * d.z)


{-| Compare two vectors within a tolerance. Returns true if the difference
between the two given vectors has magnitude less than the given tolerance.

    firstVector =
        Vector3d.fromComponents ( 2, 1, 3 )

    secondVector =
        Vector3d.fromComponents ( 2.0002, 0.9999, 3.0001 )

    Vector3d.equalWithin 1e-3 firstVector secondVector
    --> True

    Vector3d.equalWithin 1e-6 firstVector secondVector
    --> False

-}
equalWithin : Quantity Float units -> Vector3d units coordinates -> Vector3d units coordinates -> Bool
equalWithin givenTolerance firstVector secondVector =
    length (secondVector |> minus firstVector) |> Quantity.lessThanOrEqualTo givenTolerance


{-| Compare two `Vector3d` values lexicographically: first by X component, then
by Y, then by Z. Can be used to provide a sort order for `Vector3d` values.
-}
lexicographicComparison : Vector3d units coordinates -> Vector3d units coordinates -> Order
lexicographicComparison (Types.Vector3d v1) (Types.Vector3d v2) =
    if v1.x /= v2.x then
        compare v1.x v2.x

    else if v1.y /= v2.y then
        compare v1.y v2.y

    else
        compare v1.z v2.z


{-| Get the length (magnitude) of a vector.

    Vector3d.length (Vector3d.fromComponents ( 2, 1, 2 ))
    --> 3

-}
length : Vector3d units coordinates -> Quantity Float units
length (Types.Vector3d v) =
    let
        largestComponent =
            max (abs v.x) (max (abs v.y) (abs v.z))
    in
    if largestComponent == 0 then
        Quantity.zero

    else
        let
            scaledX =
                v.x / largestComponent

            scaledY =
                v.y / largestComponent

            scaledZ =
                v.z / largestComponent

            scaledLength =
                sqrt (scaledX * scaledX + scaledY * scaledY + scaledZ * scaledZ)
        in
        Quantity (scaledLength * largestComponent)


{-| Attempt to find the direction of a vector. In the case of a zero vector,
returns `Nothing`.

    Vector3d.fromComponents ( 3, 0, 3 )
        |> Vector3d.direction
    --> Just
    -->     (Direction3d.fromAzimuthAndElevation
    -->         (degrees 0)
    -->         (degrees 45)
    -->     )

    Vector3d.direction Vector3d.zero
    --> Nothing

-}
direction : Vector3d units coordinates -> Maybe (Direction3d coordinates)
direction (Types.Vector3d v) =
    let
        largestComponent =
            max (abs v.x) (max (abs v.y) (abs v.z))
    in
    if largestComponent == 0 then
        Nothing

    else
        let
            scaledX =
                v.x / largestComponent

            scaledY =
                v.y / largestComponent

            scaledZ =
                v.z / largestComponent

            scaledLength =
                sqrt (scaledX * scaledX + scaledY * scaledY + scaledZ * scaledZ)
        in
        Just <|
            Types.Direction3d
                { x = scaledX / scaledLength
                , y = scaledY / scaledLength
                , z = scaledZ / scaledLength
                }


{-| Normalize a vector to have a length of one. Zero vectors are left as-is.

    vector =
        Vector3d.fromComponents ( 3, 0, 4 )

    Vector3d.normalize vector
    --> Vector3d.fromComponents ( 0.6, 0, 0.8 )

    Vector3d.normalize Vector3d.zero
    --> Vector3d.zero

**Warning**: `Vector3d.direction` is safer since it forces you to explicitly
consider the case where the given vector is zero. `Vector3d.normalize` is
primarily useful for cases like generating WebGL meshes, where defaulting to a
zero vector for degenerate cases is acceptable, and the overhead of something
like

    Vector3d.direction vector
        |> Maybe.map Direction3d.toVector
        |> Maybe.withDefault Vector3d.zero

(which is functionally equivalent to `Vector3d.normalize vector`) is too high.

-}
normalize : Vector3d units coordinates -> Vector3d Unitless coordinates
normalize (Types.Vector3d v) =
    let
        largestComponent =
            max (abs v.x) (max (abs v.y) (abs v.z))
    in
    if largestComponent == 0 then
        zero

    else
        let
            scaledX =
                v.x / largestComponent

            scaledY =
                v.y / largestComponent

            scaledZ =
                v.z / largestComponent

            scaledLength =
                sqrt (scaledX * scaledX + scaledY * scaledY + scaledZ * scaledZ)
        in
        Types.Vector3d
            { x = scaledX / scaledLength
            , y = scaledY / scaledLength
            , z = scaledZ / scaledLength
            }


{-| Find the sum of two vectors.

    firstVector =
        Vector3d.fromComponents ( 1, 2, 3 )

    secondVector =
        Vector3d.fromComponents ( 4, 5, 6 )

    Vector3d.sum firstVector secondVector
    --> Vector3d.fromComponents ( 5, 7, 9 )

-}
plus : Vector3d units coordinates -> Vector3d units coordinates -> Vector3d units coordinates
plus (Types.Vector3d v2) (Types.Vector3d v1) =
    Types.Vector3d
        { x = v1.x + v2.x
        , y = v1.y + v2.y
        , z = v1.z + v2.z
        }


{-| Find the difference between two vectors (the first vector minus the second).

    firstVector =
        Vector3d.fromComponents ( 5, 6, 7 )

    secondVector =
        Vector3d.fromComponents ( 1, 1, 1 )

    Vector3d.difference firstVector secondVector
    --> Vector3d.fromComponents ( 4, 5, 6 )

-}
minus : Vector3d units coordinates -> Vector3d units coordinates -> Vector3d units coordinates
minus (Types.Vector3d v2) (Types.Vector3d v1) =
    Types.Vector3d
        { x = v1.x - v2.x
        , y = v1.y - v2.y
        , z = v1.z - v2.z
        }


{-| Find the dot product of two vectors.

    firstVector =
        Vector3d.fromComponents
            ( Length.meters 1
            , Length.meters 0
            , Length.meters 2
            )

    secondVector =
        Vector3d.fromComponents
            ( Length.meters 3
            , Length.meters 4
            , Length.meters 5
            )

    firstVector |> Vector3d.dot secondVector
    --> Area.squareMeters 13

-}
dot : Vector3d units2 coordinates -> Vector3d units1 coordinates -> Quantity Float (Product units1 units2)
dot (Types.Vector3d v2) (Types.Vector3d v1) =
    Quantity (v1.x * v2.x + v1.y * v2.y + v1.z * v2.z)


{-| Find the cross product of two vectors.

    firstVector =
        Vector3d.fromComponents
            ( Length.meters 2
            , Length.meters 0
            , Length.meters 0
            )

    secondVector =
        Vector3d.fromComponents
            ( Length.meters 0
            , Length.meters 3
            , Length.meters 0
            )

    firstVector |> Vector3d.cross secondVector
    --> Vector3d.fromComponents
    -->     ( Quantity.zero
    -->     , Quantity.zero
    -->     , Area.squareMeters 6
    -->     )

Note the argument order - `v1 x v2` would be written as

    v1 |> Vector3d.cross v2

which is the same as

    Vector3d.cross v2 v1

but the _opposite_ of

    Vector3d.cross v1 v2

-}
cross : Vector3d units2 coordinates -> Vector3d units1 coordinates -> Vector3d (Product units1 units2) coordinates
cross (Types.Vector3d v2) (Types.Vector3d v1) =
    Types.Vector3d
        { x = v1.y * v2.z - v1.z * v2.y
        , y = v1.z * v2.x - v1.x * v2.z
        , z = v1.x * v2.y - v1.y * v2.x
        }


{-| Reverse the direction of a vector, negating its components.

    Vector3d.reverse (Vector3d.fromComponents ( 1, -3, 2 ))
    --> Vector3d.fromComponents ( -1, 3, -2 )

(This could have been called `negate`, but `reverse` is more consistent with
the naming used in other modules.)

-}
reverse : Vector3d units coordinates -> Vector3d units coordinates
reverse (Types.Vector3d v) =
    Types.Vector3d
        { x = -v.x
        , y = -v.y
        , z = -v.z
        }


{-| Scale the length of a vector by a given scale.

    Vector3d.fromComponents ( 1, 2, 3 )
        |> Vector3d.scaleBy 3
    --> Vector3d.fromComponents ( 3, 6, 9 )

(This could have been called `multiply` or `times`, but `scaleBy` was chosen as
a more geometrically meaningful name and to be consistent with the `scaleAbout`
name used in other modules.)

-}
scaleBy : Float -> Vector3d units coordinates -> Vector3d units coordinates
scaleBy k (Types.Vector3d v) =
    Types.Vector3d
        { x = k * v.x
        , y = k * v.y
        , z = k * v.z
        }


{-| Rotate a vector around a given axis by a given angle (in radians).

    vector =
        Vector3d.fromComponents ( 2, 0, 1 )

    Vector3d.rotateAround Axis3d.x (degrees 90) vector
    --> Vector3d.fromComponents ( 2, -1, 0 )

    Vector3d.rotateAround Axis3d.z (degrees 45) vector
    --> Vector3d.fromComponents ( 1.4142, 1.4142, 1 )

-}
rotateAround : Axis3d units coordinates -> Angle -> Vector3d units coordinates -> Vector3d units coordinates
rotateAround (Types.Axis3d axis) (Quantity angle) (Types.Vector3d v) =
    let
        (Types.Direction3d d) =
            axis.direction

        halfAngle =
            0.5 * angle

        sinHalfAngle =
            sin halfAngle

        qx =
            d.x * sinHalfAngle

        qy =
            d.y * sinHalfAngle

        qz =
            d.z * sinHalfAngle

        qw =
            cos halfAngle

        wx =
            qw * qx

        wy =
            qw * qy

        wz =
            qw * qz

        xx =
            qx * qx

        xy =
            qx * qy

        xz =
            qx * qz

        yy =
            qy * qy

        yz =
            qy * qz

        zz =
            qz * qz

        a00 =
            1 - 2 * (yy + zz)

        a10 =
            2 * (xy + wz)

        a20 =
            2 * (xz - wy)

        a01 =
            2 * (xy - wz)

        a11 =
            1 - 2 * (xx + zz)

        a21 =
            2 * (yz + wx)

        a02 =
            2 * (xz + wy)

        a12 =
            2 * (yz - wx)

        a22 =
            1 - 2 * (xx + yy)
    in
    Types.Vector3d
        { x = a00 * v.x + a01 * v.y + a02 * v.z
        , y = a10 * v.x + a11 * v.y + a12 * v.z
        , z = a20 * v.x + a21 * v.y + a22 * v.z
        }


{-| Mirror a vector across a plane.

    vector =
        Vector3d.fromComponents ( 1, 2, 3 )

    Vector3d.mirrorAcross Plane3d.xy vector
    --> Vector3d.fromComponents ( 1, 2, -3 )

    Vector3d.mirrorAcross Plane3d.yz vector
    --> Vector3d.fromComponents ( -1, 2, 3 )

-}
mirrorAcross : Plane3d units coordinates -> Vector3d units coordinates -> Vector3d units coordinates
mirrorAcross (Types.Plane3d plane) (Types.Vector3d v) =
    let
        (Types.Direction3d n) =
            plane.normalDirection

        a00 =
            1 - 2 * n.x * n.x

        a11 =
            1 - 2 * n.y * n.y

        a22 =
            1 - 2 * n.z * n.z

        a12 =
            -2 * n.y * n.z

        a02 =
            -2 * n.x * n.z

        a01 =
            -2 * n.x * n.y
    in
    Types.Vector3d
        { x = a00 * v.x + a01 * v.y + a02 * v.z
        , y = a01 * v.x + a11 * v.y + a12 * v.z
        , z = a02 * v.x + a12 * v.y + a22 * v.z
        }


{-| Find the projection of a vector in a particular direction. Conceptually,
this means splitting the original vector into a portion parallel to the given
direction and a portion perpendicular to it, then returning the parallel
portion.

    vector =
        Vector3d.fromComponents ( 1, 2, 3 )

    Vector3d.projectionIn Direction3d.x vector
    --> Vector3d.fromComponents ( 1, 0, 0 )

    Vector3d.projectionIn Direction3d.z vector
    --> Vector3d.fromComponents ( 0, 0, 3 )

-}
projectionIn : Direction3d coordinates -> Vector3d units coordinates -> Vector3d units coordinates
projectionIn (Types.Direction3d d) (Types.Vector3d v) =
    let
        projectedLength =
            v.x * d.x + v.y * d.y + v.z * d.z
    in
    Types.Vector3d
        { x = d.x * projectedLength
        , y = d.y * projectedLength
        , z = d.z * projectedLength
        }


{-| Project a vector [orthographically](https://en.wikipedia.org/wiki/Orthographic_projection)
onto a plane. Conceptually, this means splitting the original vector into a
portion parallel to the plane (perpendicular to the plane's normal direction)
and a portion perpendicular to it (parallel to its normal direction), then
returning the parallel (in-plane) portion.

    vector =
        Vector3d.fromComponents ( 2, 1, 3 )

    Vector3d.projectOnto Plane3d.xy vector
    --> Vector3d.fromComponents ( 2, 1, 0 )

    Vector3d.projectOnto Plane3d.xz vector
    --> Vector3d.fromComponents ( 2, 0, 3 )

-}
projectOnto : Plane3d units coordinates -> Vector3d units coordinates -> Vector3d units coordinates
projectOnto (Types.Plane3d plane) (Types.Vector3d v) =
    let
        (Types.Direction3d n) =
            plane.normalDirection

        normalProjection =
            v.x * n.x + v.y * n.y + v.z * n.z
    in
    Types.Vector3d
        { x = v.x - normalProjection * n.x
        , y = v.y - normalProjection * n.y
        , z = v.z - normalProjection * n.z
        }


{-| Take a vector defined in global coordinates, and return it expressed in
local coordinates relative to a given reference frame.

    vector =
        Vector3d.fromComponents ( 2, 0, 3 )

    Vector3d.relativeTo rotatedFrame vector
    --> Vector3d.fromComponents ( 1.732, -1, 3 )

-}
relativeTo : Frame3d units globalCoordinates { defines : localCoordinates } -> Vector3d units globalCoordinates -> Vector3d units localCoordinates
relativeTo (Types.Frame3d frame) (Types.Vector3d v) =
    let
        (Types.Direction3d i) =
            frame.xDirection

        (Types.Direction3d j) =
            frame.yDirection

        (Types.Direction3d k) =
            frame.zDirection
    in
    Types.Vector3d
        { x = v.x * i.x + v.y * i.y + v.z * i.z
        , y = v.x * j.x + v.y * j.y + v.z * j.z
        , z = v.x * k.x + v.y * k.y + v.z * k.z
        }


{-| Take a vector defined in local coordinates relative to a given reference
frame, and return that vector expressed in global coordinates.

    vector =
        Vector3d.fromComponents ( 2, 0, 3 )

    Vector3d.placeIn rotatedFrame vector
    --> Vector3d.fromComponents ( 1.732, 1, 3 )

-}
placeIn : Frame3d units globalCoordinates { defines : localCoordinates } -> Vector3d units localCoordinates -> Vector3d units globalCoordinates
placeIn (Types.Frame3d frame) (Types.Vector3d v) =
    let
        (Types.Direction3d i) =
            frame.xDirection

        (Types.Direction3d j) =
            frame.yDirection

        (Types.Direction3d k) =
            frame.zDirection
    in
    Types.Vector3d
        { x = i.x * v.x + j.x * v.y + k.x * v.z
        , y = i.y * v.x + j.y * v.y + k.y * v.z
        , z = i.z * v.x + j.z * v.y + k.z * v.z
        }


{-| Project a vector into a given sketch plane. Conceptually, this finds the
[orthographic projection](https://en.wikipedia.org/wiki/Orthographic_projection)
of the vector onto the plane and then expresses the projected vector in 2D
sketch coordinates.

    vector =
        Vector3d.fromComponents ( 2, 1, 3 )

    Vector3d.projectInto SketchPlane3d.xy vector
    --> Vector2d.fromComponents ( 2, 1 )

    Vector3d.projectInto SketchPlane3d.yz vector
    --> Vector2d.fromComponents ( 1, 3 )

    Vector3d.projectInto SketchPlane3d.zx vector
    --> Vector2d.fromComponents ( 3, 2 )

-}
projectInto : SketchPlane3d units coordinates3d { defines : coordinates2d } -> Vector3d units coordinates3d -> Vector2d units coordinates2d
projectInto (Types.SketchPlane3d sketchPlane) (Types.Vector3d v) =
    let
        (Types.Direction3d i) =
            sketchPlane.xDirection

        (Types.Direction3d j) =
            sketchPlane.yDirection
    in
    Types.Vector2d
        { x = v.x * i.x + v.y * i.y + v.z * i.z
        , y = v.x * j.x + v.y * j.y + v.z * j.z
        }
