using UnityEngine;
using Cysharp.Threading.Tasks;

public class WaterMeshDeformer : MonoBehaviour{
    public float waveSpeed = 1f;
    public float waveHeight = 20f;
    public float waveFrequency = 1f;
    public int wave_row_start = 2;
    GameObject _self;
    Mesh mesh;
    Vector3[] vertices_ori;
    Vector3[] vertices_new;
    bool initDone = false;

    void Start(){
        _self = gameObject;
        init_gameObject().Forget();

    }

    bool _check_allow_init(string mat_name, string mesh_name){
        if (BaseClass._sys == null) return false;
        if (BaseClass._sys._MatSys == null) return false;
        if (!BaseClass._sys._MatSys._check_all_info_initDone()) return false;
        if (!BaseClass._sys._MatSys._mat._check_loaded(mat_name)) return false;
        if (!BaseClass._sys._MatSys._mesh._check_loaded(mesh_name)) return false;
        return true;
    }

    async UniTaskVoid init_gameObject(){
        string mat_name = "Liquid_Water";
        string mesh_name = "Size4x4_Grid4x4_AxisXY";
        while (!_check_allow_init(mat_name, mesh_name)){
            // Debug.Log("wait");
            await UniTask.Delay(10);
        }

        // ----- create MeshFilter, set mesh
        if (!_self.TryGetComponent(out MeshFilter meshFilter)){
            meshFilter = _self.AddComponent<MeshFilter>();
        }
        meshFilter.mesh = BaseClass._sys._MatSys._mesh._get_mesh(mesh_name);
        mesh = meshFilter.mesh;

        // ----- create MeshRenderer
        if (!_self.TryGetComponent(out MeshRenderer meshRenderer)){
            meshRenderer = _self.AddComponent<MeshRenderer>();
        }
        meshRenderer.material = BaseClass._sys._MatSys._mat._get_mat(mat_name);

        // ----- create MeshCollider
        if (!_self.TryGetComponent(out MeshCollider meshCollider)){
            meshCollider = _self.AddComponent<MeshCollider>();
        }
        meshCollider.sharedMesh = mesh;
        
        // ----- set status
        vertices_ori = mesh.vertices;
        vertices_new = new Vector3[vertices_ori.Length];

        initDone = true;
    }


    void SetCellAlpha(Vector2Int cellIndex, int gridSize, float alpha){
        int quadsPerRow = gridSize - 1; // 每行的四边形数
        int quadIndex = cellIndex.y * quadsPerRow + cellIndex.x;

        // 获取顶点颜色，如果没有则初始化
        Color[] colors = mesh.colors.Length > 0 ? mesh.colors : new Color[mesh.vertexCount];

        // 每个格子的顶点索引
        int[] quadVertices = {
            quadIndex * 4,     // 左下角
            quadIndex * 4 + 1, // 右下角
            quadIndex * 4 + 2, // 左上角
            quadIndex * 4 + 3  // 右上角
        };

        // 修改对应顶点的 Alpha 值
        foreach (int vertexIndex in quadVertices)
        {
            colors[vertexIndex].a = alpha;
        }

        // 更新顶点颜色到 Mesh
        mesh.colors = colors;
    }


    void wave(){
        // Noise noise = new(0);
        Noise noise = GameConfigs._noise;
        // int wave_row_start = 3;
        float vertexNum_per_row = 5;
        // float vertex_rowNum = 5;
        // noise._noise_simplex2();
        // noise.
        for (int i = 0; i < vertices_ori.Length; i++){
            Vector3 vertex = vertices_ori[i];
            int current_row = Mathf.FloorToInt(i / vertexNum_per_row);
            if (current_row >= wave_row_start){
                
                // vertex.y = vertices_ori[i].y 
                //         + (noise._get(transform.position.x + vertex.x + Time.time * waveSpeed, 10)
                //             + noise._get(transform.position.y + vertex.y + Time.time * waveSpeed, 10)) 
                //         * waveHeight;
                
            }
            // vertex.z = vertices_ori[i].z - (current_row/(vertex_rowNum-1) + transform.position.y);
            vertices_new[i] = vertex;
        }
        SetCellAlpha(new Vector2Int(1, 1), 5, 0.0f);

        mesh.vertices = vertices_new;
        mesh.RecalculateNormals();
    }

    void Update(){
        if (!initDone) return;
        wave();
    }
}
