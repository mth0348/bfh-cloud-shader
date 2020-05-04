Shader "Custom/Noise/3D/FBM"
{
    Properties
    {
        [Header(Noise Generation)]
        _Octaves ("Octaves", Range(1,10)) = 1
        _Amplitude ("Amplitude", Range(0.1, 1)) = 0.5
        _Scale ("Scale", Range(0.1, 10)) = 1
        _Offset ("Offset", Vector) = (0,0,0,0)
        _Min ("Min", Range(0,1)) = 0
        _Max ("Max", Range(0,1)) = 1
        _Threshold ("Threshold", Range(0,1)) = 0.1
        _Boost ("Boost", Range(0,1)) = 0
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" }
        LOD 100

        Pass
        {
            ZWrite Off
            Blend SrcAlpha OneMinusSrcAlpha

            CGPROGRAM
            #pragma vertex vert
            #pragma fragment frag

            #include "UnityCG.cginc"
            #include "UnityLightingCommon.cginc"

            #define MAX_STEPS 300
            #define SURFACE_DISTANCE 0.0001
            #define MAX_DISTANCE 100
            #define EPSILON 0.01

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;
            float _ShadowIntensity;
            float _ShadowMinDistance;
            float _ShadowMaxDistance;
            float _ShadowPenubra;
            float _ShapeBlend;
            float _AOStepSize;
            float _AOIterations;
            float _AOIntensity;
            float _Amplitude;
            float _Octaves;
            float _Scale;
            float3 _Offset;
            float _Min;
            float _Max;
            float _Threshold;
            float _StepSize;
            float3 _BoundsMin;
            float3 _BoundsMax;
            float _StepCount;
            float3 _ViewDirection;
            float _Boost;

            struct appdata
            {
                float2 uv : TEXCOORD0;
                float4 vertex : POSITION;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos : TEXCOORD1;
            };

            v2f vert(appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float  blend(float d1 , float3 d2 , float k) {
                return k * d1 + (1 - k) * d2;
            }
            
            float fract(float x) {
                return x - floor(x);
            }

            float random (float3 st) {
                return fract(sin(dot(st, float3(12.9898, 78.233, 37.719))) * 43758.5453123);
            }

            float mix(float x, float y, float a) {
                return x * (1 - a) + y * a;
            }

            // Based on Morgan McGuire @morgan3d
            // https://www.shadertoy.com/view/4dS3Wd
            float noise (float3 st) {
                st = st * _Scale + _Offset;
                float3 i = floor(st);
                float3 f = st - i;

                // Eight corners in 3D of a tile
                float x0y0z0 = random(i + float3(0, 0, 0));
                float x0y0z1 = random(i + float3(0, 0, 1));
                float x0y1z0 = random(i + float3(0, 1, 0));
                float x0y1z1 = random(i + float3(0, 1, 1));
                float x1y0z0 = random(i + float3(1, 0, 0));
                float x1y0z1 = random(i + float3(1, 0, 1));
                float x1y1z0 = random(i + float3(1, 1, 0));
                float x1y1z1 = random(i + float3(1, 1, 1));

                float3 u = f * f * (3.0 - 2.0 * f);

                return mix(
                mix(mix(x0y0z0, x1y0z0, u.x), mix(x0y0z1, x1y0z1, u.x), u.z),
                mix(mix(x0y1z0, x1y1z0, u.x), mix(x0y1z1, x1y1z1, u.x), u.z), u.y);
            }

            float fbm(float3 st) {
                // Initial values
                float value = 0.0;
                float amplitude = _Amplitude;
                //
                // Loop of octaves
                for (int i = 0; i < _Octaves; i++) {
                    value += amplitude * noise(st * _Scale + _Offset);
                    st *= 2.;
                    amplitude *= .5;
                }
                return max(value - _Threshold, 0);
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 c = fixed3(1,1,1) * fbm(i.worldPos) + _Boost;
                return fixed4(c,1);
            }
            ENDCG
        }
    }
}
