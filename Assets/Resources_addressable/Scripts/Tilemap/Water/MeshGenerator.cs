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
        Mesh mesh = new Mesh();

        Vector3[] vertices = new Vector3[25];
        int index = 0;
        for (int y = 0; y <= 4; y++){
            for (int x = 0; x <= 4; x++){
                vertices[index++] = new Vector3(x / 4.0f, y / 4.0f, 0);
            }
        }

        int[] triangles = new int[4 * 4 * 6];
        index = 0;
        for (int y = 0; y < 4; y++){
            for (int x = 0; x < 4; x++){
                int start = y * 5 + x;
                triangles[index++] = start;
                triangles[index++] = start + 5;
                triangles[index++] = start + 1;

                triangles[index++] = start + 1;
                triangles[index++] = start + 5;
                triangles[index++] = start + 6;
            }
        }

        Vector2[] uv = new Vector2[25];
        for (int i = 0; i < uv.Length; i++){
            uv[i] = new Vector2(vertices[i].x, vertices[i].y);
        }

        mesh.vertices = vertices;
        mesh.triangles = triangles;
        mesh.uv = uv;
        mesh.RecalculateNormals();

        GetComponent<MeshFilter>().mesh = mesh;

        SaveMeshAsAsset(mesh, "Assets/Size1x1_Grid4x4_AxisXY.asset");
    }

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
