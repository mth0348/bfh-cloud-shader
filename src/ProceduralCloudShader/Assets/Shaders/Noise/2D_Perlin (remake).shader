Shader "Custom/Noise/2D/Perlin"
{
    Properties
    {
        _Scale ("Scale", float) = 3.0
        _Offset ("Offset", vector) = (1,1,0,0)
        _Octaves ("Octaves", Range(1,10)) = 1
        _Persistence ("Persistence", Range(0.1, 2)) = 0.5
        _Frequency ("Frequency", Range(0.1, 10)) = 1
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

            float _Scale;
            float2 _Offset;
            int _Octaves;
            float _Persistence;
            float _Frequency;

            float fract(float x) {
                return x - floor(x);
            }

            float fract2(float2 x) {
                return float2(fract(x.x), fract(x.y));
            }

            float random(float v) {
                return fract(sin(v) * 43758.5453123);
            }

            float2 randomGradient(float x, float y) {
                float u = random(x);
                float v = random(y);
                return normalize(float2(2*u - 1, 2*v - 1));
            }

            // float2 randomGradient(float x, float y) {
                //         if (x == 0 && y == 0) return float2(-0.6, 0.2);
                //         if (x == 1 && y == 0) return float2(0.4,  0.4);
                //         if (x == 2 && y == 0) return float2(0.3, -0.5);
                //         if (x == 3 && y == 0) return float2(0.5, -0.3);
                //         if (x == 0 && y == 1) return float2(0.3, -0.5);
                //         if (x == 1 && y == 1) return float2(0.2,  0.6);
                //         if (x == 2 && y == 1) return float2(0.6, -0.2);
                //         if (x == 3 && y == 1) return float2(0.3, -0.5);
                //         if (x == 0 && y == 2) return float2(-0.3, 0.5);
                //         if (x == 1 && y == 2) return float2(-0.3,-0.5);
                //         if (x == 2 && y == 2) return float2(0.5, -0.3);
                //         if (x == 3 && y == 2) return float2(0.5,  0.3);
                //         if (x == 0 && y == 3) return float2(0.3,  0.5);
                //         if (x == 1 && y == 3) return float2(-0.1,-0.7);
                //         if (x == 2 && y == 3) return float2(-0.4, 0.4);
                //         if (x == 3 && y == 3) return float2(-0.3, 0.5);
                //         return float2(0,0);
            // }

            float2 hash(float2 v)
            {
                float2 k = float2(0.3183099, 0.3678794);
                float2 x = v * k + k.yx;
                return -1.0 + 2.0 * fract(16.0 * k * fract(x.x * x.y * (x.x + x.y)));
            }

            float fade(float t) { 
                return t * t * t * (t * (t * 6 - 15) + 10);
            }

            // Computes the dot product of the distance and gradient vectors.
            float dotGridGradient(float ix, float iy, float x, float y) {

                // gradient vectors at each grid node
                float2 gradient = hash(float2(ix, iy));

                // Compute the distance vector
                float2 d = float2(x - ix, y - iy);
                
                // Compute the dot-product
                return dot(gradient, d);
            }

            float perlin(float x, float y) {
                // source of most:
                // https://www.shadertoy.com/view/XdXGW8

                // Determine grid cell coordinates
                float2 i = float2(floor(x), floor(y));
                float2 f = float2(fract(x), fract(y));

                // Interpolate between grid point gradients
                float s = dot(hash(i + float2(0,0)), f - float2(0,0));
                float t = dot(hash(i + float2(1,0)), f - float2(1,0));
                float v = dot(hash(i + float2(0,1)), f - float2(0,1));
                float u = dot(hash(i + float2(1,1)), f - float2(1,1));

                //float2 fd = float2(fade(f.x), fade(f.y));
                float2 fd = f;

                float w1 = lerp(s, t, fd.x);
                float w2 = lerp(v, u, fd.x);
                float value = lerp(w1, w2, fd.y);
                return value;
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float getColor(float2 co, int octaves, float persistence) {
                float total = 0;
                float frequency = _Frequency;
                float amplitude = 1;
                float maxValue = 0;  // Used for normalizing result to 0.0 - 1.0
                for(int i=0; i < octaves; i++) {
                    total += perlin(co.x * frequency, co.y * frequency) * amplitude;
                    
                    maxValue += amplitude;
                    
                    amplitude *= persistence;
                    frequency *= 2;
                }
                
                return total/maxValue;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 co = float2(i.uv.x, i.uv.y) *_Scale;

                float f = getColor(co.xy, (int)_Octaves, _Persistence);
                f = 0.5 + 0.5*f;

                fixed4 col = fixed4(f,f,f,1);
                return col;
            }
            ENDCG
        }
    }
}