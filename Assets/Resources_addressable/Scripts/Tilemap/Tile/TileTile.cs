using System.Collections.Generic;
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
        map_pos = tile.map_pos;
        block_offsets = TilemapAxis._mapping_mapPos_to_blockOffsets(map_pos);
        _self.transform.position = TilemapAxis._mapping_mapPos_to_worldPos(map_pos, tile.block.layer);
        layer = new(tile.block.layer.layer, MapLayerType.Middle);
        _renderer.sortingLayerID = layer.sortingLayerID;
        _renderer.sortingOrder = layer.sortingOrder;
        container = tile.block.obj.tile_container.transform;
        _self.transform.SetParent(container);
        // _update_sprite().Forget();
    }

    public override void _init(){
        init_gameObject();
    }

    public async UniTask _update_sprite(){
        // _delay_in_update_sprite?.Cancel();
        if (tile.tile_subID == null) return;
        // _delay_in_update_sprite = new CancellationTokenSource();
        // await UniTask.Delay(10, cancellationToken: _delay_in_update_sprite.Token);

        bool need_update_collider = check_collider_need_update();
        
        tile_ID = tile.tile_ID;
        tile_subID = tile.tile_subID;
        _renderer.sprite = _MatSys._tile._get_sprite(tile_ID, tile_subID);
        string mat_ID = "TransparentSprite";
        _renderer.material = _MatSys._mat._get_mat(mat_ID);//TilemapLitMaterial

        if (need_update_collider){
            update_collider();
        }
    }

    bool check_collider_need_update(){
        bool need_update_collider;
        if (_renderer.sprite != null){
            string last_subID = _renderer.sprite.name;
            need_update_collider = last_subID != tile.tile_subID;
        }
        else{
            need_update_collider = true;
        }
        return need_update_collider;
    }

    void update_collider(){
        if (tile_ID != GameConfigs._sysCfg.TMap_empty_tile){
            _collider.enabled = true;
            _collider.pathCount = _renderer.sprite.GetPhysicsShapeCount();
            for (int i = 0; i < _collider.pathCount; i++){
                List<Vector2> path = new List<Vector2>();
                _renderer.sprite.GetPhysicsShape(i, path);
                _collider.SetPath(i, path.ToArray());
            }
        }
        else{
            _collider.enabled = false;
        }

    }

    void init_gameObject(){
        _self = new("Tile");
        _self.isStatic = true;
        _renderer = _self.AddComponent<SpriteRenderer>();
        _collider = _self.AddComponent<PolygonCollider2D>();
        _collider.enabled = false;
    }
}
