using System.Threading;
using Cysharp.Threading.Tasks;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TileTile : BaseClass{
    Vector3Int map_pos, block_offsets;
    // Tilemap TMap;
    // Transform container => _TMapSys._P3DMon._containers["TileP3D"];
    Transform container;
    LayerType layer;
    TilemapTile tile;
    // ---------- GameObject ---------- //
    public GameObject _self;
    public SpriteRenderer _renderer;
    public PolygonCollider2D _collider;
    // ---------- Status ---------- //
    public string tile_ID = "";
    public string tile_subID = "";
    CancellationTokenSource _delay_in_update_sprite;
    // public string actual_subID => get_subID();

    // public TileTile(Vector3Int map_pos, LayerType layer, Transform container){
    public TileTile(TilemapTile tile){
        this.tile = tile;
        this.map_pos = tile.map_pos;
        block_offsets = TilemapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        // TMap = _TMapSys._TMapMon._get_blkObj(block_offsets, layer).TMap;
        // TMap = TilemapBlock._get_force(block_offsets, tile.block.layer).obj.TMap;
        _self.transform.position = TilemapAxis._mapping_mapPos_to_worldPos(map_pos, tile.block.layer);
        layer = new(tile.block.layer.layer, MapLayerType.Middle);
        _renderer.sortingLayerID = layer.sortingLayerID;
        _renderer.sortingOrder = layer.sortingOrder;
        this.container = tile.block.obj.tile_container.transform;
        _self.transform.SetParent(container);
        _update_sprite().Forget();
    }

    public override void _init(){
        init_gameObject();
    }

    public async UniTaskVoid _update_sprite(){
        _delay_in_update_sprite?.Cancel();
        _delay_in_update_sprite = new CancellationTokenSource();

        if (tile.tile_subID == null) return;
        // while (tile.tile_subID == null){
            // await UniTask.Delay(10);
            await UniTask.Delay(10, cancellationToken: _delay_in_update_sprite.Token);

        // }
        // if (tile.tile_subID != null){
            tile_ID = tile.tile_ID;
            tile_subID = tile.tile_subID;
            _renderer.sprite = _MatSys._tile._get_sprite(tile_ID, tile_subID);
            string mat_ID = "TransparentSprite";
            _renderer.material = _MatSys._mat._get_mat(mat_ID);//TilemapLitMaterial
        // _collider.enabled = tile_ID != GameConfigs._sysCfg.TMap_empty_tile;
        // // _collider.autoTiling = tile_ID != GameConfigs._sysCfg.TMap_empty_tile;
        // _collider.pathCount = 0; // 清除现有路径
        // _collider.CreatePrimitive(1); // 临时创建一个基本形状
        // _collider.autoTiling = true; // 重新启用自动贴合
            return;
        // }
        // Sprite spr = TMap.GetSprite(map_pos);
        // if (spr != null){
        //     tile_ID = _MatSys._tile._get_ID(spr);
        //     tile_subID = spr.name;
        //     _renderer.sprite = _MatSys._tile._get_sprite(tile_ID, tile_subID);
        //     // string mat_ID = tile_ID == "b4" ? "TransparentSprite" : "TransparentSprite2";
        //     string mat_ID = "TransparentSprite";
        //     // _renderer.material = _MatSys._mat._get_mat("TilemapLitMaterial");
        //     _renderer.material = _MatSys._mat._get_mat(mat_ID);//TilemapLitMaterial
        // }
    }

    // string get_subID(){
    //     Sprite spr = TMap.GetSprite(map_pos);
    //     if (spr != null){
    //         return spr.name;
    //     }
    //     return "";
    // }

    void init_gameObject(){
        _self = new("Tile");
        _self.isStatic = true;
        _renderer = _self.AddComponent<SpriteRenderer>();
        // _collider = _self.AddComponent<PolygonCollider2D>();
    }
    
}
