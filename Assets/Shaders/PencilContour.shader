///
///  Reference: 	Lee H, Kwon S, Lee S. Real-time pencil rendering[C]
///						Proceedings of the 4th international symposium on Non-photorealistic animation and rendering. ACM, 2006: 37-45.
/// 
Shader "NPR/Pencil Sketch/Pencil Contour" {
	Properties {
		_MainTex ("Base (RGB)", 2D) = "white" {}
		_NoiseTex ("Noise Tex", 2D) = "black" {}
		_ErrorPeriod ("Error Period", Float) = 25.0
		_ErrorRange ("Error Range", Float) = 0.0015
		_NoiseAmount ("Noise Amount", Float) = 0.02
		_EdgeOnly ("Edge Only", Float) = 1.0
		_EdgeColor ("Edge Color", Color) = (0, 0, 0, 1)
		_BackgroundColor ("Background Color", Color) = (1, 1, 1, 1)
		_SampleDistance ("Sample Distance", Float) = 1.0
		_Sensitivity ("Sensitivity", Vector) = (1, 1, 1, 1)
	}
	SubShader {
		CGINCLUDE
		
		#include "UnityCG.cginc"
		
		sampler2D _MainTex;
		sampler2D _NoiseTex;
		half4 _MainTex_TexelSize;
		float _ErrorPeriod;
		float _ErrorRange;
		float _NoiseAmount;
		fixed _EdgeOnly;
		fixed4 _EdgeColor;
		fixed4 _BackgroundColor;
		float _SampleDistance;
		half4 _Sensitivity;
		
		sampler2D _CameraDepthNormalsTexture;
		sampler2D _CameraDepthTexture;
		sampler2D _EdgeTex;
		
		// Edge detection using Roberts filter
		struct v2fRoberts {
			float4 pos : SV_POSITION;
			half2 uv[5]: TEXCOORD0;
		};
		  
		v2fRoberts vertRobertsCrossDepthAndNormal(appdata_img v) {
			v2fRoberts o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			
			half2 uv = v.texcoord;
			o.uv[0] = uv;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
			#endif
			
			o.uv[1] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance;
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance;
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance;
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance;
					 
			return o;
		}
		
		half CheckSame(half4 center, half4 sample) {
			half2 centerNormal = center.xy;
			float centerDepth = DecodeFloatRG(center.zw);
			half2 sampleNormal = sample.xy;
			float sampleDepth = DecodeFloatRG(sample.zw);
			
			// difference in normals
			// do not bother decoding normals - there's no need here
			half2 diffNormal = abs(centerNormal - sampleNormal) * _Sensitivity.x;
			int isSameNormal = (diffNormal.x + diffNormal.y) < 0.1;
			// difference in depth
			float diffDepth = abs(centerDepth - sampleDepth) * _Sensitivity.y;
			// scale the required threshold by the distance
			int isSameDepth = diffDepth < 0.1 * centerDepth;
			
			// return:
			// 1 - if normals and depth are similar enough
			// 0 - otherwise
			return isSameNormal * isSameDepth ? 1.0 : 0.0;
		}
		
		fixed4 fragRobertsCrossDepthAndNormal(v2fRoberts i) : SV_Target {
			half4 sample1 = tex2D(_CameraDepthNormalsTexture, i.uv[1]);
			half4 sample2 = tex2D(_CameraDepthNormalsTexture, i.uv[2]);
			half4 sample3 = tex2D(_CameraDepthNormalsTexture, i.uv[3]);
			half4 sample4 = tex2D(_CameraDepthNormalsTexture, i.uv[4]);
			
			half edge = 1.0;
			
			edge *= CheckSame(sample1, sample2);
			edge *= CheckSame(sample3, sample4);
			
			return fixed4(edge, edge, edge, 1);
		}
		
		// Edge detection using Sobel filter
		struct v2fSobel {
			float4 pos : SV_POSITION;
			half2 uv[10]: TEXCOORD0;
		};
		
		v2fSobel vertSobel(appdata_img v) {
			v2fSobel o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			
			half2 uv = v.texcoord;
			o.uv[0] = uv;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
			#endif
			
			o.uv[1] = uv;
			o.uv[2] = uv + _MainTex_TexelSize.xy * half2(-1,1) * _SampleDistance; 	// TL
			o.uv[3] = uv + _MainTex_TexelSize.xy * half2(1,1) * _SampleDistance; 	// TR
			o.uv[4] = uv + _MainTex_TexelSize.xy * half2(-1,-1) * _SampleDistance; 	// BL
			o.uv[5] = uv + _MainTex_TexelSize.xy * half2(1,-1) * _SampleDistance; 	// BR
			o.uv[6] = uv + _MainTex_TexelSize.xy * half2(0,1) * _SampleDistance; 	// T
			o.uv[7] = uv + _MainTex_TexelSize.xy * half2(1,0) * _SampleDistance; 	// R
			o.uv[8] = uv + _MainTex_TexelSize.xy * half2(0,-1) * _SampleDistance; 	// B
			o.uv[9] = uv + _MainTex_TexelSize.xy * half2(-1,0) * _SampleDistance; 	// L
					 
			return o;
		}
		
		fixed4 fragSobelDepth(v2fSobel i) : SV_Target {
			half centerDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[1]));
			
			half4 depthsDiag;
			half4 depthsAxis;
			
			depthsDiag.x = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[2]));
			depthsDiag.y = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[3]));
			depthsDiag.z = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[4]));
			depthsDiag.w = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[5]));
			depthsAxis.x = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[6]));
			depthsAxis.y = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[7]));
			depthsAxis.z = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[8]));
			depthsAxis.w = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[9]));
			
			depthsDiag /= centerDepth;
			depthsAxis /= centerDepth;
			
			half4 horizDiagCoeff = half4(-1, -1, 1, 1);
			half4 horizAxisCoeff = half4(-2, 0, 2, 0);
			half4 vertDiagCoeff = half4(-1, 1, -1, 1);
			half4 vertAxisCoeff = half4(0, 2, 0, -2);
			
			half SobelH = dot(depthsDiag, horizDiagCoeff) + dot(depthsAxis, horizAxisCoeff);
			half SobelV = dot(depthsDiag, vertDiagCoeff) + dot(depthsAxis, vertAxisCoeff);
			
			half edge = 1 - pow(saturate(sqrt(SobelH * SobelH + SobelV * SobelV)), 3);
			
			return fixed4(edge, edge, edge, 1);
		}
		
		fixed4 fragSobelDepthThin(v2fSobel i) : SV_Target {
			half centerDepth = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[1]));
			
			half4 depthsDiag;
			half4 depthsAxis;
			
			depthsDiag.x = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[2]));
			depthsDiag.y = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[3]));
			depthsDiag.z = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[4]));
			depthsDiag.w = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[5]));
			depthsAxis.x = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[6]));
			depthsAxis.y = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[7]));
			depthsAxis.z = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[8]));
			depthsAxis.w = Linear01Depth(SAMPLE_DEPTH_TEXTURE(_CameraDepthTexture, i.uv[9]));
			
			depthsDiag = (depthsDiag > centerDepth.xxxx) ? depthsDiag : centerDepth.xxxx;
			depthsAxis = (depthsAxis > centerDepth.xxxx) ? depthsAxis : centerDepth.xxxx;
			
			depthsDiag /= centerDepth;
			depthsAxis /= centerDepth;
			
			half4 horizDiagCoeff = half4(-1, -1, 1, 1);
			half4 horizAxisCoeff = half4(-2, 0, 2, 0);
			half4 vertDiagCoeff = half4(-1, 1, -1, 1);
			half4 vertAxisCoeff = half4(0, 2, 0, -2);
			
			half SobelH = dot(depthsDiag, horizDiagCoeff) + dot(depthsAxis, horizAxisCoeff);
			half SobelV = dot(depthsDiag, vertDiagCoeff) + dot(depthsAxis, vertAxisCoeff);
			
			half edge = 1 - pow(saturate(sqrt(SobelH * SobelH + SobelV * SobelV)), 3);
			
			return fixed4(edge, edge, edge, 1);
		}
		
		struct v2fContour {
			float4 pos : SV_POSITION;
			half2 uv[2]: TEXCOORD0;
		};
		  
		v2fContour vertContour(appdata_img v) {
			v2fContour o;
			o.pos = mul(UNITY_MATRIX_MVP, v.vertex);
			
			half2 uv = v.texcoord;
			o.uv[0] = uv;
			
			#if UNITY_UV_STARTS_AT_TOP
			if (_MainTex_TexelSize.y < 0)
				uv.y = 1 - uv.y;
			#endif
			
			o.uv[1] = uv;
					 
			return o;
		}
		
		fixed4 fragContour(v2fContour i) : SV_Target {
			half offset = i.uv[1].x + i.uv[1].y;
			half noise = (tex2D(_NoiseTex, i.uv[0]) - 0.5) * _NoiseAmount;
			half2 uv[3];
			uv[0] = i.uv[1] + half2(_ErrorRange * sin(_ErrorPeriod * i.uv[1].y + 0.0) + noise, _ErrorRange * sin(_ErrorPeriod * i.uv[1].x + 0.0) + noise);
			uv[1] = i.uv[1] + half2(_ErrorRange * sin(_ErrorPeriod * i.uv[1].y + 1.047) + noise, _ErrorRange * sin(_ErrorPeriod * i.uv[1].x +3.142) + noise);
			uv[2] = i.uv[1] + half2(_ErrorRange * sin(_ErrorPeriod * i.uv[1].y + 2.094) + noise, _ErrorRange * sin(_ErrorPeriod * i.uv[1].x + 1.571) + noise);
			
			fixed3 edge = tex2D(_EdgeTex, uv[0]).r * tex2D(_EdgeTex, uv[1]).r * tex2D(_EdgeTex, uv[2]).r;
			fixed3 onlyEdgeColor = lerp(_EdgeColor, _BackgroundColor, edge).rgb;
			fixed3 withEdgeColor = lerp(_EdgeColor, tex2D(_MainTex, i.uv[0]), edge).rgb;
			
			return fixed4(lerp(withEdgeColor, onlyEdgeColor, _EdgeOnly), 1);
		}
		
		ENDCG
		
		Pass { 
			ZTest Always Cull Off ZWrite Off
			
			CGPROGRAM      
			
			#pragma vertex vertRobertsCrossDepthAndNormal
			#pragma fragment fragRobertsCrossDepthAndNormal
			
			ENDCG  
		}
		
		Pass { 
			ZTest Always Cull Off ZWrite Off
			
			CGPROGRAM      
			
			#pragma vertex vertSobel
			#pragma fragment fragSobelDepth
			
			ENDCG  
		}
		
		Pass { 
			ZTest Always Cull Off ZWrite Off
			
			CGPROGRAM      
			
			#pragma vertex vertSobel
			#pragma fragment fragSobelDepthThin
			
			ENDCG  
		}
		
		Pass { 
			ZTest Always Cull Off ZWrite Off
			
			CGPROGRAM      
			
			#pragma vertex vertContour
			#pragma fragment fragContour
			
			ENDCG  
		}
	} 
	FallBack Off
}
