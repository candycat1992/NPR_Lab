///
///  Reference: 	Lake A, Marshall C, Harris M, et al. Stylized rendering techniques for scalable real-time 3D animation[C]
///						Proceedings of the 1st international symposium on Non-photorealistic animation and rendering. ACM, 2000: 13-20.
///
Shader "NPR/Background Shading" {
	Properties {
		_Color ("Diffuse Color", Color) = (1, 1, 1, 1)
		_MainTex ("Paper Texture", 2D) = "white" {}
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Pass {
			Tags { "LightMode"="ForwardBase" }
			
			Cull Back
			
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
			sampler2D _MainTex;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
				float4 tangent : TANGENT;
			}; 
			
			struct v2f {
				float4 pos : POSITION;
				float4 scrPos : TEXCOORD0;		
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				o.pos = mul( UNITY_MATRIX_MVP, v.vertex);
				o.scrPos = ComputeScreenPos(o.pos);
				
				return o;
			}
			
			float4 frag(v2f i) : COLOR {
				fixed2 scrPos = i.scrPos.xy / i.scrPos.w;
				fixed3 fragColor = tex2D(_MainTex, scrPos);
				
				fragColor *= _Color.rgb;
				
				return fixed4(fragColor, 1.0);
			}
			
			ENDCG
		}
	}
	
	FallBack "Diffuse"
}
