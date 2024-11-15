using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class DecorationBase : BaseClass{
    Vector3Int map_pos, block_offsets;
    Tilemap TMap;
    Transform container;
    LayerType layer_decoration;
    // ---------- Status ---------- //
    public GameObject _self;
    public SpriteRenderer _renderer;
    // public SpriteMask _mask;
    // Sprite sprite;
    string sprite_ID;

    public DecorationBase(Vector3Int map_pos, LayerType layer, string sprite_ID, Transform container){
        this.map_pos = map_pos;
        block_offsets = _TMapSys._TMapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, layer).TMap;
        _self.transform.position = _TMapSys._TMapAxis._mapping_mapPos_to_worldPos(map_pos, layer);
        layer_decoration = new(layer.layer, MapLayerType.MiddleDecoration);
        _renderer.sortingLayerID = layer_decoration.sortingLayerID;
        _renderer.sortingOrder = layer_decoration.sortingOrder;
        _renderer.material = _MatSys._mat._get_mat("TilemapLitMaterial");
        _set_sprite(sprite_ID);
        this.container = container;
        _self.transform.SetParent(container);
        // _renderer.material = _MatSys._mat._get_mat("TransparentSprite");//TilemapLitMaterial
        _update_sprite().Forget();
    }

    public override void _init(){
        init_gameObject();
    }

    public void _set_sprite(string sprite_ID){
        this.sprite_ID = sprite_ID;
    }

    public async UniTaskVoid _update_sprite(){
        await UniTask.Delay(50);
        Sprite spr = TMap.GetSprite(map_pos);
        if (spr != null){
            // string mask_tile_ID = _MatSys._tile._get_ID(spr);
            // string mask_tile_subID = spr.name;
            // if (mask_tile_subID != "__Full"){
            //     _mask.enabled = true;
            //     _renderer.maskInteraction = SpriteMaskInteraction.VisibleInsideMask;
            //     _mask.sprite = _MatSys._tile._get_sprite(mask_tile_ID, mask_tile_subID);
            // }
            // else {
            //     _mask.enabled = false;
            //     _renderer.maskInteraction = SpriteMaskInteraction.None;
            // }
            // string tile_ID = "bd_m1";
            string sprite_subID = spr.name;
            // string tile_subID = "__Full";
            Sprite sprite = _MatSys._spr._get_sprite(sprite_ID, sprite_subID);
            _renderer.sprite = sprite;
        }

    }

    void init_gameObject(){
        _self = new("BlockDecoration");
        _renderer = _self.AddComponent<SpriteRenderer>();
        // _mask = _self.AddComponent<SpriteMask>();
        // _mask.enabled = false;
    }
    
}
