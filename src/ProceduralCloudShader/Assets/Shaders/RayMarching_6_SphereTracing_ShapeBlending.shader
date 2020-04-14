Shader "Custom/RayMarching/SphereTracing Shape Blending"
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
			#pragma fragment frag alpha

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
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			float  blend(float d1 , float3 d2 , float k) {
				return k * d1 + (1 - k) * d2;
			}

			float boxSDF(float3 p, float3 c, float3 s)
			{
				float x = max
				(   p.x - c.x - float3(s.x / 2., 0, 0),
					c.x - p.x - float3(s.x / 2., 0, 0)
				);

				float y = max
				(   p.y - c.y - float3(s.y / 2., 0, 0),
					c.y - p.y - float3(s.y / 2., 0, 0)
				);
				
				float z = max
				(   p.z - c.z - float3(s.z / 2., 0, 0),
					c.z - p.z - float3(s.z / 2., 0, 0)
				);

				float d = x;
				d = max(d,y);
				d = max(d,z);
				return d;
			}

			float cylinderSDF(float3 p, float3 a, float3 b, float r, fixed3 offset)
			{
				float3 ba = b - a;
				float3 pa = p - a - offset;
				float baba = dot(ba, ba);
				float paba = dot(pa, ba);
				float x = length(pa*baba-ba*paba) - r*baba;
				float y = abs(paba-baba*0.5)-baba*0.5;
				float x2 = x*x;
				float y2 = y*y*baba;
				float d = (max(x,y)<0.0)?-min(x2,y2):(((x>0.0)?x2:0.0)+((y>0.0)?y2:0.0));
				return sign(d)*sqrt(abs(d))/baba;
			}

			float sphereSDF(float3 position) {
				float4 sphere = float4(0, 1.2, 0, 1.5);
				float dSphere = distance(sphere.xyz, position) - sphere.w;
				return dSphere;
			}

			float sceneSDF(float3 position) {
				float dSphere = blend(sphereSDF(position), boxSDF(position, float3(0,1.2,0), float3(1.5,1.5,1.5)), _ShapeBlend);

				float3 q = abs(position) - float3(2, 0.05, 2);
  				float dGroundBox = length(max(q,0)) + min(max(q.x,max(q.y,q.z)),0);

				dSphere = max(dSphere, -cylinderSDF(position, fixed3(3,1,1), fixed3(-3,1,1), 0.9, fixed3( 0, 0.2,-1)));
				dSphere = max(dSphere, -cylinderSDF(position, fixed3(1,3,1), fixed3(1,-3,1), 0.9, fixed3(-1, 1.2,-1)));
				dSphere = max(dSphere, -cylinderSDF(position, fixed3(1,1,3), fixed3(1,1,-3), 0.9, fixed3(-1, 0.2, 0)));
				float sdf = min(dSphere, dGroundBox);
				
				return sdf;
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
					
					dOrigin += dScene;
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

			fixed4 frag(v2f i) : SV_Target
			{
				float3 worldPosition = i.worldPos;
				float3 viewDirection = normalize(i.worldPos - _WorldSpaceCameraPos.xyz);
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);

				float distance = raymarch(_WorldSpaceCameraPos.xyz, viewDirection);
				if (distance <= 0 || distance >= MAX_DISTANCE)
					return fixed4(0,0,0,0);
				
				float3 hitPoint = _WorldSpaceCameraPos.xyz + viewDirection * distance;
				float3 normal = estimateNormal(hitPoint);

				fixed3 ambient = _LightColor0 * 0.2;
				fixed3 diffuse = max(dot(normal, lightDirection), 0.0);
				fixed3 specular = 0.1 * pow(max(dot(viewDirection, reflect(lightDirection, normal)), 0.0), 32) * _LightColor0;

				fixed3 color = ambient + diffuse + specular;

				float shadow = softshadow(hitPoint, lightDirection, _ShadowMinDistance, _ShadowMaxDistance, _ShadowPenubra) * 0.5 + 0.5;
				color *= pow(shadow, _ShadowIntensity);

				return fixed4(color, 1);
			}

			ENDCG
		}
	}
}
