using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using Unity.VisualScripting;
using UnityEngine;


public class TilemapBlockAround: BaseClass {
    // readonly GameConfigs _game_configs;
    TilemapBlock _block;
    // TilemapTerrain _terrain => _TMapSys._TMapGen._terrain; 
    public TilemapBlock up => _get_around("up"); 
    public TilemapBlock down => _get_around("down"); 
    public TilemapBlock left => _get_around("left"); 
    public TilemapBlock right => _get_around("right"); 
    public TerrainHier1 up_terrainInfo => _get_terrainInfo("up"); 
    public TerrainHier1 down_terrainInfo => _get_terrainInfo("down"); 
    public TerrainHier1 left_terrainInfo => _get_terrainInfo("left"); 
    public TerrainHier1 right_terrainInfo => _get_terrainInfo("right"); 
    // public TerrainHier2Info up_terrainType => _get_terrainType("up"); 
    // public TerrainHier2Info down_terrainType => _get_terrainType("down"); 
    // public TerrainHier2Info left_terrainType => _get_terrainType("left"); 
    // public TerrainHier2Info right_terrainType => _get_terrainType("right"); 

    public TilemapBlockAround(TilemapBlock block){
        _block = block;
    }

    public TerrainHier1 _get_terrainInfo(string direction){
        TilemapBlock around_block = _get_around(direction);
        if (around_block.isExist) return _MatSys._terrain._ID2TerrainHier1[around_block.terrain_ID];
        else return new();
    }

    // public TerrainHier2Info _get_terrainType(string direction){
    //     TilemapBlock around_block = _get_around(direction);
    //     if (around_block.isExist) return _terrain.tags2TerrainHier2[around_block.terrain_tags];
    //     else return new();
    // }

    public TilemapBlock _get_around(string direction){
        Vector3Int block_offsets = new();
        switch (direction){
            case "up":
                block_offsets = _block.offsets + Vector3Int.up;
                break;
            case "down":
                block_offsets = _block.offsets + Vector3Int.down;
                break;
            case "left":
                block_offsets = _block.offsets + Vector3Int.left;
                break;
            case "right":
                block_offsets = _block.offsets + Vector3Int.right;
                break;
        }
        // if (direction == "up")
        //     direction_offsets.y = 1;
        // else if (direction == "down")
        //     direction_offsets.y = -1;
        // else if (direction == "left")
        //     direction_offsets.x = -1;
        // else if (direction == "right")
        //     direction_offsets.x = 1;
        // Vector3Int block_offsets = new(_block.offsets.x + direction_offsets.x, _block.offsets.y + direction_offsets.y);
        // if (_TMapSys._TMapMon._check_block_load(block_offsets, "Block")){
        TilemapBlock block_around =
            _TMapSys._TMapMon._check_block_load(block_offsets, new LayerType()) 
            ? _TMapSys._TMapMon._get_block(block_offsets, new LayerType())
            : new();
        // }
        // TilemapBlock block_around = _TMapSys._TMapMon._get_block(block_offsets, "Block");//.Contains(block_offsets) ? _tilemap_base.__blockLoads_infos[block_offsets] : new();
        return block_around;
    }
}

