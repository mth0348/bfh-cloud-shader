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

            float grid(float2 st, float res)
            {
                float2 grid = fract(st * res);
                return 1 - (step(res, grid.x) * step(res, grid.y));
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
                fixed4 col = fixed4(1,1,1,1)*grid(i.uv * 200, 0.05);
                col += fixed4(1,1,1,1)*grid(i.uv.yx * 200, 0.05);
                return col;
            }
            ENDCG
        }
    }
}
