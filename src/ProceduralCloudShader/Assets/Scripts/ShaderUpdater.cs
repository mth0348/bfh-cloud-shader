using UnityEngine;

[ImageEffectAllowedInSceneView, ExecuteInEditMode]
public class ShaderUpdater : MonoBehaviour
{
    public Shader shader;
    public Transform container;
    public Material material;

    void OnRenderImage(RenderTexture source, RenderTexture destination)
    {
        if (material == null) {
            material = new Material(shader);
        }

        material.SetVector("_BoundsMin", container.position - container.localScale / 2);
        material.SetVector("_BoundsMax", container.position + container.localScale / 2);
        material.SetVector("_ViewDirection", transform.right);

        Graphics.Blit(source, destination, material);
    }
}
