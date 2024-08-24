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



public class TilemapSystem : MonoBehaviour{
    // ---------- system tool ----------
    SystemManager sys;
    ControlSystem _CtrlSys { get => sys._CtrlSys; }
    // InputSystem _input_base;
    GameConfigs _GCfg { get => sys._GCfg; }
    // ---------- unity ----------
    public Tilemap _tilemap_modify;
    // ---------- sub script ----------
    public TilemapBlockGenerate _TMapGen;
    public TilemapDraw _TMapDraw;
    public TilemapConfig _TMapCfg;
    public TilemapSaveLoad _TMapSL;
    public TilemapController _TMapCtrl;
    // ---------- status ----------
    public bool _isInit = true;
    private Vector3Int _tilemapBlock_offsets;
    private bool _tilemapBlockChange = true;
    private CancellationTokenSource _cancel_balanceTilemap;

    // Start is called before the first frame update
    void Start(){
        sys = GameObject.Find("System").GetComponent<SystemManager>();
        sys._TMapSys = this;        
        // _GCfg = sys._searchInit<GameConfigs>("System");
        // _CtrlSys = sys._searchInit<ControlSystem>("System");
        // _input_base = _hierarchy_search._searchInit<InputSystem>("Input");


        // Vector3 world_pos = transform.position;
    }

    // Update is called once per frame
    void Update(){
        init();
        // _TMapCtrl._update();
    }

    void init(){
        if (!_isInit) return;
        _TMapCfg = new TilemapConfig(_GCfg);
        _TMapDraw = new TilemapDraw(_TMapCfg, _GCfg);
        _TMapGen = new TilemapBlockGenerate(_TMapCfg, _GCfg);
        _TMapSL = new(_TMapCfg, _GCfg);
        _TMapCtrl = new(_GCfg);
        _isInit = false;
    }

    // async UniTaskVoid query_trigger(float query_time){
    // // IEnumerator query_trigger(float query_time){
    //     while (true){
    //         // ---------- query ----------
    //         query_isTilemapBlockChange();

    //         // ---------- trigger ----------
    //         trigger_tilemapBlockChange();
    //         // yield return new WaitForSeconds(query_time);
    //         await UniTask.Delay(TimeSpan.FromSeconds(query_time));
    //     }
    // }

    // void query_isTilemapBlockChange(){
    //     if (_CtrlSys._player == null) return;
    //     Vector3 world_pos = _CtrlSys._player.transform.position;
    //     Vector3Int block_offsets = _mapping_worldXY_to_blockXY(world_pos, _tilemap_modify);
    //     // Debug.Log("offsets: " + block_offsets);
    //     if (_tilemapBlock_offsets != block_offsets){
    //         // init
    //         _tilemapBlock_offsets = block_offsets;
    //         _tilemapBlockChange = true;
    //     }
    // }

    // void trigger_tilemapBlockChange(){
    //     if (_tilemapBlockChange){
    //         // Debug.Log("Block change: " + _tilemapBlock_offsets);
    //         // _tilemap_system._balance_tilemap(_tilemapBlock_offsets).Forget();
    //         // StartCoroutine(_tilemap_system._balance_tilemap(_tilemapBlock_offsets));
    //         // _tilemap_system._balance_tilemap(_tilemapBlock_offsets);
    //         // _tilemapBlockChange = false;
    //         if (_cancel_balanceTilemap != null) _cancel_balanceTilemap.Cancel();
    //         _cancel_balanceTilemap = new CancellationTokenSource();
    //         _balance_tilemap(_tilemapBlock_offsets, _cancel_balanceTilemap).Forget();
    //         _tilemapBlockChange = false;
    //     }
    // }

    // public async UniTaskVoid _balance_tilemap(Vector3Int block_offsets_new, CancellationTokenSource cancel_token) {
    // // public IEnumerator _balance_tilemap(Vector3Int block_offsets_new) {
    // // public void _balance_tilemap(Vector3Int block_offsets_new, CancellationTokenSource cancel_token) {
    //     // cancel_token = new CancellationTokenSource();
    //     Vector3Int BOffsets = block_offsets_new;
    //     int loadB = _GCfg.__block_loadBound;
    //     int unloadB = _GCfg.__block_unloadBound;
    //     List<Vector3Int> loads = new List<Vector3Int>(_TMapCfg.__blockLoads_list);
    //     List<Vector3Int> loads_new = new List<Vector3Int>();
    //     List<Vector3Int> unloads_new = new List<Vector3Int>();

    //     for (int r = 0; r < loadB; r++){
    //         for (int x = -r; x <= r; x++){
    //             int y = r - Mathf.Abs(x);
    //             loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y + y));
    //             if (y != 0) loads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y - y));
    //         }
    //     }
    //     List<TilemapRegion4Draw> regions = new();
    //     List<Vector3Int> loads_wait = loads_new.Except(loads).ToList();
    //     foreach(Vector3Int block_offsets in loads_wait){
    //         TilemapBlock block = _TMapGen._generate_1DBlock(block_offsets);
    //         _TMapSL._load_block(block);
    //         regions.Add(_TMapDraw._get_draw_region(_tilemap_modify, block));
    //     }
    //     if (regions.Count > 0) _TMapDraw._draw_region(_tilemap_modify, regions, cancel_token.Token).Forget();


    //     for (int r = 0; r < unloadB; r++){
    //         for (int x = -r; x <= r; x++){
    //             int y = r - Mathf.Abs(x);
    //             unloads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y + y));
    //             if (y != 0) unloads_new.Add(new Vector3Int(BOffsets.x + x, BOffsets.y - y));
    //         }
    //     }
    //     List<Vector3Int> unloads_wait = loads.Except(unloads_new).ToList();
    //     foreach(Vector3Int block_offsets in unloads_wait){
    //         _TMapSL._unload_block(block_offsets);
    //     }
    //     await UniTask.Yield();
    //     // yield return null;
    // }

    // public TilemapBlock _generate_spawn_block(Vector3 spawn_worldPos){
    //     Vector3Int map_pos = _tilemap_modify.WorldToCell(spawn_worldPos);
    //     TilemapBlock block = _TMapGen._generate_spawn_block(map_pos, _tilemap_modify);
    //     _TMapSL._load_block(block);
    //     List<TilemapRegion4Draw> regions = new(){_TMapDraw._get_draw_region(_tilemap_modify, block)};
    //     _TMapDraw._draw_region(_tilemap_modify, regions, new()).Forget();
    //     return block;
    // }
    


    // // ---------- mapping ----------
    // public Vector3Int _mapping_worldXY_to_mapXY(Vector3 world_pos, Tilemap tilemap){
    //     return _TMapCfg._mapping_worldXY_to_mapXY(world_pos, tilemap);
    // }

    // public Vector3Int _mapping_worldXY_to_blockXY(Vector3 world_pos, Tilemap tilemap){
    //     return _TMapCfg._mapping_worldXY_to_blockXY(world_pos, tilemap);
    // }

    // public Vector3Int _mapping_mapXY_to_blockXY(Vector3Int map_pos){
    //     return _TMapCfg._mapping_mapXY_to_blockXY(map_pos);
    // }

    
}
