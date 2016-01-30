Shader "NPR/Silhouette Extraction" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_Ramp ("Ramp Texture", 2D) = "white" {}
		_Outline ("Outline", Range(0,1)) = 0.1
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
	}
	SubShader {
    	Pass {
    		Cull Front
		
			CGPROGRAM

			#pragma target 4.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			fixed _Outline;
			fixed4 _OutlineColor;
		
			struct v2g {
    			float4 pos : SV_POSITION;
			};
			
			struct g2f {
    			float4 pos : SV_POSITION;
			};

			v2g vert(appdata_base v) {
    			v2g o;
    			v.vertex = float4(v.vertex.x, v.vertex.y, _Outline * v.vertex.z, v.vertex.w);
    			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    			return o;
			}
			
			[maxvertexcount(8)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
				g2f o;
				o.pos = IN[0].pos;
				triStream.Append(o);

				o.pos = IN[1].pos;
				triStream.Append(o);

				o.pos = IN[2].pos;
				triStream.Append(o);
			}
			
			fixed4 frag(g2f i) : SV_Target {
				return _OutlineColor;
			}
			
			ENDCG
    	}

    	Pass {
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdbase
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"
			
			fixed4 _Color;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			sampler2D _Ramp;
					
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			}; 
			
			struct v2f {
				float4 pos : POSITION;
				float2 uv : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert (a2v v) {
				v2f o;
								
				o.pos = mul( UNITY_MATRIX_MVP, v.vertex);
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				o.worldNormal = mul(v.normal, _World2Object);
				o.worldPos = mul(_Object2World, v.vertex).xyz;
				
				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			float4 frag(v2f i) : COLOR { 
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);

				// Compute the lighting model
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT.xyz;
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				fixed diff =  dot(worldNormal, worldLightDir);
				diff = diff * 0.5 + 0.5;
				
				fixed4 c = tex2D (_MainTex, i.uv);
				fixed3 diffuseColor = c.rgb * _Color.rgb;
				fixed3 diffuse = _LightColor0.rgb * diffuseColor * tex2D(_Ramp, float2(diff, diff)).rgb;
				
				return fixed4(ambient + diffuse * atten, 1.0);
			} 
			
			ENDCG
		}
	}
	FallBack "Diffuse"
}