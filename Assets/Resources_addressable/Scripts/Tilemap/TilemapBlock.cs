using System.Collections.Generic;
using UnityEngine;
using MathNet.Numerics.LinearAlgebra;
using UnityEngine.Tilemaps;

public struct LayerInfo{
    public int tile_ID;
    public Matrix<int> layer;
}

public class TilemapBlock: BaseClass{
    public string terrain_ID;
    public string[] terrain_tags;
    public Vector3Int offsets;
    public Vector3Int size;
    public int seed;
    // public BoundTiles bounds;
    public float scale;
    public Vector3Int up;
    public Vector3Int down;
    public Vector3Int left;
    public Vector3Int right;
    public List<Vector3Int> groundPos;
    public string[] direction;
    public bool direction_reverse;
    public string[,] map;
    public List<LayerInfo> layers;
    public bool isExist;

    Noise _noise;


    public TilemapBlock(int seed=-1){
        if (seed == -1)
            seed = Random.Range(0, 1000000);
        this.seed = seed;
        _noise = new Noise(seed);
    }



    public float _perlin(int x, int y, float scale){
        x += offsets.x * size.x;
        y += offsets.y * size.y;
        float perlin = _noise._perlin(x, y, scale);
        return perlin;
    }
    
    public float _perlin(int x, float scale){
        x += offsets.x * size.x;
        float perlin = _noise._perlin(x, scale);
        return perlin;
    }

    public float _perlin(int x, int y){
        return _perlin(x, y, scale);
    }

    public float _perlin(int x){
        return _perlin(x, scale);
    }
}