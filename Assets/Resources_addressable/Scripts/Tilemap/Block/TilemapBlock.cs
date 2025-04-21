using System.Collections.Generic;
using UnityEngine;
using MathNet.Numerics.LinearAlgebra;
using UnityEngine.Tilemaps;
using MathNet.Numerics.LinearAlgebra.Single;
using System;
using Cysharp.Threading.Tasks;


public class TilemapBlock: BaseClass{
    // ---------- Ours ---------- //
    public static Dictionary<string, Dictionary<Vector3Int, TilemapBlock>> our = new();
    // ---------- Config ---------- //
    public TilemapBlockGameObject obj;
    public string terrain_ID;
    public string[] terrain_tags;
    public Vector3Int offsets;
    public Vector3Int size => GameConfigs._sysCfg.TMap_tiles_per_block;
    public List<Vector3Int> groundPos;
    public string[] direction;
    public bool direction_reverse;
    public TilemapBlockMap map;
    public LayerType layer;
    public TilemapBlockAround around => new(this);
    public TilemapBlockMapStatus status;
    public TilemapBlockDraw _draw;
    public TilemapBlockTerrain _terr;
    // ---------- Status ---------- //
    public bool isExist;
    public bool isDrawed;

    public int initStage;

    // public TilemapBlock(){}
    public TilemapBlock(Vector3Int offsets, LayerType layer){
        if(!our.ContainsKey(layer.ToString())){ our.Add(layer.ToString(), new()); }
        our[layer.ToString()].Add(offsets, this);
        this.offsets = offsets;
        this.layer = layer;
        isExist = true;
        // _terr = new(this);
    }

    public override bool _check_allow_init(){
        if (layer == null) return false;
        if (offsets == null) return false;
        return true;
    }

    public override void _init(){
        obj = new(this);
        map = new(this);
        status = new(this);
        _draw = new(this);
        // _terr = new(this);
    }

    public override async UniTask _init_async(){
        await UniTask.RunOnThreadPool(() => _terr = new(this));
    }

    public async UniTask _draw_me(){
        if (!isDrawed) {
            isDrawed = true;
        }
        else{
            return;
        }
        await _wait_init_done();
        await _draw._draw_block(this);
    }

    public static TilemapBlock _get(Vector3Int offsets, LayerType layer){
        if (!(our.ContainsKey(layer.ToString()) && our[layer.ToString()].ContainsKey(offsets))){
            return new(offsets, layer);
        }
        return our[layer.ToString()][offsets];
    }

    public static async UniTask<TilemapBlock> _get_async(Vector3Int offsets, LayerType layer){
        TilemapBlock block;
        if (!(our.ContainsKey(layer.ToString()) && our[layer.ToString()].ContainsKey(offsets))){
            block = new(offsets, layer);
        }
        else{
            block = our[layer.ToString()][offsets];
        }
        await block._wait_init_done();
        return block;
    }

    
}