using System.Collections;
using System.Collections.Generic;
using System;
using System.Threading;
using UnityEngine;
using UnityEngine.Tilemaps;
using Cysharp.Threading.Tasks;

public class ObjectBase : MonoBehaviour{
    public Tilemap _tilemap;
    public TilemapSystem _tilemap_system;
    bool isFirst = true;
    private CancellationTokenSource _cancel_balanceTilemap;

    // ---------- info ----------
    private Vector3Int _tilemapBlock_offsets;

    // ---------- state ----------
    private bool _tilemapBlockChange = true;


    void Start(){
        Vector3 world_pos = transform.position;
        _tilemap_system._TMapCtrl._generate_spawn_block(world_pos);
        
    }

    // Update is called once per frame
    void Update(){
        if (isFirst){
            // StartCoroutine(query_trigger(0.1f));
            query_trigger(0.1f).Forget();
        }
        isFirst = false;
    }

    async UniTaskVoid query_trigger(float query_time){
    // IEnumerator query_trigger(float query_time){
        while (true){
            // ---------- query ----------
            query_isTilemapBlockChange();

            // ---------- query ----------
            trigger_tilemapBlockChange();
            // yield return new WaitForSeconds(query_time);
            await UniTask.Delay(TimeSpan.FromSeconds(query_time));
        }
    }

    void query_isTilemapBlockChange(){
        Vector3 world_pos = transform.position;
        Vector3Int block_offsets = _tilemap_system._TMapCtrl._mapping_worldXY_to_blockXY(world_pos, _tilemap);
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
            if (_cancel_balanceTilemap != null) _cancel_balanceTilemap.Cancel();
            _cancel_balanceTilemap = new CancellationTokenSource();
            _tilemap_system._TMapCtrl._balance_tilemap(_tilemapBlock_offsets, _cancel_balanceTilemap).Forget();
            _tilemapBlockChange = false;
        }
    }

}
