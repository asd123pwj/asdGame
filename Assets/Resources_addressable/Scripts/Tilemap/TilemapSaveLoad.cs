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


public class TilemapSaveLoad: BaseClass{
    TilemapConfig TMapCfg { get => _sys._TMapSys._TMapCfg; }
    // GameConfigs _game_configs;

    // public TilemapSaveLoad(TilemapConfig tilemap_base, GameConfigs game_configs){
    //     _tilemap_base = tilemap_base;
    //     _game_configs = game_configs;
    // }



    // // ---------- save tilemap ----------
    // public void save_tilemap_by_tile_unload(Tilemap tilemap, Vector3Int tile_pos){
    //     save_tilemap_by_tile(tilemap, tile_pos, true);
    // }

    // public void save_tilemap_by_tile(Tilemap tilemap, Vector3Int tile_pos, bool unload=false){
    //     Vector3Int block_offsets = tilemap_base.mapping_mapXY_to_blockXY(tile_pos);
    //     save_tilemap(tilemap, block_offsets, unload);
    // }

    // public void save_tilemap_unload(Tilemap tilemap, Vector3Int block_offsets){
    //     save_tilemap(tilemap, block_offsets, true);
    // }

    // public void save_tilemap(Tilemap tilemap, Vector3Int block_offsets, bool unload=false){
    //     // Vector3Int block_offsets = mapping_mapXY_to_blockXY(tile_pos);
    //     // file name
    //     game_configs.__save_selected__ = game_configs.__save_playing__;
    //     string file_path = game_configs.__mapName_format__;
    //     file_path = file_path.Replace("{x}", block_offsets.x.ToString());
    //     file_path = file_path.Replace("{y}", block_offsets.y.ToString());
    //     // read tilemap
    //     BlockInfo tilemap_info = new BlockInfo();
    //     tilemap_info.block_offset = block_offsets;
    //     tilemap_info.map = tilemap_base.read_tilemap(tilemap, block_offsets, unload);
    //     // save
    //     string tilemap_info_json = JsonConvert.SerializeObject(tilemap_info, Formatting.Indented);
    //     File.WriteAllText(file_path, tilemap_info_json);
    // }

    // // ---------- load tilemap ----------
    // public void load_tilemap_by_tile(Tilemap tilemap, Vector3Int tile_pos){
    //     Vector3Int block_offsets = tilemap_base.mapping_mapXY_to_blockXY(tile_pos);
    //     load_tilemap(tilemap, block_offsets);
    // }

    // public void load_tilemap(Tilemap tilemap, Vector3Int block_offsets){
    //     // read file
    //     game_configs.__save_selected__ = game_configs.__save_playing__;
    //     string file_path = game_configs.__mapName_format__;
    //     file_path = file_path.Replace("{x}", block_offsets.x.ToString());
    //     file_path = file_path.Replace("{y}", block_offsets.y.ToString());
    //     if (!File.Exists(file_path)){
    //         // No data
    //         return;
    //     }
    //     string jsonText = File.ReadAllText(file_path);
    //     BlockInfo block_info = JsonConvert.DeserializeObject<BlockInfo>(jsonText);
    //     // draw
    //     tilemap_base.draw_tilemap(tilemap, block_offsets, block_info.map);
    // }

}
