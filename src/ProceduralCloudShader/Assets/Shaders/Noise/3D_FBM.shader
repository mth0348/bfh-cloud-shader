Shader "Unlit/2D_FBM"
{
    Properties
    {
        
        [Header(Shadow Casting)]
        _ShadowIntensity("Shadow Intensity", Range(0,4)) = 0.5
        _ShadowMinDistance("Shadow Min Distance", float) = 0.1
        _ShadowMaxDistance("Shadow Max Distance", float) = 100
        _ShadowPenubra("Shadow Penubra", Range(1,128)) = 1

        [Header(Shape Blending)]
        _ShapeBlend("Shape Blend Factor", Range(0,1)) = 1

        [Header(Ambient Occlusion)]
        _AOStepSize("Step Size", Range(0.01,1)) = 0.1
        _AOIterations("Iterations", Range(1, 128)) = 10
        _AOIntensity("Intensity", Range(0, 0.5)) = 1

        [Header(Noise Generation)]
        _Octaves ("Octaves", Range(1,10)) = 1
        _Amplitude ("Amplitude", Range(0.1, 1)) = 0.5
        _Scale ("Scale", Range(0.1, 10)) = 1
        _Offset ("Offset", Vector) = (0,0,0,0)
        _Min ("Min", Range(0,1)) = 0
        _Max ("Max", Range(0,1)) = 1
        _Threshold ("Threshold", Range(0,1)) = 0.1
        _StepSize ("_StepSize", Range(0,2)) = 0.5
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

            #define MAX_STEPS 100
            #define SURFACE_DISTANCE 0.0001
            #define MAX_DISTANCE 100
            #define EPSILON 0.01

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

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
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
                o.uv = v.uv;
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
                    value += amplitude * noise(st);
                    st *= 2.;
                    amplitude *= .5;
                }
                return value;
            }

            float sceneSDF(float3 position) {
                float f = fbm(position * _Scale + _Offset);
                if (f < _Threshold && distance(_WorldSpaceCameraPos, position) > 1)
                    return 0;
                return 1;
            }

            float3 estimateNormal(float3 p) {
                return normalize(float3(
                sceneSDF(float3(p.x + EPSILON, p.y, p.z)) - sceneSDF(float3(p.x - EPSILON, p.y, p.z)),
                sceneSDF(float3(p.x, p.y + EPSILON, p.z)) - sceneSDF(float3(p.x, p.y - EPSILON, p.z)),
                sceneSDF(float3(p.x, p.y, p.z + EPSILON)) - sceneSDF(float3(p.x, p.y, p.z - EPSILON))
                ));
            }

            float raymarch(float3 position, float3 direction)
            {
                float dOrigin = 0.0;
                for (int i = 0; i < MAX_STEPS; i++) {
                    float dScene = sceneSDF(position + direction * dOrigin);
                    if (dScene < SURFACE_DISTANCE || dScene > MAX_DISTANCE)
                    break;
                    
                    dOrigin += _StepSize;
                }
                return dOrigin;
            }

            float hardshadow(float3 position, float3 direction, float minDistance, float maxDistance)
            {
                float dOrigin = minDistance;
                for (int i = 0; i < MAX_STEPS; i++) {
                    float dScene = sceneSDF(position + direction * dOrigin);
                    if (dScene < SURFACE_DISTANCE)
                    return 0;
                    if (dScene > maxDistance)
                    return 1;
                    
                    dOrigin += dScene;
                }
                return 1;
            }

            float softshadow(float3 position, float3 direction, float minDistance, float maxDistance, float k)
            {
                float result = 1.0;
                float dOrigin = minDistance;
                for (int i = 0; i < MAX_STEPS; i++) {
                    float dScene = sceneSDF(position + direction * dOrigin);
                    if (dScene < SURFACE_DISTANCE)
                    return 0;
                    if (dOrigin > maxDistance)
                    return result;
                    
                    result = min(result, k * dScene / dOrigin);
                    dOrigin += dScene;
                }
                return result;
            }

            float ambientOcclusion(float3 position, float3 direction) {
                float ao = 0;
                float dOrigin = 0;

                for (int i = 1; i <= _AOIterations; i++) {
                    dOrigin = _AOStepSize * i;
                    ao += max(0, dOrigin - sceneSDF(position + direction * dOrigin)) / dOrigin;
                }
                return 1 - ao * _AOIntensity;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                fixed3 color = fixed3(0,0,0);
                
                float3 worldPosition = i.worldPos;
                float3 viewDirection = normalize(i.worldPos - _WorldSpaceCameraPos.xyz);
                float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);

                float3 hitPoint = float3(0,0,0);

                float distance = raymarch(_WorldSpaceCameraPos.xyz, viewDirection);
                if (distance <= 0)
                distance = raymarch(_WorldSpaceCameraPos.xyz, viewDirection);
                
                hitPoint = _WorldSpaceCameraPos.xyz + viewDirection * distance;
                // float3 normal = estimateNormal(hitPoint);

                // // lighting.
                // fixed3 ambient = _LightColor0 * 0.2;
                // fixed3 diffuse = max(dot(normal, lightDirection), 0.0);
                // fixed3 specular = 0.1 * pow(max(dot(viewDirection, reflect(lightDirection, normal)), 0.0), 32) * _LightColor0;
                // //color *= ambient + diffuse + specular;

                // // shadows.
                // float shadow = softshadow(hitPoint, lightDirection, _ShadowMinDistance, _ShadowMaxDistance, _ShadowPenubra) * 0.5 + 0.5;
                // //color *= pow(shadow, _ShadowIntensity);

                // // ambient occlusion.
                // float ao = ambientOcclusion(hitPoint, normal);
                // //color *= ao;

                float f = fbm(hitPoint * _Scale + _Offset);
                color = smoothstep(_Min, _Max, f);
                
                return fixed4(color, 1);
            }
            ENDCG
        }
    }
}
