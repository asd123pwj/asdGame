using System.Collections.Generic;
using UnityEngine;
using System;
using Cysharp.Threading.Tasks;


public class TilemapBlockMapStatus: BaseClass{
    Vector3Int size => GameConfigs._sysCfg.TMap_tiles_per_block;
    // TilemapBlockMap map => block.map;
    TilemapBlock block;
    public static Dictionary<string, Dictionary<Vector3Int, Func<string, bool>>> rules = new() { 
        {"Ground", new ()  {{Vector3Int.up, (tile) => tile == "0" }, {Vector3Int.zero, (tile) => tile != "0" }}},
        {"TileP3D", new ()  {{Vector3Int.zero, (tile) => tile != "0" }}}
    };
    public Dictionary<string, List<Vector3Int>> positions = new();

    public TilemapBlockMapStatus(TilemapBlock block){
        this.block = block;
        foreach (string status in rules.Keys){
            positions[status] = new();
        }
    }
    
    public async UniTask _update_status_typeMap(string type){
        positions[type].Clear();
        for (int i = 0; i < size.x; i++){
            for (int j = 0; j < size.y; j++){
                bool is_status = true;
                foreach (var kvp in rules[type]){
                    // if (kvp.Value(map._get_tile_force(i + kvp.Key.x, j + kvp.Key.y))){
                    if (kvp.Value((await TilemapTile._get_force_async(block.layer, new(i + kvp.Key.x, j + kvp.Key.y))).tile_ID)){
                        continue;
                    }
                    is_status = false;
                    break;
                }
                if (is_status)
                    positions[type].Add(new(i, j));
            }
        }
    }
    // public void _update_status_typeMap(){
    //     positions["ground"].Clear();
    //     for (int i = 0; i < size.x; i++){
    //         for (int j = 0; j < size.y - 1; j++){
    //             // ----- check ground ----- //
    //             bool is_status = true;
    //             foreach (var kvp in rules["ground"]){
    //                 if (kvp.Value(map._get(i + kvp.Key.x, j + kvp.Key.y))){
    //                     continue;
    //                 }
    //                 is_status = false;
    //                 break;
    //             }
    //             if (is_status)
    //                 positions["ground"].Add(new(i, j));
    //         }
    //     }
    // }
}
