///
///  Reference: 	Lake A, Marshall C, Harris M, et al. Stylized rendering techniques for scalable real-time 3D animation[C]
///						Proceedings of the 1st international symposium on Non-photorealistic animation and rendering. ACM, 2000: 13-20.
///
Shader "NPR/Pencil Sketch Shading" {
	Properties {
		_Color ("Diffuse Color", Color) = (1, 1, 1, 1)
		_Outline ("Outline", Range(0.001, 1)) = 0.1
		_TileFactor ("Tile Factor", Range(1, 10)) = 5
        _Level1 ("Level 1 (Darkest)", 2D) = "white" {}
        _Level2 ("Level 2 ", 2D) = "white" {}
        _Level3 ("Level 3 ", 2D) = "white" {}
        _Level4 ("Level 4 ", 2D) = "white" {}
        _Level5 ("Level 5 ", 2D) = "white" {}
        _Level6 ("Level 6 ", 2D) = "white" {}
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
 
            struct a2v {
                float4 vertex : POSITION;
                float3 normal : NORMAL;
            }; 
 
            struct v2f {
                float4 pos : POSITION;
            };
 
            v2f vert (a2v v) {
                v2f o;
                
                float4 pos = mul( UNITY_MATRIX_MV, v.vertex); 
				float3 normal = mul( (float3x3)UNITY_MATRIX_IT_MV, v.normal);  
				normal.z = -0.5;
				pos = pos + float4(normalize(normal),0) * _Outline;
				o.pos = mul(UNITY_MATRIX_P, pos);
				
                return o;
            }
 
            float4 frag(v2f i) : COLOR { 
            	return float4(0, 0, 0, 1);               
            } 
 
            ENDCG
        }
        
        Pass {
			Tags { "LightMode"="ForwardBase" }

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdbase
			
			#pragma glsl

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"
			
			#define DegreeToRadian 0.0174533
			
			fixed4 _Color;
			float _TileFactor;
			sampler2D _Level1;
			sampler2D _Level2;
			sampler2D _Level3;
			sampler2D _Level4;
			sampler2D _Level5;
			sampler2D _Level6;
 
 			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			}; 

			struct v2f {
				float4 pos : POSITION;
				float4 scrPos : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldLightDir : TEXCOORD2;
				float3 worldPos : TEXCOORD3;	
				// The macro in Unity 4
				LIGHTING_COORDS(4, 5)
				// Or use macro in Unity 5
//                SHADOW_COORDS(4)
			};
			
			v2f vert (a2v v) {
				v2f o;

				o.pos = mul( UNITY_MATRIX_MVP, v.vertex);
				o.worldNormal  = mul(v.normal, (float3x3)_World2Object);
				o.worldLightDir = WorldSpaceLightDir(v.vertex);
				o.worldPos = mul(_Object2World, v.vertex).xyz;
				o.scrPos = ComputeScreenPos(o.pos);
				
				// The macro in Unity 4
				// Pass lighting information to pixel shader
  				TRANSFER_VERTEX_TO_FRAGMENT(o);
  				// Or use the macro in Unity 5
//                TRANSFER_SHADOW(o);

				return o;
			}
			
			float4 frag(v2f i) : COLOR { 
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(i.worldLightDir);
				fixed2 scrPos = i.scrPos.xy / i.scrPos.w * _TileFactor;
				
				// The macro in Unity 4
				fixed atten = LIGHT_ATTENUATION(i);
				//  Or use the macro in Unity 5
//                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				fixed diff = (dot(worldNormal, worldLightDir) * 0.5 + 0.5) * atten * 6.0;
				fixed3 fragColor;
				if (diff < 1.0) {
				 	fragColor = tex2D(_Level1, scrPos).rgb;
				} else if (diff < 2.0) {
					fragColor = tex2D(_Level2, scrPos).rgb;
				} else if (diff < 3.0) {
					fragColor = tex2D(_Level3, scrPos).rgb;
				} else if (diff < 4.0) {
					fragColor = tex2D(_Level4, scrPos).rgb;
				} else if (diff < 5.0) {
					fragColor = tex2D(_Level5, scrPos).rgb;
				} else {
					fragColor = tex2D(_Level6, scrPos).rgb;
				}
				
				fragColor *= _Color.rgb * _LightColor0.rgb;
				
				return fixed4(fragColor, 1.0);
			} 

			ENDCG
		}
		
		Pass {
			Tags { "LightMode"="ForwardAdd" }
			
			Blend One One

			CGPROGRAM

			#pragma vertex vert
			#pragma fragment frag
			
			#pragma multi_compile_fwdadd
			
			#pragma glsl

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"
			
			#define DegreeToRadian 0.0174533
			
			fixed4 _Color;
			float _TileFactor;
			sampler2D _Level1;
			sampler2D _Level2;
			sampler2D _Level3;
			sampler2D _Level4;
			sampler2D _Level5;
			sampler2D _Level6;
 
 			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			}; 

			struct v2f {
				float4 pos : POSITION;
				float4 scrPos : TEXCOORD0;
				float3 worldNormal : TEXCOORD1;
				float3 worldLightDir : TEXCOORD2;
				float3 worldPos : TEXCOORD3;	
				// The macro in Unity 4
				LIGHTING_COORDS(4, 5)
				// Or use macro in Unity 5
//                SHADOW_COORDS(4)
			};
			
			v2f vert (a2v v) {
				v2f o;

				o.pos = mul( UNITY_MATRIX_MVP, v.vertex);
				o.worldNormal  = mul(v.normal, (float3x3)_World2Object);
				o.worldLightDir = WorldSpaceLightDir(v.vertex);
				o.worldPos = mul(_Object2World, v.vertex).xyz;
				o.scrPos = ComputeScreenPos(o.pos);
				
				// The macro in Unity 4
				// Pass lighting information to pixel shader
  				TRANSFER_VERTEX_TO_FRAGMENT(o);
  				// Or use the macro in Unity 5
//                TRANSFER_SHADOW(o);

				return o;
			}
			
			float4 frag(v2f i) : COLOR { 
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = normalize(i.worldLightDir);
				fixed2 scrPos = i.scrPos.xy / i.scrPos.w * _TileFactor;
				
				// The macro in Unity 4
				fixed atten = LIGHT_ATTENUATION(i);
				//  Or use the macro in Unity 5
//                UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				fixed diff = (dot(worldNormal, worldLightDir) * 0.5 + 0.5) * atten * 6.0;
				fixed3 fragColor;
				if (diff < 1.0) {
				 	fragColor = tex2D(_Level1, scrPos).rgb;
				} else if (diff < 2.0) {
					fragColor = tex2D(_Level2, scrPos).rgb;
				} else if (diff < 3.0) {
					fragColor = tex2D(_Level3, scrPos).rgb;
				} else if (diff < 4.0) {
					fragColor = tex2D(_Level4, scrPos).rgb;
				} else if (diff < 5.0) {
					fragColor = tex2D(_Level5, scrPos).rgb;
				} else {
					fragColor = tex2D(_Level6, scrPos).rgb;
				}
				
				fragColor *= _Color.rgb * _LightColor0.rgb;
				
				return fixed4(fragColor, 1.0);
			} 

			ENDCG
		}
	}
	FallBack "Diffuse"
}
