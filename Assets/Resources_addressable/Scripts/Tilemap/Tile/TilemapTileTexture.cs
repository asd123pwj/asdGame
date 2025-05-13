using System.Collections.Generic;
using Cysharp.Threading.Tasks;
using UnityEngine;


public class TilemapTileTexture : ObjectBase{
    Vector3Int map_pos => tile.map_pos;
    LayerType tile_layer;
    LayerType P3D_layer;
    LayerType mineral_layer;
    TilemapTile tile;
    // ---------- GameObject ---------- //
    public SpriteRenderer _tile_renderer;
    public PolygonCollider2D _tile_collider;
    public GameObject _P3D_self;
    public SpriteRenderer _P3D_renderer;
    public GameObject _mineral_self;
    public SpriteRenderer _mineral_renderer;
    // ---------- Status ---------- //
    public string tile_ID => tile.tile_ID;
    public string tile_subID => tile.tile_subID;
    bool initGameObjectDone = false;
    
    public TilemapTileTexture(TilemapTile tile, GameObject parent, ObjectConfig cfg) : base(parent, cfg){
        this.tile = tile;
        if (_self != null){
            init_gameObject();
            initGameObjectDone = true;
        }
    }

    public override void _init_done(){
        if (initGameObjectDone) return;
        init_gameObject();
    }

    void init_gameObject(){
        _self.isStatic = true;
        tile_layer = new(tile.block.layer, MapLayerType.Middle);
        P3D_layer = new(tile.block.layer, MapLayerType.MiddleP3D);
        mineral_layer = new(tile.block.layer, MapLayerType.MiddleDecoration);
        _self.transform.position = TilemapAxis._mapping_mapPos_to_worldPos(map_pos, tile_layer);

        string mat_ID = "TransparentSprite";
        Material material = _MatSys._mat._get_mat(mat_ID);//TilemapLitMaterial

        _tile_renderer = _self.GetComponent<SpriteRenderer>();
        _tile_collider = _self.GetComponent<PolygonCollider2D>();
        _tile_renderer.sortingLayerID = tile_layer.sortingLayerID;
        _tile_renderer.sortingOrder = tile_layer.sortingOrder;
        _tile_renderer.material = material;

        _P3D_self = _self.transform.Find("P3D").gameObject;
        _P3D_renderer = _P3D_self.GetComponent<SpriteRenderer>();
        _P3D_renderer.sortingLayerID = P3D_layer.sortingLayerID;
        _P3D_renderer.sortingOrder = P3D_layer.sortingOrder;
        _P3D_renderer.material = material;

        _mineral_self = _self.transform.Find("Mineral").gameObject;
        _mineral_renderer = _mineral_self.GetComponent<SpriteRenderer>();
        _mineral_renderer.sortingLayerID = mineral_layer.sortingLayerID;
        _mineral_renderer.sortingOrder = mineral_layer.sortingOrder;
        _mineral_renderer.material = material;
    }


    // public async UniTask _update_texture(){
        // await _wait_init_done();
    public void _update_texture(){
        if (tile_subID == null) return;
        _update_tile_and_collider();
        _update_P3D();
        _update_mineral();
    }

    void _update_tile_and_collider(){
        bool need_update_collider = check_collider_need_update();
        _tile_renderer.sprite = _MatSys._tile._get_sprite(tile_ID, tile_subID);

        if (need_update_collider){
            update_collider();
        }
    }
    
    void _update_P3D(){
        _P3D_renderer.sprite = _MatSys._tile._get_P3D(tile_ID, tile_subID);
    }

    
    void _update_mineral(){
        _mineral_renderer.sprite = _MatSys._spr._get_sprite(tile.mineral_ID, tile_subID);
    }

    bool check_collider_need_update(){
        bool need_update_collider;
        if (_tile_renderer.sprite != null){
            string last_subID = _tile_renderer.sprite.name;
            need_update_collider = last_subID != tile_subID;
        }
        else{
            need_update_collider = true;
        }
        return need_update_collider;
    }

    void update_collider(){
        if (tile_ID != GameConfigs._sysCfg.TMap_empty_tile){
            _tile_collider.enabled = true;
            _tile_collider.pathCount = _tile_renderer.sprite.GetPhysicsShapeCount();
            for (int i = 0; i < _tile_collider.pathCount; i++){
                List<Vector2> path = new List<Vector2>();
                _tile_renderer.sprite.GetPhysicsShape(i, path);
                _tile_collider.SetPath(i, path.ToArray());
            }
        }
        else{
            _tile_collider.enabled = false;
        }

    }
}
