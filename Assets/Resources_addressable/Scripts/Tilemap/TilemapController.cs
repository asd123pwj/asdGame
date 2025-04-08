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
    TilemapDraw TMapDraw { get => _TMapSys._TMapDraw; }
    TilemapAxis TMapCfg { get => _TMapSys._TMapAxis; }
    TilemapSaveLoad TMapSL { get => _TMapSys._TMapSL; }
    // ---------- status ---------- // 
    // private Vector3Int _tilemapBlock_offsets;
    // private bool _tilemapBlockChange = true;
    public Vector3Int _query_point;
    public Vector3Int _query_point_prev = new(-999999999, -999999999, -999999999);
    // public override float _update_interval { get; set; } = 0.5f;


    public TilemapController(){
        _update_interval = 0.5f;
    }


    public override void _init(){
        _sys._InputSys._register_action("Menu 4", tmp_draw, "isFirstDown");

    }

    public override async UniTask _loop(){
        while(true){
            _task_update_queryPoint();
            if (_query_point_prev == _query_point) {
                await UniTask.Yield();
                continue;
            }
            // _task_prepare_tilemap();
            // var task = 
            _task_prepare_gameObject();
            await UniTask.RunOnThreadPool(() => _task_prepare_tilemap());
            await _task_draw_tilemap();
            _query_point_prev = _query_point;
            await UniTask.Yield();
        }
    }

    
    public void _task_update_queryPoint(){
        if (_CtrlSys == null || _CtrlSys._player == null) {
            _query_point = Vector3Int.zero;
        }
        else{
            Vector3 player_pos = _CtrlSys._player.transform.position;
            _query_point = _TMapSys._TMapAxis._mapping_worldPos_to_blockOffsets(player_pos, new(0, MapLayerType.Middle));
        }
    }


    public bool _task_prepare_gameObject(){
        Vector3Int prepare_r = GameConfigs._sysCfg.TMap_prepare_blocksAround_RadiusMinusOne_loading;
        for (int x = -prepare_r.x; x <= prepare_r.x; x++){
            for (int y = -prepare_r.y; y <= prepare_r.y; y++){
                _TMapSys._TMapMon._get_blkObj(_query_point + new Vector3Int(x, y), new LayerType());
            }
        }
        return true;
    }

    public bool _task_prepare_tilemap(){
        // while (true) ;
        Vector3Int prepare_r = GameConfigs._sysCfg.TMap_prepare_blocksAround_RadiusMinusOne_loading;
        for (int x = -prepare_r.x; x <= prepare_r.x; x++){
            for (int y = -prepare_r.y; y <= prepare_r.y; y++){
                _TMapSys._TMapZoneGen._prepare_zone_in_blockOffsets(_query_point + new Vector3Int(x, y));
            }
        }
        return true;
    }

    public async UniTask _task_draw_tilemap(){
        Vector3Int draw_r = GameConfigs._sysCfg.TMap_prepare_blocksAround_RadiusMinusOne_loading;
        for (int x = -draw_r.x; x <= draw_r.x; x++){
            for (int y = -draw_r.y; y <= draw_r.y; y++){
                if (!_TMapSys._TMapMon._check_block_load(_query_point + new Vector3Int(x, y), new LayerType())) continue;
                TilemapBlock block = _TMapSys._TMapMon._get_block(_query_point + new Vector3Int(x, y), new LayerType());
                // TilemapBlock block = TMapGen._generate_block(_query_point + new Vector3Int(x, y));
                await TMapDraw._draw_block(block);
                
                ShadowGenerator._generate_shadow_from_compCollider(
                    _TMapSys._TMapMon._get_blkObj(block.offsets, new LayerType()).obj,
                    _TMapSys._TMapMon._get_blkObj(block.offsets, new LayerType()).compositeCollider
                );
            }
        }
    }

    public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        Vector3Int block_offsets = TMapCfg._mapping_worldPos_to_blockOffsets(keyPos.mouse_pos_world, new LayerType());
    
        List<Vector3Int> block_offsets_list = new();

        Vector3Int blocks_around_loading = GameConfigs._sysCfg.TMap_draw_blocksAround_RadiusMinusOne_loading;
        for (int x = -blocks_around_loading.x; x <= blocks_around_loading.x; x++){
            for (int y = -blocks_around_loading.y; y <= blocks_around_loading.y; y++){
                block_offsets_list.Add(new Vector3Int(block_offsets.x + x, block_offsets.y + y));
            }
        }

        System.Diagnostics.Stopwatch stopwatch = new();
        stopwatch.Start();
        foreach (Vector3Int BOffsets in block_offsets_list){
            TilemapBlock block = _TMapSys._TerrGen._generate_block(BOffsets, new LayerType());
            TMapDraw._draw_block(block);

        }

        foreach (Vector3Int BOffsets in block_offsets_list){
            ShadowGenerator._generate_shadow_from_compCollider(
                _TMapSys._TMapMon._get_blkObj(BOffsets, new LayerType()).obj,
                _TMapSys._TMapMon._get_blkObj(BOffsets, new LayerType()).compositeCollider
            );
        }

        stopwatch.Stop();
        Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds + ", regions: " + block_offsets_list.Count);
        return true;
    }


    public override bool _check_allow_init(){
        if (!_sys._initDone) return false;
        if (!_MatSys._check_all_info_initDone()) return false;
        if (!_MatSys._tile._check_P3D_all_loaded()) return false;
        if (!_InputSys._initDone) return false;
        return true;
        // return _GCfg._MatSys._TMap._check_info_initDone();
    }



}
