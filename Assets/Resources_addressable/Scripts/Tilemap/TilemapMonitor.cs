using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TilemapMonitor: BaseClass{
    // ---------- Config ---------- //
    // ---------- Sub Scripts ---------- //
    // TilemapAxis TMapCfg { get => _sys._TMapSys._TMapAxis; }
    // ---------- Tilemap Status ---------- //
    // ----- Blocks ----- //
    public Dictionary<string, Dictionary<Vector3Int, TilemapBlock>> _TMap_blocks => TilemapBlock.our;
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
            { new LayerType(0).ToString(), new GameObject(new LayerType(0).ToString()) },
            { new LayerType(1).ToString(), new GameObject(new LayerType(1).ToString()) },
            { new LayerType(2).ToString(), new GameObject(new LayerType(2).ToString()) },
            { new LayerType(3).ToString(), new GameObject(new LayerType(3).ToString()) },
            { new LayerType(4).ToString(), new GameObject(new LayerType(4).ToString()) },
            { new LayerType(5).ToString(), new GameObject(new LayerType(5).ToString()) },
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
        foreach(var tilemap_type in _TMap_containers.Keys){
            _TMap_blocks.Add(tilemap_type, new());
        }
    }


    // public bool _load_block(TilemapBlock block){
    //     if (_check_block_load(block.offsets, block.layer)) return false;
    //     _TMap_blocks[block.layer].Add(block.offsets, block);
    //     return true;
    // } 

    
    // public void _update_block(TilemapBlock block){
    //     if (_check_block_load(block.offsets, block.layer)) 
    //         _TMap_blocks[block.layer][block.offsets] = block;
    //     else
    //         _TMap_blocks[block.layer].Add(block.offsets, block);
    // } 

    // public void _unload_block(Vector3Int block_offsets, string layer_type){
    //     clear_block_tilemap(block_offsets, layer_type);
    //     if (_TMap_blocks[layer_type].ContainsKey(block_offsets)) _TMap_blocks[layer_type].Remove(block_offsets);
    // }

    void clear_block_tilemap(Vector3Int block_offsets, string layer_type){ /* no implement */}

    public bool _check_block_load(Vector3Int block_offsets, LayerType layer_type) => _check_block_load(block_offsets, layer_type.ToString());
    public bool _check_block_load(Vector3Int block_offsets, string layer_type){
        return _TMap_blocks[layer_type].ContainsKey(block_offsets);
    }


    public TilemapBlock _get_block(Vector3Int block_offsets, LayerType layer_type) => _get_block(block_offsets, layer_type.ToString());
    public TilemapBlock _get_block(Vector3Int block_offsets, string layer_type){
        return _TMap_blocks[layer_type][block_offsets];
    }


    // public TilemapBlockGameObject _get_blkObj(Vector3Int block_offsets, string tilemap_type){
    //     return _get_TilemapBlockGameObject(block_offsets, tilemap_type);
    // }
    
    // public TilemapBlockGameObject _get_blkObj(Vector3Int block_offsets, LayerTTT layer_type) => _get_blkObj(block_offsets, layer_type.ToString());
    public TilemapBlockGameObject _get_blkObj(Vector3Int block_offsets, LayerType layer_type){
        if(!_TMap_objs[layer_type.ToString()].ContainsKey(block_offsets)){
            TilemapBlockGameObject obj = _TMapSys._TMapObjGen._init_tilemap_gameObject(block_offsets, layer_type);
            _TMap_objs[layer_type.ToString()].Add(block_offsets, obj);
        }
        return _TMap_objs[layer_type.ToString()][block_offsets];
    }

    
}
