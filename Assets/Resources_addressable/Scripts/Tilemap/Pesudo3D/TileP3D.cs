using UnityEngine;


public class TileP3D : BaseClass{
    Vector2 place_world_pos;
    Transform container;
    string tile_ID, tile_subID;
    // ---------- Status ---------- //
    public GameObject _self;
    public SpriteRenderer _renderer;

    public TileP3D(Vector2 place_world_pos, Transform container, string tile_ID, string tile_subID){
        // this.place_tilemap = place_tilemap;
        this.place_world_pos = place_world_pos;
        this.container = container;
        this.tile_ID = tile_ID;
        this.tile_subID = tile_subID;
    }

    public override bool _check_allow_init(){
        if (container == null) return false;
        return true;
    }

    public override void _init(){
        init_gameObject();
    }

    void init_gameObject(){
        // ----- GameObject
        _self = new("P3D");
        _self.transform.SetParent(container);
        _self.transform.position = place_world_pos;

        // ----- TilemapRenderer
        _renderer = _self.AddComponent<SpriteRenderer>();
        _renderer.sprite = _MatSys._tile._get_sprite(tile_ID, tile_subID);
        
    }
    
}
