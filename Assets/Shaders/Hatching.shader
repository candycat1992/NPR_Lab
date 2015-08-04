///
///  Reference: 	Praun E, Hoppe H, Webb M, et al. Real-time hatching[C]
///						Proceedings of the 28th annual conference on Computer graphics and interactive techniques. ACM, 2001: 581.
///
Shader "NPR/Hatching" {
	Properties {
		_MainTex ("Main Tex", 2D) = "white" {}
		_TileFactor ("Tile Factor", Float) = 1
		_Outline ("Outline", Range(0.001, 1)) = 0.1
		_Hatch0 ("Hatch 0", 2D	) = "white" {}
		_Hatch1 	("Hatch 1", 2D	) = "white" {}
		_Hatch2 	("Hatch 2", 2D	) = "white" {}
		_Hatch3 	("Hatch 3", 2D	) = "white" {}
		_Hatch4 	("Hatch 4", 2D	) = "white" {}
		_Hatch5 	("Hatch 5", 2D	) = "white" {}
	}
	
	SubShader {
		Tags { "RenderType"="Opaque" }
        LOD 200
        
		Pass {
        	Tags { "LightMode"="ForwardBase" }
        	
            Cull Front
    		ZWrite On
 
            CGPROGRAM
            
            #pragma vertex vert
            #pragma fragment frag
            
            #pragma multi_compile_fwdbase
 
           	#include "UnityCG.cginc"
           	
            float _Outline;
 
            struct a2v
            {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            }; 
 
            struct v2f
            {
                float4 pos : POSITION;
            };
 
            v2f vert (a2v v)
            {
                v2f o;
                
                float4 pos = mul( UNITY_MATRIX_MV, v.vertex); 
				float3 normal = mul( (float3x3)UNITY_MATRIX_IT_MV, v.normal);  
				normal.z = -0.5;
				pos = pos + float4(normalize(normal),0) * _Outline;
				o.pos = mul(UNITY_MATRIX_P, pos);
				
                return o;
            }
 
            float4 frag(v2f i) : COLOR  
            { 
            	return float4(0, 0, 0, 1);               
            } 
 
            ENDCG
        }
        
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			CGPROGRAM
			#pragma vertex vert
			#pragma fragment frag 
			
			#include "UnityCG.cginc"

			float _TileFactor;
			sampler2D _MainTex;
			sampler2D _Hatch0;
			sampler2D _Hatch1;
			sampler2D _Hatch2;
			sampler2D _Hatch3;
			sampler2D _Hatch4;
			sampler2D _Hatch5;

			struct a2v {
				float4 vertex : POSITION;
				float4 tangent : TANGENT; 
				float3 normal : NORMAL; 
				float2 texcoord : TEXCOORD0; 
			};
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed3 hatchWeights0	: TEXCOORD1;
				fixed3 hatchWeights1	: TEXCOORD2;
			};
			
			v2f vert(a2v v) {
				v2f o;
	
				o.pos = mul(UNITY_MATRIX_MVP, v.vertex);

				o.uv 	= v.texcoord.xy * _TileFactor;
				
				fixed3 worldLightDir = normalize(WorldSpaceLightDir(v.vertex));
				fixed3 worldNormal = normalize(mul(v.normal, (float3x3)_World2Object));
				fixed diffuse = max(0, dot(worldLightDir, worldNormal));

				float hatchFactor = diffuse * 6.0;
				
				o.hatchWeights0 = fixed3(0, 0, 0);
				o.hatchWeights1 = fixed3(0, 0, 0);
				
				if (hatchFactor > 5.0) {
					o.hatchWeights0.x = 0.5;
				} else if (hatchFactor > 4.0) {
					o.hatchWeights0.x = max(0, hatchFactor - 4.0);
					o.hatchWeights0.y = max(0, 1.0 - o.hatchWeights0.x);
				} else if (hatchFactor > 3.0) {
					o.hatchWeights0.y = max(0, hatchFactor - 3.0);
					o.hatchWeights0.z = max(0, 1.0 - o.hatchWeights0.y);
				} else if (hatchFactor > 2.0) {
					o.hatchWeights0.z = max(0, hatchFactor - 2.0);
					o.hatchWeights1.x = max(0, 1.0 - o.hatchWeights0.z);
				} else if (hatchFactor > 1.0) {
					o.hatchWeights1.x = max(0, hatchFactor - 1.0);
					o.hatchWeights1.y = max(0, 1.0 - o.hatchWeights1.x);
				} else {
					o.hatchWeights1.y = max(0, hatchFactor);
					o.hatchWeights1.z = max(0, 1.0 - o.hatchWeights1.y);
				}
				
				return o; 
			}

			fixed4 frag(v2f i) : SV_Target {			
				fixed4 hatchTex0 = tex2D(_Hatch0, i.uv) * i.hatchWeights0.x;
				fixed4 hatchTex1 = tex2D(_Hatch1, i.uv) * i.hatchWeights0.y;
				fixed4 hatchTex2 = tex2D(_Hatch2, i.uv) * i.hatchWeights0.z;
				fixed4 hatchTex3 = tex2D(_Hatch3, i.uv) * i.hatchWeights1.x;
				fixed4 hatchTex4 = tex2D(_Hatch4, i.uv) * i.hatchWeights1.y;
				fixed4 hatchTex5 = tex2D(_Hatch5, i.uv) * i.hatchWeights1.z;
				fixed4 originalCol = tex2D(_MainTex, i.uv) * max(0, 1.0 - i.hatchWeights0.x - i.hatchWeights0.y - i.hatchWeights0.z - 
														i.hatchWeights1.x - i.hatchWeights1.y - i.hatchWeights1.z);
				
				fixed4 hatchColor = hatchTex0 + 
									hatchTex1 + 
									hatchTex2 + 
									hatchTex3 + 
									hatchTex4 + 
									hatchTex5 +
									originalCol;
									
				return fixed4(hatchColor.rgb, 1.0);
			}
			
			
			
			ENDCG
		} 
	} 
}
