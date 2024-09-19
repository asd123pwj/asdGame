using System;
using System.IO;
using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;
using Newtonsoft.Json;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine.Animations;
using System.Collections.Concurrent;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;


public class TilemapConfig: BaseClass{
    // ---------- object ----------
    // public SaveLoadBase __save_load_base;
    // public GameConfigs _GCfg;
    // ---------- info ----------
    // ---------- state ----------
    public List<Vector3Int> __blockLoads_list = new();
    public Dictionary<Vector3Int, TilemapBlock> __blockLoads_infos = new();

    public TilemapConfig(){
    }

    // ---------- mapping ----------

    public Vector3Int _mapping_worldXY_to_mapXY(Vector3 world_pos, Tilemap tilemap){
        Vector3Int map_pos = tilemap.WorldToCell(world_pos);
        return map_pos;
    }

    public Vector3Int _mapping_worldXY_to_blockXY(Vector3 world_pos, Tilemap tilemap){
        Vector3Int map_pos = tilemap.WorldToCell(world_pos);
        return _mapping_mapXY_to_blockXY(map_pos);
    }

    public Vector3Int _mapping_mapXY_to_blockXY(Vector3Int map_pos){ // !!! 这里在tilemap偏移时会出错
        Vector3Int block_offsets = new Vector3Int {
            x = Mathf.Abs(map_pos.x) / _GCfg._sysCfg.TMap_tiles_per_block.x,
            y = Mathf.Abs(map_pos.y) / _GCfg._sysCfg.TMap_tiles_per_block.y};
        if (map_pos.x < 0) block_offsets.x = -block_offsets.x - 1;
        if (map_pos.y < 0) block_offsets.y = -block_offsets.y - 1;
        // Debug.Log("Mouse pos: [" + pos_tilemap.x + ", " + pos_tilemap.y + "].");
        // Debug.Log("Block offset: [" + block_offset[0] + ", " + block_offset[1] + "].");
        return block_offsets;
    }

    public Vector3Int _mapping_mapXY_to_tileXY_in_block(Vector3Int map_pos){ // !!! 这里在tilemap偏移时会出错
        Vector3Int block_offsets = _mapping_mapXY_to_blockXY(map_pos);
        Vector3Int tile_offsets = new Vector3Int {
            x = map_pos.x - block_offsets.x * _GCfg._sysCfg.TMap_tiles_per_block.x,
            y = map_pos.y - block_offsets.y * _GCfg._sysCfg.TMap_tiles_per_block.y};
        return tile_offsets;
    }

}
