using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TilemapMonitor: BaseClass{
    // ---------- Config ---------- //
    // ---------- Sub Scripts ---------- //
    TilemapConfig TMapCfg { get => _sys._TMapSys._TMapCfg; }
    // ---------- Tilemap Status ---------- //
    // ----- Blocks ----- //
    public Dictionary<string, Dictionary<Vector3Int, TilemapBlock>> _TMap_blocks;
    // ----- Containers ----- //
    public Dictionary<string, GameObject> _TMap_containers;
    // ----- GameObjects ----- //
    public Dictionary<string, Dictionary<Vector3Int, TilemapBlockGameObject>> _TMap_objs;

    public TilemapMonitor(){
    }

    public override void _init(){
        // ---------- GameObject Container Init ---------- //
        // ----- Container Init ----- //
        _TMap_containers = new(){
            { "L1_Front", new GameObject("L1_Front") },
            { "L1_Middle", new GameObject("L1_Middle") },
            { "L1_Back", new GameObject("L1_Back") }
        };
        foreach(var obj in _TMap_containers.Values){
            obj.transform.SetParent(_sys._grid.transform);
        }
        // ----- GameObject Init ----- //
        _TMap_objs = new();
        foreach(var tilemap_type in _TMap_containers.Keys){
            _TMap_objs.Add(tilemap_type, new());
        }

        // ---------- GameObject Container Init ---------- //
        _TMap_blocks = new();
        foreach(var tilemap_type in _TMap_containers.Keys){
            _TMap_blocks.Add(tilemap_type, new());
        }
        // _TMap_blocks = new(){
        //     { "L1_Front", new() },
        //     { "L1_Middle", new() },
        //     { "L1_Back", new() },
        // };
    }




    public void _load_block(TilemapBlock block, string layer_type){
        if (_TMap_blocks[layer_type].ContainsKey(block.offsets)) return;
        _TMap_blocks[layer_type].Add(block.offsets, block);
        // __blockLoads_list.Add(block.offsets);
    } 

    public void _unload_block(Vector3Int block_offsets, string layer_type){
        // delete in tilemap
        clear_block(block_offsets, layer_type);
        // delete in memory
        if (_TMap_blocks[layer_type].ContainsKey(block_offsets)) _TMap_blocks[layer_type].Remove(block_offsets);
        // if (__blockLoads_list.Contains(block_offsets)) __blockLoads_list.Remove(block_offsets);
    }

    void clear_block(Vector3Int block_offsets, string layer_type){
        // no implement
    }

    public bool _check_block_load(Vector3Int block_offsets, string layer_type){
        return _TMap_blocks[layer_type].ContainsKey(block_offsets);
    }

    public TilemapBlock _get_block(Vector3Int block_offsets, string layer_type){
        return _TMap_blocks[layer_type][block_offsets];
    }


    public TilemapBlockGameObject _get_blkObj(Vector3Int block_offsets, string tilemap_type){
        return _get_TilemapBlockGameObject(block_offsets, tilemap_type);
    }
    public TilemapBlockGameObject _get_TilemapBlockGameObject(Vector3Int block_offsets, string tilemap_type){
        if(!_TMap_objs[tilemap_type].ContainsKey(block_offsets)){
            TilemapBlockGameObject obj = _TMapSys._TMapObjGen._init_tilemap_gameObject(block_offsets, tilemap_type);
            _TMap_objs[tilemap_type].Add(block_offsets, obj);
        }
        return _TMap_objs[tilemap_type][block_offsets];
    }

    
}
