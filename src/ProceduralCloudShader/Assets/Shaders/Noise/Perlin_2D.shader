Shader "Custom/Noise/2D/Perlin"
{
    Properties
    {
    }
    SubShader
    {
        Tags { "RenderType"="Opaque" }
        LOD 100

        Pass
        {
            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"
            
            #define PI 3.1415926538

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
            };

            float fract(float x) {
                return x - floor(x);
            }

            float random(float v) {
                return fract(sin(v+2.45647) * 43758.5453123);
            }

            // float2 randomGradient(float x, float y) {
            //     float u = random(x);
            //     float v = random(y);
            //     return normalize(float2(2*u - 1, 2*v - 1));
            // }

            float2 randomGradient(float x, float y) {
                    if (x == 0 && y == 0) return float2(-0.6, 0.2);
                    if (x == 1 && y == 0) return float2(0.4,  0.4);
                    if (x == 2 && y == 0) return float2(0.3, -0.5);
                    if (x == 3 && y == 0) return float2(0.5, -0.3);
                    if (x == 0 && y == 1) return float2(0.3, -0.5);
                    if (x == 1 && y == 1) return float2(0.2,  0.6);
                    if (x == 2 && y == 1) return float2(0.6, -0.2);
                    if (x == 3 && y == 1) return float2(0.3, -0.5);
                    if (x == 0 && y == 2) return float2(-0.3, 0.5);
                    if (x == 1 && y == 2) return float2(-0.3,-0.5);
                    if (x == 2 && y == 2) return float2(0.5, -0.3);
                    if (x == 3 && y == 2) return float2(0.5,  0.3);
                    if (x == 0 && y == 3) return float2(0.3,  0.5);
                    if (x == 1 && y == 3) return float2(-0.1,-0.7);
                    if (x == 2 && y == 3) return float2(-0.4, 0.4);
                    if (x == 3 && y == 3) return float2(-0.3, 0.5);
                    return float2(0,0);
            }

            float fade(float t) { 
                return t * t * t * (t * (t * 6 - 15) + 10);
            }

            // Computes the dot product of the distance and gradient vectors.
            float dotGridGradient(float ix, float iy, float x, float y) {

                // gradient vectors at each grid node
                float2 gradient = normalize(randomGradient(ix, iy));

                // Compute the distance vector
                float dx = x - ix;
                float dy = y- iy;
                float2 distV = float2(dx, dy);
                
                // Compute the dot-product
                return dot(gradient, distV);
            }

            float coserp(float y1,float y2, float mu)
            {
                float mu2;
                mu2 = (1 - cos(mu * PI)) / 2;
                return(y1 * (1 - mu2) + y2 * mu2);
            }

            float perlin(float x, float y) {

                // Determine grid cell coordinates
                float x0 = floor(x);
                float y0 = floor(y);
                float x1 = x0 + 1;
                float y1 = y0 + 1;

                // Determine interpolation weights
                // Could also use higher order polynomial/s-curve here
                float dx = x - x0;
                float dy = y - y0;

                // Interpolate between grid point gradients
                float s = dotGridGradient(x0, y0, x, y);
                float t = dotGridGradient(x1, y0, x, y);
                float v = dotGridGradient(x0, y1, x, y);
                float u = dotGridGradient(x1, y1, x, y);

                float w1 = coserp(v, u, dx);
                float w2 = coserp(s, t, dx);
                float value = coserp(w1, w2, dy);
                return value;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float c = perlin(i.uv.x*3, i.uv.y*3);
                fixed4 col = fixed4(c,c,c,1);
                return col;
            }
            ENDCG
        }
    }
}