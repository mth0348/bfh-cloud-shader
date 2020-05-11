Shader "Custom/Noise/3D/Perlin"
{
    Properties
    {
        _Scale ("Scale", float) = 1.0
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

            #include "UnityCG.cginc"
            
            #define PI 3.1415926538

            float _Scale;
            float3 _Offset;
            int _Octaves;
            float _Persistence;
            float _Frequency;
            float _Amplitude;
            float _Min;
            float _Max;
            float _Boost;

            struct appdata
            {
                float4 vertex : POSITION;
                float2 uv : TEXCOORD0;
            };

            struct v2f
            {
                float2 uv : TEXCOORD0;
                float4 vertex : SV_POSITION;
                float3 worldPos: TEXCOORD1;
            };

            float fract(float x) {
                return x - floor(x);
            }

            float random(float v) {
                return fract(sin(v+2.45647) * 43758.5453123);
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

            float getColor(float3 co, int octaves, float persistence) {
                float total = 0;
                float lacunarity = 2.0;
                float frequency = _Frequency;
                float amplitude = _Amplitude;
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

            v2f vert (appdata v)
            {
                v2f o;
                o.vertex = UnityObjectToClipPos(v.vertex);
                o.uv = v.uv;
                o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
                return o;
            }

            fixed4 frag (v2f i) : SV_Target
            {
                float3 co = float3(i.worldPos.x, i.worldPos.y, i.worldPos.z) *_Scale + _Offset;
                //float3 co = float3(i.worldPos.x+_Time.y, i.worldPos.y, i.worldPos.z) *_Scale + _Offset;

                float f = getColor(co, _Octaves, _Persistence);
                f = 0.5 + 0.5*f;

                fixed4 col = fixed4(0,0,0,1);
                col += smoothstep(_Min, _Max, f);
                return 1 - col + _Boost;
            }
            ENDCG
        }
    }
}