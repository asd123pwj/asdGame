using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class WaterBase : BaseClass{
    public static Dictionary<string, Dictionary<Vector3Int, WaterBase>> _our = new();
    public static WaterFlow _flow = new();
    Tilemap TMap;
    // Transform container => _TMapSys._P3DMon._containers["TileP3D"];
    Transform container;
    // ---------- GameObject ---------- //
    public GameObject _self;
    Mesh mesh;
    MeshRenderer meshRenderer;
    MeshCollider meshCollider;
    MeshFilter meshFilter;
    // ---------- Status ---------- //
    public Vector3Int _map_pos, _block_offsets;
    public LayerType _layer;
    Vector3[] vertices_ori;
    Vector3[] vertices_new;
    public int _amount = 0; // 0 ~ _sys._GCfg._sysCfg.water_full_amount, 0 means empty

    public WaterBase(Vector3Int map_pos, LayerType layer, Transform container){
        if (!_our.ContainsKey(layer.ToString())) {
            _our[layer.ToString()] = new();
        }
        _our[layer.ToString()].Add(map_pos, this);
        this._map_pos = map_pos;
        _block_offsets = _TMapSys._TMapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        TMap = _TMapSys._TMapMon._get_blkObj(_block_offsets, layer).TMap;
        _self.transform.position = _TMapSys._TMapAxis._mapping_mapPos_to_worldPos(map_pos, layer);
        _layer = layer;
        meshRenderer.sortingLayerID = _layer.sortingLayerID;
        meshRenderer.sortingOrder = _layer.sortingOrder;
        this.container = container;
        _self.transform.SetParent(container);
        init_mesh().Forget();

    }

    public void _full(){
        _amount = _sys._GCfg._sysCfg.water_full_amount;
        _update_mesh().Forget();
    }

    public bool _isFull(){
        return _amount == _sys._GCfg._sysCfg.water_full_amount;
    }

    public override void _init(){
        init_gameObject();
    }

    
    public async UniTaskVoid init_mesh(){
        await UniTask.Delay(50);
        string mat_name = "Liquid_Water";
        string mesh_name = "Size1x1_Grid4x4_AxisXY";
        meshFilter.mesh = _sys._MatSys._mesh._get_mesh(mesh_name);
        mesh = meshFilter.mesh;
        meshRenderer.material = _sys._MatSys._mat._get_mat(mat_name);
        meshCollider.sharedMesh = mesh;
        vertices_ori = mesh.vertices;
        vertices_new = new Vector3[vertices_ori.Length];
    }

    public async UniTaskVoid _update_mesh(){
        await UniTask.Delay(50);
        if (_amount == 1)
            _self.SetActive(true);
        else
            _self.SetActive(false);
        
    }
    
    void init_gameObject(){
        _self = new("Water");
        _self.isStatic = true;
        meshRenderer = _self.AddComponent<MeshRenderer>();
        meshCollider = _self.AddComponent<MeshCollider>();
        meshFilter = _self.AddComponent<MeshFilter>();
    }
    
    
}
