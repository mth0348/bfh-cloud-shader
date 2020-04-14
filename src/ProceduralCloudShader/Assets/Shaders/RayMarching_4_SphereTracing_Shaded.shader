Shader "Custom/RayMarching/SphereTracing Shaded"
{
	Properties
	{
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
			#define SURFACE_DISTANCE 0.001
			#define MAX_DISTANCE 100
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

			v2f vert(appdata v)
			{
				v2f o;
				o.vertex = UnityObjectToClipPos(v.vertex);
				o.worldPos = mul(unity_ObjectToWorld, v.vertex).xyz;
				return o;
			}

			float sdf(float3 position) {
				float4 sphere = float4(0, 1, 0, 1);
				return distance(sphere.xyz, position) - sphere.w;
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
				float distanceOrigin = 0.0;
				for (int i = 0; i < MAX_STEPS; i++) {
					float distanceScene = sdf(position);
					distanceOrigin += distanceScene;
					if (distanceScene < SURFACE_DISTANCE)
						return distanceOrigin;
					if (distanceScene > MAX_DISTANCE)
						return 0;
					
					position += distanceScene * direction;
				}
				return 0;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 worldPosition = i.worldPos;
				float3 viewDirection = normalize(i.worldPos - _WorldSpaceCameraPos.xyz);
				float3 lightDirection = normalize(_WorldSpaceLightPos0.xyz);

				float distance = raymarch(_WorldSpaceCameraPos.xyz, viewDirection);
				if (distance <= 0 || distance >= MAX_DISTANCE)
					return fixed4(0,0,0,0);
					
				float3 normal = estimateNormal(_WorldSpaceCameraPos.xyz + viewDirection * distance);

				fixed3 ambient = _LightColor0 * 0.2;
				fixed3 diffuse = max(dot(normal, lightDirection), 0.0);
				fixed3 specular = 0.1 * pow(max(dot(viewDirection, reflect(lightDirection, normal)), 0.0), 32) * _LightColor0;

				fixed3 color = ambient + diffuse + specular;
				return fixed4(color, 1);
			}

			ENDCG
		}
	}
}
