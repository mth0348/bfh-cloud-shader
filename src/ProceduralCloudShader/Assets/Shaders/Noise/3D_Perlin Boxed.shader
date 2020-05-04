Shader "Custom/3D_Perlin Boxed"
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

            float mix(float x, float y, float a) {
                return x * (1 - a) + y * a;
            }
            
            float fract(float x) {
                return x - floor(x);
            }

            float random (float3 st) {
                return fract(sin(dot(st, float3(12.9898, 78.233, 37.719))) * 43758.5453123);
            }

            float3 hash(float3 p){
                float3 k = float3( 3.1415926, 2.71828,6.62607015);
                p = p*k + p.yzx;
                return -1.0 + 2.0*fract( 2.0 * k * fract( p.x*p.y*(p.x+p.y)) );
            }

            float fade(float t) {
                return t * t * t * (t * (t * 6 - 15) + 10);
            }


            // float perlin(float3 p) {
                //     // source of most:
                //     // https://www.shadertoy.com/view/XdXGW8

                //     // Determine grid cell coordinates
                //     float3 i = float3(floor(p.x), floor(p.y), floor(p.z));
                //     float3 f = float3(fract(p.x), fract(p.y), fract(p.z));

                //     // Interpolate between grid point gradients
                //     float s1 = dot(hash(i + float3(0, 0, 0)), f - float3(0, 0, 0));
                //     float s2 = dot(hash(i + float3(1, 0, 0)), f - float3(1, 0, 0));
                //     float s3 = dot(hash(i + float3(1, 0, 1)), f - float3(1, 0, 1));
                //     float s4 = dot(hash(i + float3(0, 0, 1)), f - float3(0, 0, 1));
                //     float t1 = dot(hash(i + float3(0, 1, 0)), f - float3(0, 1, 0));
                //     float t2 = dot(hash(i + float3(1, 1, 0)), f - float3(1, 1, 0));
                //     float t3 = dot(hash(i + float3(1, 1, 1)), f - float3(1, 1, 1));
                //     float t4 = dot(hash(i + float3(0, 1, 1)), f - float3(0, 1, 1));

                //     float3 fd = float3(fade(f.x), fade(f.y), fade(f.z));
                //     //float2 fd = f;

                //     float w1 = lerp(s1, s2, fd.x);
                //     float w2 = lerp(s4, s3, fd.x);
                //     float w3 = lerp(t1, t2, fd.x);
                //     float w4 = lerp(t4, t3, fd.x);
                //     float w5 = lerp(w1, w2, fd.z);
                //     float w6 = lerp(w3, w4, fd.z);
                //     float value = lerp(w5, w5, fd.y);
                //     return max(0, value - _Threshold);
            // }

            float perlin(float3 st){
                float3 i = floor(st);
                float3 f = st - i;
                float3 u = f*f*f*(f*(f*6.0-15.0)+10.0);
                
                //随机梯度
                float3 g1 = hash(i+float3(0.0,0.0,0.0));
                float3 g2 = hash(i+float3(1.0,0.0,0.0));
                float3 g3 = hash(i+float3(0.0,1.0,0.0));
                float3 g4 = hash(i+float3(1.0,1.0,0.0));
                float3 g5 = hash(i+float3(0.0,0.0,1.0));
                float3 g6 = hash(i+float3(1.0,0.0,1.0));
                float3 g7 = hash(i+float3(0.0,1.0,1.0));
                float3 g8 = hash(i+float3(1.0,1.0,1.0));
                
                //方向向量
                float3 d1 = f - float3(0.0,0.0,0.0);
                float3 d2 = f - float3(1.0,0.0,0.0);
                float3 d3 = f - float3(0.0,1.0,0.0);
                float3 d4 = f - float3(1.0,1.0,0.0);
                float3 d5 = f - float3(0.0,0.0,1.0);
                float3 d6 = f - float3(1.0,0.0,1.0);
                float3 d7 = f - float3(0.0,1.0,1.0);
                float3 d8 = f - float3(1.0,1.0,1.0);
                
                //点积求权重
                float n1 = dot(g1, d1);
                float n2 = dot(g2, d2);
                float n3 = dot(g3, d3);
                float n4 = dot(g4, d4);
                float n5 = dot(g5, d5);
                float n6 = dot(g6, d6);
                float n7 = dot(g7, d7);
                float n8 = dot(g8, d8);
                
                //加权求和
                float a = mix(n1,n2,u.x);
                float b = mix(n3,n4,u.x);
                float c1 = mix(a,b,u.y);
                a = mix(n5,n6,u.x);
                b = mix(n7,n8,u.x);
                float c2 = mix(a,b,u.y);
                float c = mix(c1,c2,u.z);
                
                return max(0, c - _Threshold);
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

            float noise(float3 p){
                p = p * _Scale + _Offset;
                float f = 0.;
                f += 1.0 * abs(perlin(p)); p=2.*p;
                f += 0.5 * abs(perlin(p)); p=2.*p;
                f += 0.25 * abs(perlin(p)); p=2.*p;
                f += 0.125 * abs(perlin(p)); p=2.*p;
                f += 0.0625 * perlin(p); p=2.*p;
                return f;
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
                    totalDensity += noise(rayPos) * stepSize;
                    distTravelled += stepSize;
                }

                bool insideBox = distInsideBox > 0 && distToBox < depth;
                float val = exp(-totalDensity);
                // if (insideBox) {
                    //     col = 1;
                // }
                
                return col * smoothstep(_Min, _Max, val);
            }
            ENDCG
        }
    }
}
