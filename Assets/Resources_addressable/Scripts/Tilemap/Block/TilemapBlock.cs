using System.Collections.Generic;
using UnityEngine;
using MathNet.Numerics.LinearAlgebra;
using UnityEngine.Tilemaps;
using MathNet.Numerics.LinearAlgebra.Single;
using System;
using Cysharp.Threading.Tasks;
using System.Collections.Concurrent;
using System.Threading;
using Unity.VisualScripting;


public class TilemapBlock: BaseClass{
    // ---------- Ours ---------- //
    private readonly object _lock_our = new();
    public static ConcurrentDictionary<string, ConcurrentDictionary<Vector3Int, TilemapBlock>> our = new();
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
    public static List<CancellationTokenSource> _cts_prepare = new();
    public static List<CancellationTokenSource> _cts_draw = new();
    public bool isExist;
    public bool isDrawed;


    // public TilemapBlock(){}
    public TilemapBlock(Vector3Int offsets, LayerType layer){
        lock(_lock_our){
            // if(!our.ContainsKey(layer.ToString())){ our.TryAdd(layer.ToString(), new()); }
            var our_layer = our.GetOrAdd(layer.ToString(), _ => new ConcurrentDictionary<Vector3Int, TilemapBlock>());
            our_layer.TryAdd(offsets, this);
        }
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
        _terr = new(this);
    }

    public async UniTask _prepare_me(CancellationToken? ct){
        await UniTask.RunOnThreadPool(() => _terr._generate_terrain(ct));
    }

    public async UniTask _draw_me(CancellationToken? ct){
        await _wait_init_done();
        await _draw._draw_block_mine(ct);
    }

    public static TilemapBlock _get_force(Vector3Int offsets, LayerType layer){
        if (!(our.ContainsKey(layer.ToString()) && our[layer.ToString()].ContainsKey(offsets))){
            return new(offsets, layer);
        }
        return our[layer.ToString()][offsets];
    }

    public static async UniTask<TilemapBlock> _get_force_async(Vector3Int offsets, LayerType layer){
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