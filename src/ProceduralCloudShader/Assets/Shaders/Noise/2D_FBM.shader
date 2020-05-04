Shader "Custom/Noise/2D/FBM"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        _Octaves ("Octaves", Range(1,10)) = 1
        _Amplitude ("Amplitude", Range(0.1, 10)) = 1
        _Scale ("Scale", Range(0.1, 10)) = 1
        _Offset ("Offset", Vector) = (0,0,0,0)
        _Min ("Min", Range(0,1)) = 0
        _Max ("Max", Range(0,1)) = 1
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

            #include "UnityCG.cginc"

            float _Amplitude;
            float _Octaves;
            float _Scale;
            float2 _Offset;
            float _Min;
            float _Max;

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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                return o;
            }

            float fract(float x) {
                return x - floor(x);
            }

            float random (float2 st) {
                return fract(sin(dot(st.xy, float2(12.9898,78.233))) * 43758.5453123);
            }

            float mix(float x, float y, float a) {
                return x * (1 - a) + y * a;
            }

            // Based on Morgan McGuire @morgan3d
            // https://www.shadertoy.com/view/4dS3Wd
            float noise (float2 st) {
                float2 i = floor(st);
                float2 f = st - i;

                // Four corners in 2D of a tile
                float a = random(i);
                float b = random(i + float2(1.0, 0.0));
                float c = random(i + float2(0.0, 1.0));
                float d = random(i + float2(1.0, 1.0));

                float2 u = f * f * (3.0 - 2.0 * f);

                return mix(a, b, u.x) +
                (c - a)* u.y * (1.0 - u.x) +
                (d - b) * u.x * u.y;
            }

            float fbm (in float2 st) {
                // Initial values
                float value = 0.0;
                float amplitude = _Amplitude;
                //
                // Loop of octaves
                for (int i = 0; i < _Octaves; i++) {
                    value += amplitude * noise(st);
                    st *= 2.;
                    amplitude *= .5;
                }
                return value;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 color = fixed4(0,0,0,1);
                float c = fbm(i.uv * _Scale + _Offset);
                color += smoothstep(_Min, _Max, c);
                return color;
            }
            ENDCG
        }
    }
}
