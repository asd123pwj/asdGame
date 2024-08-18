using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;


public class TilemapAroundBlock {
    readonly TilemapConfig _tilemap_base;
    readonly GameConfigs _game_configs;
    TilemapBlock _block;
    readonly TilemapTerrain _terrain;
    public TilemapBlock up { get { return _get_around("up"); }}
    public TilemapBlock down { get { return _get_around("down"); }}
    public TilemapBlock left { get { return _get_around("left"); }}
    public TilemapBlock right { get { return _get_around("right"); }}
    public TerrainInfo up_terrainInfo { get { return _get_terrainInfo("up"); }}
    public TerrainInfo down_terrainInfo { get { return _get_terrainInfo("down"); }}
    public TerrainInfo left_terrainInfo { get { return _get_terrainInfo("left"); }}
    public TerrainInfo right_terrainInfo { get { return _get_terrainInfo("right"); }}
    public TerrainType up_terrainType { get { return _get_terrainType("up"); }}
    public TerrainType down_terrainType { get { return _get_terrainType("down"); }}
    public TerrainType left_terrainType { get { return _get_terrainType("left"); }}
    public TerrainType right_terrainType { get { return _get_terrainType("right"); }}

    public TilemapAroundBlock(TilemapConfig tilemap_base, GameConfigs game_configs, TilemapTerrain terrain){
        _tilemap_base = tilemap_base;
        _game_configs = game_configs;
        _terrain = terrain;
    }

    public void _set_block(TilemapBlock block){
        _block = block;
    }

    public TerrainInfo _get_terrainInfo(string direction){
        TilemapBlock around_block = _get_around(direction);
        if (around_block.isExist) return _terrain.ID2TerrainInfo[around_block.terrain_ID];
        else return new();
    }

    public TerrainType _get_terrainType(string direction){
        TilemapBlock around_block = _get_around(direction);
        if (around_block.isExist) return _terrain.tags2TerrainType[around_block.terrainType_tags];
        else return new();
    }

    public TilemapBlock _get_around(string direction){
        Vector3Int direction_offsets = new();
        if (direction == "up")
            direction_offsets.y = 1;
        else if (direction == "down")
            direction_offsets.y = -1;
        else if (direction == "left")
            direction_offsets.x = -1;
        else if (direction == "right")
            direction_offsets.x = 1;
        Vector3Int block_offsets = new(_block.offsets.x + direction_offsets.x, _block.offsets.y + direction_offsets.y);
        TilemapBlock block_around = _tilemap_base.__blockLoads_list.Contains(block_offsets) ? _tilemap_base.__blockLoads_infos[block_offsets] : new();
        return block_around;
    }
}

