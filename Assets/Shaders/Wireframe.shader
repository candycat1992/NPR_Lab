Shader "NPR/Wireframe" {
	Properties {
		_Color ("Color Tint", Color) = (1, 1, 1, 1)
		_WireColor ("Wire Color", Color) = (0, 0, 0, 1)
		_WireWidth ("Wire Width", Range(0.5, 5.0)) = 4.0
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
			
			fixed4 _WireColor;
			fixed4 _Color;
			half _WireWidth;
		
			struct v2g {
    			float4 pos : SV_POSITION;
    			float2 uv : TEXCOORD0;
    			float3 worldPos : TEXCOORD1;
			};
			
			struct g2f {
    			float4 pos : SV_POSITION;
    			float2 uv : TEXCOORD0;
    			float3 worldPos : TEXCOORD2;
    			float3 dist : TEXCOORD3;
    			float3 faceNormal : TEXCOORD4;
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

				float3 A = IN[1].worldPos.xyz - IN[0].worldPos.xyz;
				float3 B = IN[2].worldPos.xyz - IN[0].worldPos.xyz;
				float3 fn = normalize(cross(A, B));
			
				g2f o;
				o.pos = IN[0].pos;
				o.uv = IN[0].uv;
				o.worldPos = IN[0].worldPos;
				o.dist = float3(area/length(v0),0,0);
				o.faceNormal = fn;
				triStream.Append(o);

				o.pos = IN[1].pos;
				o.uv = IN[1].uv;
				o.worldPos = IN[1].worldPos;
				o.dist = float3(0,area/length(v1),0);
				o.faceNormal = fn;
				triStream.Append(o);

				o.pos = IN[2].pos;
				o.uv = IN[2].uv;
				o.worldPos = IN[2].worldPos;
				o.dist = float3(0,0,area/length(v2));
				o.faceNormal = fn;
				triStream.Append(o);
			}
			
			fixed4 frag(g2f i) : SV_Target {
				fixed3 lightDir = UnityWorldSpaceLightDir(i.worldPos);
				fixed3 normalDir = normalize(i.faceNormal);

				fixed diff = saturate(dot(normalDir, lightDir));
				fixed3 diffuse = _LightColor0.rgb * _Color.rgb * diff;
				
				//distance of frag from triangles center
				float d = min(i.dist.x, min(i.dist.y, i.dist.z));
				//fade based on dist from center
 				float I = exp2(-_WireWidth * d * d);
 				fixed3 wire = lerp(_Color.rgb, _WireColor.rgb, I);

 				return fixed4(diffuse * wire, 1);
			}
			
			ENDCG
    	}
	}
	FallBack "Diffuse"
}