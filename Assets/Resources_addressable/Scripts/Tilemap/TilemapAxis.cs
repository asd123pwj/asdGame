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

public enum MapLayerType{
    Back,
    BackDecoration,
    MiddleP3D,
    Middle,
    MiddleDecoration,
    Front,
    FrontDecoration,
}
public class LayerType{
    public static int sortingLayerID_default = SortingLayer.NameToID("Layer");
    public int sortingLayerID = LayerType.sortingLayerID_default;
    public MapLayerType type = MapLayerType.Middle;
    public int layer = 0;
    static readonly int num_layerType = Enum.GetValues(typeof(MapLayerType)).Length;
    public int sortingOrder;
    public Vector3 offsets;
    string layer_name;

    public LayerType(){
        sortingOrder = _mapping_layerType_to_sortOrder();
        offsets = _mapping_layerType_to_GameObjectOffsets();
        layer_name = $"L{layer}_{type}";
    }
    public LayerType(int sort_order){
        layer = sort_order / num_layerType;
        type = (MapLayerType)(sort_order % num_layerType);
        offsets = _mapping_layerType_to_GameObjectOffsets();
        this.sortingOrder = sort_order;
        layer_name = $"L{layer}_{type}";
    }
    public LayerType(string layer_type){
        string[] layer_info = layer_type.Split('_'); // e.g., L1_Middle => [L1, Middle]
        layer = int.Parse(layer_info[0][1..]); 
        type = (MapLayerType)Enum.Parse(typeof(MapLayerType), layer_info[1]);
        sortingOrder = _mapping_layerType_to_sortOrder();
        offsets = _mapping_layerType_to_GameObjectOffsets();
        layer_name = $"L{layer}_{type}";
    }
    public LayerType(int layer, MapLayerType type){
        this.layer = layer;
        this.type = type;
        sortingOrder = _mapping_layerType_to_sortOrder();
        offsets = _mapping_layerType_to_GameObjectOffsets();
        layer_name = $"L{layer}_{type}";
    }

    public static bool _check_type(int sort_order, MapLayerType type){
        return (sort_order % num_layerType) == (int)type;
    }

    public int _mapping_layerType_to_sortOrder(){
        int sort_order = layer * num_layerType + (int)type;
        return sort_order;
    }

    public Vector3 _mapping_layerType_to_GameObjectOffsets(){
        Vector3 offsets = layer * new Vector3(0.5f, 0.5f, 0.5f);
        if (type == MapLayerType.Back || type == MapLayerType.BackDecoration) offsets += new Vector3(0.5f, 0.5f, 0.5f); 
        return offsets;
    }

    public override string ToString() => layer_name;
}


public static class TilemapAxis{
    // public TilemapAxis(){
    // }


    public static Vector2 _mapping_inBlockPos_to_worldPos(Vector3Int in_block_pos, Vector3Int block_offsets, LayerType layer_type){
        Vector3Int map_pos = in_block_pos + block_offsets * GameConfigs._sysCfg.TMap_tiles_per_block;
        Vector2 world_pos = _mapping_mapPos_to_worldPos(map_pos, layer_type);
        // Vector3 offsets = _mapping_layerType_to_GameObjectOffsets(layer_type);
        // Vector2 world_pos = in_block_pos + block_offsets * _GCfg._sysCfg.TMap_tiles_per_block - offsets;
        return world_pos;
    }
    public static Vector3Int _mapping_inBlockPos_to_mapPos(Vector3Int in_block_pos, Vector3Int block_offsets){
        Vector3Int map_pos = in_block_pos + block_offsets * GameConfigs._sysCfg.TMap_tiles_per_block;
        return map_pos;
    }


    public static Vector3Int _mapping_worldPos_to_mapPos(Vector3 world_pos, LayerType layer_type){
        Vector3 offsets = layer_type.offsets;
        Vector3Int mapPos = new((int)Mathf.Floor(world_pos.x - offsets.x), (int)Mathf.Floor(world_pos.y - offsets.y), 0);
        return mapPos;
    }
    public static Vector3Int _mapping_worldPos_to_blockOffsets(Vector3 world_pos, LayerType layer_type){
        Vector3Int map_pos = _mapping_worldPos_to_mapPos(world_pos, layer_type);
        Vector3Int block_offsets = _mapping_mapPos_to_blockOffsets(map_pos);
        return block_offsets;
    }
    public static Vector3Int _mapping_worldPos_to_zoneOffsets(Vector3 world_pos, LayerType layer_type){
        // Vector3Int map_pos = _mapping_worldPos_to_mapPos(world_pos, layer_type);
        Vector3Int block_offsets = _mapping_worldPos_to_blockOffsets(world_pos, layer_type);
        Vector3Int zone_offsets = _mapping_blockOffsets_to_zoneOffsets(block_offsets);
        return zone_offsets;
    }
    

    public static Vector3Int _mapping_blockOffsets_to_blockOffsetsInZone(Vector3Int block_offsets){
        Vector3Int zone_size = GameConfigs._sysCfg.TMap_blocks_per_zone;
        if (block_offsets.x < 0) block_offsets.x = (Math.Abs(block_offsets.x) / zone_size.x + 1) * zone_size.x + block_offsets.x;
        if (block_offsets.y < 0) block_offsets.y = (Math.Abs(block_offsets.y) / zone_size.y + 1) * zone_size.y + block_offsets.y;
        Vector3Int in_zone = new(block_offsets.x % zone_size.x, block_offsets.y % zone_size.y, 0);
        return in_zone;
    }
    public static Vector3Int _mapping_blockOffsets_to_zoneOffsets(Vector3Int block_offsets){
        Vector3Int zone_size = GameConfigs._sysCfg.TMap_blocks_per_zone;
        Vector3Int block_pos = new((int)Mathf.Floor(1.0f * block_offsets.x / zone_size.x), (int)Mathf.Floor(1.0f * block_offsets.y / zone_size.y), 0);
        return block_pos;
    }


    public static Vector3Int _mapping_mapPos_to_blockOffsets(Vector3Int map_pos){
        Vector3Int block_size = GameConfigs._sysCfg.TMap_tiles_per_block;
        Vector3Int block_pos = new((int)Mathf.Floor(1.0f * map_pos.x / block_size.x), (int)Mathf.Floor(1.0f * map_pos.y / block_size.y), 0);
        return block_pos;
    }
    public static Vector3Int _mapping_mapPos_to_inBlockPos(Vector3Int map_pos){
        Vector3Int block_size = GameConfigs._sysCfg.TMap_tiles_per_block;
        if (map_pos.x < 0) map_pos.x = (Math.Abs(map_pos.x) / block_size.x + 1) * block_size.x + map_pos.x;
        if (map_pos.y < 0) map_pos.y = (Math.Abs(map_pos.y) / block_size.y + 1) * block_size.y + map_pos.y;
        Vector3Int in_block_pos = new(map_pos.x % block_size.x, map_pos.y % block_size.y, 0);
        return in_block_pos;
    }
    public static Vector2 _mapping_mapPos_to_worldPos(Vector3Int map_pos, LayerType layer_type){
        Vector2 world_pos = map_pos - layer_type.offsets;
        return world_pos;
    }


}
