using System.Collections.Concurrent;
using System.Collections.Generic;
using System.Linq;
using System;
using Unity.VisualScripting;
using UnityEngine;
using System.Threading;

public class TilemapBlockMineral: BaseClass {
    // TilemapAxis _tilemap_base { get => TilemapAxis; }
    // GameConfigs _GCfg;
    // TilemapTerrain _terrain;

    public TilemapBlockMineral(){
        // _tilemap_base = tilemap_base;
        // _GCfg = game_configs;
        // _terrain = terrain;
    }


    // public TilemapBlock _generate_2DBlock_mineral(TilemapBlock block){
    //     // ---------- init ----------
    //     Vector3Int BSize = _GCfg._sysCfg.TMap_tiles_per_block;    // for convenience
    //     float perlin;
    //     int tile_index; // for generate different mineral in different place
    //     RaritySearcher rarity_searcher = new(_tilemap_base, _GCfg);
    //     // tile to rarity
    //     string[] minerals = _MatSys._terrain._ID2TerrainHier1[block.terrain_ID].minerals;
    //     if (minerals.Count() == 0) return block;
    //     Dictionary<string, float> tileID2rarity = rarity_searcher._mapping_tilesID_to_rarity(minerals);
    //     // ---------- fill map ----------
    //     for (int x = 0; x < BSize.x; x++){
    //         for (int y = 0; y < BSize.y; y++){
    //             if (block.map._get_tile(x, y) == _GCfg._empty_tile) continue;
    //             tile_index = 0;
    //             foreach (KeyValuePair<string, float> kvp in tileID2rarity){
    //                 tile_index += 1;
    //                 perlin = block._perlin(x + BSize.x * tile_index, y + BSize.y * tile_index, 4f);
    //                 if(perlin > kvp.Value){
    //                     block.map._set_tile(x, y, kvp.Key);
    //                     break;
    //                 }
    //             }
    //         }
    //     }
    //     return block;
    // }

}

// class RaritySearcher{
//     Dictionary<string, float> _rarity = new() {
//         {"common", 0.8f},
//         {"uncommon", 0.6f},
//         {"rare", 0.4f},
//         {"mysterious", 0.2f},
//         {"root", 0.1f}};
//     // TilemapAxis _tilemap_base;
//     GameConfigs GCfg;

//     public RaritySearcher(GameConfigs game_configs){
//         // _tilemap_base = tilemap_base;
//         GCfg = game_configs;
//     }

//     float mapping_tileID_to_rarity(string tile_ID){
//         // string tile_name = GCfg._MatSys._TMap.__ID2tileName[tile_ID];
//         // string[] tile_tags = GCfg._MatSys._TMap.__tiles_info.tiles[tile_name].tags;
//         // while (GCfg._MatSys._TMap._check_loader(tile_ID)){
//         //     Debug.Log("waitting for tile to load, tile ID: " + tile_ID);
//         //     Thread.Sleep(100);
//         // }
//         string[] tile_tags = GCfg._MatSys._tile._get_info(tile_ID).tags;
//         foreach (KeyValuePair<string, float> kvp in _rarity){
//             if (tile_tags.Contains(kvp.Key)) return 1 - kvp.Value;
//         }
//         throw new ArgumentException("404: Rarity of tile-" + tile_ID + " Not Found.");
//     }

//     public Dictionary<string, float> _mapping_tilesID_to_rarity(string[] tile_ID){
//         Dictionary<string, float> rarity_dict = new();
//         // The tile further back has a higher priority
//         for (int i = tile_ID.Count()-1; i >= 0; i--){
//             rarity_dict.Add(tile_ID[i], mapping_tileID_to_rarity(tile_ID[i]));
//         }
//         return rarity_dict;
//     }
// }