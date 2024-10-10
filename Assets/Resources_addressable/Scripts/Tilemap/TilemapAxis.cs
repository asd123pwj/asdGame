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

public enum LayerType{
    FrontDecoration,
    Front,
    MiddleDecoration,
    Middle,
    BackDecoration,
    Back
}
public class LayerTTT{
    public LayerType type = LayerType.Middle;
    public int layer = 0;
    static readonly int num_layerType = Enum.GetValues(typeof(LayerType)).Length;
    public int sort_order;
    public Vector3 offsets;

    public LayerTTT(){
        sort_order = _mapping_layerType_to_sortOrder();
        offsets = _mapping_layerType_to_GameObjectOffsets();
    }
    public LayerTTT(int sort_order){
        layer = sort_order / num_layerType;
        type = (LayerType)(sort_order % num_layerType);
        offsets = _mapping_layerType_to_GameObjectOffsets();
        this.sort_order = sort_order;
    }
    public LayerTTT(string layer_type){
        string[] layer_info = layer_type.Split('_'); // e.g., L1_Middle => [L1, Middle]
        layer = int.Parse(layer_info[0][1..]); 
        type = (LayerType)Enum.Parse(typeof(LayerType), layer_info[1]);
        sort_order = _mapping_layerType_to_sortOrder();
        offsets = _mapping_layerType_to_GameObjectOffsets();
    }
    public LayerTTT(int layer, LayerType type){
        this.layer = layer;
        this.type = type;
        sort_order = _mapping_layerType_to_sortOrder();
        offsets = _mapping_layerType_to_GameObjectOffsets();
    }

    public static bool _check_type(int sort_order, LayerType type){
        return (sort_order % num_layerType) == (int)type;
    }

    public int _mapping_layerType_to_sortOrder(){
        int sort_order = layer * num_layerType + (int)type;
        return sort_order;
    }

    public Vector3 _mapping_layerType_to_GameObjectOffsets(){
        Vector3 offsets = layer * new Vector3(0.5f, 0.5f, 0.5f);
        if (type == LayerType.Back || type == LayerType.BackDecoration) offsets += new Vector3(0.5f, 0.5f, 0.5f); 
        return offsets;
    }

    public override string ToString() => $"L{layer}_{type}";
}


public class TilemapAxis: BaseClass{
    public TilemapAxis(){
    }





    // ---------- Mapping Functions ---------- //
    // public string[] _mapping_layerType_to_layerInfo(string layer_type){
    //     string[] layer_info = layer_type.Split('_'); // e.g., L1_Middle => [L1, Middle]
    //     layer_info[0] = layer_info[0][1..]; // e.g., [L1, Middle] => [1, Middle]
    //     return layer_info;
    // }

    // public Vector3 _mapping_layerType_to_GameObjectOffsets(string layer_type){
    //     string[] layer_info = _mapping_layerType_to_layerInfo(layer_type);
    //     int layer = int.Parse(layer_info[0]);
    //     Vector3 offsets = (layer - 1) * _GCfg._sysCfg.TMap_tilemap_obj_origin_offset["Layer"] + _GCfg._sysCfg.TMap_tilemap_obj_origin_offset[layer_info[1]];
    //     return offsets;
    // }


    public Vector2 _mapping_inBlockPos_to_worldPos(Vector3Int in_block_pos, Vector3Int block_offsets, LayerTTT layer_type){
        Vector3Int map_pos = in_block_pos + block_offsets * _GCfg._sysCfg.TMap_tiles_per_block;
        Vector2 world_pos = _mapping_mapPos_to_worldPos(map_pos, layer_type);
        // Vector3 offsets = _mapping_layerType_to_GameObjectOffsets(layer_type);
        // Vector2 world_pos = in_block_pos + block_offsets * _GCfg._sysCfg.TMap_tiles_per_block - offsets;
        return world_pos;
    }
    public Vector3Int _mapping_inBlockPos_to_mapPos(Vector3Int in_block_pos, Vector3Int block_offsets){
        Vector3Int map_pos = in_block_pos + block_offsets * _GCfg._sysCfg.TMap_tiles_per_block;
        return map_pos;
    }


    public Vector3Int _mapping_worldPos_to_mapPos(Vector3 world_pos, LayerTTT layer_type){
        Vector3 offsets = layer_type.offsets;
        Vector3Int mapPos = new((int)Mathf.Floor(world_pos.x - offsets.x), (int)Mathf.Floor(world_pos.y - offsets.y), 0);
        return mapPos;
    }
    public Vector3Int _mapping_worldPos_to_blockOffsets(Vector3 world_pos, LayerTTT layer_type){
        Vector3Int map_pos = _mapping_worldPos_to_mapPos(world_pos, layer_type);
        Vector3Int block_offsets = _mapping_mapPos_to_blockOffsets(map_pos);
        return block_offsets;
    }
    public Vector3Int _mapping_worldPos_to_zoneOffsets(Vector3 world_pos, LayerTTT layer_type){
        // Vector3Int map_pos = _mapping_worldPos_to_mapPos(world_pos, layer_type);
        Vector3Int block_offsets = _mapping_worldPos_to_blockOffsets(world_pos, layer_type);
        Vector3Int zone_offsets = _mapping_blockOffsets_to_zoneOffsets(block_offsets);
        return zone_offsets;
    }
    

    public Vector3Int _mapping_blockOffsets_to_blockOffsetsInZone(Vector3Int block_offsets){
        Vector3Int zone_size = _GCfg._sysCfg.TMap_blocks_per_zone;
        if (block_offsets.x < 0) block_offsets.x = (Math.Abs(block_offsets.x) / zone_size.x + 1) * zone_size.x + block_offsets.x;
        if (block_offsets.y < 0) block_offsets.y = (Math.Abs(block_offsets.y) / zone_size.y + 1) * zone_size.y + block_offsets.y;
        Vector3Int in_zone = new(block_offsets.x % zone_size.x, block_offsets.y % zone_size.y, 0);
        return in_zone;
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
    public Vector3Int _mapping_mapPos_to_inBlockPos(Vector3Int map_pos){
        Vector3Int block_size = _GCfg._sysCfg.TMap_tiles_per_block;
        if (map_pos.x < 0) map_pos.x = (Math.Abs(map_pos.x) / block_size.x + 1) * block_size.x + map_pos.x;
        if (map_pos.y < 0) map_pos.y = (Math.Abs(map_pos.y) / block_size.y + 1) * block_size.y + map_pos.y;
        Vector3Int in_block_pos = new(map_pos.x % block_size.x, map_pos.y % block_size.y, 0);
        return in_block_pos;
    }
    public Vector2 _mapping_mapPos_to_worldPos(Vector3Int map_pos, LayerTTT layer_type){
        Vector2 world_pos = map_pos - layer_type.offsets;
        return world_pos;
    }


}
