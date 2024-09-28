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
    TilemapBlockGenerator TMapGen { get => _TMapSys._TMapGen; }
    TilemapDraw TMapDraw { get => _TMapSys._TMapDraw; }
    TilemapAxis TMapCfg { get => _TMapSys._TMapAxis; }
    TilemapSaveLoad TMapSL { get => _TMapSys._TMapSL; }
    // ---------- status ---------- // 
    private Vector3Int _tilemapBlock_offsets;
    private bool _tilemapBlockChange = true;
    public Vector3Int _query_point;
    public Vector3Int _query_point_prev = new(-999999999, -999999999, -999999999);
    // private CancellationTokenSource _cancel_balanceTilemap;

    // Start is called before the first frame update
    public TilemapController(){
        update_interval = 0.5f;
        // _GCfg = game_configs;
        // Debug.Log("a");
        // load_tiles_info();
        // query_trigger(0.5f).Forget();
        // _GCfg._UpdateSys._add_updater(update, 0.5f);
        
    }

    public override void _init(){
        _sys._InputSys._register_action("Menu 4", tmp_draw, "isFirstDown");

    }

    // public override void _update(){
    //     _task_update_queryPoint();
    //     if (_query_point_prev == _query_point) return;
    //     // _task_prepare_tilemap();
    //     ThreadMonitor._add_untilDone(_task_prepare_tilemap);
    //     Debug.Log("prepare tilemap");
    //     _task_draw_tilemap();
    //     _query_point_prev = _query_point;
    // }

    public override async UniTask _loop(){
        while(true){
            _task_update_queryPoint();
            if (_query_point_prev == _query_point) {
                await UniTask.Yield();
                continue;
            }
            // _task_prepare_tilemap();
            var task = UniTask.RunOnThreadPool(() => _task_prepare_tilemap());
            await task;
            _task_draw_tilemap();
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
            _query_point = _TMapSys._TMapAxis._mapping_worldPos_to_blockOffsets(player_pos, "L1_Middle");
        }
    }

    public bool _task_prepare_tilemap(){
        // while (true) ;
        Vector3Int prepare_r = _GCfg._sysCfg.TMap_prepare_blocksAround_RadiusMinusOne_loading;
        for (int x = -prepare_r.x; x <= prepare_r.x; x++){
            for (int y = -prepare_r.y; y <= prepare_r.y; y++){
                _TMapSys._TMapZoneGen._prepare_zone_in_blockOffsets(_query_point + new Vector3Int(x, y));
            }
        }
        return true;
    }

    public void _task_draw_tilemap(){
        Vector3Int draw_r = _GCfg._sysCfg.TMap_prepare_blocksAround_RadiusMinusOne_loading;
        for (int x = -draw_r.x; x <= draw_r.x; x++){
            for (int y = -draw_r.y; y <= draw_r.y; y++){
                if (!_TMapSys._TMapMon._check_block_load(_query_point + new Vector3Int(x, y), "L1_Middle")) continue;
                TilemapBlock block = _TMapSys._TMapMon._get_block(_query_point + new Vector3Int(x, y), "L1_Middle");
                // TilemapBlock block = TMapGen._generate_block(_query_point + new Vector3Int(x, y));
                TMapDraw._draw_block(block);
                
                ShadowGenerator._generate_shadow_from_compCollider(
                    _TMapSys._TMapMon._get_blkObj(block.offsets, "L1_Middle").obj,
                    _TMapSys._TMapMon._get_blkObj(block.offsets, "L1_Middle").compositeCollider
                );
            }
        }
    }

    public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        Vector3Int block_offsets = TMapCfg._mapping_worldPos_to_blockOffsets(keyPos.mouse_pos_world, "L1_Middle");
    
        List<Vector3Int> block_offsets_list = new();

        Vector3Int blocks_around_loading = _GCfg._sysCfg.TMap_draw_blocksAround_RadiusMinusOne_loading;
        for (int x = -blocks_around_loading.x; x <= blocks_around_loading.x; x++){
            for (int y = -blocks_around_loading.y; y <= blocks_around_loading.y; y++){
                block_offsets_list.Add(new Vector3Int(block_offsets.x + x, block_offsets.y + y));
            }
        }

        System.Diagnostics.Stopwatch stopwatch = new();
        stopwatch.Start();
        foreach (Vector3Int BOffsets in block_offsets_list){
            TilemapBlock block = TMapGen._generate_block(BOffsets);
            // _TMapSys._TMapMon._load_block(block, "L1_Middle");
            TMapDraw._draw_block(block);

            // Region4DrawTilemapBlock region = TMapDraw._get_draw_region(block);
            // Dictionary<Vector3Int, Region4DrawTilemapBlock> regions_placeholder = TMapDraw._get_draw_regions_placeholder(block);

            // Tilemap TMap = _TMapSys._TMapMon._get_blkObj(BOffsets, "L1_Middle").TMap;
            // TMapDraw._draw_region(TMap, region).Forget();

            // foreach (Vector3Int offsets in regions_placeholder.Keys){
            //     Tilemap TMap_placeholder = _TMapSys._TMapMon._get_blkObj(offsets, "L1_Middle").TMap;
            //     TMapDraw._draw_region(TMap_placeholder, regions_placeholder[offsets]).Forget();
            // }
        }

        foreach (Vector3Int BOffsets in block_offsets_list){
            ShadowGenerator._generate_shadow_from_compCollider(
                _TMapSys._TMapMon._get_blkObj(BOffsets, "L1_Middle").obj,
                _TMapSys._TMapMon._get_blkObj(BOffsets, "L1_Middle").compositeCollider
            );
        }

        stopwatch.Stop();
        Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds + ", regions: " + block_offsets_list.Count);
        // if (regions.Count > 0) {
        //     Tilemap TMap = _TMapSys._TMapMon._get_tilemap(block)
        //     TMapDraw._draw_region(TMap_modify, regions).Forget();
        // }
        return true;
    }


    public override bool _check_allow_init(){
        if (!_sys._initDone) return false;
        if (!_MatSys._check_all_info_initDone()) return false;
        if (!_InputSys._initDone) return false;
        return true;
        // return _GCfg._MatSys._TMap._check_info_initDone();
    }







    public bool _prepare_zone(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        // Vector3Int block_offsets = TMapCfg._mapping_worldXY_to_blockXY(keyPos.mouse_pos_world, TMap_modify);
        Vector3Int block_offsets = TMapCfg._mapping_worldPos_to_mapPos(keyPos.mouse_pos_world, "L1_Middle");
    
        List<Vector3Int> block_offsets_list = new();

        Vector3Int blocks_around_loading = _GCfg._sysCfg.TMap_draw_blocksAround_RadiusMinusOne_loading;
        for (int x = -blocks_around_loading.x; x <= blocks_around_loading.x; x++){
            for (int y = -blocks_around_loading.y; y <= blocks_around_loading.y; y++){
                block_offsets_list.Add(new Vector3Int(block_offsets.x + x, block_offsets.y + y));
            }
        }

        System.Diagnostics.Stopwatch stopwatch = new System.Diagnostics.Stopwatch();
        stopwatch.Start();
        foreach (Vector3Int BOffsets in block_offsets_list){
            TilemapBlock block = TMapGen._generate_block(BOffsets);
            TMapDraw._draw_block(block);
            // _TMapSys._TMapMon._load_block(block, "L1_Middle");

            // Region4DrawTilemapBlock region = TMapDraw._get_draw_region(block);
            // Dictionary<Vector3Int, Region4DrawTilemapBlock> regions_placeholder = TMapDraw._get_draw_regions_placeholder(block);

            // Tilemap TMap = _TMapSys._TMapMon._get_blkObj(BOffsets, "L1_Middle").TMap;
            // TMapDraw._draw_region(TMap, region).Forget();

            // foreach (Vector3Int offsets in regions_placeholder.Keys){
            //     Tilemap TMap_placeholder = _TMapSys._TMapMon._get_blkObj(offsets, "L1_Middle").TMap;
            //     TMapDraw._draw_region(TMap_placeholder, regions_placeholder[offsets]).Forget();
            // }
        }

        foreach (Vector3Int BOffsets in block_offsets_list){
            ShadowGenerator._generate_shadow_from_compCollider(
                _TMapSys._TMapMon._get_blkObj(BOffsets, "L1_Middle").obj,
                _TMapSys._TMapMon._get_blkObj(BOffsets, "L1_Middle").compositeCollider
            );
        }

        stopwatch.Stop();
        Debug.Log("Time loop: " + stopwatch.ElapsedMilliseconds + ", regions: " + block_offsets_list.Count);
        // if (regions.Count > 0) {
        //     Tilemap TMap = _TMapSys._TMapMon._get_tilemap(block)
        //     TMapDraw._draw_region(TMap_modify, regions).Forget();
        // }
        return true;
    }












    async UniTaskVoid query_trigger(float query_time){
    // IEnumerator query_trigger(float query_time){
        while (true){
            if (!_check_allow_init()){
                await UniTask.Delay(TimeSpan.FromSeconds(query_time));
                continue;
            }
            // _generate_spawn_block(new(0, 0));
            // ---------- query ----------
            query_isTilemapBlockChange();

            // ---------- trigger ----------
            trigger_tilemapBlockChange();
            // yield return new WaitForSeconds(query_time);
            await UniTask.Delay(TimeSpan.FromSeconds(query_time));
        }
    }

    void query_isTilemapBlockChange(){
        if (_CtrlSys == null || _CtrlSys._player == null) return;
        // if (_CtrlSys == null) return;
        // Debug.Log("query_isTilemapBlockChange");
        // if (_CtrlSys._player == null) return;
        Vector3 world_pos = _CtrlSys._player.transform.position;
        // Vector3 world_pos = new(0, 0);
        // Vector3Int block_offsets = TMapCfg._mapping_worldXY_to_blockXY(world_pos, TMap_modify);
        Vector3Int block_offsets = TMapCfg._mapping_worldPos_to_blockOffsets(world_pos, "L1_Middle");
        // Debug.Log("offsets: " + block_offsets);
        if (_tilemapBlock_offsets != block_offsets){
            // init
            _tilemapBlock_offsets = block_offsets;
            _tilemapBlockChange = true;
        }
    }

    void trigger_tilemapBlockChange(){
        if (_tilemapBlockChange){
            // Debug.Log("Block change: " + _tilemapBlock_offsets);
            // _tilemap_system._balance_tilemap(_tilemapBlock_offsets).Forget();
            // StartCoroutine(_tilemap_system._balance_tilemap(_tilemapBlock_offsets));
            // _tilemap_system._balance_tilemap(_tilemapBlock_offsets);
            // _tilemapBlockChange = false;
            // if (_cancel_balanceTilemap != null) _cancel_balanceTilemap.Cancel();
            // _cancel_balanceTilemap = new CancellationTokenSource();
            // _balance_tilemap(_tilemapBlock_offsets, _cancel_balanceTilemap).Forget();
            // _balance_tilemap(_tilemapBlock_offsets).Forget();
            _tilemapBlockChange = false;
            // Debug.Log("_tilemapBlockChange = false");
        }
    }

    // public async UniTaskVoid _balance_tilemap(Vector3Int block_offsets_new, CancellationTokenSource cancel_token) {
    // public async UniTaskVoid _balance_tilemap(Vector3Int block_offsets_new) {
    // // public IEnumerator _balance_tilemap(Vector3Int block_offsets_new) {
    // // public void _balance_tilemap(Vector3Int block_offsets_new, CancellationTokenSource cancel_token) {
    //     // cancel_token = new CancellationTokenSource();
    //     Vector3Int BOffsets = block_offsets_new;
    //     int loadB = _GCfg.__block_loadBound;
    //     int unloadB = _GCfg.__block_unloadBound;
    //     List<Vector3Int> loads = new List<Vector3Int>(_TMapSys._TMapMon._TMap_blocks["L1_Middle"].Keys);
    //     List<Vector3Int> loads_new = new List<Vector3Int>();
    //     List<Vector3Int> unloads_new = new List<Vector3Int>();

    //     // for (int r = 0; r < loadB; r++){
    //     //     for (int x = -r; x <= r; x++){
    //     //         int y = r - Mathf.Abs(x);
    //     //         loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y + y));
    //     //         if (y != 0) loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y - y));
    //     //     }
    //     // }

    //     // int loadBound = 4;
    //     // for (int r = 0; r < loadB; r++){
    //     //     for (int x = -r; x <= r; x++){
    //     //         int y = r - Mathf.Abs(x);
    //     //         loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y + y));
    //     //         if (y != 0) loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y - y));
    //     //     }
    //     // }

    //     Vector3Int blocks_around_loading = _GCfg._sysCfg.TMap_blocksAround_RadiusMinusOne_loading;
    //     // int loadBound = 4;
    //     // for (int r = 0; r < loadBound; r++){
    //     //     for (int x = -r; x <= r; x++){
    //     //         int y = r - Mathf.Abs(x);
    //     //         block_offsets_list.Add(new Vector3Int(block_offsets.x + x, block_offsets.y + y));
    //     //         if (y != 0) block_offsets_list.Add(new Vector3Int(block_offsets.x + x, block_offsets.y - y));
    //     //     }
    //     // }
    //     for (int x = -blocks_around_loading.x; x <= blocks_around_loading.x; x++){
    //         for (int y = -blocks_around_loading.y; y <= blocks_around_loading.y; y++){
    //             loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y + y));
    //         }
    //     }


    //     List<Region4DrawTilemapBlock> regions = new();
    //     List<Vector3Int> loads_wait = loads_new.Except(loads).ToList();
    //     foreach(Vector3Int block_offsets in loads_wait){
    //         TilemapBlock block = TMapGen._generate_block(block_offsets);
    //         _TMapSys._TMapMon._load_block(block, "L1_Middle");
    //         regions.Add(TMapDraw._get_draw_region(block));
    //     }
    //     // if (regions.Count > 0) TMapDraw._draw_region(TMap_modify, regions, cancel_token.Token).Forget();
    //     if (regions.Count > 0) TMapDraw._draw_regions(TMap_modify, regions).Forget();


    //     for (int r = 0; r < unloadB; r++){
    //         for (int x = -r; x <= r; x++){
    //             int y = r - Mathf.Abs(x);
    //             unloads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y + y));
    //             if (y != 0) unloads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y - y));
    //         }
    //     }
    //     List<Vector3Int> unloads_wait = loads.Except(unloads_new).ToList();
    //     foreach(Vector3Int block_offsets in unloads_wait){
    //         _TMapSys._TMapMon._unload_block(block_offsets, "L1_Middle");
    //     }
    //     await UniTask.Yield();
    //     // yield return null;
    // }

    // public TilemapBlock _generate_spawn_block(Vector3 spawn_worldPos){
    //     // Vector3Int map_pos = TMap_modify.WorldToCell(spawn_worldPos);
    //     Vector3Int map_pos = TMapCfg._mapping_worldPos_to_mapPos(spawn_worldPos, "L1_Middle");
    //     TilemapBlock block = TMapGen._generate_spawn_block(map_pos, TMap_modify);
    //     _TMapSys._TMapMon._load_block(block, "L1_Middle");
    //     List<Region4DrawTilemapBlock> regions = new(){TMapDraw._get_draw_region(block)};
    //     // TMapDraw._draw_region(TMap_modify, regions, new()).Forget();
    //     TMapDraw._draw_regions(TMap_modify, regions).Forget();
    //     return block;
    // }
    


    // ---------- mapping ----------
    // public Vector3Int _mapping_worldXY_to_mapXY(Vector3 world_pos, Tilemap tilemap){
    //     return TMapCfg._mapping_worldXY_to_mapXY(world_pos, tilemap);
    // }

    // public Vector3Int _mapping_worldXY_to_blockXY(Vector3 world_pos, Tilemap tilemap){
    //     return TMapCfg._mapping_worldXY_to_blockXY(world_pos, tilemap);
    // }

    // public Vector3Int _mapping_mapXY_to_blockXY(Vector3Int map_pos){
    //     return TMapCfg._mapping_mapXY_to_blockXY(map_pos);
    // }

    
}
