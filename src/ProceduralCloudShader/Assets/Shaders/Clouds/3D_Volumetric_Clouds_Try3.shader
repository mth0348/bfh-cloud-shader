Shader "Custom/Volumetric/Clouds (Try 3)"
{
    Properties
    {
        [Header(Perlin)]
        _PerlinScale ("Perlin Scale", Range(0.1,4)) = 3.0
        _PerlinOffset ("Perlin Offset", vector) = (1,1,0,0)
        _PerlinOctaves ("Perlin Octaves", Range(1,10)) = 1
        _PerlinPersistance ("Perlin Persistence", Range(0.1, 1)) = 0.5
        _PerlinFrequency ("Perlin Frequency", Range(0.1, 10)) = 1
        _PerlinAmplitude ("Perlin Amplitude", Range(0.1, 10)) = 1
        _PerlinMin ("Perlin Min", Range(0,1)) = 0
        _PerlinMax ("Perlin Max", Range(0,1)) = 1
        _PerlinBoost ("Perlin Boost", Range(0,1)) = 0
        _PerlinDensityThreshold ("Density Threshold", Range(0,1)) = 0.2
        _PerlinDensityMultiplier ("Density Multiplier", Range(0,5)) = 1
        
        [Header(Voronoi)]
        _VoronoiScale ("Scale", Range(0.1,4)) = 3.0
        _VoronoiOffset ("Offset", vector) = (1,1,0,0)
        _VoronoiOctaves ("Octaves", Range(1,10)) = 1
        _VoronoiPersistance ("Persistence", Range(0.1, 1)) = 0.5
        _VoronoiFrequency ("Frequency", Range(0.1, 10)) = 1
        _VoronoiAmplitude ("Amplitude", Range(0.1, 10)) = 1
        _VoronoiMin ("Min", Range(0,1)) = 0
        _VoronoiMax ("Max", Range(0,1)) = 1
        _VoronoiBoost ("Boost", Range(0,1)) = 0
        _VoronoiDensityThreshold ("Density Threshold", Range(0,1)) = 0.2
        _VoronoiDensityMultiplier ("Density Multiplier", Range(0,5)) = 1

        [Header(Raymarching)]
        _MaxSteps ("Max Steps", Range(0,200)) = 100

        [Header(Lightmarching)]
        _MaxLightSamples ("Max Light Samples", Range(0,40)) = 10
        _MaxLightSteps ("Max Light Steps", Range(0,10)) = 5
        _LightStepSize ("Light Step Size", Range(0,2)) = 0.1
        [Space]
        _SunLightScattering ("Sun Light Scattering", Range(0.1,0.5)) = 0.2
        _SunLightStrength ("Sun Light Strength", Range(0,5)) = 1
        
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

            float _PerlinScale;
            float3 _PerlinOffset;
            int _PerlinOctaves;
            float _PerlinPersistance;
            float _PerlinFrequency;
            float _PerlinAmplitude;
            float _PerlinMin;
            float _PerlinMax;
            float _PerlinBoost;
            float _PerlinDensityThreshold;
            float _PerlinDensityMultiplier;

            float _VoronoiScale;
            float3 _VoronoiOffset;
            int _VoronoiOctaves;
            float _VoronoiPersistance;
            float _VoronoiFrequency;
            float _VoronoiAmplitude;
            float _VoronoiMin;
            float _VoronoiMax;
            float _VoronoiBoost;
            float _VoronoiDensityThreshold;
            float _VoronoiDensityMultiplier;

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

            fixed4 _HorizonColor;
            int _HorzionAddFactor;
            float _HorizonMinDistance;
            float _HorizonMaxDistance;

            float  _CloudDensityFactor;
            float  _CloudGapSize;
            
            float fract(float x) {
                return x - floor(x);
            }

            float random(float v) {
                return fract(sin(v) * 43758.5453123);
            }

            float sigmoid(float a) {
                return 1 / (1 + exp(-a));
            }

            fixed2 WorldToScreenPos(fixed3 pos){
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

            static int permutation[] = { 151,160,137,91,90,15,
                131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
                190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
                88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
                77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
                102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
                135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
                5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
                223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
                129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
                251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
                49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
                138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
                151,160,137,91,90,15,
                131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
                190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
                88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
                77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
                102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
                135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
                5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
                223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
                129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
                251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
                49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
                138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
            };

            float gradientDotV(uint hash, float x, float y, float z) {
                switch (hash & 15) { 
                    case  0: return  x + y; // (1,1,0) 
                    case  1: return -x + y; // (-1,1,0) 
                    case  2: return  x - y; // (1,-1,0) 
                    case  3: return -x - y; // (-1,-1,0) 
                    case  4: return  x + z; // (1,0,1) 
                    case  5: return -x + z; // (-1,0,1) 
                    case  6: return  x - z; // (1,0,-1) 
                    case  7: return -x - z; // (-1,0,-1) 
                    case  8: return  y + z; // (0,1,1), 
                    case  9: return -y + z; // (0,-1,1), 
                    case 10: return  y - z; // (0,1,-1), 
                    case 11: return -y - z; // (0,-1,-1) 
                    case 12: return  y + x; // (1,1,0) 
                    case 13: return -x + y; // (-1,1,0) 
                    case 14: return -y + z; // (0,-1,1) 
                    case 15: return -y - z; // (0,-1,-1) 
                } 
                return 0;
            }

            float fade(float t) { 
                return t * t * t * (t * (t * 6 - 15) + 10);
            }

            uint hash(int x, int y, int z)
            {
                return permutation[permutation[permutation[x] + y] + z];
            }

            float perlin(float3 p) {

                int xi0 = ((int)floor(p.x)) & 255; 
                int yi0 = ((int)floor(p.y)) & 255; 
                int zi0 = ((int)floor(p.z)) & 255; 
                
                int xi1 = (xi0 + 1) & 255; 
                int yi1 = (yi0 + 1) & 255; 
                int zi1 = (zi0 + 1) & 255; 
                
                float tx = p.x - ((int)floor(p.x)); 
                float ty = p.y - ((int)floor(p.y)); 
                float tz = p.z - ((int)floor(p.z)); 
                
                float u = fade(tx); 
                float v = fade(ty); 
                float w = fade(tz); 
                
                // generate vectors going from the grid points to p
                float x0 = tx, x1 = tx - 1; 
                float y0 = ty, y1 = ty - 1; 
                float z0 = tz, z1 = tz - 1; 
                
                float a = gradientDotV(hash(xi0, yi0, zi0), x0, y0, z0); 
                float b = gradientDotV(hash(xi1, yi0, zi0), x1, y0, z0); 
                float c = gradientDotV(hash(xi0, yi1, zi0), x0, y1, z0); 
                float d = gradientDotV(hash(xi1, yi1, zi0), x1, y1, z0); 
                float e = gradientDotV(hash(xi0, yi0, zi1), x0, y0, z1); 
                float f = gradientDotV(hash(xi1, yi0, zi1), x1, y0, z1); 
                float g = gradientDotV(hash(xi0, yi1, zi1), x0, y1, z1); 
                float h = gradientDotV(hash(xi1, yi1, zi1), x1, y1, z1); 

                float du = fade(tx); 
                float dv = fade(ty); 
                float dw = fade(tz); 
                
                float k0 = a; 
                float k1 = (b - a); 
                float k2 = (c - a); 
                float k3 = (e - a); 
                float k4 = (a + d - b - c); 
                float k5 = (a + f - b - e); 
                float k6 = (a + g - c - e); 
                float k7 = (b + c + e + h - a - d - f - g); 
                
                // derivs.x = du *(k1 + k4 * v + k5 * w + k7 * v * w); 
                // derivs.y = dv *(k2 + k4 * u + k6 * w + k7 * v * w); 
                // derivs.z = dw *(k3 + k5 * u + k6 * v + k7 * v * w); 
                
                return k0 + k1 * u + k2 * v + k3 * w + k4 * u * v + k5 * u * w + k6 * v * w + k7 * u * v * w; 
            } 

            float3 random3d3d(float3 co) {
                return float3(
                fract(sin(dot(co, float3(12.989, 78.233, 37.719))) * 43758.5453123),
                fract(sin(dot(co, float3(39.346, 11.135, 83.155))) * 14375.8545346),
                fract(sin(dot(co, float3(73.156, 52.235, 09.151))) * 31396.2234116));
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

            float voronoi(float3 p) {
                float3 i = floor(p);

                float dmin = 100;
                for(int x=-1; x<=1; x++){
                    for(int y=-1; y<=1; y++){
                        for(int z=-1; z<=1; z++){
                            float3 cell = i + float3(x, y, z);
                            float3 seed = cell + random3d3d(cell);
                            float d = length(seed - p);
                            if (d < dmin) {
                                dmin = d;
                            }
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
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            float getColorVoronoi(float3 co, int octaves, float persistence) {
                float total = 0;
                float lacunarity = 2.0;
                float frequency = _VoronoiFrequency;
                float amplitude = _VoronoiAmplitude;
                float maxValue = 0;  // Used for normalizing result to 0.0 - 1.0
                for(int i=0; i < octaves; i++) {
                    float current = voronoi(co * frequency) * amplitude;
                    total += current;
                    maxValue += amplitude;
                    
                    amplitude *= persistence;
                    frequency *= lacunarity;
                }
                
                return 1-total/maxValue;
            }

            float getColorPerlin(float3 co, int octaves, float persistence) {
                float total = 0;
                float lacunarity = 2.0;
                float frequency = _PerlinFrequency;
                float amplitude = _PerlinAmplitude;
                float maxValue = 0;  // Used for normalizing result to 0.0 - 1.0
                for(int i=0; i < octaves; i++) {
                    float current = perlin(co * frequency) * amplitude;
                    total += current;
                    maxValue += amplitude;
                    
                    amplitude *= persistence;
                    frequency *= lacunarity;
                }
                
                return total/maxValue;
            }

            float sampleDensity(float3 position) {
                float3 voronoiPosition = position * _VoronoiScale + _VoronoiOffset *_Time.y * _T;
                float3 perlinPosition = position * _PerlinScale + _PerlinOffset * _Time.y * _T;
                float voronoiDensity = smoothstep(_VoronoiMin, _VoronoiMax, getColorVoronoi(voronoiPosition, _VoronoiOctaves, _VoronoiPersistance)) + _VoronoiBoost;
                float perlinDensity = smoothstep(_PerlinMin, _PerlinMax, getColorPerlin(perlinPosition, _PerlinOctaves, _PerlinPersistance)) + _PerlinBoost;

                voronoiDensity = max(0, voronoiDensity - _VoronoiDensityThreshold) * _VoronoiDensityMultiplier;
                perlinDensity = max(0, perlinDensity - _PerlinDensityThreshold) * _PerlinDensityMultiplier;

                float density = voronoiDensity * perlinDensity * 2 /* fix boost */;
                return density;
            }

            float3 estimateNormal(float3 p) {
                return normalize(float3(
                sampleDensity(float3(p.x + EPSILON, p.y, p.z)) - sampleDensity(float3(p.x - EPSILON, p.y, p.z)),
                sampleDensity(float3(p.x, p.y + EPSILON, p.z)) - sampleDensity(float3(p.x, p.y - EPSILON, p.z)),
                sampleDensity(float3(p.x, p.y, p.z + EPSILON)) - sampleDensity(float3(p.x, p.y, p.z - EPSILON))
                ));
            }

            float lightmarch(float3 position, float3 direction) {
                float3 p = position;

                float lightTransmittance = 0;
                for (int j = 0; j < _MaxLightSteps; j++)
                {
                    lightTransmittance += sampleDensity(p);
                    p += direction * _LightStepSize;
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
                
                // light samples.
                p = position;
                for (int j = 0; j < _MaxLightSamples; j++)
                {
                    p += direction * lightStepSize;
                    lightTransmittance += lightmarch(p, sunDirection);
                }

                return float2(density, lightTransmittance);
            }

            fixed4 frag(v2f i) : SV_Target
            {
                float3 worldPosition = i.worldPos;
                float3 viewDirection = normalize(i.worldPos - _WorldSpaceCameraPos.xyz);

                float2 rm = raymarch(worldPosition, viewDirection);
                float cloudDensity = exp(-rm.x * 5);
                float lightTransmittance = exp(-rm.y);

                // get sun color.
                float projectedSunDistance = length(WorldToScreenPos(_SunPosition) - WorldToScreenPos(worldPosition));
                float sunTransmittance = 1 - pow(smoothstep(0.01, _SunLightScattering, projectedSunDistance), _SunLightStrength);
                fixed3 sunColor = sunTransmittance * _LightColor0.xyz * cloudDensity;
                fixed3 lightScattering = _LightColor0.xyz * cloudDensity * _LightScatteringStrength;
                fixed3 sunFacing = _LightColor0.xyz * cloudDensity * lightTransmittance;

                float cloudShade = pow(cloudDensity, _CloudDensityFactor * 0.01);

                float camDistance = length(worldPosition - _WorldSpaceCameraPos);

                // get cloud color.
                fixed r = cloudShade;
                fixed g = r;
                fixed b = r;
                fixed a = pow((1 - cloudDensity), _CloudGapSize) + (1 - cloudShade);

                fixed3 cloudColor = fixed3(saturate(r),saturate(g),saturate(b));
                fixed3 c = _CloudColor * cloudColor + sunColor + lightScattering + sunFacing;

                // apply horizon  distance coloring.
                c += (_HorzionAddFactor - 1) * _HorizonColor * smoothstep(_HorizonMinDistance, _HorizonMaxDistance, camDistance) * _HorizonColor.a;

                // combine.
                fixed4 col = fixed4(c.x, c.y, c.z, saturate(a * _CloudColor.a));
                return col;
            }
            ENDCG
        }
    }
}