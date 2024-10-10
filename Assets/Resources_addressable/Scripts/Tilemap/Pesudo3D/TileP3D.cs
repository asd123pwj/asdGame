using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TileP3D : BaseClass{
    Vector3Int map_pos, block_offsets;
    Tilemap TMap;
    Transform container => _TMapSys._P3DMon._TMapBD_containers["TileP3D"];
    // ---------- Status ---------- //
    public GameObject _self;
    public SpriteRenderer _renderer;

    public TileP3D(Vector3Int map_pos, LayerTTT layer){
        this.map_pos = map_pos;
        block_offsets = _TMapSys._TMapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, layer).TMap;
        _self.transform.position = _TMapSys._TMapAxis._mapping_mapPos_to_worldPos(map_pos, layer);
        _update_sprite2().Forget();
    }

    public override void _init(){
        init_gameObject();
    }

    public async UniTaskVoid _update_sprite2(){
        await UniTask.Delay(50);
        Sprite spr = TMap.GetSprite(map_pos);
        if (spr != null){
            string tile_ID = _MatSys._tile._get_ID(spr);
            string tile_subID = spr.name;
            _renderer.sprite = _MatSys._tile._get_P3D(tile_ID, tile_subID);
        }

    }

    void init_gameObject(){
        _self = new("P3D");
        _self.transform.SetParent(container);
        _renderer = _self.AddComponent<SpriteRenderer>();
    }
    
}
