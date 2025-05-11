using System.Collections.Generic;
using System.Threading;
using Cysharp.Threading.Tasks;
using UnityEngine;


public class TilemapTileTexture : ObjectBase{
    Vector3Int map_pos => tile.map_pos;
    // Tilemap TMap;
    // Transform container => _TMapSys._P3DMon._containers["TileP3D"];
    // Transform container;
    LayerType layer;
    TilemapTile tile;
    // ---------- GameObject ---------- //
    // public GameObject _self;
    public SpriteRenderer _renderer;
    public PolygonCollider2D _collider;
    // ---------- Status ---------- //
    public string tile_ID => tile.tile_ID;
    public string tile_subID => tile.tile_subID;
    
    public TilemapTileTexture(TilemapTile tile, GameObject parent, ObjectConfig cfg=null) : base(parent, cfg){
        this.tile = tile;
        layer = new(tile.block.layer, MapLayerType.Middle);
    }

    public override void _init_done(){
        _self.isStatic = true;
        _renderer = _self.GetComponent<SpriteRenderer>();
        _collider = _self.GetComponent<PolygonCollider2D>();
        _collider.enabled = false;
        _renderer.sortingLayerID = layer.sortingLayerID;
        _renderer.sortingOrder = layer.sortingOrder;
    }

    public async UniTask _update_sprite(){
        await _wait_init_done();
        if (tile_subID == null) return;
        bool need_update_collider = check_collider_need_update();
        
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
            need_update_collider = last_subID != tile_subID;
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
}
