Shader "NPR/Wireframe Transparent" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_BackWireColor ("Back Wire Color", Color) = (0, 0, 0, 1)
		_FrontWireColor ("Front Wire Color", Color) = (0, 0, 0, 1)
		_WireWidth ("Wire Width", Range(0.5, 5.0)) = 4.0
	}
	SubShader {
    	Pass {
    		Tags {"LightMode"="ForwardBase" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
    		Blend SrcAlpha OneMinusSrcAlpha
    		Cull Front
		
			CGPROGRAM

			#pragma multi_compile_fwdbase

			#pragma target 4.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			fixed4 _BackWireColor;
			fixed4 _FrontWireColor;
			half _WireWidth;
		
			struct v2g {
    			float4 pos : SV_POSITION;
			};
			
			struct g2f {
    			float4 pos : SV_POSITION;
    			float3 dist : TEXCOORD3;
			};

			v2g vert(appdata_base v) {
    			v2g o;
    			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    			return o;
			}
			
			[maxvertexcount(3)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
				float2 scale = float2(_ScreenParams.x/2.0, _ScreenParams.y/2.0);
				
				//frag position
				float2 p0 = scale * IN[0].pos.xy / IN[0].pos.w;
				float2 p1 = scale * IN[1].pos.xy / IN[1].pos.w;
				float2 p2 = scale * IN[2].pos.xy / IN[2].pos.w;
				
				//barycentric position
				float2 v0 = p2 - p1;
				float2 v1 = p2 - p0;
				float2 v2 = p1 - p0;
				//triangles area
				float area = abs(v1.x*v2.y - v1.y * v2.x);
			
				g2f o;
				o.pos = IN[0].pos;
				o.dist = float3(area/length(v0),0,0);
				triStream.Append(o);

				o.pos = IN[1].pos;
				o.dist = float3(0,area/length(v1),0);
				triStream.Append(o);

				o.pos = IN[2].pos;
				o.dist = float3(0,0,area/length(v2));
				triStream.Append(o);
			}
			
			fixed4 frag(g2f i) : SV_Target {				
				//distance of frag from triangles center
				float d = min(i.dist.x, min(i.dist.y, i.dist.z));
				//fade based on dist from center
 				float I = exp2(-_WireWidth * d * d);

 				return fixed4(_BackWireColor.rgb, I);
			}
			
			ENDCG
    	}
    	Pass {
    		Tags {"LightMode"="ForwardBase" "Queue"="Transparent" "IgnoreProjector"="True" "RenderType"="Transparent"}
    		Blend SrcAlpha OneMinusSrcAlpha
    		Cull Back
		
			CGPROGRAM

			#pragma multi_compile_fwdbase

			#pragma target 4.0
			#pragma vertex vert
			#pragma geometry geom
			#pragma fragment frag

			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			
			fixed4 _BackWireColor;
			fixed4 _FrontWireColor;
			half _WireWidth;
		
			struct v2g {
    			float4 pos : SV_POSITION;
			};
			
			struct g2f {
    			float4 pos : SV_POSITION;
    			float3 dist : TEXCOORD3;
			};

			v2g vert(appdata_base v) {
    			v2g o;
    			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
    			return o;
			}
			
			[maxvertexcount(3)]
			void geom(triangle v2g IN[3], inout TriangleStream<g2f> triStream) {
				float2 scale = float2(_ScreenParams.x/2.0, _ScreenParams.y/2.0);
				
				//frag position
				float2 p0 = scale * IN[0].pos.xy / IN[0].pos.w;
				float2 p1 = scale * IN[1].pos.xy / IN[1].pos.w;
				float2 p2 = scale * IN[2].pos.xy / IN[2].pos.w;
				
				//barycentric position
				float2 v0 = p2 - p1;
				float2 v1 = p2 - p0;
				float2 v2 = p1 - p0;
				//triangles area
				float area = abs(v1.x*v2.y - v1.y * v2.x);
			
				g2f o;
				o.pos = IN[0].pos;
				o.dist = float3(area/length(v0),0,0);
				triStream.Append(o);

				o.pos = IN[1].pos;
				o.dist = float3(0,area/length(v1),0);
				triStream.Append(o);

				o.pos = IN[2].pos;
				o.dist = float3(0,0,area/length(v2));
				triStream.Append(o);
			}
			
			fixed4 frag(g2f i) : SV_Target {				
				//distance of frag from triangles center
				float d = min(i.dist.x, min(i.dist.y, i.dist.z));
				//fade based on dist from center
 				float I = exp2(-_WireWidth * d * d);

 				return fixed4(_FrontWireColor.rgb, I);
			}
			
			ENDCG
    	}
	}
	FallBack "Diffuse"
}