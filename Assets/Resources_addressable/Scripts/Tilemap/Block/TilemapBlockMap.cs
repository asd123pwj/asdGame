using System.Collections.Generic;
using UnityEngine;


public class TilemapBlockMap: BaseClass{
    public TilemapTile[,] map;
    TilemapBlock block;
    
    // public Vector3Int size => _GCfg._sysCfg.TMap_tiles_per_block;

    // public int initStage;

    public TilemapBlockMap(TilemapBlock block){
        this.block = block;
        map = new TilemapTile[block.size.x, block.size.y];
    }


    public string _get_tile_foce(int x, int y) => _get_force(x, y).tile_ID;
    public string _get_tile_force(Vector3Int pos) => _get_tile_foce(pos.x, pos.y);
    public TilemapTile _get_force(int x, int y) {
        if (x < block.size.x && y < block.size.y && x >= 0 && y >= 0){
            if (map[x, y] == null) {
                Vector3Int map_pos = TilemapAxis._mapping_inBlockPos_to_mapPos(new(x, y), block.offsets);
                map[x, y] = new(block, map_pos);
            }
            return map[x, y];
        }
        else if (x >= block.size.x){
            TilemapBlock block_right = block.around.right;
            return block_right.isExist ? block_right.map._get_force(x - block.size.x, y) : new() { tile_ID = GameConfigs._sysCfg.TMap_notLoaded_tile };
        }
        else if (y >= block.size.y){
            TilemapBlock block_up = block.around.up;
            return block_up.isExist ? block_up.map._get_force(x, y - block.size.y) : new() { tile_ID = GameConfigs._sysCfg.TMap_notLoaded_tile };
        }
        else if (x < 0){
            TilemapBlock block_left = block.around.left;
            return block_left.isExist ? block_left.map._get_force(x + block.size.x, y) : new() { tile_ID = GameConfigs._sysCfg.TMap_notLoaded_tile };
        }
        else if (y < 0){
            TilemapBlock block_down = block.around.down;
            return block_down.isExist ? block_down.map._get_force(x, y - block.size.y) : new() { tile_ID = GameConfigs._sysCfg.TMap_notLoaded_tile };
        }
        return new() { tile_ID = GameConfigs._sysCfg.TMap_notLoaded_tile };
    }

    public void _set_tile(Dictionary<Vector3Int, string> map){
        foreach (var pair in map){
            _set_tile(pair.Key, pair.Value);
        }
    } 
    public void _set_tile(Vector3Int pos, string tile_ID){
        _set_tile(pos.x, pos.y, tile_ID);
    } 
    public void _set_tile(int x, int y, string tile_ID){
        _get_force(x, y)._set_ID(tile_ID);
    } 

    // public void _update_


}