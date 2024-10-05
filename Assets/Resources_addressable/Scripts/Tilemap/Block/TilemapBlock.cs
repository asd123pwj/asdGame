using System.Collections.Generic;
using UnityEngine;
using MathNet.Numerics.LinearAlgebra;
using UnityEngine.Tilemaps;
using MathNet.Numerics.LinearAlgebra.Single;
using System;


public class TilemapBlock: BaseClass{
    // - Dictionary<layer, Dictionary<block_offsets, block>>
    public static Dictionary<string, Dictionary<Vector3Int, TilemapBlock>> our = new(); 
    public string terrain_ID;
    public string[] terrain_tags;
    public Vector3Int offsets;
    public Vector3Int size => _GCfg._sysCfg.TMap_tiles_per_block;
    // public int seed;
    // public BoundTiles bounds;
    public float scale;
    public Vector3Int up;
    public Vector3Int down;
    public Vector3Int left;
    public Vector3Int right;
    public List<Vector3Int> groundPos;
    public string[] direction;
    public bool direction_reverse;
    // string[,] map;
    public TilemapBlockMap map;
    // public List<Vector3Int> status_mapGround;
    public string layer;
    public bool isExist;
    public TilemapBlockAround around => new(this);
    public TilemapBlockMapStatus status;
    // static Dictionary<string, Dictionary<Vector3Int, Func<string, bool>>> status_rules = new() { 
    //     {"ground", new ()  {{Vector3Int.up, (tile) => tile == "0" }, {Vector3Int.zero, (tile) => tile != "0" }}} 
    // };
    // public Dictionary<string, List<Vector3Int>> status_pos = new(){
    //     {"ground", new () }
    // };
    // static List<MapStatusRule> rules => new() { 
    //         new() {
    //             status = 1,
    //             rule = {{Vector3Int.up, (tile) => tile == "0" }, {Vector3Int.zero, (tile) => tile != "0" }},
    //         }
    //     };

    public int initStage;

    public TilemapBlock(){
        map = new(this);
        status = new(map);
    }

    // public TilemapBlockAround _get_around() => new(this);

    // public string[,] _get_map() => map;
    // public string _get_map(int x, int y) => map[x, y];
    // public string _get_map(Vector3Int pos) => map[pos.x, pos.y];
    // // public void _set_map(string[,] map){
    // //     this.map = map;
    // // } 
    // public void _set_map(Dictionary<Vector3Int, string> map){
    //     foreach (var pair in map){
    //         _set_map(pair.Key, pair.Value);
    //         // this.map[pair.Key.x, pair.Key.y] = pair.Value;
    //     }
    // } 
    // public void _set_map(Vector3Int pos, string tile_ID){
    //     map[pos.x, pos.y] = tile_ID;
    // } 
    // public void _set_map(int x, int y, string tile_ID){
    //     map[x, y] = tile_ID;
    // } 

    // public void _update_status_typeMap(){
    //     // status_mapGround = new List<Vector3Int>();
    //     status.positions["ground"].Clear();
    //     for (int i = 0; i < size.x; i++){
    //         for (int j = 0; j < size.y - 1; j++){
    //             // ----- check ground ----- //
    //             int pass = 0;
    //             foreach (var kvp in status.rules["ground"]){
    //                 // status_pos["ground"].Add(new(i, j));
    //                 // status_pos["ground"].Add(new(i, j));
    //                 if (kvp.Value(map[i + kvp.Key.x, j + kvp.Key.y])){
    //                     // status_pos["ground"].Add(new Vector3Int(i, j, 0));
    //                     pass++;
    //                 }
    //                 // status_pos["ground"].Remove(new(i, j));
    //             }
    //             if (pass == status_rules["ground"].Count)
    //                 status_pos["ground"].Add(new(i, j));
    //         }
    //     }
    //     Debug.Log(status_pos["ground"].Count);
    // }

    public float _perlin(int x, int y, float scale){
        x += offsets.x * size.x;
        y += offsets.y * size.y;
        float perlin = _GCfg._noise._perlin(x, y, scale);
        return perlin;
    }
    
    public float _perlin(int x, float scale){
        x += offsets.x * size.x;
        float perlin = _GCfg._noise._perlin(x, scale);
        return perlin;
    }

    public float _perlin(int x, int y){
        return _perlin(x, y, scale);
    }

    public float _perlin(int x){
        return _perlin(x, scale);
    }

    
}