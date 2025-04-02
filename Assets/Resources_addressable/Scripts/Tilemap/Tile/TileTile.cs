using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TileTile : BaseClass{
    Vector3Int map_pos, block_offsets;
    Tilemap TMap;
    // Transform container => _TMapSys._P3DMon._containers["TileP3D"];
    Transform container;
    LayerType P3D_layer;
    
    // ---------- GameObject ---------- //
    public GameObject _self;
    public SpriteRenderer _renderer;
    // ---------- Status ---------- //
    public string tile_ID = "";
    public string tile_subID = "";

    public TileTile(Vector3Int map_pos, LayerType layer, Transform container){
        this.map_pos = map_pos;
        block_offsets = _TMapSys._TMapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, layer).TMap;
        _self.transform.position = _TMapSys._TMapAxis._mapping_mapPos_to_worldPos(map_pos, layer);
        P3D_layer = new(layer.layer, MapLayerType.Middle);
        _renderer.sortingLayerID = P3D_layer.sortingLayerID;
        _renderer.sortingOrder = P3D_layer.sortingOrder;
        this.container = container;
        _self.transform.SetParent(container);
        _update_sprite().Forget();
    }

    public override void _init(){
        init_gameObject();
    }

    public async UniTaskVoid _update_sprite(){
        await UniTask.Delay(10);
        Sprite spr = TMap.GetSprite(map_pos);
        if (spr != null){
            tile_ID = _MatSys._tile._get_ID(spr);
            tile_subID = spr.name;
            _renderer.sprite = _MatSys._tile._get_sprite(tile_ID, tile_subID);
            // string mat_ID = tile_ID == "b4" ? "TransparentSprite" : "TransparentSprite2";
            string mat_ID = "TransparentSprite";
            // _renderer.material = _MatSys._mat._get_mat("TilemapLitMaterial");
            _renderer.material = _MatSys._mat._get_mat(mat_ID);//TilemapLitMaterial
        }

    }

    void init_gameObject(){
        _self = new("Tile");
        _self.isStatic = true;
        _renderer = _self.AddComponent<SpriteRenderer>();
    }
    
}
