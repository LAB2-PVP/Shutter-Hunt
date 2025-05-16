shader_type canvas_item;

uniform vec2 center = vec2(0.5, 0.5); // Center of the circle (normalized screen coords)
uniform float radius : hint_range(0.0, 1.414) = 0.0; // Radius of the circle
uniform vec2 resolution = vec2(1.0, 1.0); // Viewport resolution for aspect ratio correction

void fragment() {
    // Calculate aspect ratio
    float aspect = resolution.x / resolution.y;
    float correction = sqrt(aspect); // Use square root to balance the correction

    // Adjust UV coordinates to account for aspect ratio, keeping center at (0.5, 0.5)
    vec2 adjusted_uv = UV - vec2(0.5); // Move origin to center (0.5, 0.5)
    adjusted_uv.x *= correction; // Slightly stretch x
    adjusted_uv.y /= correction; // Slightly compress y
    adjusted_uv += vec2(0.5); // Move origin back

    // Adjust center in the same way
    vec2 adjusted_center = center - vec2(0.5);
    adjusted_center.x *= correction;
    adjusted_center.y /= correction;
    adjusted_center += vec2(0.5);

    // Calculate distance with aspect-corrected coordinates
    float dist = distance(adjusted_uv, adjusted_center);
    float alpha = step(dist, radius); // 1.0 if inside the radius, 0.0 if outside
    COLOR.a = 1.0 - alpha; // Invert alpha: inside circle is transparent, outside is opaque
}