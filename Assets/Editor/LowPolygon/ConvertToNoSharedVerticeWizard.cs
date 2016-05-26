using UnityEngine;
using UnityEditor;
using System.Collections;

public class ConvertToNoSharedVerticeWizard : ScriptableWizard {
	public MeshFilter meshFilter;
	
	void OnWizardUpdate () {
		helpString = "Select a mesh and convert it to a clone with no-shared vertices";
		isValid = (meshFilter != null);
	}
	
	void OnWizardCreate () {
		Mesh mesh = Instantiate(meshFilter.sharedMesh) as Mesh;
		Vector3[] oldVerts = mesh.vertices;
		Vector4[] oldTangents = mesh.tangents;
		Vector2[] oldUVs = mesh.uv;
		int[] triangles = mesh.triangles;
		Vector3[] newVerts = new Vector3[triangles.Length];
		Vector4[] newTangents = new Vector4[triangles.Length];
		Vector2[] newUVs = new Vector2[triangles.Length];
		for (int i = 0; i < triangles.Length; i++) {
			newVerts[i] = oldVerts[triangles[i]];
			newTangents[i] = oldTangents[triangles[i]];
			newUVs[i] = oldUVs[triangles[i]];
			triangles[i] = i;
		}
		mesh.vertices = newVerts;
		mesh.tangents = newTangents;
		mesh.triangles = triangles;
		mesh.uv = newUVs;
		mesh.RecalculateBounds();
		mesh.RecalculateNormals();

		GameObject go = Instantiate(meshFilter.gameObject) as GameObject;
		go.GetComponent<MeshFilter>().sharedMesh = mesh;

		// Save a copy to the disk
		string fileName = "Assets/Models/" + meshFilter.gameObject.name + "_NoSharedVertices.asset";
		AssetDatabase.CreateAsset(mesh, fileName);
		AssetDatabase.SaveAssets();
	}
	
	[MenuItem("Window/Convert to No-Shared Vertices Mesh")]
	static void RenderCubemap () {
		ScriptableWizard.DisplayWizard<ConvertToNoSharedVerticeWizard>(
			"Convert Mesh", "Convert");
	}
}
