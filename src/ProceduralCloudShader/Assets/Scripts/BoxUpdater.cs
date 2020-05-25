using System;
using UnityEngine;

public class BoxUpdater : MonoBehaviour
{
    public Transform sun;
    public ComputeShader noiseComputeShader;

    //////////////////////////////////////////

    public Vector3 _PerlinScale = new Vector3(1, 1, 1);
    public Vector3 _PerlinOffset = new Vector3(0, 0, 0);
    [Range(0, 10)] public int _PerlinOctaves = 1;
    [Range(0.1f, 1)] public float _PerlinPersistance = 0.5f;
    [Range(0.1f, 10)] public float _PerlinFrequency = 1;
    [Range(0.1f, 10)] public float _PerlinAmplitude = 1;
    [Range(0, 1)] public float _PerlinMin = 0;
    [Range(0, 1)] public float _PerlinMax = 1;
    [Range(0, 1)] public float _PerlinBoost = 0;
    [Range(0, 1)] public float _PerlinDensityThreshold = 0.2f;
    [Range(0, 5)] public float _PerlinDensityMultiplier = 1;

    public Vector3 _VoronoiScale = new Vector3(1, 1, 1);
    public Vector3 _VoronoiOffset = new Vector3(0, 0, 0);
    [Range(0, 10)] public int _VoronoiOctaves = 1;
    [Range(0.1f, 1)] public float _VoronoiPersistance = 0.5f;
    [Range(0.1f, 10)] public float _VoronoiFrequency = 1;
    [Range(0.1f, 10)] public float _VoronoiAmplitude = 1;
    [Range(0, 1)] public float _VoronoiMin = 0;
    [Range(0, 1)] public float _VoronoiMax = 1;
    [Range(0, 1)] public float _VoronoiBoost = 0;
    [Range(0, 1)] public float _VoronoiDensityThreshold = 0.2f;
    [Range(0, 5)] public float _VoronoiDensityMultiplier = 1;

    //////////////////////////////////////////

    private Material material;
    private RenderTexture noiseTexture;
    private int noiseKernel;
    private ComputeBuffer permutationBuffer;

    private const int resolution = 100;

    private int sizeX, sizeY, sizeZ = 0;

    void Start()
    {
        material = GetComponent<Renderer>().material;

        sizeX = (int)transform.localScale.x;
        sizeY = (int)transform.localScale.y;
        sizeZ = (int)transform.localScale.z;

        if (noiseComputeShader != null)
        {
            noiseTexture = new RenderTexture(sizeX, sizeY, 0, RenderTextureFormat.ARGB32, RenderTextureReadWrite.Linear);
            noiseTexture.dimension = UnityEngine.Rendering.TextureDimension.Tex3D;
            noiseTexture.enableRandomWrite = true;
            noiseTexture.volumeDepth = sizeZ;
            noiseTexture.Create();
            noiseKernel = noiseComputeShader.FindKernel("CSMain");
            noiseComputeShader.SetTexture(noiseKernel, "Result", noiseTexture);

            permutationBuffer = new ComputeBuffer(512, sizeof(int), ComputeBufferType.Constant);
            permutationBuffer.SetData(new[] { 151,160,137,91,90,15,
                131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
                190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
                88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
                77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
                102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
                135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
                5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
                223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
                129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
                251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
                49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
                138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180,
                151,160,137,91,90,15,
                131,13,201,95,96,53,194,233,7,225,140,36,103,30,69,142,8,99,37,240,21,10,23,
                190, 6,148,247,120,234,75,0,26,197,62,94,252,219,203,117,35,11,32,57,177,33,
                88,237,149,56,87,174,20,125,136,171,168, 68,175,74,165,71,134,139,48,27,166,
                77,146,158,231,83,111,229,122,60,211,133,230,220,105,92,41,55,46,245,40,244,
                102,143,54, 65,25,63,161, 1,216,80,73,209,76,132,187,208, 89,18,169,200,196,
                135,130,116,188,159,86,164,100,109,198,173,186, 3,64,52,217,226,250,124,123,
                5,202,38,147,118,126,255,82,85,212,207,206,59,227,47,16,58,17,182,189,28,42,
                223,183,170,213,119,248,152, 2,44,154,163, 70,221,153,101,155,167, 43,172,9,
                129,22,39,253, 19,98,108,110,79,113,224,232,178,185, 112,104,218,246,97,228,
                251,34,242,193,238,210,144,12,191,179,162,241, 81,51,145,235,249,14,239,107,
                49,192,214, 31,181,199,106,157,184, 84,204,176,115,121,50,45,127, 4,150,254,
                138,236,205,93,222,114,67,29,24,72,243,141,128,195,78,66,215,61,156,180
            });
            noiseComputeShader.SetBuffer(noiseKernel, "permutation", permutationBuffer);
        }
    }

    void Update()
    {
        noiseComputeShader.SetVector("_PerlinScale", _PerlinScale);
        noiseComputeShader.SetVector("_PerlinOffset", _PerlinOffset);
        noiseComputeShader.SetInt("_PerlinOctaves", _PerlinOctaves);
        noiseComputeShader.SetFloat("_PerlinPersistance", _PerlinPersistance);
        noiseComputeShader.SetFloat("_PerlinFrequency", _PerlinFrequency);
        noiseComputeShader.SetFloat("_PerlinAmplitude", _PerlinAmplitude);
        noiseComputeShader.SetFloat("_PerlinMin", _PerlinMin);
        noiseComputeShader.SetFloat("_PerlinMax", _PerlinMax);
        noiseComputeShader.SetFloat("_PerlinBoost", _PerlinBoost);
        noiseComputeShader.SetFloat("_PerlinDensityThreshold", _PerlinDensityThreshold);
        noiseComputeShader.SetFloat("_PerlinDensityMultiplier", _PerlinDensityMultiplier);

        noiseComputeShader.SetVector("_VoronoiScale", _VoronoiScale);
        noiseComputeShader.SetVector("_VoronoiOffset", _VoronoiOffset);
        noiseComputeShader.SetInt("_VoronoiOctaves", _VoronoiOctaves);
        noiseComputeShader.SetFloat("_VoronoiPersistance", _VoronoiPersistance);
        noiseComputeShader.SetFloat("_VoronoiFrequency", _VoronoiFrequency);
        noiseComputeShader.SetFloat("_VoronoiAmplitude", _VoronoiAmplitude);
        noiseComputeShader.SetFloat("_VoronoiMin", _VoronoiMin);
        noiseComputeShader.SetFloat("_VoronoiMax", _VoronoiMax);
        noiseComputeShader.SetFloat("_VoronoiBoost", _VoronoiBoost);
        noiseComputeShader.SetFloat("_VoronoiDensityThreshold", _VoronoiDensityThreshold);
        noiseComputeShader.SetFloat("_VoronoiDensityMultiplier", _VoronoiDensityMultiplier);

        material.SetVector("_BoundsMin", transform.position - transform.localScale / 2);
        material.SetVector("_BoundsMax", transform.position + transform.localScale / 2);
        material.SetVector("_SunPosition", sun.position);

        if (noiseComputeShader != null)
        {
            noiseComputeShader.Dispatch(noiseKernel, Math.Max(1, sizeX / 8), Math.Max(1, sizeY / 8), Math.Max(1, sizeZ / 8));
            material.SetTexture("_NoiseTexture", noiseTexture);
        }
    }

    void OnDestroy()
    {
        noiseTexture?.Release();
        permutationBuffer?.Release();
    }
}
