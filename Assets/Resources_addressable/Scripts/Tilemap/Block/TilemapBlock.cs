using System.Collections.Generic;
using UnityEngine;
using MathNet.Numerics.LinearAlgebra;
using UnityEngine.Tilemaps;
using MathNet.Numerics.LinearAlgebra.Single;

public struct LayerInfo{
    public int tile_ID;
    public Matrix<int> layer;
}

public class TilemapBlock: BaseClass{
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
    public string[,] map;
    public Matrix<int> typeMap;
    public string layer;
    public bool isExist;

    public int initStage;

    public TilemapBlock(){
        typeMap = Matrix<int>.Build.Dense(size.x, size.y, 0);
    }

    public void _update_typeMap(){
        for (int i = 0; i < size.x; i++){
            for (int j = 0; j < size.y; j++){
                typeMap[i, j] = map[i, j] == "0" ? 0 : 1;
            }
        }
    }

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