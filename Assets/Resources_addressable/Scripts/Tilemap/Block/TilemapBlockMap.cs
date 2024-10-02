using System.Collections.Generic;
using UnityEngine;


public class TilemapBlockMap{
    public Vector3Int size;
    string[,] map;

    public int initStage;

    public TilemapBlockMap(Vector3Int size){
        map = new string[size.x, size.y];
    }


    // public string[,] _get_map() => map;
    public string _get(int x, int y) => map[x, y];
    public string _get(Vector3Int pos) => map[pos.x, pos.y];

    public void _set(Dictionary<Vector3Int, string> map){
        foreach (var pair in map){
            _set(pair.Key, pair.Value);
        }
    } 
    public void _set(Vector3Int pos, string tile_ID){
        map[pos.x, pos.y] = tile_ID;
    } 
    public void _set(int x, int y, string tile_ID){
        map[x, y] = tile_ID;
    } 


    
}