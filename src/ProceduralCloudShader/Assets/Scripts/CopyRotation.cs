using UnityEngine;

public class CopyRotation : MonoBehaviour
{
	public Transform target;

	void Update()
	{
		transform.localRotation = target.localRotation;
	}
}
