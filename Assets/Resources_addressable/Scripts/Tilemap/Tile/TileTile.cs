using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TileTile : BaseClass{
    Vector3Int map_pos, block_offsets;
    Tilemap TMap;
    // Transform container => _TMapSys._P3DMon._containers["TileP3D"];
    Transform container;
    LayerType P3D_layer;
    TilemapTile tile;
    // ---------- GameObject ---------- //
    public GameObject _self;
    public SpriteRenderer _renderer;
    // ---------- Status ---------- //
    public string tile_ID = "";
    public string tile_subID = "";
    public string actual_subID => get_subID();

    // public TileTile(Vector3Int map_pos, LayerType layer, Transform container){
    public TileTile(TilemapTile tile){
        this.tile = tile;
        this.map_pos = tile.map_pos;
        block_offsets = TilemapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        // TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, layer).TMap;
        TMap = TilemapBlock._get(block_offsets, tile.block.layer).obj.TMap;
        _self.transform.position = TilemapAxis._mapping_mapPos_to_worldPos(map_pos, tile.block.layer);
        P3D_layer = new(tile.block.layer.layer, MapLayerType.Middle);
        _renderer.sortingLayerID = P3D_layer.sortingLayerID;
        _renderer.sortingOrder = P3D_layer.sortingOrder;
        this.container = tile.block.obj.P3D_container.transform;
        _self.transform.SetParent(container);
        _update_sprite().Forget();
    }

    public override void _init(){
        init_gameObject();
    }

    public async UniTaskVoid _update_sprite(){
        await UniTask.Delay(10);
        if (tile.tile_subID != null){
            tile_ID = tile.tile_ID;
            tile_subID = tile.tile_subID;
            _renderer.sprite = _MatSys._tile._get_sprite(tile_ID, tile_subID);
            string mat_ID = "TransparentSprite";
            _renderer.material = _MatSys._mat._get_mat(mat_ID);//TilemapLitMaterial
            return;
        }
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

    string get_subID(){
        Sprite spr = TMap.GetSprite(map_pos);
        if (spr != null){
            return spr.name;
        }
        return "";
    }

    void init_gameObject(){
        _self = new("Tile");
        _self.isStatic = true;
        _renderer = _self.AddComponent<SpriteRenderer>();
    }
    
}
