using UnityEngine;
using System.Collections;

public class PencilContour : PostEffectsBase {

	public Shader edgeDetectShader;
	private Material edgeDetectMaterial = null;
	public Material material {  
		get {
			edgeDetectMaterial = CheckShaderAndCreateMaterial(edgeDetectShader, edgeDetectMaterial);
			return edgeDetectMaterial;
		}  
	}

	public enum EdgeDetectMode {
		RobertsCrossDepthNormals = 0,
		SobelDepth = 1,
		SobelDepthThin = 2
	}

	public EdgeDetectMode mode = EdgeDetectMode.RobertsCrossDepthNormals;

	public Texture2D noiseTex;

	[Range(10.0f, 50.0f)]
	public float errorPeriod = 25.0f;

	[Range(0.0f, 0.005f)]
	public float errorRange = 0.0015f;

	[Range(0.0f, 0.5f)]
	public float noiseAmount = 0.02f;

	[Range(0.0f, 1.0f)]
	public float edgesOnly = 1.0f;

	public Color edgeColor = Color.black;

	public Color backgroundColor = Color.white;

	public float sampleDistance = 1.0f;

	public float sensitivityDepth = 1.0f;

	public float sensitivityNormals = 1.0f;

	private EdgeDetectMode oldMode = EdgeDetectMode.RobertsCrossDepthNormals;
	
	void OnEnable() {
		SetCameraFlag();
	}

	void SetCameraFlag() {
		if (mode == EdgeDetectMode.SobelDepth || mode == EdgeDetectMode.SobelDepthThin)
			GetComponent<Camera>().depthTextureMode |= DepthTextureMode.Depth;
		else if (mode == EdgeDetectMode.RobertsCrossDepthNormals)
			GetComponent<Camera>().depthTextureMode |= DepthTextureMode.DepthNormals;
	}

	[ImageEffectOpaque]
	void OnRenderImage (RenderTexture src, RenderTexture dest) {
		if (oldMode != mode) {
			SetCameraFlag();
			oldMode = mode;
		}

		if (material != null) {
			material.SetTexture("_NoiseTex", noiseTex);
			material.SetFloat("_EdgeOnly", edgesOnly);
			material.SetFloat("_ErrorPeriod", errorPeriod);
			material.SetFloat("_ErrorRange", errorRange);
			material.SetFloat("_NoiseAmount", noiseAmount);
			material.SetColor("_EdgeColor", edgeColor);
			material.SetColor("_BackgroundColor", backgroundColor);
			material.SetFloat("_SampleDistance", sampleDistance);
			material.SetVector("_Sensitivity", new Vector4(sensitivityNormals, sensitivityDepth, 0.0f, 0.0f));

			RenderTexture buffer = RenderTexture.GetTemporary(src.width, src.height, 0);

			Graphics.Blit(src, buffer, material, (int)mode);

			material.SetTexture("_EdgeTex", buffer);
			Graphics.Blit(src, dest, material, 3);

			RenderTexture.ReleaseTemporary(buffer);
		} else {
			Graphics.Blit(src, dest);
		}
	}
}
