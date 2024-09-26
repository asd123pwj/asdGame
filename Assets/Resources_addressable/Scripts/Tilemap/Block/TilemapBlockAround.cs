using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;


public class TilemapBlockAround: BaseClass {
    TilemapAxis _tilemap_base { get => _TMapSys._TMapAxis; }
    // readonly GameConfigs _game_configs;
    TilemapBlock _block;
    TilemapTerrain _terrain { get => _TMapSys._TMapGen._terrain; }
    public TilemapBlock up { get { return _get_around("up"); }}
    public TilemapBlock down { get { return _get_around("down"); }}
    public TilemapBlock left { get { return _get_around("left"); }}
    public TilemapBlock right { get { return _get_around("right"); }}
    public TerrainHier1Info up_terrainInfo { get { return _get_terrainInfo("up"); }}
    public TerrainHier1Info down_terrainInfo { get { return _get_terrainInfo("down"); }}
    public TerrainHier1Info left_terrainInfo { get { return _get_terrainInfo("left"); }}
    public TerrainHier1Info right_terrainInfo { get { return _get_terrainInfo("right"); }}
    public TerrainHier2Info up_terrainType { get { return _get_terrainType("up"); }}
    public TerrainHier2Info down_terrainType { get { return _get_terrainType("down"); }}
    public TerrainHier2Info left_terrainType { get { return _get_terrainType("left"); }}
    public TerrainHier2Info right_terrainType { get { return _get_terrainType("right"); }}

    public TilemapBlockAround(TilemapBlock block){
        _block = block;
        // _tilemap_base = tilemap_base;
        // _game_configs = game_configs;
        // _terrain = terrain;
    }

    // public void _set_block(TilemapBlock block){
    //     _block = block;
    // }

    public TerrainHier1Info _get_terrainInfo(string direction){
        TilemapBlock around_block = _get_around(direction);
        if (around_block.isExist) return _terrain.ID2TerrainHier1[around_block.terrain_ID];
        else return new();
    }

    public TerrainHier2Info _get_terrainType(string direction){
        TilemapBlock around_block = _get_around(direction);
        if (around_block.isExist) return _terrain.tags2TerrainHier2[around_block.terrain_tags];
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
        // if (_TMapSys._TMapMon._check_block_load(block_offsets, "Block")){
        TilemapBlock block_around =
            _TMapSys._TMapMon._check_block_load(block_offsets, "L1_Middle") 
            ? _TMapSys._TMapMon._get_block(block_offsets, "L1_Middle")
            : new();
        // }
        // TilemapBlock block_around = _TMapSys._TMapMon._get_block(block_offsets, "Block");//.Contains(block_offsets) ? _tilemap_base.__blockLoads_infos[block_offsets] : new();
        return block_around;
    }
}

