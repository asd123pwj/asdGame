using UnityEngine;

public class WaterMeshDeformer : MonoBehaviour{
    public float waveSpeed = 1f;
    public float waveHeight = 0.125f;
    public float waveFrequency = 1f;

    private Mesh mesh;
    private Vector3[] originalVertices;
    private Vector3[] deformedVertices;

    void Start()
    {
        mesh = GetComponent<MeshFilter>().mesh;
        originalVertices = mesh.vertices;
        deformedVertices = new Vector3[originalVertices.Length];

    }

    void Update()
    {
        int wave_row = 3;
        int num_row = 11;
        int num_col = 11;
        for (int i = 0; i < originalVertices.Length; i++){
            Vector3 vertex = originalVertices[i];
            int current_row = i / num_row;
            float wave_delta_x, wave_delta_y, wave_delta_z;
            // ----- wave in surface
            if (current_row <= wave_row - 1) {
                // wave_x - waveHeight: make wave in the front of tilemap
                wave_delta_x = Mathf.Sin(Time.time * waveSpeed + vertex.x * waveFrequency) * waveHeight ;
                // wave_z + waveHeight: make water in surface
                wave_delta_z = Mathf.Sin(Time.time * waveSpeed + vertex.z * waveFrequency) * waveHeight;
                // wave_delta_z = 0;
                // wave_delta_y = wave_delta_x + wave_delta_z;
                vertex.y = originalVertices[i].y + wave_delta_x + wave_delta_z;
                vertex.z = - (wave_row - current_row);
            }
            // ----- water in side 
            else{
                wave_delta_y = (current_row - wave_row + 1) * -1;
                // wave_z = (current_row - 3) * -1;
                wave_delta_x = 0;
                wave_delta_z = 0;
                vertex.y = (current_row - wave_row + 1) * -1;
                vertex.z = 0;
            }
            // vertex.y = originalVertices[i].y + wave_delta_x + wave_delta_z;
            deformedVertices[i] = vertex;
        }
        // for (int i = 0; i < originalVertices.Length; i++)
        // {
        //     Vector3 vertex = originalVertices[i];
            
        //     // 在 x 和 z 方向上同时应用波浪效果
        //     float waveX = Mathf.Sin(Time.time * waveSpeed + vertex.x * waveFrequency) * waveHeight;
        //     float waveZ = Mathf.Sin(Time.time * waveSpeed + vertex.z * waveFrequency) * waveHeight * 0.1f;

        //     vertex.y = originalVertices[i].y + waveX + waveZ;
        //     deformedVertices[i] = vertex;
        // }

        mesh.vertices = deformedVertices;
        mesh.RecalculateNormals();
    }
}
