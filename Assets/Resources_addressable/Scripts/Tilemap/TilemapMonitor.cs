using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

public class TilemapBlockGameObject{
    public GameObject TMap_obj;
    public Tilemap TMap;
    public TilemapRenderer TMap_renderer;
    public TilemapCollider2D TMap_collider;
    public Rigidbody2D TMap_rb;
    public CompositeCollider2D TMap_compositeCollider;
}

public class TilemapMonitor: BaseClass{
    // ---------- Config ----------
    // ---------- unity ----------
    Tilemap TMap { get => _TMapSys._tilemap_modify; }
    // ---------- status ----------
    // public Dictionary<int[,], TilemapBlock> _blocks;
    // ---------- Tilemap Container ----------
    public Dictionary<string, GameObject> _TMap_containers;
    public Dictionary<string, Dictionary<Vector3Int, TilemapBlockGameObject>> _TMap_obj;

    // Start is called before the first frame update
    public TilemapMonitor(){
        // _GCfg = game_configs;
    }

    public override void _init(){
        _TMap_containers = new();
        _TMap_containers.Add("Block", new GameObject("Block"));
        _TMap_containers.Add("Wall", new GameObject("Wall"));

        foreach(var obj in _TMap_containers.Values){
            obj.transform.SetParent(_sys._grid.transform);
        }

        _TMap_obj = new();
        foreach(var tilemap_type in _TMap_containers.Keys){
            _TMap_obj.Add(tilemap_type, new());
        }
    }

    public Tilemap _get_tilemap(Vector3Int block_offsets, string tilemap_type){
        if(!_TMap_obj[tilemap_type].ContainsKey(block_offsets)){
            TilemapBlockGameObject obj = _init_tilemap_gameObject(block_offsets, tilemap_type);
            _TMap_obj[tilemap_type].Add(block_offsets, obj);
        }
        return _TMap_obj[tilemap_type][block_offsets].TMap;
    }

    TilemapBlockGameObject _init_tilemap_gameObject(Vector3Int block_offsets, string tilemap_type="Block", string layer_name="Default"){
        TilemapBlockGameObject obj = new();

        // ----- GameObject
        obj.TMap_obj = new GameObject();
        obj.TMap_obj.transform.SetParent(_TMapSys._TMapMon._TMap_containers[tilemap_type].transform);
        obj.TMap_obj.name = block_offsets.x + "_" + block_offsets.y;
        obj.TMap_obj.layer = LayerMask.NameToLayer(layer_name);
        // // position.z: right > left, up > down, finally, Pseudo3DTile will overall well.
        // TMap_obj.transform.position = new (0, 0, (block_pos.x + block_pos.y) * z_scale);

        // ----- Tilemap
        obj.TMap = obj.TMap_obj.AddComponent<Tilemap>();

        // ----- TilemapRenderer
        obj.TMap_renderer = obj.TMap_obj.AddComponent<TilemapRenderer>();
        obj.TMap_renderer.material = _MatSys._mat._get_mat("TilemapLitMaterial");

        // ----- TilemapCollider2D
        obj.TMap_collider = obj.TMap_obj.AddComponent<TilemapCollider2D>();
        obj.TMap_collider.usedByComposite = true;

        // ----- CompositeCollider2D
        obj.TMap_compositeCollider = obj.TMap_obj.AddComponent<CompositeCollider2D>();

        // ----- Rigidbody2D
        // When CompositeCollider2D add, Rigidbody2D will be added automatically by Unity.
        // obj.TMap_rb = obj.TMap_obj.AddComponent<Rigidbody2D>();
        obj.TMap_rb = obj.TMap_obj.GetComponent<Rigidbody2D>();
        obj.TMap_rb.bodyType = RigidbodyType2D.Static;
        obj.TMap_rb.sharedMaterial = _MatSys._phyMat._get_phyMat("Default");

        return obj;
    }
    
}
