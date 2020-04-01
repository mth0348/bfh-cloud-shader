﻿Shader "Custom/RayMarching/Traditional"
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
			#define STEP_SIZE 0.1
			#define MINIMUM_STEP_SIZE 0.01

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

			bool sphereHit(float3 position) {
				float4 sphere = float4(0, 1, 0, 1);
				return distance(sphere.xyz, position) < sphere.w;
			}

			fixed4 raymarch(float3 position, float3 direction)
			{
				float stepSize = STEP_SIZE;
				float dirMultiplier = 1;
				for (int i = 0; i < MAX_STEPS; i++)
				{
					if (stepSize < MINIMUM_STEP_SIZE)
						return fixed4(1,0,0,1);

					if (sphereHit(position)) {
						stepSize /= 2;
						dirMultiplier = -1;
					} else {
						dirMultiplier = 1;
					}
					
					position += normalize(direction) * stepSize * dirMultiplier;
				}
				
				return fixed4(0,0,0,1);
			}

			fixed4 frag(v2f i) : SV_Target
			{
				float3 worldPosition = i.worldPos;
				float3 viewDirection = normalize(i.worldPos - _WorldSpaceCameraPos.xyz);

				fixed4 col = raymarch(worldPosition, viewDirection);
				return col;
			}

			ENDCG
		}
	}
}
