/*
 * This Source Code Form is subject to the terms of the Mozilla Public License, v. 2.0. If a copy of the MPL was not
 * distributed with this file, You can obtain one at http://mozilla.org/MPL/2.0/.
 */

module gx.util.geometry;

struct Point {
    int x;
    int y;
}

/**
 * Barycentric test — returns true if `p` lies inside the triangle
 * p0-p1-p2 (inclusive of edges). Works regardless of vertex winding
 * order. Degenerate (collinear) triangles return false for every
 * point.
 *
 * Cribbed from https://stackoverflow.com/questions/2049582 to avoid
 * reimplementing barycentric math from scratch.
 */
bool pointInTriangle(Point p, Point p0, Point p1, Point p2) {
    int s = p0.y * p2.x - p0.x * p2.y + (p2.y - p0.y) * p.x + (p0.x - p2.x) * p.y;
    int t = p0.x * p1.y - p0.y * p1.x + (p0.y - p1.y) * p.x + (p1.x - p0.x) * p.y;

    if ((s < 0) != (t < 0))
        return false;

    int a = -p1.y * p2.x + p0.y * (p2.x - p1.x) + p0.x * (p1.y - p2.y) + p1.x * p2.y;
    if (a < 0) {
        s = -s;
        t = -t;
        a = -a;
    }
    return s > 0 && t > 0 && (s + t) <= a;
}

// -- tests --------------------------------------------------------------

unittest {
    // Clearly inside: centroid of an axis-aligned right triangle.
    auto a = Point(0, 0), b = Point(10, 0), c = Point(0, 10);
    assert(pointInTriangle(Point(2, 2), a, b, c));
}

unittest {
    // Clearly outside in each direction.
    auto a = Point(0, 0), b = Point(10, 0), c = Point(0, 10);
    assert(!pointInTriangle(Point(-1, 5), a, b, c));
    assert(!pointInTriangle(Point(5, -1), a, b, c));
    assert(!pointInTriangle(Point(20, 20), a, b, c));
    assert(!pointInTriangle(Point(6, 6), a, b, c)); // outside the hypotenuse
}

unittest {
    // Reversed winding order — the `a < 0` branch must flip signs so
    // the result is identical regardless of vertex ordering.
    auto a = Point(0, 0), b = Point(10, 0), c = Point(0, 10);
    assert(pointInTriangle(Point(2, 2), a, b, c));
    assert(pointInTriangle(Point(2, 2), c, b, a));
    assert(pointInTriangle(Point(2, 2), b, a, c));
}

unittest {
    // Degenerate triangle (collinear vertices): no point is inside.
    auto a = Point(0, 0), b = Point(5, 5), c = Point(10, 10);
    assert(!pointInTriangle(Point(5, 5), a, b, c));
    assert(!pointInTriangle(Point(1, 1), a, b, c));
    assert(!pointInTriangle(Point(0, 0), a, b, c));
}

unittest {
    // Point on an edge of an axis-aligned triangle is considered
    // inside by the current implementation (`(s + t) <= a`). Locking
    // this in so a future refactor can't accidentally flip it.
    auto a = Point(0, 0), b = Point(10, 0), c = Point(0, 10);
    assert(pointInTriangle(Point(5, 5), a, b, c)); // on hypotenuse
    // Strictly at a vertex: s or t becomes zero, so the `s > 0 && t > 0`
    // guard rejects it. Documented behavior.
    assert(!pointInTriangle(Point(0, 0), a, b, c));
    assert(!pointInTriangle(Point(10, 0), a, b, c));
    assert(!pointInTriangle(Point(0, 10), a, b, c));
}

unittest {
    // Four-quadrant split of a 100×100 widget — the actual use case.
    // A centered cursor lands in exactly one quadrant (the first one
    // tested wins by short-circuit). Off-center points fall in the
    // expected quadrant.
    auto topLeft     = Point(0, 0);
    auto topRight    = Point(100, 0);
    auto bottomRight = Point(100, 100);
    auto bottomLeft  = Point(0, 100);
    auto center      = Point(50, 50);

    // Clearly-left cursor: inside (topLeft, bottomLeft, center), not others.
    auto leftCursor = Point(10, 50);
    assert(pointInTriangle(leftCursor, topLeft, bottomLeft, center));
    assert(!pointInTriangle(leftCursor, topLeft, topRight, center));
    assert(!pointInTriangle(leftCursor, topRight, bottomRight, center));
    assert(!pointInTriangle(leftCursor, bottomLeft, bottomRight, center));

    // Clearly-top cursor.
    auto topCursor = Point(50, 10);
    assert(!pointInTriangle(topCursor, topLeft, bottomLeft, center));
    assert(pointInTriangle(topCursor, topLeft, topRight, center));
}
