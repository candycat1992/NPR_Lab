Shader "NPR/Low Polygon With Geometry Shader" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
	}
	SubShader {
    	Pass {
    		Tags {"LightMode"="ForwardBase"}
		
			CGPROGRAM

			#pragma multi_compile_fwdbase

			#pragma target 4.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
		
			struct v2g {
    			float4 pos : SV_POSITION;
    			float2 uv : TEXCOORD0;
    			float3 worldPos : TEXCOORD1;
			};
			
			struct g2f {
    			float4 pos : SV_POSITION;
    			float2 uv : TEXCOORD0;
    			float3 worldPos : TEXCOORD2;
    			float3 faceNormal : TEXCOORD3;
			};

			v2g vert(appdata_base v) {
    			v2g o;
    			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    			o.uv = v.texcoord;
    			o.worldPos = mul(_Object2World, v.vertex);

    			return o;
			}
			
			[maxvertexcount(3)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
				float3 A = IN[1].worldPos.xyz - IN[0].worldPos.xyz;
				float3 B = IN[2].worldPos.xyz - IN[0].worldPos.xyz;
				float3 fn = normalize(cross(A, B));
			
				g2f o;
				o.pos = IN[0].pos;
				o.uv = IN[0].uv;
				o.worldPos = IN[0].worldPos;
				o.faceNormal = fn;
				triStream.Append(o);

				o.pos = IN[1].pos;
				o.uv = IN[1].uv;
				o.worldPos = IN[1].worldPos;
				o.faceNormal = fn;
				triStream.Append(o);

				o.pos = IN[2].pos;
				o.uv = IN[2].uv;
				o.worldPos = IN[2].worldPos;
				o.faceNormal = fn;
				triStream.Append(o);
			}
			
			fixed4 frag(g2f i) : SV_Target {
				fixed3 lightDir = UnityWorldSpaceLightDir(i.worldPos);
				fixed3 normalDir = normalize(i.faceNormal);

				fixed diff = saturate(dot(normalDir, lightDir));

				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * diff;

 				return fixed4(diffuse, 1);
			}
			
			ENDCG
    	}

    	Pass {
    		Tags {"LightMode"="ForwardAdd"}

    		Blend One One
		
			CGPROGRAM

			#pragma multi_compile_fwdadd

			#pragma target 4.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"

			fixed4 _Color;
		
			struct v2g {
    			float4 pos : SV_POSITION;
    			float2 uv : TEXCOORD0;
    			float3 worldPos : TEXCOORD1;
    			float4 _ShadowCoord : TEXCOORD2;
			};
			
			struct g2f {
    			float4 pos : SV_POSITION;
    			float2 uv : TEXCOORD0;
    			float3 worldPos : TEXCOORD1;
    			float3 faceNormal : TEXCOORD2;
    			float4 _ShadowCoord : TEXCOORD3;
			};

			v2g vert(appdata_base v) {
    			v2g o;
    			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    			o.uv = v.texcoord;
    			o.worldPos = mul(_Object2World, v.vertex);

    			o._ShadowCoord = mul(unity_World2Shadow[0], mul(_Object2World, v.vertex));

    			return o;
			}
			
			[maxvertexcount(3)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
				float3 A = IN[1].worldPos.xyz - IN[0].worldPos.xyz;
				float3 B = IN[2].worldPos.xyz - IN[0].worldPos.xyz;
				float3 fn = normalize(cross(A, B));

				float3 worldPos = (IN[0].worldPos + IN[1].worldPos + IN[2].worldPos)/3.0;
			
				g2f o;
				o.pos = IN[0].pos;
				o.uv = IN[0].uv;
				o.worldPos = worldPos;
				o.faceNormal = fn;
				o._ShadowCoord = IN[0]._ShadowCoord;
				triStream.Append(o);

				o.pos = IN[1].pos;
				o.uv = IN[1].uv;
				o.worldPos = worldPos;
				o.faceNormal = fn;
				o._ShadowCoord = IN[1]._ShadowCoord;
				triStream.Append(o);

				o.pos = IN[2].pos;
				o.uv = IN[2].uv;
				o.worldPos = worldPos;
				o.faceNormal = fn;
				o._ShadowCoord = IN[2]._ShadowCoord;
				triStream.Append(o);
			}
			
			fixed4 frag(g2f i) : SV_Target {
				fixed3 lightDir = UnityWorldSpaceLightDir(i.worldPos);
				fixed3 normalDir = normalize(i.faceNormal);

				fixed diff = saturate(dot(normalDir, lightDir));

				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);

				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * diff * atten * atten;

 				return fixed4(diffuse, 1);
			}
			
			ENDCG
    	}
	}
	FallBack "Diffuse"
}