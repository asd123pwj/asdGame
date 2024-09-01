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



public class TilemapController: BaseClass{
    // ---------- system tool ----------
    // HierarchySearch _HierSearch;
    // ControlSystem _CtrlSys { get => _GCfg._CtrlSys; }
    // InputSystem _input_base;
    // GameConfigs _GCfg;
    // TilemapSystem TMapSys { get => _GCfg._TMapSys; }
    // ---------- unity ----------
    Tilemap TMap_modify { get => _TMapSys._tilemap_modify; }
    // ---------- sub script ----------
    TilemapBlockGenerate TMapGen { get => _TMapSys._TMapGen; }
    TilemapDraw TMapDraw { get => _TMapSys._TMapDraw; }
    TilemapConfig TMapCfg { get => _TMapSys._TMapCfg; }
    TilemapSaveLoad TMapSL { get => _TMapSys._TMapSL; }
    // ---------- status ----------
    private Vector3Int _tilemapBlock_offsets;
    private bool _tilemapBlockChange = true;
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

    public override void _update(){
        // if (!_check_loaded()) return;
        return;
        // _generate_spawn_block(new(0, 0));
        // Debug.Log("a");
        query_isTilemapBlockChange();

        trigger_tilemapBlockChange();
    }

    public override void _init(){
        _sys._InputSys._register_action("Menu 4", tmp_draw, "isFirstDown");

    }

    public bool tmp_draw(KeyPos keyPos, Dictionary<string, KeyInfo> keyStatus){
        Vector3Int block_offsets = _mapping_worldXY_to_blockXY(keyPos.mouse_pos_world, TMap_modify);
    
        List<TilemapRegion4Draw> regions = new();
        List<Vector3Int> block_offsets_list = new();

        // int loadBound = _GCfg.__block_loadBound;
        int loadBound = 4;
        for (int r = 0; r < loadBound; r++){
            for (int x = -r; x <= r; x++){
                int y = r - Mathf.Abs(x);
                block_offsets_list.Add(new Vector3Int(block_offsets.x + x, block_offsets.y + y));
                if (y != 0) block_offsets_list.Add(new Vector3Int(block_offsets.x + x, block_offsets.y - y));
            }
        }

        foreach (Vector3Int BOffsets in block_offsets_list){
            TilemapBlock block = TMapGen._generate_block(BOffsets);
            TMapSL._load_block(block);
            regions.Add(TMapDraw._get_draw_region(TMap_modify, block));
        }

        if (regions.Count > 0) TMapDraw._draw_region(TMap_modify, regions).Forget();
        return true;
    }

    public override bool _check_allow_init(){
        if (!_sys._initDone) return false;
        if (!_MatSys._check_all_info_initDone()) return false;
        if (!_InputSys._initDone) return false;
        return true;
        // return _GCfg._MatSys._TMap._check_info_initDone();
    }

    async UniTaskVoid query_trigger(float query_time){
    // IEnumerator query_trigger(float query_time){
        while (true){
            if (!_check_allow_init()){
                await UniTask.Delay(TimeSpan.FromSeconds(query_time));
                continue;
            }
            _generate_spawn_block(new(0, 0));
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
        Vector3Int block_offsets = _mapping_worldXY_to_blockXY(world_pos, TMap_modify);
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
            _balance_tilemap(_tilemapBlock_offsets).Forget();
            _tilemapBlockChange = false;
            // Debug.Log("_tilemapBlockChange = false");
        }
    }

    // public async UniTaskVoid _balance_tilemap(Vector3Int block_offsets_new, CancellationTokenSource cancel_token) {
    public async UniTaskVoid _balance_tilemap(Vector3Int block_offsets_new) {
    // public IEnumerator _balance_tilemap(Vector3Int block_offsets_new) {
    // public void _balance_tilemap(Vector3Int block_offsets_new, CancellationTokenSource cancel_token) {
        // cancel_token = new CancellationTokenSource();
        Vector3Int BOffsets = block_offsets_new;
        int loadB = _GCfg.__block_loadBound;
        int unloadB = _GCfg.__block_unloadBound;
        List<Vector3Int> loads = new List<Vector3Int>(TMapCfg.__blockLoads_list);
        List<Vector3Int> loads_new = new List<Vector3Int>();
        List<Vector3Int> unloads_new = new List<Vector3Int>();

        // for (int r = 0; r < loadB; r++){
        //     for (int x = -r; x <= r; x++){
        //         int y = r - Mathf.Abs(x);
        //         loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y + y));
        //         if (y != 0) loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y - y));
        //     }
        // }

        // int loadBound = 4;
        for (int r = 0; r < loadB; r++){
            for (int x = -r; x <= r; x++){
                int y = r - Mathf.Abs(x);
                loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y + y));
                if (y != 0) loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y - y));
            }
        }



        List<TilemapRegion4Draw> regions = new();
        List<Vector3Int> loads_wait = loads_new.Except(loads).ToList();
        foreach(Vector3Int block_offsets in loads_wait){
            TilemapBlock block = TMapGen._generate_block(block_offsets);
            TMapSL._load_block(block);
            regions.Add(TMapDraw._get_draw_region(TMap_modify, block));
        }
        // if (regions.Count > 0) TMapDraw._draw_region(TMap_modify, regions, cancel_token.Token).Forget();
        if (regions.Count > 0) TMapDraw._draw_region(TMap_modify, regions).Forget();


        for (int r = 0; r < unloadB; r++){
            for (int x = -r; x <= r; x++){
                int y = r - Mathf.Abs(x);
                unloads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y + y));
                if (y != 0) unloads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y - y));
            }
        }
        List<Vector3Int> unloads_wait = loads.Except(unloads_new).ToList();
        foreach(Vector3Int block_offsets in unloads_wait){
            TMapSL._unload_block(block_offsets);
        }
        await UniTask.Yield();
        // yield return null;
    }

    public TilemapBlock _generate_spawn_block(Vector3 spawn_worldPos){
        Vector3Int map_pos = TMap_modify.WorldToCell(spawn_worldPos);
        TilemapBlock block = TMapGen._generate_spawn_block(map_pos, TMap_modify);
        TMapSL._load_block(block);
        List<TilemapRegion4Draw> regions = new(){TMapDraw._get_draw_region(TMap_modify, block)};
        // TMapDraw._draw_region(TMap_modify, regions, new()).Forget();
        TMapDraw._draw_region(TMap_modify, regions).Forget();
        return block;
    }
    


    // ---------- mapping ----------
    public Vector3Int _mapping_worldXY_to_mapXY(Vector3 world_pos, Tilemap tilemap){
        return TMapCfg._mapping_worldXY_to_mapXY(world_pos, tilemap);
    }

    public Vector3Int _mapping_worldXY_to_blockXY(Vector3 world_pos, Tilemap tilemap){
        return TMapCfg._mapping_worldXY_to_blockXY(world_pos, tilemap);
    }

    public Vector3Int _mapping_mapXY_to_blockXY(Vector3Int map_pos){
        return TMapCfg._mapping_mapXY_to_blockXY(map_pos);
    }

    
}
