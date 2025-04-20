using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;

public enum WaterTextureStatus{
    Dynamic,
    Front,
    FrontSide,
    FrontSideDynamic
}

public class WaterBase : BaseClass{
    public static Dictionary<string, Dictionary<Vector3Int, WaterBase>> _our = new();
    public static WaterFlow _flow = new();
    public static WaterWave _wave = new();
    public static WaterTexture _texture = new();
    Tilemap TMap;
    // Transform container => _TMapSys._P3DMon._containers["TileP3D"];
    Transform container;
    // ---------- GameObject ---------- //
    public GameObject _self;
    public Mesh mesh;
    public MeshRenderer meshRenderer;
    public MeshCollider meshCollider;
    public MeshFilter meshFilter;
    // ---------- Shortcut ---------- //
    public WaterBase _up    => _get_neighbor(_map_pos + Vector3Int.up);
    public WaterBase _down  => _get_neighbor(_map_pos + Vector3Int.down);
    public WaterBase _left  => _get_neighbor(_map_pos + Vector3Int.left);
    public WaterBase _right => _get_neighbor(_map_pos + Vector3Int.right);
    // ---------- Status ---------- //
    public bool _isExist = true;
    public bool _isTop => (_up == null) || (_up._amount_after == 0);
    public bool _isBottom => (_down == null) || (_down._amount_after == 0);
    public WaterTextureStatus _textureStatus = WaterTextureStatus.Dynamic;

    public Vector3Int _map_pos, _block_offsets;
    public LayerType _layer;
    public int _amount = 0; // 0 ~ _sys._GCfg._sysCfg.water_full_amount, 0 means empty
    public int _increase = 0;
    public int _decrease = 0;
    public int _diff => _increase - _decrease;
    public int _amount_after => _amount + _diff;
    public int _amount_remain => _amount - _decrease;

    public bool _flowed_left = false;
    public bool _flowed_right = false;
    // public bool _flowed_down = false;

    public Vector3Int _water_fewer_left;    // Amount fewer than this, e.g. A1 B2 C2 D2, A1 is fewer than B2, C2, D2
    public Vector3Int _water_fewer_right;   // _water_fewer_right like _water_fewer_left


    public bool _mesh_init_done;
    // public WaterBase() { _isExist = false; }
    public WaterBase(Vector3Int map_pos, LayerType layer, Transform container){
        if (!_our.ContainsKey(layer.ToString())) {
            _our[layer.ToString()] = new();
        }
        _our[layer.ToString()].Add(map_pos, this);
        this._map_pos = map_pos;
        _block_offsets = _TMapSys._TMapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        // TMap = _TMapSys._TMapMon._get_blkObj(_block_offsets, layer).TMap;
        TMap = TilemapBlock._get(_block_offsets, layer).obj.TMap;
        _self.transform.position = _TMapSys._TMapAxis._mapping_mapPos_to_worldPos(map_pos, layer);
        _layer = layer;
        meshRenderer.sortingLayerID = _layer.sortingLayerID;
        meshRenderer.sortingOrder = _layer.sortingOrder;
        this.container = container;
        _self.transform.SetParent(container);
        _texture._init_mesh(this).Forget();

    }

    public void _full(){
        _amount = GameConfigs._sysCfg.water_full_amount;
        _update_mesh().Forget();
    }

    public bool _check_full(bool isAfter=false){
        if (isAfter) return _amount_after == GameConfigs._sysCfg.water_full_amount;
        return _amount == GameConfigs._sysCfg.water_full_amount;
    }

    public override void _init(){
        init_gameObject();
    }

    
    // public async UniTaskVoid init_mesh(){
    //     await UniTask.Delay(50);
    //     // string mat_name = "Liquid_Water";
    //     string sprMat_name = "l1";
    //     string mesh_name = "Size1x1_Grid4x4_AxisXY";
    //     meshFilter.mesh = _sys._MatSys._mesh._get_mesh(mesh_name);
    //     mesh = meshFilter.mesh;
    //     // meshRenderer.material = _sys._MatSys._mat._get_mat(mat_name);
    //     List<string> items = new List<string>() {"__Full", "__Front", "__Side", "__Up"};
    //     int randomIndex = Random.Range(0, items.Count);
    //     meshRenderer.material = _sys._MatSys._sprMat._get_mat(sprMat_name, "__Front");
    //     // meshRenderer.material = _sys._MatSys._sprMat._get_mat(sprMat_name, items[randomIndex]);
    //     meshCollider.sharedMesh = mesh;
    //     _mesh_init_done = true;
    // }

    public async UniTaskVoid _update_mesh(){
        await UniTask.Delay(10);
        while (!_mesh_init_done){
            await UniTask.Delay(10);
        }
        _wave._wave(this);
        
    }
    
    void init_gameObject(){
        _self = new("Water");
        _self.isStatic = true;
        meshRenderer = _self.AddComponent<MeshRenderer>();
        meshCollider = _self.AddComponent<MeshCollider>();
        meshFilter   = _self.AddComponent<MeshFilter>();
    }
    
    public WaterBase _get_neighbor(Vector3Int neighbor_pos){
        if (_our[_layer.ToString()].ContainsKey(neighbor_pos)) return _our[_layer.ToString()][neighbor_pos];
        return null;
    }
    public static WaterBase _get_neighbor(LayerType layer, Vector3Int neighbor_pos){
        if (_our.ContainsKey(layer.ToString()) && _our[layer.ToString()].ContainsKey(neighbor_pos)) return _our[layer.ToString()][neighbor_pos];
        return null;
    }
}
