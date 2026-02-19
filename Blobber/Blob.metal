//
//  Blob.metal
//  BlobGen
//
//  Created by Leonardo Nápoles on 12/20/25.
//

#include <metal_stdlib>
#include <SwiftUI/SwiftUI_Metal.h>

using namespace metal;

#define NUM_BLOBS 3

struct Blob {
    float2 pos;
    float radius;
    half3 color;
};

/// hue rotation using YIQ color space
half3 hueShift(half3 col, float shift) {
    float cosA = cos(shift);
    float sinA = sin(shift);
    half3 result;
    result.r = half(float(col.r) * (0.299 + 0.701 * cosA + 0.168 * sinA)
                  + float(col.g) * (0.587 - 0.587 * cosA + 0.330 * sinA)
                  + float(col.b) * (0.114 - 0.114 * cosA - 0.497 * sinA));
    result.g = half(float(col.r) * (0.299 - 0.299 * cosA - 0.328 * sinA)
                  + float(col.g) * (0.587 + 0.413 * cosA + 0.035 * sinA)
                  + float(col.b) * (0.114 - 0.114 * cosA + 0.292 * sinA));
    result.b = half(float(col.r) * (0.299 - 0.300 * cosA + 1.250 * sinA)
                  + float(col.g) * (0.587 - 0.588 * cosA - 1.050 * sinA)
                  + float(col.b) * (0.114 + 0.886 * cosA - 0.203 * sinA));
    return saturate(result);
}

// constant arrays in global memory for better cache usage
//constant float speeds[NUM_BLOBS]  = { 0.7, -0.5, 0.9, -0.8, 0.6, -1.1, 0.4, -0.65 };
//constant float orbits[NUM_BLOBS]  = { 0.22, 0.18, 0.28, 0.15, 0.25, 0.20, 0.12, 0.24 };
//constant float phases[NUM_BLOBS]  = { 0.0, 0.79, 1.57, 2.36, 3.14, 3.93, 4.71, 5.50 };
//constant float radii[NUM_BLOBS]   = { 0.18, 0.15, 0.20, 0.14, 0.17, 0.16, 0.13, 0.19 };
//constant float hueShifts[NUM_BLOBS] = { 0.0, 0.05, -0.05, 0.1, -0.1, 0.15, -0.15, 0.08 };
constant float speeds[NUM_BLOBS]  = { 0.7, -0.5, 0.9};
constant float orbits[NUM_BLOBS]  = { 0.22, 0.18, 0.28 };
constant float phases[NUM_BLOBS]  = { 0.0, 0.79, 1.57 };
constant float radii[NUM_BLOBS]   = { 0.18, 0.15, 0.20 };
constant float hueShifts[NUM_BLOBS] = { 0.0, 0.05, -0.05 };


[[ stitchable ]] half4 dynamicBlob(
    float2 position,
    half4 currentColor,
    float2 size,
    float time,
    float complexity,
    float evolution,
    float tapElapsed,
    float2 mouseUV,
    float mouseSpeed
) {
    float2 uv = (position - size * 0.5) / min(size.x, size.y) * 2.0;

    /// fmod to avoid float32 precision issues
    float t = fmod(time, 1000.0);

    /// damped spring for the tap bounce
    float tapScatter = 0.0;
    float tapSquish  = 0.0;

    if (tapElapsed > 0.0 && tapElapsed < 3.5) {
        float decay = exp(-tapElapsed * 2.8);
        tapScatter = 0.25 * decay * fast::sin(tapElapsed * 10.0);
        tapSquish  = 0.12 * decay * fast::sin(tapElapsed * 14.0);
    }

    half3 baseHue = currentColor.rgb;

    float field = 0.0;
    half3 colorSum = half3(0.0);
    float weightSum = 0.0;
    
    for (int i = 0; i < NUM_BLOBS; i++) {
        float speed  = speeds[i];
        float orbit  = orbits[i];
        float phase  = phases[i];
        float blobR  = radii[i];
        float hShift = hueShifts[i];

        float cx = complexity * 0.08;
        float ev = evolution * 0.03;
        /// more taps = blobs spread further apart
        float spread = min(evolution * 0.0015, 0.15);

        /// fast math for organic movement
        float angle = t * speed + phase + ev;
        float orbitR = orbit + spread
                     + 0.05 * fast::sin(t * speed * 0.7 + phase * 2.0)
                     + 0.03 * fast::sin(t * 0.3 + phase * 1.7)
                     + cx * 0.02;

        /// slow drift
        float2 drift = float2(
            0.04 * fast::sin(t * 0.2 + phase * 3.1),
            0.04 * fast::cos(t * 0.17 + phase * 2.3)
        );

        orbitR += tapScatter * (0.8 + 0.2 * fast::sin(phase * 3.0));

        float2 blobPos = float2(fast::cos(angle), fast::sin(angle)) * orbitR + drift;

        /// breathing
        blobR += 0.025 * fast::sin(t * (0.8 + speed * 0.5) + phase);

        /// mouse repulsion
        if (mouseUV.x > -90.0) {
            float2 toBlob = blobPos - mouseUV;
            /// avoid sqrt here by using length_squared for dist check if possible?
            /// we need strict length for smoothstep logic though
            float mouseDistSq = length_squared(toBlob);
            
            /// optimization: only repel if close enough (avoid sqrt if far away)
            if (mouseDistSq < 0.8) {
                float mouseDist = sqrt(mouseDistSq);
                float proximity = 4.0 - smoothstep(0.0, 0.5, mouseDist);
                float repelStrength = proximity * clamp(mouseSpeed * 0.002, 0.0, 0.08);
                float2 repelDir = (mouseDist > 0.001) ? normalize(toBlob) : float2(0.0);
                blobPos += repelDir * repelStrength;
            }
        }

        /// metaball influence: r^2 / d^2
        /// OPTIMIZATION: use distance_squared to avoid sqrt()
        float distSq = distance_squared(uv, blobPos);
        float influence = (blobR * blobR) / (distSq + 0.009);

        field += influence;

        float weight = influence * influence;
        half3 blobColor = hueShift(baseHue, hShift);
        blobColor = mix(blobColor, half3(1.0), half(saturate(influence * 0.3)));

        colorSum += blobColor * half(weight);
        weightSum += weight;
    }

    field *= (1.0 + tapSquish);

    /// smoothstep creates the soft edge of the orb
    float threshold = 1.8;
    float softness  = 0.6;
    float shape = smoothstep(threshold - softness, threshold + softness * 0.3, field);

    /// weighted average of all the blob colors
    half3 blobColor = (weightSum > 0.0) ? colorSum / half(weightSum) : baseHue;

    /// darken edges, brighten where blobs overlap
    float coreBright = smoothstep(threshold, threshold * 3.0, field);
    blobColor = mix(blobColor * 0.6h, blobColor, half(shape));
    blobColor = mix(blobColor, mix(blobColor, half3(1.0), 0.5h), half(coreBright) * 0.25h);

    /// subtle pulsing brightness 
    float internalVar = 0.5 + 0.5 * sin(field * 3.0 + t * 0.5);
    blobColor *= half(0.85 + 0.15 * internalVar);

    /// specular highlight, top left
    float2 lightPos = float2(-0.15, -0.2);
    float lightDist = length(uv - lightPos);
    float specular = exp(-lightDist * lightDist * 12.0) * shape;
    blobColor += half3(1.0) * half(specular) * 0.15h;

    /// rim glow on the edges, kinda like fresnel in 3d rendering
    float edgeGlow = smoothstep(threshold + softness * 0.3, threshold, field)
                   * smoothstep(threshold - softness * 1.5, threshold - softness * 0.5, field);
    blobColor += half3(0.3, 0.5, 0.8) * half(edgeGlow) * 0.1h;

    float alpha = shape;

    /// outer glow, only shows outside the main shape
    float glowField = smoothstep(threshold * 0.3, threshold * 0.8, field);
    float outerGlow = glowField * (1.0 - shape);
    outerGlow *= 0.15;

    /// flash the glow brighter when you tap
//    if (tapElapsed > 0.0 && tapElapsed < 2.5) {
//        float glowPulse = exp(-tapElapsed * 3.5) * 0.2;
//        outerGlow += glowPulse * glowField;
//    }

    half3 glowColor = blobColor * 0.4h;

    half3 finalCol = blobColor * half(alpha);
    finalCol += glowColor * half(outerGlow);
    float finalAlpha = saturate(alpha + outerGlow);

    return half4(finalCol, half(finalAlpha) * currentColor.a);
}
