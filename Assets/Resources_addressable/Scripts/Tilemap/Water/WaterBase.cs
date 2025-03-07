using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class WaterBase : BaseClass{
    public static Dictionary<string, Dictionary<Vector3Int, WaterBase>> _our = new();
    public Vector3Int _map_pos, _block_offsets;
    public static WaterFlow _flow = new();
    Tilemap TMap;
    // Transform container => _TMapSys._P3DMon._containers["TileP3D"];
    Transform container;
    public LayerType _layer;
    // ---------- Status ---------- //
    public GameObject _self;
    public SpriteRenderer _renderer;
    public int _amount = 0; // 0 ~ 7, 0 means empty, 7 means full

    public WaterBase(Vector3Int map_pos, LayerType layer, Transform container){
        // _amount = 0;
        this._map_pos = map_pos;
        _block_offsets = _TMapSys._TMapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        TMap = _TMapSys._TMapMon._get_blkObj(_block_offsets, layer).TMap;
        _self.transform.position = _TMapSys._TMapAxis._mapping_mapPos_to_worldPos(map_pos, layer);
        _layer = layer;
        _renderer.sortingLayerID = _layer.sortingLayerID;
        _renderer.sortingOrder = _layer.sortingOrder;
        this.container = container;
        _self.transform.SetParent(container);
        _update_sprite().Forget();

        if (!_our.ContainsKey(layer.ToString())) {
            _our[layer.ToString()] = new();
        }
        _our[layer.ToString()].Add(map_pos, this);
    }

    public void _full(){
        _amount = 1;
        _update_sprite().Forget();
    }

    public override void _init(){
        init_gameObject();
    }
    
    public async UniTaskVoid _update_sprite(){
        await UniTask.Delay(50);
        string tile_ID = "b5";
        string tile_subID;
        if (_amount == 1)
            tile_subID = "__Full";
        else
            tile_subID = "__M";

        _renderer.sprite = _MatSys._tile._get_sprite(tile_ID, tile_subID);
        string mat_ID = "TransparentSprite";
        _renderer.material = _MatSys._mat._get_mat(mat_ID);//TilemapLitMaterial
    }

    void init_gameObject(){
        _self = new("Water");
        _self.isStatic = true;
        _renderer = _self.AddComponent<SpriteRenderer>();
    }
    
    
}
