///
///  Reference: http://prideout.net/blog/?p=22
/// 
Shader "NPR/Cartoon/Antialiased Cel Shading" {
	Properties {
		_MainTex ("Main Tex", 2D)  = "white" {}
		_Outline ("Outline", Range(0,1)) = 0.1
		_OutlineColor ("Outline Color", Color) = (0, 0, 0, 1)
		_DiffuseColor ("Diffuse Color", Color) = (1, 1, 1, 1)
		_SpecularColor ("Specular Color", Color) = (1, 1, 1, 1)
		_Shininess ("Shininess", Range(1, 500)) = 40
		_DiffuseSegment ("Diffuse Segment", Vector) = (0.1, 0.3, 0.6, 1.0)
		_SpecularSegment ("Specular Segment", Range(0, 1)) = 0.5
	}
	SubShader {
		Tags { "RenderType"="Opaque" }
		LOD 200
		
		Pass {
			NAME "OUTLINE"
			
			Cull Front
			
			CGPROGRAM
			
			#pragma vertex vert
			#pragma fragment frag
			
			#include "UnityCG.cginc"
			
			float _Outline;
			fixed4 _OutlineColor;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
			}; 
			
			struct v2f {
				float4 pos : SV_POSITION;
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				float4 pos = mul(UNITY_MATRIX_MV, v.vertex); 
				float3 normal = mul((float3x3)UNITY_MATRIX_IT_MV, v.normal);  
				normal.z = -0.5;
				pos = pos + float4(normalize(normal), 0) * _Outline;
				o.pos = mul(UNITY_MATRIX_P, pos);
				
				return o;
			}
			
			float4 frag(v2f i) : SV_Target { 
				return float4(_OutlineColor.rgb, 1);               
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
		
			fixed4 _DiffuseColor;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _SpecularColor;
			float _Shininess;
			fixed4 _DiffuseSegment;
			fixed _SpecularSegment;
		
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			}; 
		
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert (a2v v) {
				v2f o;
				
				o.pos = mul( UNITY_MATRIX_MVP, v.vertex); 
				o.worldNormal  = mul(v.normal, (float3x3)_World2Object);
				o.worldPos = mul(_Object2World, v.vertex).xyz;
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				
				TRANSFER_SHADOW(o);
		    	
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target { 
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
				fixed3 worldViewDir = UnityWorldSpaceViewDir(i.worldPos);
				fixed3 worldHalfDir = normalize(worldViewDir + worldLightDir);
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
		    	
				fixed diff = dot(worldNormal, worldLightDir);
				diff = diff * 0.5 + 0.5;
				fixed spec = max(0, dot(worldNormal, worldHalfDir));
				spec = pow(spec, _Shininess);
				
				fixed w = fwidth(diff) * 2.0;
				if (diff < _DiffuseSegment.x + w) {
					diff = lerp(_DiffuseSegment.x, _DiffuseSegment.y, smoothstep(_DiffuseSegment.x - w, _DiffuseSegment.x + w, diff));
//					diff = lerp(_DiffuseSegment.x, _DiffuseSegment.y, clamp(0.5 * (diff - _DiffuseSegment.x) / w, 0, 1));
				} else if (diff < _DiffuseSegment.y + w) {
					diff = lerp(_DiffuseSegment.y, _DiffuseSegment.z, smoothstep(_DiffuseSegment.y - w, _DiffuseSegment.y + w, diff));
//					diff = lerp(_DiffuseSegment.y, _DiffuseSegment.z, clamp(0.5 * (diff - _DiffuseSegment.y) / w, 0, 1));
				} else if (diff < _DiffuseSegment.z + w) {
					diff = lerp(_DiffuseSegment.z, _DiffuseSegment.w, smoothstep(_DiffuseSegment.z - w, _DiffuseSegment.z + w, diff));
//					diff = lerp(_DiffuseSegment.z, _DiffuseSegment.w, clamp(0.5 * (diff - _DiffuseSegment.z) / w, 0, 1));
				} else {
					diff = _DiffuseSegment.w;
				}
				
				w = fwidth(spec);
				if (spec < _SpecularSegment + w) {
					spec = lerp(0, 1, smoothstep(_SpecularSegment - w, _SpecularSegment + w, spec));
				} else {
					spec = 1;
				}
				
				fixed3 ambient = UNITY_LIGHTMODEL_AMBIENT;
				
				
				fixed3 texColor = tex2D(_MainTex, i.uv).rgb;
				fixed3 diffuse = diff * _LightColor0.rgb * _DiffuseColor.rgb * texColor;
				fixed3 specular = spec * _LightColor0.rgb * _SpecularColor.rgb;
				
				return fixed4(ambient + (diffuse + specular) * atten, 1);
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
			
			#include "UnityCG.cginc"
			#include "Lighting.cginc"
			#include "AutoLight.cginc"
			#include "UnityShaderVariables.cginc"
			
			
			fixed4 _DiffuseColor;
			sampler2D _MainTex;
			float4 _MainTex_ST;
			fixed4 _SpecularColor;
			float _Shininess;
			fixed4 _DiffuseSegment;
			fixed _SpecularSegment;
			
			struct a2v {
				float4 vertex : POSITION;
				float3 normal : NORMAL;
				float4 texcoord : TEXCOORD0;
			}; 
			
			struct v2f {
				float4 pos : SV_POSITION;
				float2 uv : TEXCOORD0;
				fixed3 worldNormal : TEXCOORD1;
				float3 worldPos : TEXCOORD2;
				SHADOW_COORDS(3)
			};
			
			v2f vert (a2v v) {
				v2f o;
			
				o.pos = mul( UNITY_MATRIX_MVP, v.vertex); 
				o.worldNormal  = mul(v.normal, (float3x3)_World2Object);
				o.worldPos = mul(_Object2World, v.vertex).xyz;
				o.uv = TRANSFORM_TEX (v.texcoord, _MainTex);
				
				TRANSFER_SHADOW(o);
				
				return o;
			}
			
			fixed4 frag(v2f i) : SV_Target { 
				fixed3 worldNormal = normalize(i.worldNormal);
				fixed3 worldLightDir = UnityWorldSpaceLightDir(i.worldPos);
				fixed3 worldViewDir = UnityWorldSpaceViewDir(i.worldPos);
				fixed3 worldHalfDir = normalize(worldViewDir + worldLightDir);
				
				UNITY_LIGHT_ATTENUATION(atten, i, i.worldPos);
				
				fixed diff = dot(worldNormal, worldLightDir);
				diff = (diff * 0.5 + 0.5) * atten;
				fixed spec = max(0, dot(worldNormal, worldHalfDir));
				spec = pow(spec, _Shininess);
				
				fixed w = fwidth(diff) * 2.0;
				if (diff < _DiffuseSegment.x + w) {
					diff = lerp(_DiffuseSegment.x, _DiffuseSegment.y, smoothstep(_DiffuseSegment.x - w, _DiffuseSegment.x + w, diff));
//					diff = lerp(_DiffuseSegment.x, _DiffuseSegment.y, clamp(0.5 * (diff - _DiffuseSegment.x) / w, 0, 1));
				} else if (diff < _DiffuseSegment.y + w) {
					diff = lerp(_DiffuseSegment.y, _DiffuseSegment.z, smoothstep(_DiffuseSegment.y - w, _DiffuseSegment.y + w, diff));
//					diff = lerp(_DiffuseSegment.y, _DiffuseSegment.z, clamp(0.5 * (diff - _DiffuseSegment.y) / w, 0, 1));
				} else if (diff < _DiffuseSegment.z + w) {
					diff = lerp(_DiffuseSegment.z, _DiffuseSegment.w, smoothstep(_DiffuseSegment.z - w, _DiffuseSegment.z + w, diff));
//					diff = lerp(_DiffuseSegment.z, _DiffuseSegment.w, clamp(0.5 * (diff - _DiffuseSegment.z) / w, 0, 1));
				} else {
					diff = _DiffuseSegment.w;
				}
				
				w = fwidth(spec);
				if (spec < _SpecularSegment + w) {
					spec = lerp(0, _SpecularSegment, smoothstep(_SpecularSegment - w, _SpecularSegment + w, spec));
				} else {
					spec = _SpecularSegment;
				}
				
				fixed3 texColor = tex2D(_MainTex, i.uv).rgb;
				fixed3 diffuse = diff * _LightColor0.rgb * _DiffuseColor.rgb * texColor;
				fixed3 specular = spec * _LightColor0.rgb * _SpecularColor.rgb;
				
				return fixed4((diffuse + specular) * atten, 1);
			}
			
			ENDCG
		}
	}
	
	FallBack "Diffuse"	    
}
