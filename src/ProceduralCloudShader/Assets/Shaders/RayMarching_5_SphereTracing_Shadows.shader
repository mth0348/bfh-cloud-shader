Shader "Custom/RayMarching/SphereTracing Hard Shadows"
{
	Properties
	{
		_ShadowIntensity("Shadow Intensity", Range(0,4)) = 0.5
		_ShadowMinDistance("Shadow Min Distance", float) = 0.1
		_ShadowMaxDistance("Shadow Max Distance", float) = 100
		_ShadowPenubra("Shadow Penubra", Range(1,128)) = 1
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

			float sdf(float3 position) {
				float4 sphere = float4(0, 2, 0, 1);
				float dSphere = distance(sphere.xyz, position) - sphere.w;

				float3 q = abs(position) - float3(2, 0.05, 2);
  				float dSphere2 = length(max(q,0)) + min(max(q.x,max(q.y,q.z)),0);

				// float4 sphere2 = float4(0, 0, 1, 0.5);
				// float dSphere2 = distance(sphere2.xyz, position) - sphere2.w;

				return min(dSphere, dSphere2);
			}

			float3 estimateNormal(float3 p) {
				return normalize(float3(
					sdf(float3(p.x + EPSILON, p.y, p.z)) - sdf(float3(p.x - EPSILON, p.y, p.z)),
					sdf(float3(p.x, p.y + EPSILON, p.z)) - sdf(float3(p.x, p.y - EPSILON, p.z)),
					sdf(float3(p.x, p.y, p.z + EPSILON)) - sdf(float3(p.x, p.y, p.z - EPSILON))
				));
			}

			float raymarch(float3 position, float3 direction)
			{
				float dOrigin = 0.0;
				for (int i = 0; i < MAX_STEPS; i++) {
					float dScene = sdf(position + direction * dOrigin);
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
					float dScene = sdf(position + direction * dOrigin);
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
					float dScene = sdf(position + direction * dOrigin);
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
