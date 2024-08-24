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


public class TilemapConfig{
    // ---------- object ----------
    // public SaveLoadBase __save_load_base;
    public GameConfigs __game_configs;
    // ---------- info ----------
    // ---------- state ----------
    public List<Vector3Int> __blockLoads_list = new();
    public Dictionary<Vector3Int, TilemapBlock> __blockLoads_infos = new();

    public TilemapConfig(GameConfigs game_configs){
        __game_configs = game_configs;
        // load_tiles_info();
    }

    // ---------- mapping ----------
    // public TileBase _load_tile_by_name(string name){
    //     if (name == "") return null; // No tile
    //     if (__name2tile.ContainsKey(name)) return __name2tile[name]; // Tile have been loaded
    //     return __name2tile[name];
    //     // // Load tile
    //     // string tile_path = _tiles_info.tiles[name].path;
    //     // TileBase tile = Resources.Load<TileBase>(tile_path);
    //     // _name2tile.Add(name, tile);
    //     // return tile;
    // }

    // public TileBase _load_tile_by_ID(int ID){
    //     return _load_tile_by_name(__ID2tileName[ID]);
    // }

    // public int _map_tile_to_ID(TileBase tile){
    //     if (tile == null) return 0;
    //     else return _tiles_info.tiles[tile.name].ID;
    // }

    public Vector3Int _mapping_worldXY_to_mapXY(Vector3 world_pos, Tilemap tilemap){
        Vector3Int map_pos = tilemap.WorldToCell(world_pos);
        return map_pos;
    }

    public Vector3Int _mapping_worldXY_to_blockXY(Vector3 world_pos, Tilemap tilemap){
        Vector3Int map_pos = tilemap.WorldToCell(world_pos);
        return _mapping_mapXY_to_blockXY(map_pos);
    }

    public Vector3Int _mapping_mapXY_to_blockXY(Vector3Int map_pos){
        Vector3Int block_offsets = new Vector3Int {
            x = Mathf.Abs(map_pos.x) / __game_configs.__block_size.x,
            y = Mathf.Abs(map_pos.y) / __game_configs.__block_size.y};
        if (map_pos.x < 0) block_offsets.x = -block_offsets.x - 1;
        if (map_pos.y < 0) block_offsets.y = -block_offsets.y - 1;
        // Debug.Log("Mouse pos: [" + pos_tilemap.x + ", " + pos_tilemap.y + "].");
        // Debug.Log("Block offset: [" + block_offset[0] + ", " + block_offset[1] + "].");
        return block_offsets;
    }

    public Vector3Int _mapping_mapXY_to_tileXY_in_block(Vector3Int map_pos){
        Vector3Int block_offsets = _mapping_mapXY_to_blockXY(map_pos);
        Vector3Int tile_offsets = new Vector3Int {
            x = map_pos.x - block_offsets.x * __game_configs.__block_size.x,
            y = map_pos.y - block_offsets.y * __game_configs.__block_size.y};
        return tile_offsets;
    }

}
