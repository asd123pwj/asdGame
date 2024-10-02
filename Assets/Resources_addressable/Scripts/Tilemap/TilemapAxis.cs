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


public class TilemapAxis: BaseClass{
    public TilemapAxis(){
    }





    // ---------- Mapping Functions ---------- //
    public string[] _mapping_layerType_to_layerInfo(string layer_type){
        string[] layer_info = layer_type.Split('_'); // e.g., L1_Middle => [L1, Middle]
        layer_info[0] = layer_info[0][1..]; // e.g., [L1, Middle] => [1, Middle]
        return layer_info;
    }

    public Vector3 _mapping_layerType_to_GameObjectOffsets(string layer_type){
        string[] layer_info = _mapping_layerType_to_layerInfo(layer_type);
        int layer = int.Parse(layer_info[0]);
        Vector3 offsets = (layer - 1) * _GCfg._sysCfg.TMap_tilemap_obj_origin_offset["Layer"] + _GCfg._sysCfg.TMap_tilemap_obj_origin_offset[layer_info[1]];
        return offsets;
    }

    // public Vector3Int _mapping_worldXY_to_mapXY(Vector3 world_pos, Tilemap tilemap){
    //     Vector3Int map_pos = tilemap.WorldToCell(world_pos);
    //     return map_pos;
    // }

    // public Vector3Int _mapping_worldXY_to_blockXY(Vector3 world_pos, Tilemap tilemap){
    //     Vector3Int map_pos = tilemap.WorldToCell(world_pos);
    //     return _mapping_mapXY_to_blockXY(map_pos);
    // }
    public Vector2 _mapping_inBlockPos_to_worldPos(Vector3Int in_block_pos, Vector3Int block_offsets, string layer_type){
        Vector3 offsets = _mapping_layerType_to_GameObjectOffsets(layer_type);
        Vector2 world_pos = in_block_pos + block_offsets * _GCfg._sysCfg.TMap_tiles_per_block - offsets;
        // Vector2 world_pos = new((in_block_pos.x + block_offsets.x + offsets.x), (in_block_pos.y + block_offsets.y + offsets.y));
        return world_pos;

    }

    public Vector3Int _mapping_worldPos_to_mapPos(Vector3 world_pos, string layer_type){
        Vector3 offsets = _mapping_layerType_to_GameObjectOffsets(layer_type);
        Vector3Int mapPos = new((int)Mathf.Floor(world_pos.x - offsets.x), (int)Mathf.Floor(world_pos.y - offsets.y), 0);
        return mapPos;
    }
    public Vector3Int _mapping_worldPos_to_blockOffsets(Vector3 world_pos, string layer_type){
        Vector3Int map_pos = _mapping_worldPos_to_mapPos(world_pos, layer_type);
        Vector3Int block_offsets = _mapping_mapPos_to_blockOffsets(map_pos);
        return block_offsets;
    }
    public Vector3Int _mapping_worldPos_to_zoneOffsets(Vector3 world_pos, string layer_type){
        // Vector3Int map_pos = _mapping_worldPos_to_mapPos(world_pos, layer_type);
        Vector3Int block_offsets = _mapping_worldPos_to_blockOffsets(world_pos, layer_type);
        Vector3Int zone_offsets = _mapping_blockOffsets_to_zoneOffsets(block_offsets);
        return zone_offsets;
    }
    
    public Vector3Int _mapping_blockOffsets_to_zoneOffsets(Vector3Int block_offsets){
        Vector3Int zone_size = _GCfg._sysCfg.TMap_blocks_per_zone;
        Vector3Int block_pos = new((int)Mathf.Floor(1.0f * block_offsets.x / zone_size.x), (int)Mathf.Floor(1.0f * block_offsets.y / zone_size.y), 0);
        return block_pos;
    }

    public Vector3Int _mapping_mapPos_to_blockOffsets(Vector3Int map_pos){
        Vector3Int block_size = _GCfg._sysCfg.TMap_tiles_per_block;
        Vector3Int block_pos = new((int)Mathf.Floor(1.0f * map_pos.x / block_size.x), (int)Mathf.Floor(1.0f * map_pos.y / block_size.y), 0);
        return block_pos;
    }
    public Vector3Int _mapping_mapPos_to_posInBlock(Vector3Int map_pos){
        Vector3Int block_size = _GCfg._sysCfg.TMap_tiles_per_block;
        if (map_pos.x < 0) map_pos.x = (Math.Abs(map_pos.x) / block_size.x + 1) * block_size.x + map_pos.x;
        if (map_pos.y < 0) map_pos.y = (Math.Abs(map_pos.y) / block_size.y + 1) * block_size.y + map_pos.y;
        Vector3Int in_block_pos = new(map_pos.x % block_size.x, map_pos.y % block_size.y, 0);
        return in_block_pos;
    }
    public Vector3Int _mapping_blockOffsets_to_blockOffsetsInZone(Vector3Int block_offsets){
        Vector3Int zone_size = _GCfg._sysCfg.TMap_blocks_per_zone;
        if (block_offsets.x < 0) block_offsets.x = (Math.Abs(block_offsets.x) / zone_size.x + 1) * zone_size.x + block_offsets.x;
        if (block_offsets.y < 0) block_offsets.y = (Math.Abs(block_offsets.y) / zone_size.y + 1) * zone_size.y + block_offsets.y;
        Vector3Int in_zone = new(block_offsets.x % zone_size.x, block_offsets.y % zone_size.y, 0);
        return in_zone;
    }

    // public Vector3Int _mapping_mapXY_to_blockXY(Vector3Int map_pos){ // !!! 这里在tilemap偏移时会出错
    //     Vector3Int block_offsets = new Vector3Int {
    //         x = Mathf.Abs(map_pos.x) / _GCfg._sysCfg.TMap_tiles_per_block.x,
    //         y = Mathf.Abs(map_pos.y) / _GCfg._sysCfg.TMap_tiles_per_block.y};
    //     if (map_pos.x < 0) block_offsets.x = -block_offsets.x - 1;
    //     if (map_pos.y < 0) block_offsets.y = -block_offsets.y - 1;
    //     // Debug.Log("Mouse pos: [" + pos_tilemap.x + ", " + pos_tilemap.y + "].");
    //     // Debug.Log("Block offset: [" + block_offset[0] + ", " + block_offset[1] + "].");
    //     return block_offsets;
    // }

    // public Vector3Int _mapping_mapXY_to_tileXY_in_block(Vector3Int map_pos){ // !!! 这里在tilemap偏移时会出错
    //     Vector3Int block_offsets = _mapping_mapXY_to_blockXY(map_pos);
    //     Vector3Int tile_offsets = new Vector3Int {
    //         x = map_pos.x - block_offsets.x * _GCfg._sysCfg.TMap_tiles_per_block.x,
    //         y = map_pos.y - block_offsets.y * _GCfg._sysCfg.TMap_tiles_per_block.y};
    //     return tile_offsets;
    // }

}
