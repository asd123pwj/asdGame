using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TileP3D : BaseClass{
    Vector3Int map_pos, block_offsets;
    Tilemap TMap;
    // Transform container => _TMapSys._P3DMon._containers["TileP3D"];
    Transform container;
    LayerType P3D_layer;
    // ---------- Status ---------- //
    public GameObject _self;
    public SpriteRenderer _renderer;

    public TileP3D(Vector3Int map_pos, LayerType layer, Transform container){
        this.map_pos = map_pos;
        block_offsets = TilemapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        // TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, layer).TMap;
        TMap = TilemapBlock._get(block_offsets, layer).obj.TMap;
        _self.transform.position = TilemapAxis._mapping_mapPos_to_worldPos(map_pos, layer);
        P3D_layer = new(layer.layer, MapLayerType.MiddleP3D);
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
            string tile_ID = _MatSys._tile._get_ID(spr);
            string tile_subID = spr.name;
            _renderer.sprite = _MatSys._tile._get_P3D(tile_ID, tile_subID);
            // string mat_ID = tile_ID == "b4" ? "TransparentSprite" : "TransparentSprite2";
            string mat_ID = "TransparentSprite";
            // _renderer.material = _MatSys._mat._get_mat("TilemapLitMaterial");
            _renderer.material = _MatSys._mat._get_mat(mat_ID);//TilemapLitMaterial
        }

    }

    void init_gameObject(){
        _self = new("P3D");
        _self.isStatic = true;
        _renderer = _self.AddComponent<SpriteRenderer>();
    }
    
}
