using UnityEngine;

public class RotateAround : MonoBehaviour
{
	public Transform target;
	public float speed = 30;

	private float angle;

	void Update()
	{
		angle = speed * Time.deltaTime;
		transform.RotateAround(target.position, Vector3.up, angle);
	}
}
