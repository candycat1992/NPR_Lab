using UnityEngine;
using System.Collections;

public class MouseFollow : MonoBehaviour {

	public Transform trans;

	// Use this for initialization
	void Start () {
	
	}
	
	// Update is called once per frame
	void Update () {
		if (trans == null) {
			return;
		}

		Vector3 target = trans.position;
		if (Input.GetMouseButton(0)) {
			target = Camera.main.ScreenToWorldPoint(new Vector3(Input.mousePosition.x, Input.mousePosition.y, Camera.main.nearClipPlane));
			target.z = trans.position.z;
		}
		trans.position = target;
	}
}
