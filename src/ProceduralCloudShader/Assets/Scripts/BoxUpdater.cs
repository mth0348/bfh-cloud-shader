using UnityEngine;

public class BoxUpdater : MonoBehaviour
{
    private Material material;

    void Start()
    {
        material = GetComponent<Renderer>().material;
    }

    void Update()
    {
        material.SetVector("_BoundsMin", transform.position - transform.localScale / 2);
        material.SetVector("_BoundsMax", transform.position + transform.localScale / 2);
    }
}
