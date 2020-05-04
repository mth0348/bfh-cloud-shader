Shader "Custom/Noise/2D/Voronoi"
{
    Properties
    {
        _Scale ("Scale", float) = 3.0
        _Offset ("Offset", vector) = (1,1,0,0)
        _Octaves ("Octaves", Range(1,10)) = 1
        _Persistence ("Persistence", Range(0.1, 2)) = 0.5
        _Frequency ("Frequency", Range(0.1, 10)) = 1
        _Amplitude ("_Amplitude", Range(0.1, 10)) = 1
        _Min ("Min", Range(0,1)) = 0
        _Max ("Max", Range(0,1)) = 1
        _Boost ("Boost", Range(0,1)) = 0

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
            float _Amplitude;
            float _Min;
            float _Max;
            float _Boost;

            float fract(float x) {
                return x - floor(x);
            }

            float fract2(float2 x) {
                return float2(fract(x.x), fract(x.y));
            }

            float random(float v) {
                return fract(sin(v) * 43758.5453123);
            }

            float random2d(float2 co) {
                return fract(sin(dot(co, float2(12.9898,78.233))) * 43758.5453123);
            }

            float random2d2d(float2 co) {
                return float2(
                    fract(sin(dot(co, float2(12.9898,78.233))) * 43758.5453123),
                    fract(sin(dot(co, float2(39.346, 11.135))) * 143758.5453));
            }

            float2 randomSeed(float2 s) {
                if (s.x == 0 && s.y == 0) return float2(0.3, 0.2);
                if (s.x == 1 && s.y == 0) return float2(0.4, 0.8);
                if (s.x == 2 && s.y == 0) return float2(0.7, 0.1);
                if (s.x == 0 && s.y == 1) return float2(0.4, 0.6);
                if (s.x == 1 && s.y == 1) return float2(0.6, 0.5);
                if (s.x == 2 && s.y == 1) return float2(0.4, 0.1);
                if (s.x == 0 && s.y == 2) return float2(0.1, 0.7);
                if (s.x == 1 && s.y == 2) return float2(0.7, 0.2);
                if (s.x == 2 && s.y == 2) return float2(0.9, 0.4);
                return float2(0,0);
            }


            float voronoi(float2 p) {
                float2 i = floor(p);

                float dmin = 10;
                for(int x=-1; x<=1; x++){
                    for(int y=-1; y<=1; y++){
                        float2 cell = i + float2(x, y);
                        float2 seed = cell + randomSeed(cell);
                        float d = length(seed - p);
                        if (d < dmin) {
                            dmin = d;
                        }
                    }
                }
                
                return dmin;
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
                float amplitude = _Amplitude;
                float maxValue = 0;  // Used for normalizing result to 0.0 - 1.0
                for(int i=0; i < octaves; i++) {
                    float current = voronoi(co * frequency) * amplitude;
                    total += current;
                    maxValue += amplitude;
                    
                    amplitude *= persistence;
                    frequency *= 2;
                }
                
                return total/maxValue*1;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float2 co = float2(i.uv.x, i.uv.y) *_Scale + _Offset;

                float f = getColor(co.xy, (int)_Octaves, _Persistence);
                f = 0.5 + 0.5*f;

                fixed4 col = fixed4(0,0,0,1);
                col += smoothstep(_Min, _Max, f);
                return 1 - col + _Boost;
            }
            ENDCG
        }
    }
}