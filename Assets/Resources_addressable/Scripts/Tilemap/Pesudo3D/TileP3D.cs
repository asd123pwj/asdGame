using Cysharp.Threading.Tasks;
using UnityEngine;


public class TileP3D : BaseClass{
    Vector2 place_world_pos;
    Transform container => _TMapSys._P3DMon._TMapBD_containers["TileP3D"];
    string latest_tile_ID, latest_tile_subID;
    string render_tile_ID, render_tile_subID;
    // ---------- Status ---------- //
    public GameObject _self;
    public SpriteRenderer _renderer;
    bool onUpdate;

    public TileP3D(Vector2 place_world_pos, string tile_ID, string tile_subID){
        // this.place_tilemap = place_tilemap;
        this.place_world_pos = place_world_pos;
        // this.container = container;
        this.latest_tile_ID = tile_ID;
        this.latest_tile_subID = tile_subID;
        
        _self.transform.position = place_world_pos;
        _update_sprite2(tile_ID, tile_subID).Forget();
    }

    // public override bool _check_allow_init(){
    //     if (container == null) return false;
    //     return true;
    // }

    public override void _init(){
        init_gameObject();
    }

    public void _set_sprite(string tile_ID, string tile_subID){
        this.latest_tile_ID = tile_ID;
        this.latest_tile_subID = tile_subID;
    }

    public async UniTaskVoid _update_sprite2(string tile_ID, string tile_subID){
        this.latest_tile_ID = tile_ID;
        this.latest_tile_subID = tile_subID;
            // Debug.Log(place_world_pos);
        if (!_initDone) return;
        if (onUpdate) return;
        onUpdate = true;
        while(true){
            render_tile_ID = latest_tile_ID;
            render_tile_subID = latest_tile_subID;
            _renderer.sprite = _MatSys._tile._get_P3D(tile_ID, tile_subID);
            await UniTask.Delay(100);
            if (render_tile_ID == latest_tile_ID && render_tile_subID == latest_tile_subID) 
                break;
        }
        onUpdate = false;
    }


    public void _update_sprite(string tile_ID, string tile_subID){
        this.latest_tile_ID = tile_ID;
        this.latest_tile_subID = tile_subID;
        _renderer.sprite = _MatSys._tile._get_P3D(tile_ID, tile_subID);

    }

    void init_gameObject(){
        // ----- GameObject
        _self = new("P3D");
        _self.transform.SetParent(container);
        _self.transform.position = place_world_pos;

        // ----- TilemapRenderer
        _renderer = _self.AddComponent<SpriteRenderer>();
        // _renderer.sprite = _MatSys._tile._get_P3D(latest_tile_ID, latest_tile_subID);
        
    }
    
}
