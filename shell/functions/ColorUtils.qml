pragma Singleton
pragma ComponentBehavior: Bound

import QtQuick
import Quickshell

Singleton {
    id: root

    // Blend two colors by factor t in [0, 1]
    // t=0 → color1, t=1 → color2
    function mix(color1, color2, t) {
        return Qt.rgba(
            color1.r + (color2.r - color1.r) * t,
            color1.g + (color2.g - color1.g) * t,
            color1.b + (color2.b - color1.b) * t,
            color1.a + (color2.a - color1.a) * t
        );
    }

    // Return the color with a new alpha value
    function withAlpha(color, alpha) {
        return Qt.rgba(color.r, color.g, color.b, alpha);
    }

    // Lighten a color by factor in [0, 1]
    function lighten(color, factor) {
        return mix(color, Qt.rgba(1, 1, 1, 1), factor);
    }

    // Darken a color by factor in [0, 1]
    function darken(color, factor) {
        return mix(color, Qt.rgba(0, 0, 0, 1), factor);
    }
}
