using System.Collections.Generic;
using UnityEngine;
using UnityEngine.Tilemaps;


public class TilemapZoneGenerator: BaseClass{
    Vector3Int zone_size => _GCfg._sysCfg.TMap_blocks_per_zone;
    Vector3Int keep_block = Vector3Int.one; // num_keep_block_for_zoneTransition. why zoneTransition? for fix the block in zone, transitionBlock between zone is random
    public TilemapZoneGenerator(){}
    
    public void _prepare_zone_by_worldPos(Vector3Int world_pos){
        Vector3Int zone_offsets = _TMapSys._TMapCfg._mapping_worldPos_to_zoneOffsets(world_pos, "L1_Middle");
        _prepare_zone(zone_offsets);
    }
    public void _prepare_zone(Vector3Int zone_offsets){
        for (int i = keep_block.x; i < zone_size.x - keep_block.x; i++){
            for (int j = keep_block.y; j < zone_size.y - keep_block.y; j++){
                Vector3Int block_offsets = zone_offsets * zone_size + new Vector3Int(i, j, 0);
                TilemapBlock block = _TMapSys._TMapGen._generate_block(block_offsets);
                _TMapSys._TMapMon._load_block(block, "L1_Middle");
            }
        }
    }

    // public TilemapBlock _generate_block(Vector3Int block_offsets, Vector3Int[] extra_targets=null, string[] direction=null){
    //     TilemapBlock block = new() {
    //         offsets = block_offsets,
    //         isExist = true,
    //         size = _GCfg._sysCfg.TMap_tiles_per_block,
    //         // seed = _GCfg._sysCfg.seed
    //     };
    //     TilemapBlockAround BAround = new(block);

    //     block = _terrain._random_terrainHier1(block, BAround);
    //     block = _terrain._random_terrainHier2_random(block, BAround);
    //     block = BDir._random_direction(block, BAround, _terrain, extra_targets, direction);
    //     block = fill_1DBlock(block);
    //     block = generate_2Dblock_transition(block, BAround);
    //     block = _block_mineral._generate_2DBlock_mineral(block);
    //     return block;
    // }


}
