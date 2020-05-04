Shader "Custom/3D_FBM Boxed"
{
    Properties
    {
        _MainTex ("Texture", 2D) = "white" {}
        
        _ViewDirection ("View Direction", Vector) = (0,0,1,0)
        _BoundsMin ("BoundsMin", Vector) = (0,0,0,0)
        _BoundsMax ("BoundsMax", Vector) = (0,0,0,0)

        [Header(Noise Generation)]
        _Octaves ("Octaves", Range(1,10)) = 1
        _Amplitude ("Amplitude", Range(0.1, 1)) = 0.5
        _Scale ("Scale", Range(0.1, 10)) = 1
        _Offset ("Offset", Vector) = (0,0,0,0)
        _Min ("Min", Range(0,1)) = 0
        _Max ("Max", Range(0,1)) = 1
        _Threshold ("Threshold", Range(0,1)) = 0.1
        _StepCount ("StepCount", Range(1,200)) = 1
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
            // make fog work
            #pragma multi_compile_fog

            #include "UnityCG.cginc"

            sampler2D _MainTex;
            float4 _MainTex_ST;
            sampler2D _CameraDepthTexture;

            float3 _BoundsMin;
            float3 _BoundsMax;

            float _Amplitude;
            float _Octaves;
            float _Scale;
            float3 _Offset;
            float _Min;
            float _Max;
            float _Threshold;
            float _StepCount;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 viewVector : TEXCOORD1;

            };
            
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

            float2 rayBoxDist(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDirection) {
                float3 t0 = (boundsMin - rayOrigin) / rayDirection;
                float3 t1 = (boundsMax - rayOrigin) / rayDirection;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(tmax.x, min(tmax.y, tmax.z));

                float dstToBox = max(0, dstA);
                float dstInsideBox = max(0, dstB - dstToBox);
                return float2(dstToBox, dstInsideBox);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = TRANSFORM_TEX(v.uv, _MainTex);
                float3 viewVector = mul(unity_CameraInvProjection, float4(v.uv * 2 - 1, 0, -1));
                o.viewVector = mul(unity_CameraToWorld, float4(viewVector,0));

                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed4 col = tex2D(_MainTex, i.uv);
                float3 viewDirection = normalize(i.viewVector);

                float2 rayBoxInfo = rayBoxDist(_BoundsMin, _BoundsMax, _WorldSpaceCameraPos, i.viewVector);
                float distToBox = rayBoxInfo.x;
                float distInsideBox = rayBoxInfo.y;

                float nonLinearDepth = SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv);
                float depth = LinearEyeDepth(nonLinearDepth) * length(i.viewVector);

                float distTravelled = 0;
                float totalDensity = 0;
                float stepSize = distInsideBox / _StepCount;
                float distLimit = min(depth - distToBox, distInsideBox);

                while (distTravelled < distLimit) {
                    float3 rayPos = _WorldSpaceCameraPos + viewDirection * (distToBox + distTravelled);
                    totalDensity += fbm(rayPos) * stepSize;
                    distTravelled += stepSize;
                }

                bool insideBox = distInsideBox > 0 && distToBox < depth;
                float val = exp(-totalDensity);
                // if (insideBox) {
                //     col = 1;
                // }
                
                return col * val;
            }
            ENDCG
        }
    }
}
