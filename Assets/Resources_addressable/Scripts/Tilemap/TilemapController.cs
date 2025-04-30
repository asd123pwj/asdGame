using System.Collections;
using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;
using System.Linq;
using Unity.Jobs;
using UnityEngine.AddressableAssets;
using UnityEngine.ResourceManagement.AsyncOperations;
using Cysharp.Threading.Tasks;
using System.Threading;
using System;
using System.Threading.Tasks;


public class TilemapController: BaseClass{
    // ---------- system tool ----------
    // HierarchySearch _HierSearch;
    // ControlSystem _CtrlSys { get => _GCfg._CtrlSys; }
    // InputSystem _input_base;
    // GameConfigs _GCfg;
    // TilemapSystem TMapSys { get => _GCfg._TMapSys; }
    // ---------- unity ----------
    // Tilemap TMap_modify { get => _TMapSys._tilemap_modify; }
    // ---------- sub script ----------
    // TilemapBlockGenerator TMapGen { get => _TMapSys._TMapGen; }
    // TilemapDraw TMapDraw { get => _TMapSys._TMapDraw; }
    // TilemapAxis TMapCfg { get => _TMapSys._TMapAxis; }
    // TilemapSaveLoad TMapSL { get => _TMapSys._TMapSL; }
    // ---------- status ---------- // 
    // private Vector3Int _tilemapBlock_offsets;
    // private bool _tilemapBlockChange = true;
    public Dictionary<string, List<Vector3Int>> _TMapsHaveDraw = new();
    public Vector3Int _query_point;
    public Vector3Int _query_point_prev = new(-999999999, -999999999, -999999999);
    // public override float _update_interval { get; set; } = 0.5f;
    CancellationTokenSource cts;
    UniTask task;


    public TilemapController(){
        _update_interval = 0.5f;
    }

    public override async UniTask _loop(){
        // return;
        while(true){
            _task_update_queryPoint();
            if (_query_point_prev == _query_point) {
                await UniTask.Delay(GameConfigs._sysCfg.TMap_interval_per_loading);
                continue;
            }
            _query_point_prev = _query_point;
            cts?.Cancel();try {
            await task; 
            } catch (OperationCanceledException) { }
            cts = new();
            task = draw_by_cmd(cts.Token);
        }
    }

    async UniTask draw_by_cmd(CancellationToken ct){
        // Vector3Int prepare_r = GameConfigs._sysCfg.TMap_prepare_blocksAround_RadiusMinusOne_loading;
        Vector3Int draw_r = GameConfigs._sysCfg.TMap_draw_blocksAround_RadiusMinusOne_loading;
        int maxRadius = Mathf.Max(draw_r.x, draw_r.y);
        List<UniTask> tasks = new();
        for (int radius = 0; radius <= maxRadius; radius++){
            for (int x = -radius; x <= radius; x++){
                tasks.Add(draw_block(x, -radius, ct));
                // tasks.Add(UniTask.RunOnThreadPool(() => draw_block(x, -radius, ct)));
                if (tasks.Count >= GameConfigs._sysCfg.TMap_blocks_per_loading) { await UniTask.WhenAll(tasks); tasks.Clear(); }
                tasks.Add(draw_block(x, radius, ct));  
                // tasks.Add(UniTask.RunOnThreadPool(() => draw_block(x, radius, ct)));
                if (tasks.Count >= GameConfigs._sysCfg.TMap_blocks_per_loading) { await UniTask.WhenAll(tasks); tasks.Clear(); }
            }
            
            for (int y = -radius + 1; y < radius; y++){
                tasks.Add(draw_block(-radius, y, ct)); 
                // tasks.Add(UniTask.RunOnThreadPool(() => draw_block(-radius, y, ct)));
                if (tasks.Count >= GameConfigs._sysCfg.TMap_blocks_per_loading) { await UniTask.WhenAll(tasks); tasks.Clear(); }
                tasks.Add(draw_block(radius, y, ct));  
                // tasks.Add(UniTask.RunOnThreadPool(() => draw_block(radius, y, ct)));
                if (tasks.Count >= GameConfigs._sysCfg.TMap_blocks_per_loading) { await UniTask.WhenAll(tasks); tasks.Clear(); }
            }
        }
    }

    async UniTask draw_block(int x, int y, CancellationToken ct){
        if (Mathf.Abs(x) > GameConfigs._sysCfg.TMap_draw_blocksAround_RadiusMinusOne_loading.x || Mathf.Abs(y) > GameConfigs._sysCfg.TMap_draw_blocksAround_RadiusMinusOne_loading.y) 
            return;
        await _Msg._send2COMMAND($"TMapGen --x_block {_query_point.x + x} --y_block {_query_point.y + y}", ct);
    }



    public void _task_update_queryPoint(){
        if (_CtrlSys == null || _CtrlSys._player == null) {
            _query_point = Vector3Int.zero;
        }
        else{
            Vector3 player_pos = _CtrlSys._player._self.transform.position;
            // _query_point = TilemapAxis._mapping_worldPos_to_blockOffsets(player_pos, new(0, MapLayerType.Middle));
            _query_point = TilemapAxis._mapping_worldPos_to_blockOffsets(player_pos, _CtrlSys._get_current_layer());
            
        }
    }

    public async UniTask _prepare_block(Vector3Int block_offsets, LayerType layer_type, CancellationToken? ct){
        // TilemapBlock block = await TilemapBlock._get_force_async(block_offsets, layer_type);
        // UniTask.RunOnThreadPool(() => TilemapBlock._get_force_async(block_offsets, layer_type)).Forget();
        TilemapBlock block = await UniTask.RunOnThreadPool(() => TilemapBlock._get_force_waitInitDone(block_offsets, layer_type));
        await UniTask.RunOnThreadPool(() => block._prepare_me(ct));
        // block._terr._generate_terrain();
    }

    public async UniTask _draw_block_complete(Vector3Int block_offsets, LayerType layer_type, CancellationToken? ct){
        TilemapBlock block = await TilemapBlock._get_force_waitInitDone(block_offsets, layer_type);
        await UniTask.RunOnThreadPool(() => block._prepare_me(ct));
        await block._draw_me(ct);
    }

    public override bool _check_allow_init(){
        if (!_sys._initDone) return false;
        if (!_MatSys._check_all_info_initDone()) return false;
        if (!_MatSys._tile._check_P3D_all_loaded()) return false;
        if (!_InputSys._initDone) return false;
        return true;
    }



}
