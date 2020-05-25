Shader "Custom/Volumetric/Clouds (Try 3) (compute)"
{
    Properties
    {
        _Mask ("Mask", 2D) = "white" {}

        // [Header(Perlin)]
        // _PerlinScale ("Perlin Scale", vector) = (1,1,1,0)
        // _PerlinOffset ("Perlin Offset", vector) = (1,1,0,0)
        // _PerlinOctaves ("Perlin Octaves", Range(1,10)) = 1
        // _PerlinPersistance ("Perlin Persistence", Range(0.1, 1)) = 0.5
        // _PerlinFrequency ("Perlin Frequency", Range(0.1, 10)) = 1
        // _PerlinAmplitude ("Perlin Amplitude", Range(0.1, 10)) = 1
        // _PerlinMin ("Perlin Min", Range(0,1)) = 0
        // _PerlinMax ("Perlin Max", Range(0,1)) = 1
        // _PerlinBoost ("Perlin Boost", Range(0,1)) = 0
        // _PerlinDensityThreshold ("Density Threshold", Range(0,1)) = 0.2
        // _PerlinDensityMultiplier ("Density Multiplier", Range(0,5)) = 1
        
        // [Header(Voronoi)]
        // _VoronoiScale ("Scale", vector) = (1,1,1,0)
        // _VoronoiOffset ("Offset", vector) = (1,1,0,0)
        // _VoronoiOctaves ("Octaves", Range(1,10)) = 1
        // _VoronoiPersistance ("Persistence", Range(0.1, 1)) = 0.5
        // _VoronoiFrequency ("Frequency", Range(0.1, 10)) = 1
        // _VoronoiAmplitude ("Amplitude", Range(0.1, 10)) = 1
        // _VoronoiMin ("Min", Range(0,1)) = 0
        // _VoronoiMax ("Max", Range(0,1)) = 1
        // _VoronoiBoost ("Boost", Range(0,1)) = 0
        // _VoronoiDensityThreshold ("Density Threshold", Range(0,1)) = 0.2
        // _VoronoiDensityMultiplier ("Density Multiplier", Range(0,5)) = 1

        [Header(Raymarching)]
        _MaxSteps ("Max Steps", Range(0,40)) = 25

        [Header(Lightmarching)]
        _MaxLightSamples ("Max Light Samples", Range(0,40)) = 25
        _MaxLightSteps ("Max Light Steps", Range(0,10)) = 5
        _LightStepSize ("Light Step Size", Range(0,2)) = 0.1
        _SubSurfaceScatteringFade ("Sub-Surface Scattering Fade", Range(0,4)) = 1
        [Space]
        _SunLightScattering ("Sun Light Scattering", Range(0.1,0.5)) = 0.2
        _SunLightStrength ("Sun Light Strength", Range(0,5)) = 1
        _ShineThroughColor ("Sun Shine Through Color", Color) = (1,1,1,1)
        _IlluminationColor ("Global Illumination Color", Color) = (1,1,1,1)
        [Enum(Subtractive,0,Additive,2)] _IlluminationFactor ("Illumination Mode", int) = 0
        _DirectionalColor ("Sun Directional Color", Color) = (1,1,1,1)
        [Enum(Subtractive,0,Additive,2)] _DirectionalFactor ("Directional Mode", int) = 0

        [Header(Clouds)]
        _CloudColor ("Cloud Color", Color) = (1,1,1,1)
        _CloudDensityFactor ("Cloud Density Factor", Range(0,5)) = 1
        _CloudGapSize ("Cloud Gap Size", Range(1,10)) = 1
        _LightScatteringStrength ("Light Scattering Strength", Range(0,2)) = 0.5
        
        [Header(Horizon)]
        _HorizonMinDistance ("Horizon Min Distance", Range(1,200)) = 10
        _HorizonMaxDistance ("Horizon Max Distance", Range(1,200)) = 150
        _HorizonColor ("Horizon Color", Color) = (0,0,0,1)
        [Enum(Subtractive,0,Additive,2)] _HorzionAddFactor ("Darken Horizon", int) = 0

        [Space(2)]
        [Header(Unity Runtime Properties)]
        _T ("Time", Range(0,1)) = 0
        _BoundsMin ("Box Min Boundaries", vector) = (-2,-2,-2,0)
        _BoundsMax ("Box Max Boundaries", vector) = ( 2, 2, 2,0)
        _SunPosition ("Sun Position", vector) = (5, 5, 5, 0)
        _Offy ("_Offy", Vector) = (0,0,0,0)
    }
    SubShader
    {
        Tags { "Queue"="Transparent" "RenderType"="Transparent" "LightMode"="ForwardBase"}
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
            
            #define PI 3.1415926538
            #define EPSILON 0.01

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

            sampler2D _Mask;
            Texture3D<float4> _NoiseTexture;
            SamplerState sampler_NoiseTexture;

            float _T;

            int  _MaxSteps;
            int  _MaxLightSamples;
            int  _MaxLightSteps;
            float  _LightStepSize;
            float _SunLightScattering;
            float _SunLightStrength;

            float3 _BoundsMin;
            float3 _BoundsMax;
            float3  _SunPosition;
            fixed4 _CloudColor;
            float _LightScatteringStrength;
            float _SubSurfaceScatteringFade;
            int _IlluminationFactor;
            int _DirectionalFactor;

            fixed4 _HorizonColor;
            fixed4 _ShineThroughColor;
            fixed4 _DirectionalColor;
            fixed4 _IlluminationColor;
            int _HorzionAddFactor;
            float _HorizonMinDistance;
            float _HorizonMaxDistance;

            float  _CloudDensityFactor;
            float  _CloudGapSize;

            float3  _Offy;
            
            fixed2 worldToScreenPos(fixed3 pos){
                pos = normalize(pos - _WorldSpaceCameraPos)*(_ProjectionParams.y + (_ProjectionParams.z - _ProjectionParams.y))+_WorldSpaceCameraPos;
                fixed2 uv = 0;
                fixed3 toCam = mul(unity_WorldToCamera, pos);
                fixed camPosZ = toCam.z;
                fixed height = 2 * camPosZ / unity_CameraProjection._m11;
                fixed width = _ScreenParams.x / _ScreenParams.y * height;
                uv.x = (toCam.x + width / 2) / width;
                uv.y = (toCam.y + height / 2) / height;
                return uv;
            }

            float2 boxInfo(float3 boundsMin, float3 boundsMax, float3 rayOrigin, float3 rayDirection) {
                float3 t0 = (boundsMin - rayOrigin) / rayDirection;
                float3 t1 = (boundsMax - rayOrigin) / rayDirection;
                float3 tmin = min(t0, t1);
                float3 tmax = max(t0, t1);

                float dstA = max(max(tmin.x, tmin.y), tmin.z);
                float dstB = min(min(tmax.x, tmax.y), tmax.z);

                float distToBox = max(0, dstA);
                float distInsideBox = max(0, dstB - distToBox);
                return float2(distToBox, distInsideBox);
            }

            float sampleDensity(float3 position) {
                // float3 voronoiPosition = position * _VoronoiScale + _VoronoiOffset *_Time.y * _T;
                // float3 perlinPosition = position * _PerlinScale + _PerlinOffset * _Time.y * _T;
                // float voronoiDensity = smoothstep(_VoronoiMin, _VoronoiMax, getColorVoronoi(voronoiPosition, _VoronoiOctaves, _VoronoiPersistance)) + _VoronoiBoost;
                // float perlinDensity = smoothstep(_PerlinMin, _PerlinMax, getColorPerlin(perlinPosition, _PerlinOctaves, _PerlinPersistance)) + _PerlinBoost;

                // voronoiDensity = max(0, voronoiDensity - _VoronoiDensityThreshold) * _VoronoiDensityMultiplier;
                // perlinDensity = max(0, perlinDensity - _PerlinDensityThreshold) * _PerlinDensityMultiplier;

                // float density = voronoiDensity * perlinDensity * 2 /* fix boost */;
                // return density;
                return _NoiseTexture.SampleLevel(sampler_NoiseTexture, position - _BoundsMax, 0);
            }

            float lightmarch(float3 position, float3 direction) {
                float3 p = position;

                float lightTransmittance = 0;
                for (int j = 0; j < _MaxLightSteps; j++)
                {
                    p += direction * _LightStepSize;
                    lightTransmittance += sampleDensity(p);
                }

                return lightTransmittance;
            }

            float2 raymarch(float3 position, float3 direction)
            {
                float3 p = position;
                //float3 sunDirection = normalize(_WorldSpaceLightPos0); // sun direction
                float3 sunDirection = normalize(_SunPosition - position); // sun position

                float2 box = boxInfo(_BoundsMin, _BoundsMax, position, direction);
                float stepSize = box.y / _MaxSteps;
                float lightStepSize = box.y / _MaxLightSamples;

                if (stepSize <= 0)
                return fixed4(0,0,0,0);

                float density = 0;
                float lightTransmittance = 0;

                // Density samples.
                for (int i = 0; i < _MaxSteps; i++)
                {
                    density += sampleDensity(p) * stepSize;
                    p += direction * stepSize;
                }

                // early exit.
                if (density <= 0) {
                    return float2(density, 0);
                }
                
                // light samples.
                p = position;
                for (int j = 0; j < _MaxLightSamples; j++)
                {
                    p += direction * lightStepSize;
                    lightTransmittance += lightmarch(p, sunDirection);
                }

                return float2(density, lightTransmittance);
            }

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag(v2f i) : SV_Target
            {
                fixed mask = tex2D(_Mask, i.uv).r;

                float3 worldPosition = i.worldPos;
                float3 viewDirection = normalize(i.worldPos - _WorldSpaceCameraPos.xyz);

                float2 rm = raymarch(worldPosition, viewDirection);
                float cloudDensity = exp(-rm.x * 5);
                float lightTransmittance = exp(-rm.y);

                // get lighting colors.
                float projectedSunDistance = length(worldToScreenPos(_SunPosition) - worldToScreenPos(worldPosition));
                float sunTransmittance = 1 - pow(smoothstep(0.01, _SunLightScattering, projectedSunDistance), _SunLightStrength);
                float directionalLight = pow(lightTransmittance, _SubSurfaceScatteringFade);

                fixed3 shineThroughColor     = _ShineThroughColor.xyz * _ShineThroughColor.a * cloudDensity * sunTransmittance;
                fixed3 illuminationColor     = _IlluminationColor.xyz * _IlluminationColor.a * cloudDensity * _LightScatteringStrength * (_IlluminationFactor - 1);
                fixed3 directionalLightColor = _DirectionalColor.xyz  * _DirectionalColor.a  * cloudDensity * directionalLight * (_DirectionalFactor - 1);

                float cloudShade = pow(cloudDensity, _CloudDensityFactor * 0.01);

                float camDistance = length(worldPosition - _WorldSpaceCameraPos);

                // get cloud color.
                fixed r = cloudShade;
                fixed g = r;
                fixed b = r;
                fixed a = pow((1 - cloudDensity), _CloudGapSize) + (1 - cloudShade);

                fixed3 cloudColor = fixed3(saturate(r),saturate(g),saturate(b));
                fixed3 c = _CloudColor * cloudColor + shineThroughColor + illuminationColor + directionalLightColor;

                // apply horizon  distance coloring.
                float horizonFading = smoothstep(_HorizonMinDistance, _HorizonMaxDistance, camDistance);
                c += (_HorzionAddFactor - 1) * _HorizonColor * horizonFading * _HorizonColor.a;

                // combine.
                fixed4 col = fixed4(c.x, c.y, c.z, saturate(a * _CloudColor.a * mask));
                return col;
            }
            ENDCG
        }
    }
}