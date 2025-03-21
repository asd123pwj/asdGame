// Thanks ChatGPT for this code, this generate a mesh,
// this mesh has 4x4 grid, which means 5x5 vertices,
// axis is x, y, just a plane like 2D water in the side view.
// add this script to 3D object - plane, into playmode, it will generate mesh in Assets/Size1x1_Grid4x4_AxisXY.asset

using UnityEngine;
using UnityEditor;

public class MeshGenerator : MonoBehaviour{

    void Start(){
        create_mesh();
    }


    void create_mesh(){
        int gridSize = 7;           // 顶点数：6x6
        float totalSize = 1.5f;       // 总大小 1.5x1.5
        float step = totalSize / (gridSize - 1);  // 每个间隔：1.5 / 5 = 0.3

        Mesh mesh = new Mesh();
        // mesh.name = "6x6 Grid";

        // 创建顶点和 UV 数组
        Vector3[] vertices = new Vector3[gridSize * gridSize];
        Vector2[] uvs = new Vector2[gridSize * gridSize];

        // 生成顶点和 UV：顶点沿 XY 平面分布
        for (int y = 0; y < gridSize; y++)
        {
            for (int x = 0; x < gridSize; x++)
            {
                int index = y * gridSize + x;
                vertices[index] = new Vector3(x * step, y * step, 0);
                // UV 值在 0 到 1 之间均匀分布
                uvs[index] = new Vector2((float)x / (gridSize - 1), (float)y / (gridSize - 1));
            }
        }

        // 每个小格由两个三角形构成
        int quadCount = (gridSize - 1) * (gridSize - 1);
        int[] triangles = new int[quadCount * 6];
        int t = 0;
        for (int y = 0; y < gridSize - 1; y++)
        {
            for (int x = 0; x < gridSize - 1; x++)
            {
                int i = y * gridSize + x;
                // 第一个三角形
                triangles[t++] = i;
                triangles[t++] = i + gridSize;
                triangles[t++] = i + gridSize + 1;
                // 第二个三角形
                triangles[t++] = i;
                triangles[t++] = i + gridSize + 1;
                triangles[t++] = i + 1;
            }
        }

        // 应用到网格
        mesh.vertices = vertices;
        mesh.uv = uvs;
        mesh.triangles = triangles;
        mesh.RecalculateNormals();

        // 将生成的网格赋给 MeshFilter
        // MeshFilter mf = GetComponent<MeshFilter>();
        // mf.mesh = mesh;
        SaveMeshAsAsset(mesh, "Assets/Resources_addressable/Mesh/Size1.5x1.5_Grid6x6_AxisXY.asset");

    }

    // void create_mesh(){
    //     Vector3Int size = new Vector3Int(1, 1, 1);
    //     Mesh mesh = new Mesh();

    //     // Vector3[] vertices = new Vector3[25];
    //     Vector3[] vertices = new Vector3[49];
    //     int row = 6;
    //     int col = 6;
    //     int index = 0;
    //     for (int y = 0; y <= row; y++){
    //         for (int x = 0; x <= col; x++){
    //             vertices[index++] = new Vector3(x / 4.0f, y / 4.0f, 0);
    //             // vertices[index++] = new Vector3(x, y, 0);
    //         }
    //     }

    //     int[] triangles = new int[4 * 4 * 6];
    //     index = 0;
    //     for (int y = 0; y < 4; y++){
    //         for (int x = 0; x < 4; x++){
    //             int start = y * 5 + x;
    //             triangles[index++] = start;
    //             triangles[index++] = start + 5;
    //             triangles[index++] = start + 1;

    //             triangles[index++] = start + 1;
    //             triangles[index++] = start + 5;
    //             triangles[index++] = start + 6;
    //         }
    //     }

    //     // Vector2[] uv = new Vector2[25];
    //     Vector2[] uv = new Vector2[49];
    //     for (int i = 0; i < uv.Length; i++){
    //         uv[i] = new Vector2(vertices[i].x, vertices[i].y);
    //     }

    //     mesh.vertices = vertices;
    //     mesh.triangles = triangles;
    //     mesh.uv = uv;
    //     mesh.RecalculateNormals();

    //     // GetComponent<MeshFilter>().mesh = mesh;

    //     // SaveMeshAsAsset(mesh, "Assets/Resources_addressable/Mesh/Size4x4_Grid4x4_AxisXY.asset");
    //     SaveMeshAsAsset(mesh, "Assets/Resources_addressable/Mesh/Size1.5x1.5_Grid6x6_AxisXY.asset");
    // }

    void SaveMeshAsAsset(Mesh mesh, string path){
        Mesh existingMesh = AssetDatabase.LoadAssetAtPath<Mesh>(path);
        if (existingMesh != null){
            existingMesh.Clear();
            existingMesh.vertices = mesh.vertices;
            existingMesh.triangles = mesh.triangles;
            existingMesh.uv = mesh.uv;
            existingMesh.RecalculateNormals();
            AssetDatabase.SaveAssets();
        }
        else{
            AssetDatabase.CreateAsset(mesh, path);
            AssetDatabase.SaveAssets();
        }
    }

}
