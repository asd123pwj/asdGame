using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class DecorationBase : BaseClass{
    Vector3Int map_pos, block_offsets;
    Tilemap TMap;
    Transform container => _TMapSys._P3DMon._containers["Decoration"];
    LayerType layer_decoration;
    // ---------- Status ---------- //
    public GameObject _self;
    public SpriteRenderer _renderer;

    public DecorationBase(Vector3Int map_pos, LayerType layer){
        this.map_pos = map_pos;
        block_offsets = _TMapSys._TMapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, layer).TMap;
        _self.transform.position = _TMapSys._TMapAxis._mapping_mapPos_to_worldPos(map_pos, layer);
        layer_decoration = new(layer.layer, MapLayerType.MiddleDecoration);
        _renderer.sortingLayerID = layer_decoration.sortingLayerID;
        _renderer.sortingOrder = layer_decoration.sortingOrder;
        _renderer.material = _MatSys._mat._get_mat("TilemapLitMaterial");
        // _renderer.material = _MatSys._mat._get_mat("TransparentSprite");//TilemapLitMaterial
        _update_sprite().Forget();
    }

    public override void _init(){
        init_gameObject();
    }

    public async UniTaskVoid _update_sprite(){
        await UniTask.Delay(50);
        Sprite spr = TMap.GetSprite(map_pos);
        if (spr != null){
            // string tile_ID = _MatSys._tile._get_ID(spr);
            string tile_ID = "bd_m1";
            string tile_subID = spr.name;
            _renderer.sprite = _MatSys._spr._get_sprite(tile_ID, tile_subID);
        }

    }

    void init_gameObject(){
        _self = new("BlockDecoration");
        _self.transform.SetParent(container);
        _renderer = _self.AddComponent<SpriteRenderer>();
    }
    
}
