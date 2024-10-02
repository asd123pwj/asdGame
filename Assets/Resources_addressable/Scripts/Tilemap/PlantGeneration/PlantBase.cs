using UnityEngine;


public class PlantBase : BaseClass{
    // Tilemap place_tilemap;
    Vector2 place_world_pos;
    Vector3Int place_map_pos;
    Transform container;

    // ---------- Status ---------- //
    public Vector3 _place_pos = Vector3.zero;
    public GameObject _self;
    public SpriteRenderer _renderer;

    public PlantBase(Vector2 place_world_pos, Transform container){
        // this.place_tilemap = place_tilemap;
        this.place_world_pos = place_world_pos;
        this.container = container;
    }
    public PlantBase(Vector3Int place_map_pos, Transform container){
        // this.place_tilemap = place_tilemap;
        this.place_map_pos = place_map_pos;
        this.container = container;
        place_world_pos = new(place_map_pos.x, place_world_pos.y);
    }

    public override bool _check_allow_init(){
        if (container == null) return false;
        return true;
    }

    public override void _init(){
        _place_pos.x = find_generation_x();
        _place_pos.y = find_generation_y();
        init_gameObject();
    }

    void init_gameObject(){
        // ----- GameObject
        _self = new("Plant");
        _self.transform.SetParent(container);
        _self.transform.position = _place_pos;

        // ----- TilemapRenderer
        _renderer = _self.AddComponent<SpriteRenderer>();
        _renderer.sprite = _MatSys._spr._get_sprite("bd1", "[bd_H2_1]");
        
    }

    float find_generation_x(){
        return place_world_pos.x;
    }

    float find_generation_y() {
        float plant_height = 0;
        float cell_size = 1;
        float tolerance = 0.01f;
        Vector3 ray_pos = new(_place_pos.x, place_world_pos.y + plant_height + cell_size - tolerance, 0);
        RaycastHit2D hit = Physics2D.Raycast(ray_pos, Vector2.down);

        if (hit.collider != null) {
            Vector3 collision_point = hit.point;

            // float y_distance = ray_pos.y - collision_point.y;
            return collision_point.y;
        } else {
            Debug.LogWarning("No collider");
            return -1;
        }
    }

    
}
