Shader "Custom/RayMarching/SphereTracing"
{
	Properties
	{
	}
	SubShader
	{
		Tags { "RenderType" = "Opaque" }
		LOD 100

		Pass
		{
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag

			#include "UnityCG.cginc"

			#define MAX_STEPS 100
			#define SURFACE_DISTANCE 0.001
			#define MAX_DISTANCE 100

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

			float sphereDistance(float3 position) {
				float4 sphere = float4(0, 1, 0, 1);
				return distance(sphere.xyz, position) - sphere.w;
			}

			float raymarch(float3 position, float3 direction)
			{
				float distanceOrigin = 0.0;
				for (int i = 0; i < MAX_STEPS; i++) {
					float  distanceScene = sphereDistance(position);
					distanceOrigin  +=  distanceScene;
					if (distanceScene  < SURFACE_DISTANCE  ||  distanceScene  > MAX_DISTANCE)
						break;
					
					position  +=  distanceScene * direction;
					}
				return distanceOrigin;
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 worldPosition = i.worldPos;
				float3 viewDirection = normalize(i.worldPos - _WorldSpaceCameraPos.xyz);

				float d = raymarch(_WorldSpaceCameraPos.xyz, viewDirection);
				fixed3 col = fixed3(d, d, d);
				return fixed4(col / 10, 1.0);
			}

			ENDCG
		}
	}
}
