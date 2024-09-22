using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;

public class TilemapBlockGameObject{
    public GameObject obj;
    public Tilemap TMap;
    public TilemapRenderer TMap_renderer;
    public TilemapCollider2D TMap_collider;
    public Rigidbody2D rb;
    public CompositeCollider2D compositeCollider;
}

public class TilemapMonitor: BaseClass{
    // ---------- Config ----------
    // ---------- unity ----------
    // Tilemap TMap { get => _TMapSys._tilemap_modify; }
    // ---------- Sub scripts ----------
    TilemapConfig TMapCfg { get => _sys._TMapSys._TMapCfg; }
    // ---------- Tilemap Container ----------
    public Dictionary<string, GameObject> _TMap_containers;
    public Dictionary<string, Dictionary<Vector3Int, TilemapBlockGameObject>> _TMap_obj;

    public TilemapMonitor(){
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




    public void _load_block(TilemapBlock block){
        if (TMapCfg.__blockLoads_list.Contains(block.offsets)) return;
        TMapCfg.__blockLoads_infos.Add(block.offsets, block);
        TMapCfg.__blockLoads_list.Add(block.offsets);
    } 

    public void _unload_block(Vector3Int block_offsets){
        // delete in tilemap
        clear_block(block_offsets);
        // delete in memory
        if (TMapCfg.__blockLoads_infos.ContainsKey(block_offsets)) TMapCfg.__blockLoads_infos.Remove(block_offsets);
        if (TMapCfg.__blockLoads_list.Contains(block_offsets)) TMapCfg.__blockLoads_list.Remove(block_offsets);
    }

    void clear_block(Vector3Int block_offsets){
        // no implement
    }

    public TilemapBlock _get_block(Vector3Int block_offsets){
        return TMapCfg.__blockLoads_infos[block_offsets];
    }








    // public Tilemap _get_tilemap(Vector3Int block_offsets, string tilemap_type){
    //     return _get_TilemapBlockGameObject(block_offsets, tilemap_type).TMap;
    // }

    public TilemapBlockGameObject _get_blkObj(Vector3Int block_offsets, string tilemap_type){
        return _get_TilemapBlockGameObject(block_offsets, tilemap_type);
    }
    public TilemapBlockGameObject _get_TilemapBlockGameObject(Vector3Int block_offsets, string tilemap_type){
        if(!_TMap_obj[tilemap_type].ContainsKey(block_offsets)){
            TilemapBlockGameObject obj = _init_tilemap_gameObject(block_offsets, tilemap_type);
            _TMap_obj[tilemap_type].Add(block_offsets, obj);
        }
        return _TMap_obj[tilemap_type][block_offsets];
    }

    TilemapBlockGameObject _init_tilemap_gameObject(Vector3Int block_offsets, string tilemap_type="Block", string layer_name="Default"){
        TilemapBlockGameObject obj = new();

        // ----- GameObject
        obj.obj = new GameObject();
        obj.obj.transform.SetParent(_TMapSys._TMapMon._TMap_containers[tilemap_type].transform);
        obj.obj.name = block_offsets.x + "_" + block_offsets.y;
        obj.obj.layer = LayerMask.NameToLayer(layer_name);

        // ----- Tilemap
        obj.TMap = obj.obj.AddComponent<Tilemap>();

        // ----- TilemapRenderer
        obj.TMap_renderer = obj.obj.AddComponent<TilemapRenderer>();
        obj.TMap_renderer.material = _MatSys._mat._get_mat("TransparentSprite");
        // !!! Necessary for Pseudo3D: 
        // TilemapRenderer.Mode.Individual: make tile overlap tile, while Mode.Chunk make tile overlap tile only same type
        // URP render data, "Transparency Sort Axis" with "x=-1, y=-1, z=0": make top overlap bottom, make right overlap left
        // Now, I dont need to draw tilemap in different overlap, "7 sprite for 1 tile" is PAST, "1 sprite for 1 tile" is NOW.
        obj.TMap_renderer.mode = TilemapRenderer.Mode.Individual;

        // ----- TilemapCollider2D
        obj.TMap_collider = obj.obj.AddComponent<TilemapCollider2D>();
        obj.TMap_collider.usedByComposite = true;

        // ----- CompositeCollider2D
        obj.compositeCollider = obj.obj.AddComponent<CompositeCollider2D>();

        // ----- Rigidbody2D
        // When CompositeCollider2D add, Rigidbody2D will be added automatically by Unity.
        // obj.TMap_rb = obj.TMap_obj.AddComponent<Rigidbody2D>();
        obj.rb = obj.obj.GetComponent<Rigidbody2D>();
        obj.rb.bodyType = RigidbodyType2D.Static;
        obj.rb.sharedMaterial = _MatSys._phyMat._get_phyMat("Default");

        return obj;
    }
    
}
