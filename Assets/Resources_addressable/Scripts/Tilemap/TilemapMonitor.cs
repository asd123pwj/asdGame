using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TilemapMonitor: BaseClass{
    // ---------- Config ---------- //
    // ---------- Sub Scripts ---------- //
    // TilemapAxis TMapCfg { get => _sys._TMapSys._TMapAxis; }
    // ---------- Tilemap Status ---------- //
    // ----- Blocks ----- //
    // public Dictionary<string, Dictionary<Vector3Int, TilemapBlock>> _TMap_blocks => TilemapBlock.our;
    public Dictionary<string, Dictionary<Vector3Int, TilemapTile>> _TMap_tiles => TilemapTile._our;
    // ----- Containers ----- //
    public Dictionary<string, Transform> _TMap_containers;
    public Dictionary<string, Transform> _transforms;
    // ----- GameObjects ----- //
    // public Dictionary<string, Dictionary<Vector3Int, TilemapBlockGameObject>> _TMap_objs;

    public TilemapMonitor(){
    }

    public override void _init(){
        // ---------- GameObject Container Init ---------- //
        // ----- Container Init ----- //
        _TMap_containers = new(){
            { new LayerType(0).ToString(), new GameObject(new LayerType(0).ToString()).transform },
            { new LayerType(1).ToString(), new GameObject(new LayerType(1).ToString()).transform },
            { new LayerType(2).ToString(), new GameObject(new LayerType(2).ToString()).transform },
            { new LayerType(3).ToString(), new GameObject(new LayerType(3).ToString()).transform },
            { new LayerType(4).ToString(), new GameObject(new LayerType(4).ToString()).transform },
            { new LayerType(5).ToString(), new GameObject(new LayerType(5).ToString()).transform },
        };
        foreach(var obj in _TMap_containers.Values){
            obj.SetParent(_sys._grid.transform);
        }
        // ----- GameObject Init ----- //
        // _TMap_objs = new();
        // foreach(var tilemap_type in _TMap_containers.Keys){
        //     _TMap_objs.Add(tilemap_type, new());
        // }

        // ----- Transform Init ----- //
        _transforms = new(){
            { "Water", new GameObject("Water").transform },
        };
        foreach(var obj in _transforms.Values){
            obj.SetParent(_sys._grid.transform);
        }

        // ---------- GameObject Container Init ---------- //
        // foreach(var tilemap_type in _TMap_containers.Keys){
        //     _TMap_blocks.Add(tilemap_type, new());
        // }
        
        foreach(var tilemap_type in _TMap_containers.Keys){
            _TMap_tiles.Add(tilemap_type, new());
        }
    }


    void clear_block_tilemap(Vector3Int block_offsets, string layer_type){ /* no implement */}

    // public bool _check_block_load(Vector3Int block_offsets, LayerType layer_type) => _TMap_blocks[layer_type.ToString()].ContainsKey(block_offsets);
    public bool _check_tile_load(Vector3Int map_pos, LayerType layer_type) => _TMap_tiles[layer_type.ToString()].ContainsKey(map_pos);


    // public TilemapBlock _get_block(Vector3Int block_offsets, LayerType layer_type) => _TMap_blocks[layer_type.ToString()][block_offsets];


    public TilemapTile _get_tile(Vector3Int map_pos, LayerType layer_type) => _TMap_tiles[layer_type.ToString()][map_pos];


    // public TilemapBlockGameObject _get_blkObj(Vector3Int block_offsets, string tilemap_type){
    //     return _get_TilemapBlockGameObject(block_offsets, tilemap_type);
    // }
    
    // public TilemapBlockGameObject _get_blkObj(Vector3Int block_offsets, LayerTTT layer_type) => _get_blkObj(block_offsets, layer_type.ToString());
    // public TilemapBlockGameObject _get_blkObj(Vector3Int block_offsets, LayerType layer_type){
    //     // return _get_block(block_offsets, layer_type.ToString()).obj;
    //     if(!_TMap_objs[layer_type.ToString()].ContainsKey(block_offsets)){
    //         TilemapBlockGameObject obj = _TMapSys._TMapObjGen._init_tilemap_gameObject(block_offsets, layer_type);
    //         _TMap_objs[layer_type.ToString()].Add(block_offsets, obj);
    //     }
    //     return _TMap_objs[layer_type.ToString()][block_offsets];
    // }

    
}
