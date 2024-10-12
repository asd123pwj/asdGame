using System.Collections.Generic;
using UnityEngine;
using MathNet.Numerics.LinearAlgebra;
using UnityEngine.Tilemaps;
using MathNet.Numerics.LinearAlgebra.Single;
using System;


public class TilemapBlock: BaseClass{
    // - Dictionary<layer, Dictionary<block_offsets, block>>
    public static Dictionary<string, Dictionary<Vector3Int, TilemapBlock>> our = new();
    public TilemapBlockGameObject obj => _TMapSys._TMapMon._get_blkObj(offsets, layer);
    public string terrain_ID;
    public string[] terrain_tags;
    public Vector3Int offsets;
    public Vector3Int size => _GCfg._sysCfg.TMap_tiles_per_block;
    // public int seed;
    // public BoundTiles bounds;
    // public float scale;
    // public Vector3Int up;
    // public Vector3Int down;
    // public Vector3Int left;
    // public Vector3Int right;
    public List<Vector3Int> groundPos;
    public string[] direction;
    public bool direction_reverse;
    // string[,] map;
    public TilemapBlockMap map;
    // public List<Vector3Int> status_mapGround;
    public LayerType layer;
    public bool isExist;
    public TilemapBlockAround around => new(this);
    public TilemapBlockMapStatus status;

    public int initStage;

    public TilemapBlock(){}
    public TilemapBlock(Vector3Int offsets, LayerType layer){
        this.offsets = offsets;
        this.layer = layer;
        isExist = true;
        our[layer.ToString()].Add(offsets, this);
        map = new(this);
        status = new(map);
        // _TMapSys._TMapObjGen._init_tilemap_gameObject(offsets, layer);
    }


    // public float _perlin(int x, int y, float scale){
    //     x += offsets.x * size.x;
    //     y += offsets.y * size.y;
    //     float perlin = _GCfg._noise._perlin_01(x, y, scale);
    //     return perlin;
    // }
    
    // public float _perlin(int x, float scale){
    //     x += offsets.x * size.x;
    //     float perlin = _GCfg._noise._perlin_01(x, scale);
    //     return perlin;
    // }

    // public float _perlin(int x, int y){
    //     return _perlin(x, y, scale);
    // }

    // public float _perlin(int x){
    //     return _perlin(x, scale);
    // }

    
}