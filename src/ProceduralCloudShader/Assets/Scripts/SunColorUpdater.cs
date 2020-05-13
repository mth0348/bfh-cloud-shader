using UnityEngine;

public class SunColorUpdater : MonoBehaviour
{
    private Material material;
    private new Light light;

    void Start()
    {
        material = GetComponent<Renderer>().material;
        light = GetComponent<Light>();
    }

    void Update()
    {
        material.SetColor("_EmissionColor", light.color * 8);
    }
}
